import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

/// Identité du flux de suivi d'un ticket.
///
/// Le flux appartient à un ticket précis, pas à son état courant : keyer sur
/// le [Ticket] entier rouvrait une connexion WebSocket à chaque changement de
/// statut, et l'ancienne restait vivante tant qu'un `ref.listen` la tenait.
///
/// Seuls les champs qui figurent dans l'URL du flux sont retenus. Ils ne
/// changent jamais au cours de la vie d'un ticket.
final class QueueTrackingKey {
  const QueueTrackingKey(this.ticket);

  final Ticket ticket;

  @override
  bool operator ==(Object other) =>
      other is QueueTrackingKey &&
      other.ticket.id == ticket.id &&
      other.ticket.number == ticket.number &&
      other.ticket.agencyId == ticket.agencyId;

  @override
  int get hashCode => Object.hash(ticket.id, ticket.number, ticket.agencyId);
}

/// Flux temps réel de la file pour un ticket donné.
///
/// Le flux est recréé quand le ticket change et refermé quand l'écran de suivi
/// est quitté (`autoDispose`) : aucune connexion WebSocket ne survit à la
/// sortie de l'écran.
final queueTrackingProvider = StreamProvider.autoDispose
    .family<QueueUpdate, QueueTrackingKey>((ref, key) {
      return ref.watch(queueTrackingServiceProvider).watch(key.ticket);
    });
