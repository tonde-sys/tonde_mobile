import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';
import 'package:tonde/l10n/generated/app_localizations_en.dart';
import 'package:tonde/l10n/generated/app_localizations_fr.dart';
import 'package:tonde/l10n/generated/app_localizations_rn.dart';

Map<String, dynamic> _readArb(String path) {
  final content = File(path).readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  final fr = _readArb('lib/l10n/app_fr.arb');
  final en = _readArb('lib/l10n/app_en.arb');
  final rn = _readArb('lib/l10n/app_rn.arb');

  test('fr, en et rn partagent exactement les mêmes clés', () {
    final frKeys = _messageKeys(fr);
    expect(_messageKeys(en), frKeys);
    expect(_messageKeys(rn), frKeys);
  });

  test('toutes les traductions sont des chaînes non vides', () {
    for (final arb in [fr, en, rn]) {
      for (final key in _messageKeys(arb)) {
        final value = arb[key];
        expect(
          value,
          isA<String>(),
          reason: 'La valeur de $key doit être une chaîne.',
        );
        expect(
          value,
          isNotEmpty,
          reason: 'La valeur de $key ne doit pas être vide.',
        );
      }
    }
  });

  test('les classes générées reflètent les ARB', () {
    expect(AppLocalizationsFr().foundationTitle, 'Socle technique');
    expect(AppLocalizationsEn().foundationTitle, 'Technical foundation');
    expect(AppLocalizationsRn().foundationTitle, "Ishingiro ry'ubuhanga");
  });

  test('les locales supportées couvrent fr, rn et en', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(['fr', 'rn', 'en']),
    );
  });
}
