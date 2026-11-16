import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';

import '../../helpers/fakes.dart';

List<Override> _overrides({FakeAuthService? auth}) => [
  organizationRepositoryProvider.overrideWithValue(
    MockOrganizationRepository(latency: Duration.zero),
  ),
  authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
];

void main() {
  testWidgets('exige des champs remplis', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsNWidgets(2));
  });

  testWidgets('affiche une erreur pour des identifiants refusés', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(auth: FakeAuthService(rejectLogin: true)),
        child: const TondeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'jospin kanani');
    await tester.enterText(find.byType(TextFormField).at(1), 'mauvais');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password.'), findsOneWidget);
  });

  testWidgets("l'inscription crée un compte et ouvre le tableau de bord", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jean Test');
    await tester.enterText(find.byType(TextFormField).at(1), 'jean.test');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Le nom n'apparaît plus dans l'onglet Plus : la tuile de compte n'affiche
    // que l'icône, et le détail s'ouvre au clic.
    expect(find.text('Jean Test'), findsNothing);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Jean Test'), findsOneWidget);
  });
}
