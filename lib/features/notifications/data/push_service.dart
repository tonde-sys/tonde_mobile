import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Ce qu'un appui sur une notification demande d'ouvrir.
///
/// Le payload ne transporte que l'identifiant du ticket et le type d'événement :
/// c'est le strict nécessaire pour retrouver le bon écran, et rien qui
/// identifie la personne (voir `fcm_gateway.build_message` côté serveur).
@immutable
final class PushTap {
  const PushTap({required this.ticketId, this.type});

  final String ticketId;
  final String? type;

  /// Lit un payload FCM. Retourne null si le message ne désigne aucun ticket :
  /// un appui sans cible ne doit pas ouvrir un écran au hasard.
  static PushTap? fromData(Map<String, dynamic> data) {
    final ticketId = data['ticket_id'];
    if (ticketId is! String || ticketId.isEmpty) {
      return null;
    }
    final type = data['type'];
    return PushTap(ticketId: ticketId, type: type is String ? type : null);
  }

  @override
  bool operator ==(Object other) =>
      other is PushTap && other.ticketId == ticketId && other.type == type;

  @override
  int get hashCode => Object.hash(ticketId, type);

  @override
  String toString() => 'PushTap($ticketId, $type)';
}

/// Accès aux notifications push de la plateforme.
///
/// L'interface existe pour que le reste de l'application — enregistrement du
/// jeton, navigation à l'appui — soit testable sans Firebase ni appareil. Les
/// tests et les aperçus reçoivent [NoopPushService] ; `main()` branche
/// l'implémentation réelle.
abstract interface class PushService {
  /// Prépare le service.
  ///
  /// Retourne `false` quand la configuration Firebase manque — par exemple un
  /// build sans `google-services.json`. Ce n'est pas une erreur : l'application
  /// démarre sans push, ce qui vaut mieux qu'un écran blanc.
  Future<bool> initialize();

  /// Jeton de l'appareil, ou null si les push ne sont pas disponibles.
  Future<String?> token();

  /// Nouveaux jetons émis par la plateforme (réinstallation, restauration).
  Stream<String?> get tokenRefreshes;

  /// Invalide le jeton courant.
  ///
  /// Appelé à la déconnexion : sans cela, l'appareil continuerait à recevoir
  /// les appels au guichet du compte qui vient de se déconnecter.
  Future<void> deleteToken();

  /// Appuis sur une notification alors que l'application tournait déjà.
  Stream<PushTap> get taps;

  /// Appui qui a lancé l'application (elle était terminée).
  Future<PushTap?> initialTap();
}

/// Implémentation inerte : aucune initialisation, aucun jeton, aucun appui.
///
/// C'est la valeur par défaut des providers, donc celle que voient les tests et
/// les aperçus. Elle évite d'avoir à simuler une plateforme mobile.
final class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String?> get tokenRefreshes => const Stream<String?>.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<PushTap> get taps => const Stream<PushTap>.empty();

  @override
  Future<PushTap?> initialTap() async => null;
}

/// Handler de fond exigé par FlutterFire.
///
/// Il doit être une fonction de premier niveau et porter `vm:entry-point`,
/// sinon il n'est pas compilé dans l'isolate que le système réveille.
///
/// Le backend envoie toujours un bloc `notification` : c'est Android qui
/// affiche la bannière, avec l'icône et le canal qu'il désigne. Ce handler
/// n'affiche donc rien lui-même — le faire produirait une seconde
/// notification pour le même événement.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Implémentation réelle, adossée à Firebase Cloud Messaging.
final class FirebasePushService implements PushService {
  FirebasePushService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  bool _ready = false;

  /// Vrai une fois Firebase initialisé et le handler de fond enregistré.
  bool get isReady => _ready;

  @override
  Future<bool> initialize() async {
    if (_ready) {
      return true;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } on Object {
      // Configuration absente ou invalide : l'application continue sans push.
      return false;
    }

    // iOS n'a pas d'équivalent au POST_NOTIFICATIONS d'Android : la demande
    // d'autorisation passe par Firebase. Sur Android c'est déjà
    // LocalNotificationService qui la porte, au moment de la première prise de
    // ticket — redemander ici ouvrirait un second dialogue.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Premier plan : pas de bannière, l'écran de suivi est déjà à l'écran et
      // se met à jour par le WebSocket. Le son viendra de l'application (L3),
      // pas du système, pour n'être joué qu'une fois.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    _ready = true;
    return true;
  }

  @override
  Future<String?> token() async {
    if (!_ready) {
      return null;
    }
    try {
      // `getToken()` est déprécié au profit de `register()` / `onRegistered`,
      // qui renvoie un Firebase Installation ID (FID). Le backend envoie
      // aujourd'hui `{token: <jeton>}` à l'API FCM v1, et le FID n'y est pas
      // encore équivalent de façon documentée. On garde donc le jeton tant que
      // l'envoi n'a pas été basculé et vérifié : la migration ne touchera que
      // cette classe.
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object {
      // Pas de Google Play Services, ou jeton refusé : pas de push, pas d'échec.
      return null;
    }
  }

  @override
  Stream<String?> get tokenRefreshes => _ready
      // ignore: deprecated_member_use
      ? _messaging.onTokenRefresh
      : const Stream<String?>.empty();

  @override
  Future<void> deleteToken() async {
    if (!_ready) {
      return;
    }
    try {
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } on Object {
      // Le serveur a déjà oublié le jeton ; l'échec local est sans conséquence.
    }
  }

  @override
  Stream<PushTap> get taps {
    if (!_ready) {
      return const Stream<PushTap>.empty();
    }
    return FirebaseMessaging.onMessageOpenedApp
        .map((message) => PushTap.fromData(message.data))
        .where((tap) => tap != null)
        .cast<PushTap>();
  }

  @override
  Future<PushTap?> initialTap() async {
    if (!_ready) {
      return null;
    }
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) {
        return null;
      }
      return PushTap.fromData(message.data);
    } on Object {
      return null;
    }
  }
}
