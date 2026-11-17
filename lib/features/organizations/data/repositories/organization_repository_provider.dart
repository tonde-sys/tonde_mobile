import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/organizations/data/repositories/api_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/cached_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

/// Point d'injection unique du repository des organisations.
///
/// Les deux sources sont enveloppées par [CachedOrganizationRepository] : le
/// catalogue des organisations, agences et services reste consultable hors
/// ligne. C'est ce cache qui rend l'écran de choix utilisable dans une salle
/// d'attente sans réseau — cas courant, et précisément là où l'on prend un
/// ticket.
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return CachedOrganizationRepository(
    remote: config.isApiConfigured
        ? ApiOrganizationRepository(client: ref.watch(apiClientProvider))
        : const MockOrganizationRepository(),
    cache: ref.watch(localCacheProvider),
    isOnline: () => ref.read(isOnlineProvider),
  );
});
