import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_driver.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_invite.dart';
import 'package:tonde/features/tickets/presentation/widgets/home_widget_invite_card.dart';

/// Passerelle de test : le lanceur accepte ou non l'épinglage.
class _FakeBridge implements HomeWidgetBridge {
  _FakeBridge({this.supported = true, this.pinAccepted = true});

  final bool supported;
  final bool pinAccepted;
  int pins = 0;

  @override
  Future<void> update(HomeWidgetState state) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<bool> isPinSupported() async => supported;

  @override
  Future<bool> requestPin() async {
    pins++;
    return pinAccepted;
  }
}

/// Monte la carte seule, dans un conteneur inspectable.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _FakeBridge bridge,
  LocalCache? cache,
}) async {
  final container = ProviderContainer(
    overrides: [
      homeWidgetBridgeProvider.overrideWithValue(bridge),
      if (cache != null) localCacheProvider.overrideWithValue(cache),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const Scaffold(body: HomeWidgetInviteCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('la carte propose l’épinglage quand le lanceur le permet', (
    tester,
  ) async {
    await _pump(tester, bridge: _FakeBridge());

    expect(find.text("Suivez votre position depuis l'accueil"), findsOneWidget);
    expect(find.text('Ajouter le widget'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
  });

  testWidgets('« Plus tard » écarte la proposition et la mémorise', (
    tester,
  ) async {
    final cache = MemoryLocalCache();
    final container = await _pump(tester, bridge: _FakeBridge(), cache: cache);

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter le widget'), findsNothing);
    expect(
      container.read(homeWidgetInviteProvider),
      HomeWidgetInvite.dismissed,
    );
    expect(await cache.read('home_widget.invite'), 'dismissed');
  });

  testWidgets('« Ajouter le widget » demande l’épinglage puis se retire', (
    tester,
  ) async {
    final cache = MemoryLocalCache();
    final bridge = _FakeBridge();
    final container = await _pump(tester, bridge: bridge, cache: cache);

    await tester.tap(find.text('Ajouter le widget'));
    await tester.pumpAndSettle();

    expect(bridge.pins, 1);
    expect(container.read(homeWidgetInviteProvider), HomeWidgetInvite.accepted);
    expect(await cache.read('home_widget.invite'), 'accepted');
    expect(find.text('Ajouter le widget'), findsNothing);
    expect(
      find.text("Confirmez l'ajout dans la fenêtre du lanceur."),
      findsOneWidget,
    );
  });

  testWidgets('sans épinglage possible, rien n’est proposé', (tester) async {
    // iOS et les lanceurs réfractaires : proposer une action impossible est
    // pire que de ne rien proposer.
    await _pump(tester, bridge: _FakeBridge(supported: false));

    expect(find.text('Ajouter le widget'), findsNothing);
  });

  testWidgets('un refus déjà enregistré ne réapparaît pas', (tester) async {
    final cache = MemoryLocalCache();
    await cache.write('home_widget.invite', 'dismissed');

    await _pump(tester, bridge: _FakeBridge(), cache: cache);

    expect(find.text('Ajouter le widget'), findsNothing);
    expect(find.text('Plus tard'), findsNothing);
  });

  testWidgets('le refus du lanceur est expliqué, pas ignoré', (tester) async {
    final bridge = _FakeBridge(pinAccepted: false);
    await _pump(tester, bridge: bridge);

    await tester.tap(find.text('Ajouter le widget'));
    await tester.pumpAndSettle();

    expect(bridge.pins, 1);
    expect(
      find.textContaining("ne permet pas d'ajouter le widget"),
      findsOneWidget,
    );
  });
}
