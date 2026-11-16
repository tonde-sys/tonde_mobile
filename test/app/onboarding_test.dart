import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/bootstrap.dart';
import 'package:tonde/app/pages/onboarding_page.dart';
import 'package:tonde/app/pages/splash_page.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';

import '../helpers/fakes.dart';

/// Avance le temps par petites touches.
///
/// `pumpAndSettle` est inutilisable ici : l'animation de file d'attente et la
/// ligne de scan tournent en boucle, donc l'arbre ne se stabilise jamais.
Future<void> _advance(WidgetTester tester, [Duration step = const Duration(milliseconds: 60)]) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(step);
  }
}

/// Monte l'enchaînement de démarrage avec un cache vierge (ou déjà marqué).
Future<MemoryLocalCache> _pumpBootstrap(
  WidgetTester tester, {
  bool onboardingCompleted = false,
}) async {
  final cache = MemoryLocalCache();
  if (onboardingCompleted) {
    await cache.write(TondeBootstrap.onboardingKey, true);
  }

  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(cache),
      organizationRepositoryProvider.overrideWithValue(
        MockOrganizationRepository(latency: Duration.zero),
      ),
      authServiceProvider.overrideWithValue(FakeAuthService()),
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
  return cache;
}

void main() {
  testWidgets("le premier lancement montre l'écran de marque puis l'onboarding", (
    tester,
  ) async {
    await _pumpBootstrap(tester);

    // Écran de marque : le nom au-dessus du logo.
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('TONDE'), findsOneWidget);

    await tester.pump(TondeBootstrap.splashDuration);
    await _advance(tester);

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('No more endless queues.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Premier écran : pas de retour en arrière possible.
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('la présentation se parcourt puis se termine', (tester) async {
    final cache = await _pumpBootstrap(tester);
    await tester.pump(TondeBootstrap.splashDuration);
    await _advance(tester);

    await tester.tap(find.text('Next'));
    await _advance(tester);
    expect(find.text('Arrive right on time.'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await _advance(tester);
    expect(find.text('Already have a paper ticket? Scan it.'), findsOneWidget);
    // Dernier écran : « Passer » s'efface (il reste dans l'arbre, invisible et
    // non cliquable) et « Commencer » prend toute la largeur.
    final skipFade = tester.widget<AnimatedOpacity>(
      find.ancestor(of: find.text('Skip'), matching: find.byType(AnimatedOpacity)).first,
    );
    expect(skipFade.opacity, 0);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await _advance(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    expect(await cache.read(TondeBootstrap.onboardingKey), isTrue);
  });

  testWidgets('un lancement déjà présenté va droit à l’application', (tester) async {
    await _pumpBootstrap(tester, onboardingCompleted: true);

    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(TondeBootstrap.splashDuration);
    await _advance(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    // Non connecté : la porte d'authentification affiche la connexion.
    expect(find.text('Username'), findsOneWidget);
  });
}
