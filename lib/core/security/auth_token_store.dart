import 'package:tonde/core/security/secure_key_value_store.dart';

/// Détient l'access token en mémoire uniquement et le refresh token dans le
/// stockage sécurisé (voir DECISIONS.md).
///
/// L'access token est perdu au redémarrage de l'application : la session est
/// alors récupérée via le refresh token, sans persister l'access token.
final class AuthTokenStore {
  AuthTokenStore(this._secure);

  static const String _refreshTokenKey = 'refresh_token';

  final SecureKeyValueStore _secure;

  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String token) => _accessToken = token;

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _secure.write(key: _refreshTokenKey, value: token);

  Future<void> clear() async {
    _accessToken = null;
    await _secure.delete(key: _refreshTokenKey);
  }
}
