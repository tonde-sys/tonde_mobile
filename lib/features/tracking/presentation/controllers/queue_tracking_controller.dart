import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

/// Flux temps réel de la file pour un ticket donné.
///
/// Le flux est recréé quand le ticket change et refermé quand l'écran de suivi
/// est quitté (`autoDispose`) : aucune connexion WebSocket ne survit à la
/// sortie de l'écran.
final queueTrackingProvider = StreamProvider.autoDispose
    .family<QueueUpdate, Ticket>((ref, ticket) {
      return ref.watch(queueTrackingServiceProvider).watch(ticket);
    });
