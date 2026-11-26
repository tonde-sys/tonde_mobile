import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/pages/onboarding_page.dart';
import 'package:tonde/app/pages/splash_page.dart';
import 'package:tonde/app/theme/app_theme.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';

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

  /// Durée de l'écran de marque une fois Flutter affiché.
  ///
  /// Volontairement courte : l'écran natif a déjà montré le logo pendant le
  /// chargement du moteur, donc ce délai ne sert plus qu'à laisser lire le nom
  /// et voir la file s'écouler. Les trois secondes précédentes s'ajoutaient à
  /// l'attente réelle et donnaient l'impression d'une application lente.
  static const Duration splashDuration = Duration(milliseconds: 900);

  /// Budget propre à la résolution de session, menée en parallèle de l'écran
  /// de marque.
  ///
  /// La résolution interroge le réseau (`GET /auth/me`, puis un renouvellement
  /// de jeton si l'accès a expiré). Sur un réseau lent ou coupé, elle peut
  /// dépasser plusieurs secondes : au-delà de ce plafond on entre dans
  /// l'application avec ce que l'on sait déjà, et l'écran d'attente prend le
  /// relais sans jamais mentir sur l'état de la session.
  ///
  /// Plus long que [splashDuration] à dessein : tant que l'écran de marque est
  /// déjà à l'écran, attendre la session coûte moins cher qu'un écran
  /// d'attente supplémentaire.
  static const Duration sessionTimeout = Duration(seconds: 2);

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
    // Les trois travaux courent ensemble : l'écran de marque, la lecture de la
    // présentation et la résolution de la session. Le premier lancement
    // n'attend donc pas trois fois, et la marque sert de couverture à la
    // requête réseau au lieu de s'y ajouter.
    //
    // Conséquence voulue : un utilisateur déjà connecté dont la session est en
    // cache entre dans l'application après [splashDuration], pas après le
    // budget complet de la session.
    final results = await Future.wait<Object?>([
      Future<void>.delayed(TondeBootstrap.splashDuration),
      ref.read(localCacheProvider).read(TondeBootstrap.onboardingKey),
      _awaitSession(TondeBootstrap.sessionTimeout),
    ]);
    if (!mounted) {
      return;
    }
    final completed = results[1] == true;
    setState(() => _stage = completed ? _Stage.app : _Stage.onboarding);
  }

  /// Attend la session, sans jamais dépasser [limit].
  ///
  /// L'application est construite **après** cette attente : le routeur connaît
  /// donc l'état réel de la session dès sa première évaluation, et un
  /// utilisateur connecté ne voit jamais l'écran de connexion apparaître puis
  /// disparaître. Si le réseau traîne, on rend la main au bout de [limit] :
  /// le routeur démarre alors sur l'écran d'attente, jamais sur la connexion.
  ///
  /// L'erreur éventuelle est absorbée. Un échec de résolution n'est pas une
  /// raison de bloquer le démarrage : le service d'authentification retombe
  /// déjà sur le profil en cache, et un état d'erreur est traité comme une
  /// session absente par la porte d'authentification.
  ///
  /// Le minuteur de plafond est annulé dès que la session répond : sans cela
  /// chaque démarrage laisserait un minuteur armé pour rien, et un test qui
  /// n'attend pas sa sonnerie échouerait sur un « timer encore en attente ».
  Future<void> _awaitSession(Duration limit) {
    final completer = Completer<void>();
    void settle() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    final timer = Timer(limit, settle);
    ref
        .read(authControllerProvider.future)
        .then<void>(
          (_) {
            timer.cancel();
            settle();
          },
          onError: (Object _) {
            timer.cancel();
            settle();
          },
        );
    return completer.future;
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
