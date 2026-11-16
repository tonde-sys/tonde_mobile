import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/bootstrap.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/notifications/data/local_notification_service.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/features/profile/data/local_profile_photo_picker.dart';
import 'package:tonde/features/profile/presentation/controllers/profile_photo_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le cache local est ouvert avant le premier écran : le ticket actif doit
  // être disponible dès l'affichage, même sans réseau.
  final cache = await _openCache();

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

  runApp(
    ProviderScope(
      overrides: [
        localCacheProvider.overrideWithValue(cache),
        notificationServiceProvider.overrideWithValue(notifications),
        // Le sélecteur natif n'a besoin d'aucune initialisation : il est
        // branché ici pour que les tests gardent un sélecteur inerte.
        profilePhotoPickerProvider.overrideWithValue(LocalProfilePhotoPicker()),
      ],
      child: const TondeBootstrap(),
    ),
  );
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
