import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/bootstrap.dart';
import 'package:tonde/core/logging/startup_timeline.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/notifications/data/local_notification_service.dart';
import 'package:tonde/features/notifications/data/push_registrar.dart';
import 'package:tonde/features/notifications/data/push_service.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/features/profile/data/local_profile_photo_picker.dart';
import 'package:tonde/features/profile/presentation/controllers/profile_photo_providers.dart';

/// Budget accordé à une tâche de démarrage avant de la laisser continuer seule.
///
/// Ce plafond protège la boucle Dart : au-delà, on cesse d'attendre. Il ne
/// protège pas d'un blocage du thread natif Android — c'est précisément
/// pourquoi plus rien de tout cela ne se trouve sur le chemin de la première
/// image.
const Duration _warmUpBudget = Duration(seconds: 5);

/// Démarre l'application.
///
/// **Rien n'est attendu avant `runApp`.** C'est la règle qui manquait : le
/// démarrage enchaînait trois initialisations avant d'afficher quoi que ce
/// soit, dont `Firebase.initializeApp()`. Sur un Infinix sous Android 11, cette
/// dernière bloque le thread principal Android — donc aussi la boucle Dart,
/// puisque Flutter les partage désormais. Résultat : le minuteur de sécurité
/// lui-même ne pouvait pas se déclencher, aucune image n'était produite, et la
/// fenêtre de démarrage du système restait affichée indéfiniment.
///
/// Désormais la première image part immédiatement ; ce qui peut attendre est
/// préparé derrière elle, et Firebase n'est initialisé qu'au moment où un jeton
/// devient réellement utile, c'est-à-dire après la connexion.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimeline.mark('main');

  final notifications = LocalNotificationService();
  final push = FirebasePushService();

  runApp(
    ProviderScope(
      overrides: [
        // Le cache s'ouvre à sa première lecture, pas au démarrage : Hive
        // passe par le système de fichiers, et aucun écran ne doit attendre
        // cela pour s'afficher.
        localCacheProvider.overrideWithValue(HiveLocalCache()),
        notificationServiceProvider.overrideWithValue(notifications),
        pushServiceProvider.overrideWithValue(push),
        // Le sélecteur natif n'a besoin d'aucune initialisation : il est
        // branché ici pour que les tests gardent un sélecteur inerte.
        profilePhotoPickerProvider.overrideWithValue(LocalProfilePhotoPicker()),
      ],
      child: const TondeBootstrap(),
    ),
  );

  // Relevé après la première image, pas après une initialisation : c'est le
  // moment où l'utilisateur voit l'application.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupTimeline.mark('first_frame');
    StartupTimeline.reportOnce();
    unawaited(_warmUpNotifications(notifications));
  });
}

/// Crée les canaux de notification une fois l'application à l'écran.
///
/// Les canaux doivent exister avant la première alerte, mais rien ne justifie
/// de retarder l'affichage pour eux. Un échec ici n'est pas définitif :
/// [LocalNotificationService.initialize] reste réessayable, et `show()` la
/// rappelle de toute façon.
Future<void> _warmUpNotifications(LocalNotificationService notifications) async {
  final watch = Stopwatch()..start();
  try {
    await notifications.initialize().timeout(_warmUpBudget);
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tonde',
        context: ErrorDescription('initialisation des notifications'),
      ),
    );
  }
  debugPrint('TONDE_WARMUP notifications=${watch.elapsedMilliseconds}ms');
}
