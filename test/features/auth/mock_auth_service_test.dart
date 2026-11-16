import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/auth/data/mock_auth_service.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';

void main() {
  test('se connecte avec le compte de démonstration', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(await service.currentUser(), isNull);

    final user = await service.login(
      username: 'jospin kanani',
      password: '12345',
    );

    expect(user.username, 'jospin kanani');
    expect(user.name, 'Jospin Kanani');
    expect(await service.currentUser(), same(user));
  });

  test('refuse un mot de passe incorrect', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.login(username: 'jospin kanani', password: 'mauvais'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('refuse un nom d\'utilisateur inconnu', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.login(username: 'inconnu', password: '12345'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('crée un compte puis connecte l\'utilisateur', () async {
    final service = MockAuthService(latency: Duration.zero);

    final user = await service.register(
      name: 'Jean Test',
      username: 'jean.test',
      password: 'secret',
    );

    expect(user.name, 'Jean Test');
    expect(user.username, 'jean.test');
    expect(await service.currentUser(), same(user));
  });

  test('refuse un nom d\'utilisateur déjà pris', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.register(
        name: 'Autre',
        username: 'jospin kanani',
        password: 'secret',
      ),
      throwsA(isA<UsernameAlreadyTakenException>()),
    );
  });

  test('la déconnexion efface la session', () async {
    final service = MockAuthService(latency: Duration.zero);

    await service.login(username: 'jospin kanani', password: '12345');
    await service.logout();

    expect(await service.currentUser(), isNull);
  });
}
