import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';

import '../helpers/fakes.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

void main() {
  testWidgets('utilise le français quand la locale système est fr', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final container = ProviderContainer(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(
          MockOrganizationRepository(latency: Duration.zero),
        ),
        authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/organizations');
    await tester.pumpAndSettle();

    expect(find.text('Rechercher une organisation'), findsOneWidget);
  });

  testWidgets('retombe sur le français pour une locale non supportée', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final container = ProviderContainer(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(
          MockOrganizationRepository(latency: Duration.zero),
        ),
        authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/organizations');
    await tester.pumpAndSettle();

    expect(find.text('Rechercher une organisation'), findsOneWidget);
  });
}
