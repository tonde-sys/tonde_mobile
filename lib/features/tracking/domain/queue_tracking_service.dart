import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';

/// Origine d'une mise à jour reçue.
enum QueueFeedSource {
  /// Message poussé par le WebSocket.
  live,

  /// Repli sur un rafraîchissement périodique HTTP.
  polling,
}

/// Mise à jour de la file, avec son origine.
///
/// L'écran affiche [source] pour que le client sache si sa position est
/// poussée en direct ou simplement rafraîchie périodiquement.
final class QueueUpdate {
  const QueueUpdate({required this.snapshot, required this.source});

  final QueueSnapshot snapshot;
  final QueueFeedSource source;
}

/// Suivi temps réel de la file d'attente.
///
/// Le flux est froid : une souscription ouvre la connexion, son annulation la
/// ferme. Aucun état n'est conservé côté mobile — le backend reste la source de
/// vérité de la position et du statut.
abstract interface class QueueTrackingService {
  /// Émet une mise à jour à chaque changement de position ou de statut.
  Stream<QueueUpdate> watch(Ticket ticket);
}
