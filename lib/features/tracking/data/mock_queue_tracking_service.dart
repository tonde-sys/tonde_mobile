import 'dart:async';

import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

/// Simulation locale du flux temps réel, pour la démo.
///
/// Le backend n'exposant pas encore de flux `queue`, ce service rejoue une file
/// réelle : **une personne devant soi est servie par minute**, comme au guichet.
/// Le client voit donc sa position décroître d'un rang par minute, le numéro
/// appelé progresser, puis son propre numéro être appelé et sa prise en charge
/// démarrer. L'état est conservé par numéro de ticket, de sorte que rouvrir
/// l'écran reprend la simulation là où elle s'était arrêtée plutôt que de
/// repartir de zéro.
///
/// À remplacer par [WebSocketQueueTrackingService] dès que le contrat sera
/// disponible : le point de bascule est `queueTrackingServiceProvider`.
final class MockQueueTrackingService implements QueueTrackingService {
  MockQueueTrackingService({this.tick = const Duration(minutes: 1)});

  /// Temps qu'une personne passe au guichet : une minute. La file avance donc
  /// d'un rang par minute, en temps réel.
  final Duration tick;

  /// Rang courant par numéro de ticket, conservé entre deux ouvertures.
  final Map<String, int> _positions = <String, int>{};

  /// Nombre de messages déjà émis par ticket, pour reprendre la simulation.
  final Map<String, int> _elapsed = <String, int>{};

  @override
  Stream<QueueUpdate> watch(Ticket ticket) {
    late final StreamController<QueueUpdate> controller;
    Timer? timer;

    var position = _positions[ticket.number] ?? ticket.position;
    var ticksAtFront = _elapsed[ticket.number] ?? 0;

    // Guichet stable pour un même ticket, sans dépendre de l'aléatoire.
    final counterNumber = (ticket.number.hashCode.abs() % 5) + 1;

    QueueSnapshot snapshot() {
      final QueueStatus status;
      if (position > 1) {
        status = QueueStatus.waiting;
      } else if (ticksAtFront >= 2) {
        status = QueueStatus.inService;
      } else {
        status = QueueStatus.called;
      }

      return QueueSnapshot(
        ticketNumber: ticket.number,
        position: position,
        // Une minute par personne devant soi : l'estimation suit la file.
        estimatedMinutes: position - 1,
        status: status,
        updatedAt: DateTime.now(),
        // Le numéro appelé est celui qui précède le client dans la file.
        calledNumber: _shift(ticket.number, position - 1),
        counterLabel: 'Guichet $counterNumber',
        qrPayload: _qrPayload(ticket),
      );
    }

    void advance() {
      if (position > 1) {
        position--;
        _positions[ticket.number] = position;
      } else {
        ticksAtFront++;
        _elapsed[ticket.number] = ticksAtFront;
      }
      if (ticksAtFront >= 2) {
        timer?.cancel();
        timer = null;
      }
      controller.add(
        QueueUpdate(snapshot: snapshot(), source: QueueFeedSource.live),
      );
    }

    controller = StreamController<QueueUpdate>(
      onListen: () {
        controller.add(
          QueueUpdate(snapshot: snapshot(), source: QueueFeedSource.live),
        );
        if (ticksAtFront < 2) {
          timer = Timer.periodic(tick, (_) => advance());
        }
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );

    return controller.stream;
  }

  /// Décale le numéro de ticket de [delta] rangs, en gardant le préfixe et la
  /// largeur (« T-1042 » décalé de 3 donne « T-1039 »).
  static String _shift(String number, int delta) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(number);
    if (match == null) {
      return number;
    }
    final prefix = match.group(1)!;
    final digits = match.group(2)!;
    final value = int.parse(digits) - delta;
    return '$prefix${value.toString().padLeft(digits.length, '0')}';
  }

  /// Charge utile de démonstration.
  ///
  /// La vraie signature sera produite par le backend et reçue telle quelle :
  /// le mobile ne signe jamais un ticket lui-même.
  static String _qrPayload(Ticket ticket) {
    return 'tonde://ticket/${ticket.number}'
        '?org=${ticket.organizationId}'
        '&agency=${ticket.agencyId}'
        '&sig=DEMO';
  }
}
