import 'dart:async';
import 'dart:convert';

import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connexion socket minimale.
///
/// Abstraite pour deux raisons : isoler `web_socket_channel` du reste du code
/// et permettre d'injecter une fausse connexion en test sans ouvrir de port.
abstract interface class QueueSocket {
  /// Messages entrants, déjà décodés par la couche transport.
  Stream<dynamic> get messages;

  /// Envoie un message texte. Sert au `ping` de maintien de connexion et au
  /// `sync` qui redemande un état complet sans rouvrir le socket.
  void send(String message);

  /// Ferme la connexion.
  Future<void> close();
}

class _ChannelSocket implements QueueSocket {
  _ChannelSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// Suivi de file par WebSocket, avec repli automatique sur du polling HTTP.
///
/// Contrat réel du backend :
///   `ws(s)://<hôte>/api/v1/tickets/ws/queue/{ticket_id}?agency_id=…&token=…`
///
/// Le jeton passe en paramètre de requête et non dans un en-tête : les
/// navigateurs — et donc la plateforme web de Flutter — n'autorisent pas
/// d'en-tête personnalisé à l'ouverture d'un WebSocket. C'est aussi la forme que
/// documente le serveur.
///
/// Le socket est fragile par nature (réseau mobile, mise en veille, redémarrage
/// d'instance). Le service bascule donc sur `GET /tickets/{id}` dès qu'il tombe,
/// et retente le socket à intervalles réguliers. La source accompagne chaque
/// mise à jour pour que l'écran puisse dire honnêtement « Direct » ou « Mode
/// secours ».
final class WebSocketQueueTrackingService implements QueueTrackingService {
  WebSocketQueueTrackingService({
    required AppConfig config,
    required ApiClient client,
    this.pollInterval = const Duration(seconds: 15),
    this.reconnectEveryPolls = 4,
    this.pingInterval = const Duration(seconds: 25),
    QueueSocket Function(Uri uri)? connect,
    Future<Map<String, dynamic>> Function(Ticket ticket)? pollOverride,
  }) : _config = config,
       _client = client,
       _connect =
           connect ?? ((uri) => _ChannelSocket(WebSocketChannel.connect(uri))),
       _pollOverride = pollOverride;

  final AppConfig _config;
  final ApiClient _client;

  /// Période du repli HTTP.
  final Duration pollInterval;

  /// Nombre de cycles de polling avant de retenter le WebSocket.
  final int reconnectEveryPolls;

  /// Période du `ping` de maintien de connexion.
  ///
  /// Les proxys et équilibreurs coupent une connexion inactive au bout de
  /// 30 à 60 s. Sans ping, un client qui attend 20 minutes verrait sa
  /// connexion tomber en boucle et basculerait définitivement en mode secours.
  final Duration pingInterval;

  final QueueSocket Function(Uri uri) _connect;

  /// Remplace l'appel HTTP du repli, pour les tests.
  ///
  /// Même raison d'être que [connect] : vérifier le comportement de secours
  /// sans monter de pile HTTP ni ouvrir de port.
  final Future<Map<String, dynamic>> Function(Ticket ticket)? _pollOverride;

  @override
  Stream<QueueUpdate> watch(Ticket ticket) {
    late final StreamController<QueueUpdate> controller;

    QueueSocket? socket;
    StreamSubscription<dynamic>? socketSubscription;
    Timer? pollTimer;
    Timer? pingTimer;

    var closed = false;
    var pollsSinceSocket = 0;
    var generation = 0;
    QueueSnapshot? last;

    // Le QR vient du ticket, jamais du flux : les événements de file ne le
    // transportent pas. Sans ce repli, l'écran de suivi perdrait le QR à la
    // première mise à jour de position.
    final qrFallback = ticket.qrToken;

    void emit(QueueSnapshot snapshot, QueueFeedSource source) {
      if (closed) {
        return;
      }
      last = snapshot;
      controller.add(QueueUpdate(snapshot: snapshot, source: source));
    }

    void emitFrom(Map<String, dynamic> json, QueueFeedSource source) {
      final snapshot = QueueSnapshot.fromJson(
        json,
        previous: last,
      ).copyWith(qrPayload: last?.qrPayload ?? qrFallback);
      emit(snapshot, source);
    }

    /// Applique un changement de statut sans toucher au reste.
    void emitStatus(QueueStatus status, {String? counter, String? called}) {
      final previous = last;
      final base =
          previous ??
          QueueSnapshot(
            ticketNumber: ticket.number,
            position: ticket.position,
            estimatedMinutes: ticket.estimatedMinutes,
            status: QueueStatus.waiting,
            updatedAt: DateTime.now(),
            qrPayload: qrFallback,
          );
      emit(
        base.copyWith(
          status: status,
          counterLabel: counter ?? base.counterLabel,
          calledNumber: called ?? base.calledNumber,
          updatedAt: DateTime.now(),
        ),
        QueueFeedSource.live,
      );
    }

    Future<void> pollOnce() async {
      try {
        final json = await _poll(ticket);
        emitFrom(json, QueueFeedSource.polling);
      } on Object {
        // Un échec de polling ne doit pas vider l'écran : on réémet la dernière
        // position connue en signalant qu'elle vient du mode secours.
        final previous = last;
        if (previous != null) {
          emit(
            previous.copyWith(updatedAt: DateTime.now()),
            QueueFeedSource.polling,
          );
        }
      }
    }

    // Déclaré avant définition : le repli et la reconnexion s'appellent
    // mutuellement.
    late final void Function() openSocket;

    void startPolling() {
      if (closed || pollTimer != null) {
        return;
      }
      pingTimer?.cancel();
      pingTimer = null;
      pollTimer = Timer.periodic(pollInterval, (_) {
        pollsSinceSocket++;
        if (pollsSinceSocket >= reconnectEveryPolls) {
          pollsSinceSocket = 0;
          openSocket();
        } else {
          unawaited(pollOnce());
        }
      });
      unawaited(pollOnce());
    }

    void handleMessage(Object? raw) {
      Object? decoded;
      try {
        decoded = jsonDecode(raw.toString());
      } on FormatException {
        // Message illisible : on ignore plutôt que de casser le flux.
        return;
      }
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      switch (decoded['type']) {
        case 'queue_update':
          emitFrom(decoded, QueueFeedSource.live);
        case 'your_turn':
          emitStatus(
            QueueStatus.called,
            counter: decoded['counter_name']?.toString(),
          );
        case 'ticket_called':
          // Diffusion de salle : le numéro appelé n'est pas forcément le nôtre.
          // On met à jour l'affichage du guichet, jamais notre statut.
          final called = decoded['called_number']?.toString();
          if (called != null && last != null) {
            emit(
              last!.copyWith(
                calledNumber: called,
                updatedAt: DateTime.now(),
              ),
              QueueFeedSource.live,
            );
          }
        case 'ticket_absent':
          emitStatus(QueueStatus.absent);
        case 'ticket_done':
          emitStatus(QueueStatus.done);
        // `connected` et `pong` sont des accusés de réception : le snapshot
        // arrive juste après `connected`, il n'y a rien à afficher ici.
      }
    }

    openSocket = () {
      if (closed) {
        return;
      }
      pollTimer?.cancel();
      pollTimer = null;

      final current = ++generation;
      unawaited(socketSubscription?.cancel());
      unawaited(socket?.close());
      socketSubscription = null;
      socket = null;

      final uri = _socketUri(ticket);
      if (uri == null) {
        // Pas de jeton : inutile de tenter un socket qui sera refusé en 4001.
        // Le polling, lui, passera par le renouvellement automatique du jeton.
        startPolling();
        return;
      }

      try {
        final opened = _connect(uri);
        socket = opened;
        socketSubscription = opened.messages.listen(
          (dynamic raw) {
            if (current != generation || closed) {
              return;
            }
            handleMessage(raw);
          },
          onError: (Object _) {
            if (current == generation) {
              startPolling();
            }
          },
          onDone: () {
            if (current == generation && !closed) {
              startPolling();
            }
          },
          cancelOnError: true,
        );
        pingTimer?.cancel();
        pingTimer = Timer.periodic(pingInterval, (_) {
          if (current != generation || closed) {
            return;
          }
          try {
            opened.send('ping');
          } on Object {
            // Socket déjà fermé : `onDone` enchaînera sur le repli.
          }
        });
      } on Object {
        startPolling();
      }
    };

    controller = StreamController<QueueUpdate>(
      onListen: openSocket,
      onCancel: () {
        closed = true;
        generation++;
        pollTimer?.cancel();
        pollTimer = null;
        pingTimer?.cancel();
        pingTimer = null;
        unawaited(socketSubscription?.cancel());
        unawaited(socket?.close());
      },
    );

    return controller.stream;
  }

  /// État complet par HTTP, quand le socket n'est pas disponible.
  ///
  /// `GET /tickets/{id}` renvoie la même vérité que le snapshot de connexion :
  /// position, statut, guichet. C'est ce qui permet au repli de rester fidèle
  /// au lieu d'afficher une position figée.
  Future<Map<String, dynamic>> _poll(Ticket ticket) {
    final override = _pollOverride;
    if (override != null) {
      return override(ticket);
    }
    final id = ticket.id;
    if (id == null) {
      // Ticket local : rien à demander au serveur.
      return Future<Map<String, dynamic>>.error(
        StateError('Ticket sans identifiant serveur.'),
      );
    }
    return _client.get('/tickets/$id');
  }

  /// URL du socket, ou null si le ticket n'est pas encore confirmé.
  ///
  /// Un ticket pris hors ligne n'a pas d'identifiant serveur : il n'existe
  /// qu'en local, et le serveur n'a rien à pousser pour lui.
  Uri? _socketUri(Ticket ticket) {
    final root = _config.apiRoot;
    final id = ticket.id;
    final token = _client.accessToken;
    if (root == null || id == null || token == null) {
      return null;
    }
    final prefix = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    return root.replace(
      scheme: root.scheme == 'https' ? 'wss' : 'ws',
      path: '$prefix/tickets/ws/queue/$id',
      queryParameters: <String, String>{
        'agency_id': ticket.agencyId,
        'token': token,
      },
    );
  }
}
