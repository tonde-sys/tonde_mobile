import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/l10n/kirundi_localizations.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/app/theme/app_theme.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Délégués de localisation communs à toute l'application.
///
/// Partagés avec les écrans affichés avant le routeur (démarrage et
/// présentation) pour que la langue soit identique partout dès la première
/// image.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  // Flutter ne couvre pas le kirundi : ces deux délégués prennent le relais
  // pour les libellés Material et Cupertino.
  KirundiMaterialLocalizationsDelegate(),
  KirundiCupertinoLocalizationsDelegate(),
];

/// Langues proposées par l'application.
const List<Locale> appSupportedLocales = [
  Locale('fr'),
  Locale('rn'),
  Locale('en'),
];

class TondeApp extends ConsumerWidget {
  const TondeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Préférences choisies dans l'onglet « Plus » ; null = langue du système.
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Active le veilleur de notifications au sommet de l'application : les
    // alertes doivent partir même quand l'utilisateur est sur un autre écran
    // que le suivi de sa file.
    ref.watch(ticketNotificationDriverProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
