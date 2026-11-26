import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/more_tab.dart';
import 'package:tonde/features/dashboard/presentation/widgets/tonde_navigation_bar.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_driver.dart';

import '../../helpers/fakes.dart';
import '../../helpers/screen.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'kananijospin63@gmail.com',
  phone: '+257 79490806',
  role: 'Agent',
  organization: 'TONDE - Bujumbura',
  createdAt: '2026-01-15',
);

List<Override> _overrides({LocalCache? cache, HomeWidgetBridge? homeWidget}) => [
  organizationRepositoryProvider.overrideWithValue(
    const MockOrganizationRepository(latency: Duration.zero),
  ),
  authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
  ticketServiceProvider.overrideWithValue(FakeTicketService()),
  if (cache != null) localCacheProvider.overrideWithValue(cache),
  if (homeWidget != null)
    homeWidgetBridgeProvider.overrideWithValue(homeWidget),
];

/// Passerelle de test qui accepte ou refuse l'épinglage du widget.
class _FakeHomeWidgetBridge implements HomeWidgetBridge {
  _FakeHomeWidgetBridge({this.pinSupported = false});

  final bool pinSupported;
  int pinRequests = 0;

  @override
  Future<void> update(HomeWidgetState state) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<bool> isPinSupported() async => pinSupported;

  @override
  Future<bool> requestPin() async {
    pinRequests++;
    return pinSupported;
  }
}

/// Ouvre l'application puis sélectionne l'onglet « Plus ».
Future<void> _openMoreTab(
  WidgetTester tester, {
  LocalCache? cache,
  HomeWidgetBridge? homeWidget,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(cache: cache, homeWidget: homeWidget),
      child: const TondeApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(TondeNavigationBar),
      matching: find.text('More'),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inMore(Finder matching) =>
    find.descendant(of: find.byType(MoreTab), matching: matching);

/// Cible une entrée de la feuille modale ouverte, sans confondre avec le
/// même libellé affiché derrière (par exemple « Sisitemu » comme valeur du
/// thème dans l'onglet Plus).
Finder _inSheet(Finder matching) =>
    find.descendant(of: find.byType(BottomSheet), matching: matching);

void main() {
  setUp(usePhoneSurfaceForEachTest);

  group('Onglet Plus', () {
    testWidgets('ne montre aucune donnée personnelle', (tester) async {
      await _openMoreTab(tester);

      expect(_inMore(find.text('Language')), findsOneWidget);
      expect(_inMore(find.text('Appearance')), findsOneWidget);
      expect(_inMore(find.text('About')), findsOneWidget);
      expect(_inMore(find.text('Sign out')), findsOneWidget);

      // La tuile de compte n'affiche que l'icône : ni nom, ni @username.
      expect(_inMore(find.byType(ProfileAvatar)), findsOneWidget);
      expect(_inMore(find.text('Jospin Kanani')), findsNothing);
      expect(_inMore(find.text('@jospin kanani')), findsNothing);

      // Les informations du compte vivent sur la page profil.
      expect(find.text('kananijospin63@gmail.com'), findsNothing);
      expect(find.text('+257 79490806'), findsNothing);
      expect(find.text('Agent'), findsNothing);
    });

    testWidgets('l\'icône de compte ouvre le profil avec les informations', (
      tester,
    ) async {
      await _openMoreTab(tester);

      await tester.tap(_inMore(find.byType(ProfileAvatar)));
      await tester.pumpAndSettle();

      expect(find.text('Jospin Kanani'), findsOneWidget);
      expect(find.text('kananijospin63@gmail.com'), findsOneWidget);
      expect(find.text('+257 79490806'), findsOneWidget);
      expect(find.text('Agent'), findsOneWidget);
    });

    testWidgets('choisir le kirundi change la langue de l\'interface', (
      tester,
    ) async {
      await _openMoreTab(tester);

      await tester.tap(_inMore(find.text('Language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirundi'));
      await tester.pumpAndSettle();

      // « Sign out » devient « Sohoka » : la préférence a bien traversé
      // jusqu'au MaterialApp.
      expect(_inMore(find.text('Sohoka')), findsOneWidget);
    });

    testWidgets('choisir un thème sombre change l\'affichage', (tester) async {
      await _openMoreTab(tester);

      await tester.tap(_inMore(find.text('Appearance')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(_inMore(find.text('Dark')), findsOneWidget);
    });

    testWidgets('l\'option Système ramène à la langue du téléphone', (
      tester,
    ) async {
      await _openMoreTab(tester);

      await tester.tap(_inMore(find.text('Language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirundi'));
      await tester.pumpAndSettle();
      expect(_inMore(find.text('Sohoka')), findsOneWidget);

      // Le libellé du menu est désormais en kirundi.
      await tester.tap(_inMore(find.text('Ururimi')));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet(find.text('Sisitemu')));
      await tester.pumpAndSettle();

      // La locale de test est l'anglais : on revient donc à l'anglais.
      expect(_inMore(find.text('Sign out')), findsOneWidget);
    });
  });

  group('Préférences persistées', () {
    test('la langue choisie est restaurée au redémarrage', () async {
      final cache = MemoryLocalCache();
      final first = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(first.dispose);
      await first.read(localeProvider.notifier).select(const Locale('rn'));

      final restarted = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(restarted.dispose);
      restarted.read(localeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(restarted.read(localeProvider)?.languageCode, 'rn');
    });

    test('revenir à la langue du système efface la préférence', () async {
      final cache = MemoryLocalCache();
      final first = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(first.dispose);
      await first.read(localeProvider.notifier).select(const Locale('rn'));
      await first.read(localeProvider.notifier).select(null);

      final restarted = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(restarted.dispose);
      restarted.read(localeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(restarted.read(localeProvider), isNull);
    });

    test('le thème choisi est restauré au redémarrage', () async {
      final cache = MemoryLocalCache();
      final first = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(first.dispose);
      await first.read(themeModeProvider.notifier).select(ThemeMode.dark);

      final restarted = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(restarted.dispose);
      restarted.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(restarted.read(themeModeProvider), ThemeMode.dark);
    });

    test('sans préférence enregistrée, la langue suit le système', () async {
      final container = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(MemoryLocalCache())],
      );
      addTearDown(container.dispose);

      container.read(localeProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeProvider), isNull);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('Widget d\'écran d\'accueil', () {
    testWidgets('l\'entrée reste cachée si le lanceur ne sait pas épingler', (
      tester,
    ) async {
      // Passerelle par défaut : aucun canal natif dans les tests, donc le
      // lanceur est réputé incompatible. C'est aussi le cas d'iOS.
      await _openMoreTab(tester);

      expect(_inMore(find.text('Home screen widget')), findsNothing);
    });

    testWidgets('l\'entrée demande l\'épinglage et confirme', (tester) async {
      final bridge = _FakeHomeWidgetBridge(pinSupported: true);
      await _openMoreTab(tester, homeWidget: bridge);

      final tile = _inMore(find.text('Home screen widget'));
      expect(tile, findsOneWidget);

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(bridge.pinRequests, 1);
      // Le lanceur ouvre sa propre boîte de dialogue : l'application ne peut
      // que dire ce qu'elle a demandé.
      expect(
        find.text("Confirm the addition in your launcher's dialog."),
        findsOneWidget,
      );
    });
  });
}
