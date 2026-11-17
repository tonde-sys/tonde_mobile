import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/auth/data/mock_auth_service.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';

void main() {
  test('se connecte avec le compte de démonstration', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(await service.currentUser(), isNull);

    final user = await service.login(
      email: MockAuthService.demoEmail,
      password: MockAuthService.demoPassword,
    );

    // L'identité affichée est l'e-mail : le backend n'a pas de nom
    // d'utilisateur, et le mock suit le même contrat pour que les écrans ne
    // dépendent pas du mode d'exécution.
    expect(user.email, MockAuthService.demoEmail);
    expect(user.name, 'Jospin Kanani');
    expect(await service.currentUser(), same(user));
  });

  test('ignore la casse et les espaces de l\'adresse', () async {
    final service = MockAuthService(latency: Duration.zero);

    final user = await service.login(
      email: '  ${MockAuthService.demoEmail.toUpperCase()}  ',
      password: MockAuthService.demoPassword,
    );

    expect(user.email, MockAuthService.demoEmail);
  });

  test('refuse un mot de passe incorrect', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.login(
        email: MockAuthService.demoEmail,
        password: 'mauvais',
      ),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('refuse une adresse inconnue', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.login(email: 'inconnu@example.com', password: '12345'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('crée un compte puis connecte l\'utilisateur', () async {
    final service = MockAuthService(latency: Duration.zero);

    final user = await service.register(
      name: 'Jean Test',
      email: 'jean.test@example.com',
      password: 'motdepasse',
    );

    expect(user.name, 'Jean Test');
    expect(user.email, 'jean.test@example.com');
    expect(await service.currentUser(), same(user));
  });

  test('refuse une adresse déjà prise', () async {
    final service = MockAuthService(latency: Duration.zero);

    expect(
      () => service.register(
        name: 'Autre',
        email: MockAuthService.demoEmail,
        password: 'motdepasse',
      ),
      throwsA(isA<EmailAlreadyTakenException>()),
    );
  });

  test('la déconnexion efface la session', () async {
    final service = MockAuthService(latency: Duration.zero);

    await service.login(
      email: MockAuthService.demoEmail,
      password: MockAuthService.demoPassword,
    );
    await service.logout();

    expect(await service.currentUser(), isNull);
  });
}
