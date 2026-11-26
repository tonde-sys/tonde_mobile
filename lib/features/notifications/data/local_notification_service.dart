import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/domain/notification_service.dart';

/// Notifications système (bannière, tiroir, son) via Android.
///
/// Deux canaux seulement, parce qu'ils n'ont pas le même poids pour
/// l'utilisateur : le suivi de file peut attendre, l'appel au guichet non.
/// Android laisse ensuite le client couper l'un sans perdre l'autre.
final class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String progressChannelId = 'tonde_queue_progress';
  static const String urgentChannelId = 'tonde_queue_urgent';

  /// Petite icône de la barre d'état.
  ///
  /// Android n'affiche que le canal alpha de cette icône : elle est donc
  /// dérivée du tracé du logo TONDE (le chemin et ses trois nœuds), pas de
  /// l'icône de lancement — cette dernière, colorée, serait rendue en aplat
  /// blanc, c'est-à-dire un carré.
  ///
  /// Le nom doit rester identique à `fcm_gateway.SMALL_ICON` côté backend :
  /// c'est le serveur qui désigne l'icône des push reçus application fermée.
  static const String smallIcon = 'ic_stat_tonde';

  /// Grande icône, affichée dans la notification dépliée : le logo complet,
  /// en couleur.
  static const String largeIcon = 'tonde_logo';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _permissionGranted = false;
  int _nextId = 1000;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(smallIcon),
      ),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        progressChannelId,
        'Suivi de la file',
        description:
            'Confirmation du ticket, progression et fin de votre passage.',
        importance: Importance.defaultImportance,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        urgentChannelId,
        'Appel au guichet',
        description:
            'Votre tour, appel au guichet et rappel de présentation.',
        importance: Importance.max,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Android 13+ demande une autorisation explicite ; en dessous, la méthode
    // renvoie true sans rien afficher.
    final granted = await android?.requestNotificationsPermission() ?? true;
    _permissionGranted = granted;
    return granted;
  }

  @override
  Future<void> show(TondeNotification notification) async {
    await initialize();
    if (!_permissionGranted) {
      // Sans autorisation, `show` échouerait silencieusement : on évite un
      // aller-retour inutile vers le système.
      final granted = await requestPermission();
      if (!granted) {
        return;
      }
    }

    await _plugin.show(
      id: _nextId++,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notification.urgent ? urgentChannelId : progressChannelId,
          notification.urgent ? 'Appel au guichet' : 'Suivi de la file',
          channelDescription: 'Notifications de votre file d’attente TONDE.',
          icon: smallIcon,
          largeIcon: const DrawableResourceAndroidBitmap(largeIcon),
          importance: notification.urgent
              ? Importance.max
              : Importance.defaultImportance,
          priority: notification.urgent
              ? Priority.high
              : Priority.defaultPriority,
          // Le numéro de ticket reste visible dans le tiroir : c'est le seul
          // repère utile quand plusieurs notifications se suivent.
          styleInformation: BigTextStyleInformation(notification.body),
        ),
      ),
      payload: notification.ticketNumber,
    );
  }
}
