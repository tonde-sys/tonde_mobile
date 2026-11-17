import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/tickets/data/api_ticket_service.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Point d'injection unique du service de tickets.
///
/// Le service distant est enveloppé par [CachedTicketService] : lecture depuis
/// le cache hors ligne, écriture après chaque succès, et prise de ticket
/// différée quand le réseau manque. Ce comportement ne dépend pas de la source :
/// le mock comme le backend en bénéficient, et l'UI l'ignore.
final ticketServiceProvider = Provider<TicketService>((ref) {
  final cache = ref.watch(localCacheProvider);
  final config = ref.watch(appConfigProvider);
  return CachedTicketService(
    // Le mock reçoit le cache pour simuler un serveur qui se souvient de son
    // ticket d'une exécution à l'autre.
    remote: config.isApiConfigured
        ? ApiTicketService(client: ref.watch(apiClientProvider))
        : MockTicketService(store: cache),
    cache: cache,
    isOnline: () => ref.read(isOnlineProvider),
  );
});
