import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tonde/core/config/app_config.dart';
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

  /// Ferme la connexion.
  Future<void> close();
}

class _ChannelSocket implements QueueSocket {
  _ChannelSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

/// Suivi de file par WebSocket, avec repli automatique sur du polling HTTP.
///
/// Le mobile ouvre `wss://<api>/ws/queue/{ticket}` et affiche chaque message
/// reçu. Si la connexion tombe (réseau mobile instable, mise en veille, erreur
/// serveur), le service bascule immédiatement sur un rafraîchissement HTTP
/// toutes les [pollInterval] et retente le WebSocket tous les
/// [reconnectEveryPolls] cycles. La source est transmise à l'écran, qui peut
/// ainsi signaler honnêtement « Direct » ou « Mode secours ».
///
/// Le contrat n'étant pas encore validé par l'équipe backend, le format des
/// messages est lu de façon tolérante par [QueueSnapshot.fromJson] et les deux
/// chemins (socket et HTTP) sont isolés ici : c'est le seul fichier à ajuster
/// quand le contrat sera figé.
final class WebSocketQueueTrackingService implements QueueTrackingService {
  WebSocketQueueTrackingService({
    required AppConfig config,
    required Dio dio,
    this.pollInterval = const Duration(seconds: 30),
    this.reconnectEveryPolls = 4,
    QueueSocket Function(Uri uri)? connect,
    Future<Map<String, dynamic>> Function(String ticketNumber)? fetchSnapshot,
  }) : _config = config,
       _dio = dio,
       _connect =
           connect ?? ((uri) => _ChannelSocket(WebSocketChannel.connect(uri))),
       _fetchSnapshot = fetchSnapshot;

  final AppConfig _config;
  final Dio _dio;

  /// Période du repli HTTP.
  final Duration pollInterval;

  /// Nombre de cycles de polling avant de retenter le WebSocket.
  final int reconnectEveryPolls;

  final QueueSocket Function(Uri uri) _connect;
  final Future<Map<String, dynamic>> Function(String ticketNumber)?
  _fetchSnapshot;

  @override
  Stream<QueueUpdate> watch(Ticket ticket) {
    late final StreamController<QueueUpdate> controller;

    QueueSocket? socket;
    StreamSubscription<dynamic>? socketSubscription;
    Timer? pollTimer;

    var closed = false;
    var pollsSinceSocket = 0;
    var generation = 0;
    QueueSnapshot? last;

    void emit(QueueUpdate update) {
      if (closed) {
        return;
      }
      last = update.snapshot;
      controller.add(update);
    }

    Future<void> pollOnce() async {
      try {
        final json = await _fetch(ticket.number);
        emit(
          QueueUpdate(
            snapshot: QueueSnapshot.fromJson(json),
            source: QueueFeedSource.polling,
          ),
        );
      } on Object {
        // Un échec de polling ne doit pas couper l'écran : on réémet la
        // dernière position connue en signalant qu'elle vient du mode secours.
        final previous = last;
        if (previous != null) {
          emit(
            QueueUpdate(
              snapshot: previous.copyWith(updatedAt: DateTime.now()),
              source: QueueFeedSource.polling,
            ),
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

      try {
        final opened = _connect(_socketUri(ticket.number));
        socket = opened;
        socketSubscription = opened.messages.listen(
          (dynamic raw) {
            if (current != generation || closed) {
              return;
            }
            try {
              final decoded = jsonDecode(raw.toString());
              if (decoded is Map<String, dynamic>) {
                emit(
                  QueueUpdate(
                    snapshot: QueueSnapshot.fromJson(decoded),
                    source: QueueFeedSource.live,
                  ),
                );
              }
            } on FormatException {
              // Message illisible : on ignore plutôt que de casser le flux.
            }
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
        unawaited(socketSubscription?.cancel());
        unawaited(socket?.close());
      },
    );

    return controller.stream;
  }

  Future<Map<String, dynamic>> _fetch(String ticketNumber) async {
    final override = _fetchSnapshot;
    if (override != null) {
      return override(ticketNumber);
    }
    // Chemin provisoire : à aligner sur le contrat backend validé.
    final response = await _dio.get<Map<String, dynamic>>(
      '/queue/$ticketNumber',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Uri _socketUri(String ticketNumber) {
    final base = _config.apiBaseUrl;
    if (base == null) {
      throw StateError('Aucune base URL API configurée pour le WebSocket.');
    }
    final prefix = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '$prefix/ws/queue/$ticketNumber',
    );
  }
}
