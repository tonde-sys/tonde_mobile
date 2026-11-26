import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelHomeWidgetBridge.channelName);
  final calls = <MethodCall>[];
  Object? nextResult;

  setUp(() {
    calls.clear();
    nextResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return nextResult;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('HomeWidgetState', () {
    test('publie toutes les clés du contrat Kotlin', () {
      const state = HomeWidgetState(
        hasTicket: true,
        number: 'A-014',
        agency: 'Agence Centre',
        status: 'En attente',
        position: 'Position 3',
        eta: '≈ 12 min',
        updated: 'Mis à jour à 11:34',
        emptyTitle: 'Aucun ticket',
        emptyBody: 'Touchez pour en prendre un',
      );

      expect(state.toMap().keys, <String>{
        'has_ticket',
        'number',
        'agency',
        'status',
        'position',
        'eta',
        'updated',
        'empty_title',
        'empty_body',
      });
      expect(state.toMap()['has_ticket'], isTrue);
      expect(state.toMap()['number'], 'A-014');
    });

    test('deux états identiques sont égaux, un champ différent non', () {
      const a = HomeWidgetState(hasTicket: true, number: 'A-014');
      const b = HomeWidgetState(hasTicket: true, number: 'A-014');
      const c = HomeWidgetState(hasTicket: true, number: 'A-015');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('l\'état vide ne porte pas de numéro', () {
      const empty = HomeWidgetState.empty(title: 'Aucun ticket', body: '…');

      expect(empty.hasTicket, isFalse);
      expect(empty.number, isEmpty);
      expect(empty.emptyTitle, 'Aucun ticket');
    });
  });

  group('MethodChannelHomeWidgetBridge', () {
    test('update envoie l\'état complet sur le canal', () async {
      const bridge = MethodChannelHomeWidgetBridge();
      const state = HomeWidgetState(
        hasTicket: true,
        number: 'A-014',
        position: 'Position 3',
      );

      await bridge.update(state);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'update');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['has_ticket'], isTrue);
      expect(args['number'], 'A-014');
      expect(args['position'], 'Position 3');
      // Les champs laissés vides partent quand même : le natif efface les clés
      // avant d'écrire, un champ absent et un champ vide sont équivalents.
      expect(args['eta'], isEmpty);
    });

    test('clear demande l\'effacement', () async {
      const bridge = MethodChannelHomeWidgetBridge();

      await bridge.clear();

      expect(calls.single.method, 'clear');
      expect(calls.single.arguments, isNull);
    });

    test('isPinSupported et requestPin lisent le booléen natif', () async {
      const bridge = MethodChannelHomeWidgetBridge();

      nextResult = true;
      expect(await bridge.isPinSupported(), isTrue);
      expect(calls.last.method, 'isPinSupported');

      nextResult = false;
      expect(await bridge.requestPin(), isFalse);
      expect(calls.last.method, 'requestPin');
    });

    test('une réponse nulle vaut « non » plutôt qu\'un plantage', () async {
      const bridge = MethodChannelHomeWidgetBridge();
      nextResult = null;

      expect(await bridge.isPinSupported(), isFalse);
      expect(await bridge.requestPin(), isFalse);
    });
  });

  group('NoopHomeWidgetBridge', () {
    test('ne touche jamais au canal et refuse l\'épinglage', () async {
      const bridge = NoopHomeWidgetBridge();

      await bridge.update(const HomeWidgetState(hasTicket: true, number: 'A-1'));
      await bridge.clear();

      expect(await bridge.isPinSupported(), isFalse);
      expect(await bridge.requestPin(), isFalse);
      expect(calls, isEmpty);
    });
  });
}
