import 'dart:async';

import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/domain/notification_service.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Message prêt à composer, une fois la langue connue.
typedef _Message = ({String title, String body});

/// Décide **quand** notifier, à partir du ticket et du flux de la file.
///
/// Cette classe ne connaît ni Flutter ni le système de notifications : elle
/// reçoit des instantanés et rend des [TondeNotification]. C'est ce qui permet
/// de la tester sans téléphone, et de brancher plus tard un vrai service push
/// sans réécrire la règle métier.
///
/// Chaque étape n'est émise qu'une fois par ticket ([_sent]) : le flux temps
/// réel répète la même position plusieurs fois, et l'usager ne doit pas
/// recevoir dix fois le même message.
final class TicketNotificationWatcher {
  TicketNotificationWatcher({
    required NotificationService service,
    required Future<AppLocalizations> Function() localizations,
    required void Function(TondeNotification notification) onDelivered,
    this.reminderDelay = const Duration(seconds: 90),
    this.progressThreshold = 10,
    this.approachingThreshold = 3,
    bool Function()? isEnabled,
    DateTime Function()? clock,
  }) : _service = service,
       _localizations = localizations,
       _onDelivered = onDelivered,
       _isEnabled = isEnabled ?? (() => true),
       _clock = clock ?? DateTime.now;

  final NotificationService _service;
  final Future<AppLocalizations> Function() _localizations;
  final void Function(TondeNotification notification) _onDelivered;
  final bool Function() _isEnabled;
  final DateTime Function() _clock;

  /// Délai après l'appel avant de relancer l'usager qui ne s'est pas présenté.
  final Duration reminderDelay;

  /// Seuil « encore une dizaine de personnes ».
  final int progressThreshold;

  /// Seuil « votre tour approche ».
  final int approachingThreshold;

  String? _ticketNumber;
  final Set<TondeNotificationKind> _sent = <TondeNotificationKind>{};
  QueueStatus? _lastStatus;
  Timer? _reminder;

  /// Nouveau ticket courant (ou `null` quand il n'y en a plus).
  void onTicket(Ticket? ticket) {
    if (ticket == null) {
      _reset();
      return;
    }

    if (ticket.number != _ticketNumber) {
      _reset();
      _ticketNumber = ticket.number;
      if (!ticket.pendingSync) {
        _emit(
          TondeNotificationKind.ticketConfirmed,
          urgent: false,
          compose: (l10n) => (
            title: l10n.notifTicketConfirmedTitle(ticket.number),
            body: l10n.notifTicketConfirmedBody(
              ticket.serviceName ?? '',
              ticket.agencyName,
            ),
          ),
        );
      }
    }

    // La fin de prise en charge ne vient pas du flux : elle est décidée par le
    // contrôleur de ticket, qui libère la place pour un ticket suivant.
    if (ticket.served) {
      _emit(
        TondeNotificationKind.served,
        urgent: false,
        compose: (l10n) => (
          title: l10n.notifServedTitle,
          body: l10n.notifServedBody,
        ),
      );
    }
  }

  /// Nouvelle photo de la file.
  void onSnapshot(QueueSnapshot snapshot) {
    if (_ticketNumber == null || snapshot.ticketNumber != _ticketNumber) {
      // Un flux d'un ancien ticket peut survivre quelques instants : on
      // l'ignore plutôt que de notifier sur une file qui n'est plus la sienne.
      return;
    }

    final previous = _lastStatus;
    _lastStatus = snapshot.status;

    switch (snapshot.status) {
      case QueueStatus.absent:
        _reminder?.cancel();
        _emit(
          TondeNotificationKind.absent,
          urgent: false,
          compose: (l10n) => (
            title: l10n.notifAbsentTitle,
            body: l10n.notifAbsentBody(snapshot.ticketNumber),
          ),
        );

      case QueueStatus.called:
        _emit(
          TondeNotificationKind.called,
          urgent: true,
          compose: (l10n) => (
            title: l10n.notifCalledTitle,
            body: l10n.notifCalledBody(
              snapshot.ticketNumber,
              snapshot.counterLabel ?? l10n.notifCounterFallback,
            ),
          ),
        );
        _scheduleReminder(snapshot.counterLabel);

      case QueueStatus.inService:
        // Le client est au guichet : plus rien à relancer.
        _reminder?.cancel();

      case QueueStatus.waiting:
        if (previous == QueueStatus.absent) {
          _emit(
            TondeNotificationKind.resumed,
            urgent: false,
            compose: (l10n) => (
              title: l10n.notifResumedTitle,
              body: l10n.notifResumedBody(snapshot.ticketNumber),
            ),
          );
        }
        _emitProgress(snapshot);
    }
  }

  void _emitProgress(QueueSnapshot snapshot) {
    final ahead = snapshot.peopleAhead;
    if (ahead <= approachingThreshold && ahead > 0) {
      _emit(
        TondeNotificationKind.turnApproaching,
        urgent: true,
        compose: (l10n) => (
          title: l10n.notifApproachingTitle,
          body: l10n.notifApproachingBody(ahead),
        ),
      );
      return;
    }
    if (ahead <= progressThreshold && ahead > approachingThreshold) {
      _emit(
        TondeNotificationKind.queueProgress,
        urgent: false,
        compose: (l10n) => (
          title: l10n.notifProgressTitle(ahead),
          body: l10n.notifProgressBody(snapshot.estimatedMinutes),
        ),
      );
    }
  }

  void _scheduleReminder(String? counterLabel) {
    _reminder?.cancel();
    _reminder = Timer(reminderDelay, () {
      if (_lastStatus != QueueStatus.called) {
        return;
      }
      _emit(
        TondeNotificationKind.presentationReminder,
        urgent: true,
        compose: (l10n) => (
          title: l10n.notifReminderTitle,
          body: l10n.notifReminderBody(
            counterLabel ?? l10n.notifCounterFallback,
          ),
        ),
      );
    });
  }

  void _emit(
    TondeNotificationKind kind, {
    required bool urgent,
    required _Message Function(AppLocalizations l10n) compose,
  }) {
    if (_sent.contains(kind) || !_isEnabled()) {
      return;
    }
    // Marquée tout de suite : la composition du message est asynchrone, et
    // deux instantanés rapprochés ne doivent pas produire deux envois.
    _sent.add(kind);
    // Le ticket est figé ici : si un autre ticket arrive avant l'envoi, la
    // notification doit rester celle de la file qu'elle décrit.
    final number = _ticketNumber ?? '';
    // Différé d'un microtask : le veilleur est appelé depuis le build du
    // pilote, et Riverpod interdit de modifier un provider pendant qu'un
    // autre se construit (l'historique est mis à jour à l'envoi).
    unawaited(Future<void>.microtask(() => _deliver(kind, number, urgent, compose)));
  }

  Future<void> _deliver(
    TondeNotificationKind kind,
    String ticketNumber,
    bool urgent,
    _Message Function(AppLocalizations l10n) compose,
  ) async {
    final l10n = await _localizations();
    final message = compose(l10n);
    final notification = TondeNotification(
      kind: kind,
      title: message.title,
      body: message.body,
      ticketNumber: ticketNumber,
      sentAt: _clock(),
      urgent: urgent,
    );
    _onDelivered(notification);
    await _service.show(notification);
  }

  void _reset() {
    _reminder?.cancel();
    _reminder = null;
    _sent.clear();
    _ticketNumber = null;
    _lastStatus = null;
  }

  void dispose() {
    _reminder?.cancel();
    _reminder = null;
  }
}
