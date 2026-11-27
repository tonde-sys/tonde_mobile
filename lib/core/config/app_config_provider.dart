import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  final config = AppConfig.fromEnvironment();
  // Un APK construit sans `TONDE_API_BASE_URL` s'ouvre normalement mais ne
  // joint aucun serveur : la panne est silencieuse et ressemble à un problème
  // de réseau de l'utilisateur. Une ligne dans logcat suffit à la reconnaître.
  if (config.apiRoot == null) {
    debugPrint(
      'TONDE_CONFIG apiRoot=null — APK construit sans '
      '--dart-define=TONDE_API_BASE_URL',
    );
  }
  return config;
});
