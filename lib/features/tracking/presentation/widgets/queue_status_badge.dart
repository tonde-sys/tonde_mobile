import 'package:flutter/material.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Badge de statut du ticket, conforme au Design System TONDE.
///
/// Quatre états : « En attente » (ambre), « Appelé » (rouge pulsant, c'est une
/// alerte qui doit attirer l'œil), « En cours » (émeraude) et « Absent » (rose).
/// Seul l'état « Appelé » pulse : une animation permanente sur les autres états
/// fatiguerait l'œil sans rien apporter.
class QueueStatusBadge extends StatefulWidget {
  const QueueStatusBadge({super.key, required this.status, this.large = false});

  /// Fige les animations (tests de widgets, où `pumpAndSettle` doit aboutir).
  static bool animationsEnabled = true;

  final QueueStatus status;

  /// Taille du badge, pour le mettre en avant sur l'écran de suivi.
  final bool large;

  static Color colorFor(QueueStatus status) {
    return switch (status) {
      QueueStatus.waiting => const Color(0xFFBA7517),
      QueueStatus.called => const Color(0xFFE24B4A),
      QueueStatus.inService => const Color(0xFF1D9E75),
      QueueStatus.absent => const Color(0xFFD4537E),
    };
  }

  static String labelFor(AppLocalizations l10n, QueueStatus status) {
    return switch (status) {
      QueueStatus.waiting => l10n.trackingStatusWaiting,
      QueueStatus.called => l10n.trackingStatusCalled,
      QueueStatus.inService => l10n.trackingStatusInService,
      QueueStatus.absent => l10n.trackingStatusAbsent,
    };
  }

  @override
  State<QueueStatusBadge> createState() => _QueueStatusBadgeState();
}

class _QueueStatusBadgeState extends State<QueueStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant QueueStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _sync();
    }
  }

  void _sync() {
    final shouldPulse =
        widget.status == QueueStatus.called &&
        QueueStatusBadge.animationsEnabled;
    if (shouldPulse) {
      if (!_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      }
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = QueueStatusBadge.colorFor(widget.status);
    final label = QueueStatusBadge.labelFor(
      AppLocalizations.of(context),
      widget.status,
    );
    final fontSize = widget.large ? 14.0 : 12.0;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.large ? 14 : 10,
          vertical: widget.large ? 8 : 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
