import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/bootstrap.dart';
import 'package:tonde/app/pages/splash_page.dart';
import 'package:tonde/app/pages/startup_page.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/auth/presentation/pages/login_page.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';

import '../helpers/fakes.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

/// Monte l'enchaînement de démarrage comme un lancement à froid.
Future<ProviderContainer> _pumpStartup(
  WidgetTester tester, {
  User? session,
  bool onboardingCompleted = true,
  LocalCache? cache,
}) async {
  final localCache = cache ?? MemoryLocalCache();
  if (onboardingCompleted) {
    await localCache.write(TondeBootstrap.onboardingKey, true);
  }

  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(localCache),
      organizationRepositoryProvider.overrideWithValue(
        MockOrganizationRepository(latency: Duration.zero),
      ),
      authServiceProvider.overrideWithValue(FakeAuthService(current: session)),
      // Sans latence : le service fictif de démonstration attend 600 ms pour
      // rendre la prise de ticket perceptible, ce qui laisse des minuteurs
      // armés après la fin du test. Le démarrage n'a rien à démontrer.
      ticketServiceProvider.overrideWithValue(
        MockTicketService(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TondeBootstrap(),
    ),
  );
  await tester.pump();
  return container;
}

/// Avance image par image, sans `pumpAndSettle`.
///
/// La file d'attente du démarrage et l'indicateur d'attente tournent en
/// boucle : l'arbre ne se stabilise jamais, donc `pumpAndSettle` ne rendrait
/// pas la main. On avance à la main pour pouvoir observer **chaque** image.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets(
    'une session en cache mène au tableau de bord sans jamais montrer la connexion',
    (tester) async {
      await _pumpStartup(tester, session: _user);

      // Le critère du lot : aucune image intermédiaire ne doit être l'écran de
      // connexion. On inspecte chaque image du démarrage, pas seulement la
      // dernière — c'est justement le clignotement qu'on corrige.
      for (var i = 0; i < 40; i++) {
        expect(
          find.byType(LoginPage),
          findsNothing,
          reason: 'image $i du démarrage : la connexion ne doit pas apparaître',
        );
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(find.byType(LoginPage), findsNothing);
      expect(find.text('Manage your queue easily'), findsOneWidget);
    },
  );

  testWidgets('sans session, la porte d’authentification ouvre la connexion', (
    tester,
  ) async {
    await _pumpStartup(tester);
    await _advance(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('le logo du démarrage est centré comme l’icône native', (
    tester,
  ) async {
    // Montage direct : ce test ne porte que sur la géométrie de l'écran de
    // marque, inutile de traverser tout le démarrage.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const SplashPage(),
      ),
    );

    // Android 12+ dessine l'icône de son écran de démarrage au centre de
    // l'écran, sans possibilité de la décaler. Si le logo Flutter s'en écarte,
    // l'utilisateur voit un saut au moment où le moteur prend la main.
    final logo = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/app_logo.png',
    );
    expect(logo, findsOneWidget);

    final screen = tester.getRect(find.byType(SplashBrand));
    final logoCenter = tester.getCenter(logo);

    expect(
      (logoCenter.dx - screen.center.dx).abs(),
      lessThan(1),
      reason: 'le logo doit être centré horizontalement',
    );
    expect(
      (logoCenter.dy - screen.center.dy).abs(),
      lessThan(1.5),
      reason: 'le logo doit être centré verticalement',
    );
  });

  testWidgets('l’écran d’attente reprend la marque du démarrage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const StartupPage(),
      ),
    );

    expect(find.byType(SplashBrand), findsOneWidget);
    expect(find.text('TONDE'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
