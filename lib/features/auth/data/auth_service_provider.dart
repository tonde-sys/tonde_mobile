import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/core/security/security_providers.dart';
import 'package:tonde/features/auth/data/api_auth_service.dart';
import 'package:tonde/features/auth/data/mock_auth_service.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';

/// Point de bascule unique entre la démo et le backend réel.
///
/// Sans `TONDE_API_BASE_URL`, aucune route n'existe : le mock fournit alors les
/// comptes de démonstration. Dès que la variable est renseignée, c'est le
/// serveur qui authentifie, et aucun écran ne change.
///
/// Le cache local est transmis aux deux implémentations, sous la même clé : une
/// application rouverte hors ligne retrouve son profil au lieu de renvoyer
/// l'utilisateur vers l'écran de connexion.
final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  final cache = ref.watch(localCacheProvider);
  if (!config.isApiConfigured) {
    return MockAuthService(cache: cache);
  }
  return ApiAuthService(
    client: ref.watch(apiClientProvider),
    tokens: ref.watch(authTokenStoreProvider),
    cache: cache,
  );
});
