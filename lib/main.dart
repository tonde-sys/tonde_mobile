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

/// Temps maximal accordé à Firebase avant d'afficher l'écran.
///
/// En deçà, l'initialisation est terminée au moment du premier rendu et rien
/// ne change par rapport à un démarrage strictement séquentiel. Au-delà — un
/// téléphone d'entrée de gamme met parfois plus d'une seconde à démarrer le
/// SDK natif — on affiche l'écran et l'initialisation continue seule. Le
/// service attend sa propre disponibilité avant de rendre un jeton, donc
/// aucun appareil ne perd son enregistrement push.
const Duration _pushBudget = Duration(milliseconds: 800);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimeline.mark('main');

  // Le cache local est ouvert avant le premier écran : le ticket actif doit
  // être disponible dès l'affichage, même sans réseau. Hive ouvre un fichier
  // local, l'attente se compte en dizaines de millisecondes.
  final cache = await _openCache();
  StartupTimeline.mark('cache');

  // Les notifications système sont préparées ici, pas dans un écran : le
  // canal doit exister avant la première alerte, et l'initialisation ne doit
  // jamais retarder le démarrage.
  final notifications = LocalNotificationService();
  try {
    await notifications.initialize();
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
  StartupTimeline.mark('notifications');

  // Firebase est lancé avant le premier écran, mais avec un budget.
  //
  // Jusqu'ici, `initializeApp` était attendu sans limite : c'est lui qui
  // tenait l'écran figé sur les téléphones lents. Le handler de fond reste
  // enregistré tôt, ce qui est la seule chose qui doive l'être avant un push.
  final push = FirebasePushService();
  try {
    await push.initialize().timeout(_pushBudget);
  } on TimeoutException {
    // Budget dépassé, pas initialisation abandonnée : elle se termine seule
    // en tâche de fond, et `token()` l'attendra.
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tonde',
        context: ErrorDescription('initialisation des notifications push'),
      ),
    );
  }
  StartupTimeline.mark('push');

  runApp(
    ProviderScope(
      overrides: [
        localCacheProvider.overrideWithValue(cache),
        notificationServiceProvider.overrideWithValue(notifications),
        pushServiceProvider.overrideWithValue(push),
        // Le sélecteur natif n'a besoin d'aucune initialisation : il est
        // branché ici pour que les tests gardent un sélecteur inerte.
        profilePhotoPickerProvider.overrideWithValue(LocalProfilePhotoPicker()),
      ],
      child: const TondeBootstrap(),
    ),
  );

  // Relevé après la première image, pas après l'initialisation de Flutter :
  // c'est le moment où l'utilisateur voit l'application.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupTimeline.mark('first_frame');
    StartupTimeline.reportOnce();
  });
}

Future<LocalCache> _openCache() async {
  try {
    return await HiveLocalCache.open();
  } on Object catch (error, stackTrace) {
    // Un stockage indisponible ne doit pas empêcher l'application de démarrer,
    // mais l'incident est remonté plutôt que masqué.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tonde',
        context: ErrorDescription('ouverture du cache local'),
      ),
    );
    return MemoryLocalCache();
  }
}
