import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/domain/notification_service.dart';
import 'package:tonde/features/notifications/presentation/controllers/ticket_notification_watcher.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Canal d'envoi des notifications.
///
/// La valeur par défaut n'affiche rien : les tests et les aperçus n'ont donc
/// jamais besoin d'un appareil ni d'une autorisation. `main()` la remplace par
/// l'implémentation système.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);

/// Historique des notifications reçues pendant la session.
///
/// Il alimente l'onglet Notifications : ce que l'usager a raté dans le tiroir
/// du téléphone reste lisible dans l'application.
final notificationCenterProvider =
    NotifierProvider<NotificationCenter, List<TondeNotification>>(
      NotificationCenter.new,
    );

class NotificationCenter extends Notifier<List<TondeNotification>> {
  @override
  List<TondeNotification> build() => const <TondeNotification>[];

  /// Ajoute [notification] en tête, sans doublon.
  void add(TondeNotification notification) {
    if (state.any((item) => item.dedupKey == notification.dedupKey)) {
      return;
    }
    state = <TondeNotification>[notification, ...state];
  }

  /// Marque une alerte comme lue (elle quitte la pastille, reste dans la liste).
  void markRead(String dedupKey) {
    state = [
      for (final item in state)
        if (item.dedupKey == dedupKey && !item.read)
          item.copyWith(read: true)
        else
          item,
    ];
  }

  /// Supprime définitivement une alerte de l'historique.
  void remove(String dedupKey) {
    state = state.where((item) => item.dedupKey != dedupKey).toList();
  }

  void clear() => state = const <TondeNotification>[];
}

/// Nombre d'alertes non lues, pour la pastille de l'onglet.
final unreadNotificationsProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationCenterProvider);
  return notifications.where((item) => !item.read).length;
});

/// Instance unique du veilleur : elle conserve la mémoire des étapes déjà
/// notifiées d'un ticket à l'autre.
final _notificationWatcherProvider = Provider<TicketNotificationWatcher>((
  ref,
) {
  final watcher = TicketNotificationWatcher(
    service: ref.watch(notificationServiceProvider),
    localizations: () => _resolveLocalizations(ref),
    onDelivered: (notification) =>
        ref.read(notificationCenterProvider.notifier).add(notification),
    isEnabled: () => ref.read(notificationsEnabledProvider),
  );
  ref.onDispose(watcher.dispose);
  return watcher;
});

/// Branche le veilleur sur le ticket courant et sur le flux de la file.
///
/// Observé une seule fois, au sommet de l'application : les notifications
/// doivent partir même quand l'utilisateur est sur un autre écran que le suivi.
final ticketNotificationDriverProvider = Provider<void>((ref) {
  final watcher = ref.watch(_notificationWatcherProvider);
  final ticket = ref.watch(activeTicketProvider).value;

  watcher.onTicket(ticket);

  if (ticket == null) {
    return;
  }
  // Le flux est partagé avec les écrans : une seule connexion, plusieurs
  // lecteurs (carte du tableau de bord, suivi, notifications).
  ref.listen(queueTrackingProvider(ticket), (previous, next) {
    final snapshot = next.value?.snapshot;
    if (snapshot != null) {
      watcher.onSnapshot(snapshot);
    }
  }, fireImmediately: true);
});

/// Charge les libellés dans la langue réellement appliquée par l'application.
Future<AppLocalizations> _resolveLocalizations(Ref ref) {
  final preference = ref.read(localeProvider);
  final code =
      preference?.languageCode ??
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final locale = supportedAppLocales[code] ?? const Locale('fr');
  return AppLocalizations.delegate.load(locale);
}
