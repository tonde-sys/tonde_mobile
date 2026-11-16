import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/core/security/secure_key_value_store.dart';

final class _FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

void main() {
  test("l'access token reste en mémoire uniquement", () {
    final store = AuthTokenStore(_FakeSecureStore());

    expect(store.accessToken, isNull);
    store.setAccessToken('access-token');
    expect(store.accessToken, 'access-token');
  });

  test('le refresh token est lu et écrit dans le stockage sécurisé', () async {
    final secure = _FakeSecureStore();
    final store = AuthTokenStore(secure);

    await store.writeRefreshToken('refresh-token');

    expect(secure.values, containsPair('refresh_token', 'refresh-token'));
    expect(await store.readRefreshToken(), 'refresh-token');
  });

  test('clear efface access token et refresh token', () async {
    final secure = _FakeSecureStore();
    final store = AuthTokenStore(secure);
    store.setAccessToken('access-token');
    await store.writeRefreshToken('refresh-token');

    await store.clear();

    expect(store.accessToken, isNull);
    expect(secure.values, isEmpty);
  });
}
