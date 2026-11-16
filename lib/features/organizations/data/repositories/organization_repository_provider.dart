import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/organizations/data/repositories/cached_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

/// Point d'injection unique du repository des organisations.
///
/// Le mock est enveloppé par [CachedOrganizationRepository] : le catalogue des
/// organisations et des agences reste consultable hors ligne. Le remplacement
/// par l'implémentation Dio se fera ici, sans changer le domaine ni la
/// présentation.
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return CachedOrganizationRepository(
    remote: const MockOrganizationRepository(),
    cache: ref.watch(localCacheProvider),
    isOnline: () => ref.read(isOnlineProvider),
  );
});
