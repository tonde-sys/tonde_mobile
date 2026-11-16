import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/domain/notification_service.dart';
import 'package:tonde/features/notifications/presentation/controllers/ticket_notification_watcher.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Service d'envoi factice : enregistre au lieu d'afficher.
class _RecordingService implements NotificationService {
  final List<TondeNotification> sent = <TondeNotification>[];
  int permissionRequests = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> show(TondeNotification notification) async {
    sent.add(notification);
  }
}

const _ticket = Ticket(
  number: 'B-145',
  position: 12,
  estimatedMinutes: 24,
  organizationId: 'org-1',
  organizationName: 'Banque Horizon',
  agencyId: 'ag-1',
  agencyName: 'Agence Centre',
  serviceId: 'svc-1',
  serviceName: 'Consultation',
);

QueueSnapshot _snapshot({
  int position = 12,
  QueueStatus status = QueueStatus.waiting,
  String? counter,
}) {
  return QueueSnapshot(
    ticketNumber: _ticket.number,
    position: position,
    estimatedMinutes: position * 2,
    status: status,
    updatedAt: DateTime(2026, 11, 15, 10),
    counterLabel: counter,
  );
}

void main() {
  late _RecordingService service;
  late AppLocalizations l10n;
  late TicketNotificationWatcher watcher;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() {
    service = _RecordingService();
    watcher = TicketNotificationWatcher(
      service: service,
      localizations: () async => l10n,
      onDelivered: (_) {},
      // Rappel très court : le test n'attend pas 90 secondes réelles.
      reminderDelay: const Duration(milliseconds: 40),
    );
  });

  tearDown(() => watcher.dispose());

  List<TondeNotificationKind> kinds() =>
      service.sent.map((n) => n.kind).toList();

  test('la prise de ticket envoie une confirmation nominative', () async {
    watcher.onTicket(_ticket);
    await pumpEventQueue();

    expect(kinds(), [TondeNotificationKind.ticketConfirmed]);
    final message = service.sent.single;
    expect(message.title, contains('B-145'));
    expect(message.body, contains('Consultation'));
    expect(message.body, contains('Agence Centre'));
    expect(message.urgent, isFalse);
  });

  test('un ticket en attente de synchronisation ne confirme rien', () async {
    watcher.onTicket(
      Ticket(
        number: _ticket.number,
        position: _ticket.position,
        estimatedMinutes: _ticket.estimatedMinutes,
        organizationId: _ticket.organizationId,
        organizationName: _ticket.organizationName,
        agencyId: _ticket.agencyId,
        agencyName: _ticket.agencyName,
        serviceName: _ticket.serviceName,
        pendingSync: true,
      ),
    );
    await pumpEventQueue();

    expect(service.sent, isEmpty);
  });

  test('la progression puis l’approche du tour, une seule fois chacune', () async {
    watcher.onTicket(_ticket);

    // Encore 10 personnes : message de progression.
    watcher.onSnapshot(_snapshot(position: 11));
    await pumpEventQueue();
    expect(kinds(), contains(TondeNotificationKind.queueProgress));

    // La même position répétée par le flux ne redouble pas le message.
    watcher.onSnapshot(_snapshot(position: 11));
    watcher.onSnapshot(_snapshot(position: 10));
    await pumpEventQueue();
    expect(
      kinds().where((k) => k == TondeNotificationKind.queueProgress).length,
      1,
    );

    // Trois personnes : le tour approche, et le message est prioritaire.
    watcher.onSnapshot(_snapshot(position: 4));
    await pumpEventQueue();
    expect(kinds(), contains(TondeNotificationKind.turnApproaching));
    expect(
      service.sent
          .firstWhere((n) => n.kind == TondeNotificationKind.turnApproaching)
          .urgent,
      isTrue,
    );
  });

  test('l’appel au guichet est urgent et relance après le délai', () async {
    watcher.onTicket(_ticket);
    watcher.onSnapshot(_snapshot(position: 1, status: QueueStatus.called, counter: 'Guichet 4'));
    await pumpEventQueue();

    final called = service.sent.firstWhere(
      (n) => n.kind == TondeNotificationKind.called,
    );
    expect(called.title, contains('tour'));
    expect(called.body, contains('Guichet 4'));
    expect(called.urgent, isTrue);

    // Personne ne s'est présenté : le rappel part après le délai.
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(kinds(), contains(TondeNotificationKind.presentationReminder));
  });

  test('aucun rappel si le client est déjà au guichet', () async {
    watcher.onTicket(_ticket);
    watcher.onSnapshot(_snapshot(position: 1, status: QueueStatus.called));
    await pumpEventQueue();

    watcher.onSnapshot(_snapshot(position: 1, status: QueueStatus.inService));
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(
      kinds(),
      isNot(contains(TondeNotificationKind.presentationReminder)),
    );
  });

  test('absence puis réactivation du ticket', () async {
    watcher.onTicket(_ticket);

    watcher.onSnapshot(_snapshot(position: 1, status: QueueStatus.absent));
    await pumpEventQueue();
    expect(kinds(), contains(TondeNotificationKind.absent));

    watcher.onSnapshot(_snapshot(position: 5));
    await pumpEventQueue();
    expect(kinds(), contains(TondeNotificationKind.resumed));
  });

  test('la fin de prise en charge clôt le parcours', () async {
    watcher.onTicket(_ticket);
    watcher.onTicket(_ticket.copyWith(served: true));
    await pumpEventQueue();

    expect(kinds(), contains(TondeNotificationKind.served));
  });

  test('un nouveau ticket repart d’une ardoise vierge', () async {
    watcher.onTicket(_ticket);
    await pumpEventQueue();

    watcher.onTicket(
      Ticket(
        number: 'B-146',
        position: 4,
        estimatedMinutes: 8,
        organizationId: _ticket.organizationId,
        organizationName: _ticket.organizationName,
        agencyId: _ticket.agencyId,
        agencyName: _ticket.agencyName,
        serviceName: _ticket.serviceName,
      ),
    );
    await pumpEventQueue();

    final confirmations = service.sent
        .where((n) => n.kind == TondeNotificationKind.ticketConfirmed)
        .toList();
    expect(confirmations.length, 2);
    expect(confirmations.last.ticketNumber, 'B-146');
  });

  test('notifications coupées : rien n’est envoyé', () async {
    final muted = TicketNotificationWatcher(
      service: service,
      localizations: () async => l10n,
      onDelivered: (_) {},
      isEnabled: () => false,
    );
    addTearDown(muted.dispose);

    muted.onTicket(_ticket);
    muted.onSnapshot(_snapshot(position: 4));
    await pumpEventQueue();

    expect(service.sent, isEmpty);
  });

  test('le centre distingue les alertes lues et permet de les supprimer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final center = container.read(notificationCenterProvider.notifier);

    final confirmation = TondeNotification(
      kind: TondeNotificationKind.ticketConfirmed,
      title: 'Ticket confirmé',
      body: 'Vous êtes inscrit dans la file.',
      ticketNumber: 'B-145',
      sentAt: DateTime(2026, 11, 15, 10),
    );
    final appel = TondeNotification(
      kind: TondeNotificationKind.called,
      title: 'C’est votre tour',
      body: 'Guichet 4.',
      ticketNumber: 'B-145',
      sentAt: DateTime(2026, 11, 15, 10, 5),
      urgent: true,
    );

    center.add(confirmation);
    center.add(appel);
    expect(container.read(notificationCenterProvider).length, 2);
    expect(container.read(unreadNotificationsProvider), 2);

    // Ouvrir une alerte la marque comme lue : elle ne compte plus.
    center.markRead(confirmation.dedupKey);
    expect(container.read(unreadNotificationsProvider), 1);
    expect(
      container
          .read(notificationCenterProvider)
          .firstWhere((n) => n.dedupKey == confirmation.dedupKey)
          .read,
      isTrue,
    );

    // Supprimer retire l'alerte de l'historique, sans toucher aux autres.
    center.remove(appel.dedupKey);
    final rest = container.read(notificationCenterProvider);
    expect(rest.length, 1);
    expect(rest.single.dedupKey, confirmation.dedupKey);
    expect(container.read(unreadNotificationsProvider), 0);
  });
}
