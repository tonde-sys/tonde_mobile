import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/notifications/data/local_notification_service.dart';

/// Contrat entre le mobile et le backend pour les push.
///
/// Ces trois chaînes traversent le réseau : le serveur les écrit dans le
/// message FCM, l'application doit les avoir créées. Une divergence ne casse
/// aucun test de rendu — elle fait simplement arriver l'appel du guichet dans
/// un canal de repli, sans son ni importance maximale.
void main() {
  test('les canaux et les icônes sont ceux qu’annonce le backend', () {
    // Miroir de `app/services/fcm_gateway.py` : CHANNEL_URGENT,
    // CHANNEL_PROGRESS et SMALL_ICON.
    expect(LocalNotificationService.progressChannelId, 'tonde_queue_progress');
    expect(LocalNotificationService.urgentChannelId, 'tonde_queue_urgent');
    expect(LocalNotificationService.smallIcon, 'ic_stat_tonde');
    // Grande icône : le logo complet, en couleur.
    expect(LocalNotificationService.largeIcon, 'tonde_logo');
  });
}
