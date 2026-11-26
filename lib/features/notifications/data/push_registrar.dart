import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/features/notifications/data/push_service.dart';

/// Service push utilisé par l'application.
///
/// Inerte par défaut : les tests et les aperçus n'ont ainsi ni Firebase ni
/// appareil à simuler. `main()` le remplace par [FirebasePushService].
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoopPushService(),
);

/// Enregistre le jeton de l'appareil auprès du serveur.
///
/// Le jeton FCM **est** l'adresse à laquelle le serveur pousse : tant qu'il
/// n'est pas connu du serveur, l'appareil ne reçoit rien, quelle que soit la
/// qualité de la configuration côté mobile.
final class PushRegistrar {
  PushRegistrar({required PushService service, required ApiClient client})
    : _service = service,
      _client = client;

  /// Route d'enregistrement, côté backend (`app/routers/auth.py`).
  static const String path = '/auth/me/fcm-token';

  final PushService _service;
  final ApiClient _client;

  StreamSubscription<String?>? _refreshes;

  /// Dernier jeton accepté par le serveur.
  ///
  /// Évite de renvoyer le même jeton à chaque démarrage : le serveur n'a rien
  /// à en faire, et l'écriture en base est inutile.
  String? _sent;

  /// Enregistre l'appareil pour la session courante.
  ///
  /// N'échoue jamais bruyamment : un serveur injoignable au moment de la
  /// connexion ne doit pas empêcher d'entrer dans l'application. Le prochain
  /// démarrage, ou le prochain renouvellement de jeton, réessaiera.
  Future<void> register() async {
    final token = await _service.token();
    if (token == null || token.isEmpty) {
      return;
    }
    await _send(token);
    _listenRefreshes();
  }

  void _listenRefreshes() {
    _refreshes ??= _service.tokenRefreshes.listen((token) {
      if (token != null && token.isNotEmpty) {
        unawaited(_send(token));
      }
    });
  }

  Future<void> _send(String token) async {
    if (token == _sent) {
      return;
    }
    try {
      await _client.put(
        path,
        body: <String, Object?>{
          'fcm_token': token,
          // Le serveur garde un appareil par jeton : ces trois champs lui
          // permettent de dire « le téléphone du 24/11 » plutôt qu'un jeton
          // opaque quand il faut expliquer pourquoi un push n'est pas parti.
          'platform': Platform.operatingSystem,
          'device_model': Platform.operatingSystemVersion,
          'app_version': kAppVersion,
        },
      );
      _sent = token;
    } on Object {
      // Silencieux à dessein : voir register().
    }
  }

  /// Désenregistre l'appareil.
  ///
  /// À appeler **avant** de fermer la session : l'endpoint exige un jeton
  /// d'accès valide. Un appareil qui garderait le jeton d'un compte déconnecté
  /// continuerait à recevoir ses appels au guichet — sur un téléphone partagé,
  /// c'est une fuite d'information, pas seulement une gêne.
  Future<void> unregister() async {
    await _refreshes?.cancel();
    _refreshes = null;
    // Capturé avant d'être oublié : c'est lui qui désigne l'appareil à retirer.
    final deviceToken = _sent;
    _sent = null;
    try {
      await _client.put(
        path,
        body: <String, Object?>{
          'fcm_token': null,
          'device_token': deviceToken,
        },
      );
    } on Object {
      // La session disparaît de toute façon juste après.
    }
    await _service.deleteToken();
  }

  /// Coupe l'écoute des renouvellements sans toucher au serveur.
  Future<void> dispose() async {
    await _refreshes?.cancel();
    _refreshes = null;
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(
    service: ref.watch(pushServiceProvider),
    client: ref.watch(apiClientProvider),
  );
  ref.onDispose(() => unawaited(registrar.dispose()));
  return registrar;
});
