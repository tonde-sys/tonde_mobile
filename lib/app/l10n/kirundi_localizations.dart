import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Libellés Material et Cupertino pour le kirundi.
///
/// Flutter ne fournit ni `GlobalMaterialLocalizations` ni
/// `GlobalCupertinoLocalizations` pour `rn`. Sans ces délégués, choisir le
/// kirundi prive les feuilles modales, dialogues et menus de leurs libellés :
/// la première feuille ouverte lève une exception. On réutilise donc les
/// libellés français, seconde langue officielle du Burundi et langue de
/// l'administration — les textes de l'application, eux, restent en kirundi.
class KirundiMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KirundiMaterialLocalizationsDelegate();

  static const Locale _fallback = Locale('fr');

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rn';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallback);

  @override
  bool shouldReload(KirundiMaterialLocalizationsDelegate old) => false;
}

/// Équivalent Cupertino du délégué Material ci-dessus.
class KirundiCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KirundiCupertinoLocalizationsDelegate();

  static const Locale _fallback = Locale('fr');

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rn';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallback);

  @override
  bool shouldReload(KirundiCupertinoLocalizationsDelegate old) => false;
}
