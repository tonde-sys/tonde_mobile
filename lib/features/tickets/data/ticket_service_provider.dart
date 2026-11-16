import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Point d'injection unique du service de tickets.
///
/// Le service distant (mock à données fictives approuvé pour la démo) est
/// enveloppé par [CachedTicketService] : lecture depuis le cache hors ligne,
/// écriture après chaque succès, et prise de ticket différée quand le réseau
/// manque. Le remplacement par le client backend réel se fera ici, sans
/// toucher à l'UI.
final ticketServiceProvider = Provider<TicketService>((ref) {
  final cache = ref.watch(localCacheProvider);
  return CachedTicketService(
    // Le mock reçoit le cache pour simuler un serveur qui se souvient de son
    // ticket d'une exécution à l'autre.
    remote: MockTicketService(store: cache),
    cache: cache,
    isOnline: () => ref.read(isOnlineProvider),
  );
});
