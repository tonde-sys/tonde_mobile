import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';
import 'package:tonde/features/tracking/presentation/widgets/queue_status_badge.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Détails du ticket actif.
///
/// Tout tient sur une seule feuille, comme un ticket papier : identité en
/// haut, file d'attente, puis institution, séparés par des traits de
/// perforation plutôt que par des cartes distinctes. Les informations
/// volatiles viennent exclusivement du flux ; l'écran ne calcule jamais sa
/// position lui-même.
class QueueTrackingPage extends ConsumerWidget {
  const QueueTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ticketAsync = ref.watch(activeTicketProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketDetailsTitle)),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            AsyncErrorView(onRetry: () => ref.invalidate(activeTicketProvider)),
        data: (ticket) {
          if (ticket == null) {
            return _NoTicket(
              onTakeTicket: () => context.push(AppRoutes.organizations),
            );
          }
          // Un ticket pris hors ligne n'existe pas encore côté serveur :
          // ouvrir le flux temps réel n'aurait aucun sens et produirait une
          // erreur réseau pour une action critique.
          if (ticket.pendingSync) {
            return _PendingSyncView(ticket: ticket);
          }
          return _DetailsBody(ticket: ticket);
        },
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(queueTrackingProvider(ticket));

    return updateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => AsyncErrorView(
        onRetry: () => ref.invalidate(queueTrackingProvider(ticket)),
      ),
      data: (update) => _DetailsContent(ticket: ticket, update: update),
    );
  }
}

class _DetailsContent extends ConsumerStatefulWidget {
  const _DetailsContent({required this.ticket, required this.update});

  final Ticket ticket;
  final QueueUpdate update;

  @override
  ConsumerState<_DetailsContent> createState() => _DetailsContentState();
}

class _DetailsContentState extends ConsumerState<_DetailsContent> {
  bool _cancelling = false;

  Ticket get _ticket => widget.ticket;
  QueueSnapshot get _snapshot => widget.update.snapshot;

  Future<void> _refresh() async {
    // Reconstruit le flux : la nouvelle connexion renvoie immédiatement un
    // instantané, l'écran n'a donc pas besoin d'état de chargement local.
    ref.invalidate(queueTrackingProvider(_ticket));
  }

  Future<void> _cancelTicket() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.detailsCancelTitle(_ticket.number)),
        content: Text(l10n.detailsCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.detailsCancelKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.detailsCancelConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    await ref.read(activeTicketProvider.notifier).cancelTicket();
    if (!mounted) {
      return;
    }
    setState(() => _cancelling = false);
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.detailsCancelled)));
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) =>
          _NotificationsSheet(ticket: _ticket, snapshot: _snapshot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final snapshot = _snapshot;
    final updatedAt = DateFormat('HH:mm').format(snapshot.updatedAt);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _TicketPaper(
            ticket: _ticket,
            snapshot: snapshot,
            source: widget.update.source,
          ),
          if (snapshot.status == QueueStatus.called) ...[
            const SizedBox(height: 16),
            _CalledBanner(counterLabel: snapshot.counterLabel),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _cancelling ? null : _refresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.detailsRefresh),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _cancelling ? null : _openNotifications,
            icon: const Icon(Icons.notifications_none, size: 18),
            label: Text(l10n.detailsNotifications),
          ),
          if (!snapshot.isTerminal) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _cancelling ? null : _cancelTicket,
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: _cancelling
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.error,
                      ),
                    )
                  : Text(l10n.detailsCancel),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.trackingUpdatedAt(updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le ticket entier, présenté comme une feuille unique.
///
/// Le bloc « Ticket » a été retiré : le numéro et le statut figuraient deux
/// fois (en-tête + section). Ils restent ici une seule fois, là où le client
/// les cherche, et le reste des informations se lit d'un seul tenant.
class _TicketPaper extends StatelessWidget {
  const _TicketPaper({
    required this.ticket,
    required this.snapshot,
    required this.source,
  });

  final Ticket ticket;
  final QueueSnapshot snapshot;
  final QueueFeedSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final issuedAt = ticket.issuedAt;
    final service = ticket.serviceName;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      QueueStatusBadge(status: snapshot.status, large: true),
                      const Spacer(),
                      _SourcePill(source: source),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.organizationName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.agencyName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.trackingYourTicket.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticket.number,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: scheme.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.qrPayload != null) ...[
                        const SizedBox(width: 12),
                        _QrThumb(payload: snapshot.qrPayload!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const _PaperRule(),
            if (snapshot.pausedCounters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _counterPauseNotice(context, l10n, snapshot.pausedCounters.first),
              ),
            _PaperSection(
              title: l10n.detailsQueue,
              children: [
                _DetailRow(
                  label: l10n.trackingPosition,
                  value: '${snapshot.position}',
                  mono: true,
                ),
                _DetailRow(
                  label: l10n.detailsPeopleAhead,
                  value: '${snapshot.peopleAhead}',
                  mono: true,
                ),
                _DetailRow(
                  label: l10n.detailsCalledNumber,
                  value: snapshot.calledNumber ?? '—',
                  mono: true,
                ),
                _DetailRow(
                  label: l10n.trackingWaitTime,
                  value: l10n.trackingMinutesValue(snapshot.estimatedMinutes),
                ),
                _DetailRow(
                  label: l10n.detailsCounter,
                  value: snapshot.counterLabel ?? l10n.passDeskPending,
                  highlight: snapshot.counterLabel != null,
                ),
              ],
            ),
            const _PaperRule(),
            _PaperSection(
              title: l10n.detailsInstitution,
              children: [
                if (service != null && service.isNotEmpty)
                  _DetailRow(label: l10n.detailsService, value: service),
                _DetailRow(label: l10n.detailsName, value: ticket.organizationName),
                _DetailRow(label: l10n.detailsAgency, value: ticket.agencyName),
              ],
            ),
            if (issuedAt != null) ...[
              const _PaperRule(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Text(
                  '${l10n.detailsIssuedAt} '
                  '${DateFormat('dd/MM/yyyy · HH:mm').format(issuedAt)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section d'une feuille : un intitulé en petites capitales et ses lignes.
class _PaperSection extends StatelessWidget {
  const _PaperSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Trait de perforation entre deux sections de la feuille.
class _PaperRule extends StatelessWidget {
  const _PaperRule();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 1,
        child: CustomPaint(
          painter: _DashedRulePainter(
            Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
                color: highlight ? scheme.primary : null,
                fontFeatures: mono
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrThumb extends StatelessWidget {
  const _QrThumb({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: QrImageView(
        data: payload,
        version: QrVersions.auto,
        size: 68,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Bandeau d'alerte affiché quand le numéro du client est appelé.
class _CalledBanner extends StatelessWidget {
  const _CalledBanner({this.counterLabel});

  final String? counterLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const alert = Color(0xFFE24B4A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: alert, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trackingCalledBanner,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: alert,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.trackingCalledBannerBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Historique des événements du ticket.
///
/// Les entrées sont dérivées de l'instantané courant : on n'invente jamais un
/// événement qui n'a pas eu lieu, et l'état vide est explicite.
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.ticket, required this.snapshot});

  final Ticket ticket;
  final QueueSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = DateFormat('HH:mm').format(snapshot.updatedAt);

    final events = <({IconData icon, String title, String subtitle})>[
      if (ticket.issuedAt != null)
        (
          icon: Icons.confirmation_number_outlined,
          title: l10n.detailsNumber,
          subtitle:
              '${DateFormat('dd/MM/yyyy · HH:mm').format(ticket.issuedAt!)} · ${ticket.number}',
        ),
      if (snapshot.counterLabel != null)
        (
          icon: Icons.meeting_room_outlined,
          title: l10n.detailsCounter,
          subtitle: '${snapshot.counterLabel} · $time',
        ),
      if (snapshot.status == QueueStatus.called)
        (
          icon: Icons.campaign_outlined,
          title: l10n.trackingCalledBanner,
          subtitle: '${l10n.detailsCalledNumber} : ${ticket.number} · $time',
        ),
      (
        icon: Icons.groups_2_outlined,
        title: l10n.trackingPosition,
        subtitle: '${snapshot.position} · $time',
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.detailsNotifications,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.detailsNotificationsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(event.icon, size: 18, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              event.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Indique d'où viennent les mises à jour : poussées ou rafraîchies.
class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.source});

  final QueueFeedSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLive = source == QueueFeedSource.live;
    final color = isLive ? const Color(0xFF1D9E75) : const Color(0xFFBA7517);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLive ? Icons.bolt : Icons.sync, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            isLive ? l10n.trackingLive : l10n.trackingPolling,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTicket extends StatelessWidget {
  const _NoTicket({required this.onTakeTicket});

  final VoidCallback onTakeTicket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noActiveTicket,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noActiveTicketBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onTakeTicket,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: Text(l10n.heroCta),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran affiché à la place du suivi quand le ticket attend sa confirmation.
class _PendingSyncView extends StatelessWidget {
  const _PendingSyncView({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFFD98A) : const Color(0xFF7A4E00);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: accent),
            const SizedBox(height: 16),
            Text(
              l10n.trackingPendingTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trackingPendingBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              ticket.number,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _counterPauseNotice(
  BuildContext context,
  AppLocalizations l10n,
  CounterPauseInfo pause,
) {
  final until = pause.pausedUntil;
  final text = until == null
      ? l10n.trackingCounterPaused(pause.name)
      : l10n.trackingCounterPausedUntil(
          pause.name,
          MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(until),
          ),
        );
  final color = Theme.of(context).colorScheme.tertiary;
  return Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Icon(Icons.pause_circle_outline, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
