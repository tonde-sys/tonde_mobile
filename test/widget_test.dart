import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';

import 'helpers/fakes.dart';

const _user = User(name: 'Jospin Kanani', username: 'jospin kanani');

List<Override> _overrides({FakeAuthService? auth}) => [
  organizationRepositoryProvider.overrideWithValue(
    MockOrganizationRepository(latency: Duration.zero),
  ),
  authServiceProvider.overrideWithValue(
    auth ?? FakeAuthService(current: _user),
  ),
];

void main() {
  testWidgets('la connexion mène au tableau de bord', (tester) async {
    final container = ProviderContainer(
      overrides: _overrides(auth: FakeAuthService()),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    // Non connecté : la porte d'authentification redirige vers la connexion.
    expect(find.text('Username'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'jospin kanani');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Connecté : le tableau de bord s'affiche.
    expect(find.text('Manage your queue easily'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // La liste des organisations reste accessible.
    container.read(appRouterProvider).go('/organizations');
    await tester.pumpAndSettle();

    expect(find.text('Banque Horizon'), findsOneWidget);
  });

  testWidgets('affiche la page introuvable puis revient au tableau de bord', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/route-inconnue');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('le socle technique reste accessible sur /socle', (tester) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/socle');
    await tester.pumpAndSettle();

    expect(find.text('Technical foundation'), findsOneWidget);
  });
}
