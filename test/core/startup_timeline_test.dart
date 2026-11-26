import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/logging/startup_timeline.dart';

/// Le relevé de démarrage sert à diagnostiquer un téléphone qu'on n'a pas en
/// main : s'il écrit deux lignes ou perd des jalons, il ne dit plus rien.
void main() {
  setUp(StartupTimeline.reset);

  test('écrit une seule ligne, même appelée plusieurs fois', () {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        lines.add(message);
      }
    };
    addTearDown(() => debugPrint = original);

    StartupTimeline.mark('main');
    StartupTimeline.mark('cache');
    StartupTimeline.reportOnce();
    StartupTimeline.reportOnce();

    expect(lines, hasLength(1));
    expect(lines.single, startsWith('TONDE_STARTUP'));
    expect(lines.single, contains('main='));
    expect(lines.single, contains('cache='));
  });

  test('un jalon déjà posé ne produit pas de doublon', () {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        lines.add(message);
      }
    };
    addTearDown(() => debugPrint = original);

    StartupTimeline.mark('cache');
    StartupTimeline.mark('cache');
    StartupTimeline.reportOnce();

    expect('cache='.allMatches(lines.single).length, 1);
  });
}
