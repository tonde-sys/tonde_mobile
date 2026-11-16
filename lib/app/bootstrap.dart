import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/pages/onboarding_page.dart';
import 'package:tonde/app/pages/splash_page.dart';
import 'package:tonde/app/theme/app_theme.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/core/settings/settings_providers.dart';

/// Enchaînement de démarrage : écran de marque → présentation (une seule fois)
/// → application.
///
/// Cette porte vit **au-dessus** du routeur : les tests et les aperçus qui
/// montent directement [TondeApp] ne la voient pas, et un utilisateur qui a
/// déjà terminé la présentation va droit à l'accueil.
class TondeBootstrap extends ConsumerStatefulWidget {
  const TondeBootstrap({super.key});

  /// Clé de persistance de la présentation initiale.
  static const String onboardingKey = 'onboarding.completed';

  /// Durée de l'écran de marque : le temps de lire le nom et de voir la file
  /// s'écouler, sans retarder l'accès à l'application.
  static const Duration splashDuration = Duration(seconds: 3);

  @override
  ConsumerState<TondeBootstrap> createState() => _TondeBootstrapState();
}

enum _Stage { splash, onboarding, app }

class _TondeBootstrapState extends ConsumerState<TondeBootstrap> {
  _Stage _stage = _Stage.splash;

  @override
  void initState() {
    super.initState();
    unawaited(_decide());
  }

  Future<void> _decide() async {
    // La lecture disque et l'animation de démarrage courent ensemble : le
    // premier lancement n'attend donc pas deux fois.
    final results = await Future.wait<Object?>([
      Future<void>.delayed(TondeBootstrap.splashDuration),
      ref.read(localCacheProvider).read(TondeBootstrap.onboardingKey),
    ]);
    if (!mounted) {
      return;
    }
    final completed = results[1] == true;
    setState(() => _stage = completed ? _Stage.app : _Stage.onboarding);
  }

  Future<void> _finishOnboarding() async {
    await ref
        .read(localCacheProvider)
        .write(TondeBootstrap.onboardingKey, true);
    if (!mounted) {
      return;
    }
    setState(() => _stage = _Stage.app);
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.app) {
      return const TondeApp();
    }

    // Avant le routeur, il faut une MaterialApp minimale : même thème, même
    // langue, mêmes délégués que l'application finale.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: _stage == _Stage.splash
          ? const SplashPage()
          : OnboardingPage(onFinished: _finishOnboarding),
    );
  }
}
