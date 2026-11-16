import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tonde/features/dashboard/presentation/widgets/pending_sync_chip.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';
import 'package:tonde/features/tracking/presentation/widgets/queue_status_badge.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Ticket présenté comme un pass numérique.
///
/// La carte se met à jour toute seule : elle écoute le même flux temps réel
/// que l'écran de suivi (`queueTrackingProvider`), donc la position, l'attente
/// et le statut bougent sans que l'accueil ait à se reconstruire entièrement.
///
/// Deux retours sensoriels seulement, pour ne pas transformer le téléphone en
/// vibreur :
///  * le passage au statut « appelé » déclenche une vibration franche ;
///  * chaque place gagnée dans la file donne un clic discret.
class TicketPassCard extends ConsumerStatefulWidget {
  const TicketPassCard({super.key, required this.ticket, this.onTap});

  final Ticket ticket;
  final VoidCallback? onTap;

  @override
  ConsumerState<TicketPassCard> createState() => _TicketPassCardState();
}

class _TicketPassCardState extends ConsumerState<TicketPassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final updateAsync = ref.watch(queueTrackingProvider(widget.ticket));

    // Le flux peut être indisponible (hors ligne, ticket en attente de
    // synchronisation) : la carte retombe alors sur les valeurs du ticket,
    // jamais sur un écran vide.
    final snapshot = updateAsync.value?.snapshot;
    final status = snapshot?.status ?? QueueStatus.waiting;
    final position = snapshot?.position ?? widget.ticket.position;
    final minutes =
        snapshot?.estimatedMinutes ?? widget.ticket.estimatedMinutes;
    final counter = snapshot?.counterLabel;

    ref.listen(queueTrackingProvider(widget.ticket), (previous, next) {
      final before = previous?.value?.snapshot;
      final after = next.value?.snapshot;
      if (after == null) {
        return;
      }
      if (before?.status != QueueStatus.called &&
          after.status == QueueStatus.called) {
        HapticFeedback.heavyImpact();
        _pulse.forward(from: 0);
      } else if (before != null && after.position < before.position) {
        HapticFeedback.selectionClick();
      }
    });

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final beat = _pulse.isAnimating
            ? 1 + 0.02 * (1 - (_pulse.value * 2 - 1).abs())
            : 1.0;
        return Transform.scale(scale: beat, child: child);
      },
      child: Semantics(
        button: widget.onTap != null,
        label: l10n.ticketSemantics(widget.ticket.number, position),
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PassHeader(ticket: widget.ticket, status: status),
                  const _DashedRule(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.passYourNumber,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            widget.ticket.number,
                            key: ValueKey(widget.ticket.number),
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
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _PassMetric(
                                icon: Icons.groups_2_outlined,
                                label: l10n.detailsPeopleAhead,
                                value: '${position > 1 ? position - 1 : 0}',
                                emphasize: position <= 1,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            Expanded(
                              child: _PassMetric(
                                icon: Icons.schedule,
                                label: l10n.trackingWaitTime,
                                value: l10n.trackingMinutesValue(minutes),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              counter ?? l10n.passDeskPending,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: counter == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const _DashedRule(),
                  _PassFooter(
                    ticket: widget.ticket,
                    payload: snapshot?.qrPayload,
                    pendingSync: widget.ticket.pendingSync,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassHeader extends StatelessWidget {
  const _PassHeader({required this.ticket, required this.status});

  final Ticket ticket;
  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.agencyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (ticket.serviceName != null &&
                    ticket.serviceName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ticket.serviceName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (ticket.pendingSync)
            const PendingSyncChip()
          else if (ticket.served)
            const _ServedChip()
          else
            QueueStatusBadge(status: status),
        ],
      ),
    );
  }
}

/// Pastille d'un ticket déjà servi : le client est passé au guichet.
class _ServedChip extends StatelessWidget {
  const _ServedChip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            l10n.ticketServed,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassMetric extends StatelessWidget {
  const _PassMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(
            value,
            key: ValueKey(value),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasize
                  ? QueueStatusBadge.colorFor(QueueStatus.called)
                  : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _PassFooter extends StatelessWidget {
  const _PassFooter({
    required this.ticket,
    required this.payload,
    required this.pendingSync,
  });

  final Ticket ticket;
  final String? payload;
  final bool pendingSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasQr = !pendingSync && payload != null && payload!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          if (hasQr)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: payload!,
                version: QrVersions.auto,
                size: 62,
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
            )
          else
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                pendingSync ? Icons.cloud_off_outlined : Icons.qr_code_2,
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendingSync ? l10n.passPendingQr : l10n.trackingQrHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      l10n.seePosition,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: scheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trait de perforation du pass, dessiné à la main pour éviter une dépendance.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedRulePainter(
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7),
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
    var x = 12.0;
    while (x < size.width - 12) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
