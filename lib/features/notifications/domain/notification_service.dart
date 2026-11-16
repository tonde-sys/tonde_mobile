import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';

/// Canal d'envoi des notifications.
///
/// L'interface est étroite à dessein : le jour où le backend enverra de vraies
/// notifications push (FCM), il suffira d'une seconde implémentation, sans
/// toucher à la logique qui décide *quand* notifier.
abstract interface class NotificationService {
  /// Prépare le canal d'affichage. Idempotent : appelable à chaque démarrage.
  Future<void> initialize();

  /// Demande l'autorisation d'afficher des notifications.
  ///
  /// Retourne `true` si l'application peut notifier. Sur les versions
  /// d'Android antérieures à 13, l'autorisation est implicite.
  Future<bool> requestPermission();

  /// Affiche [notification] sur l'appareil.
  Future<void> show(TondeNotification notification);
}

/// Implémentation neutre : n'affiche rien.
///
/// C'est la valeur par défaut du provider, pour que les tests et les aperçus
/// n'aient jamais besoin d'un appareil réel ni d'une autorisation.
final class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show(TondeNotification notification) async {}
}
