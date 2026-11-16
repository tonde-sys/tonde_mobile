import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Onglet Notifications : historique des alertes reçues pendant la session.
///
/// Les messages sont exactement ceux envoyés au téléphone : l'usager qui a
/// raté une bannière retrouve la même information ici, dans le même ordre.
class NotificationsTab extends ConsumerWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationCenterProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tabNotifications,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (unread > 0)
                  Text(
                    l10n.notifUnreadCount(unread),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: notifications[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.notifCenterEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.notifCenterEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final TondeNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = DateFormat.Hm().format(notification.sentAt);
    final unread = !notification.read;
    final center = ref.read(notificationCenterProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Une alerte non lue se repère au premier regard : fond teinté et titre
      // en gras. Une fois lue, elle redevient une carte neutre.
      color: unread ? colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: ListTile(
        onTap: unread ? () => center.markRead(notification.dedupKey) : null,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: notification.urgent
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              child: Icon(
                _iconFor(notification.kind),
                size: 20,
                color: notification.urgent
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            if (unread)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
            color: unread ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 2),
            Text(
              time,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        // Suppression directe : l'historique est un confort, l'usager doit
        // pouvoir faire le ménage sans passer par un menu.
        trailing: IconButton(
          tooltip: l10n.notifDelete,
          icon: const Icon(Icons.delete_outline),
          color: colorScheme.onSurfaceVariant,
          onPressed: () => center.remove(notification.dedupKey),
        ),
      ),
    );
  }

  static IconData _iconFor(TondeNotificationKind kind) {
    return switch (kind) {
      TondeNotificationKind.ticketConfirmed =>
        Icons.confirmation_number_outlined,
      TondeNotificationKind.queueProgress => Icons.trending_up,
      TondeNotificationKind.turnApproaching => Icons.directions_walk,
      TondeNotificationKind.called => Icons.campaign_outlined,
      TondeNotificationKind.presentationReminder => Icons.alarm,
      TondeNotificationKind.absent => Icons.person_off_outlined,
      TondeNotificationKind.resumed => Icons.replay,
      TondeNotificationKind.served => Icons.celebration_outlined,
    };
  }
}
