import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/auth/data/mock_auth_service.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';

/// Point de remplacement unique : le mock sera remplacé par le client
/// backend réel dès que le contrat d'authentification sera disponible.
///
/// Le cache local est transmis au mock pour qu'il restaure la session au
/// redémarrage : c'est ce qui rend le ticket consultable après une relance
/// sans réseau.
final authServiceProvider = Provider<AuthService>((ref) {
  return MockAuthService(cache: ref.watch(localCacheProvider));
});
