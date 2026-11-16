import 'package:flutter/material.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Pastille signalant qu'un ticket a été pris hors ligne et attend sa
/// confirmation par le serveur.
///
/// Volontairement ambre et non rouge : le ticket existe et est conservé, il
/// n'est simplement pas encore reconnu par le guichet.
class PendingSyncChip extends StatelessWidget {
  const PendingSyncChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF3A2E12)
        : const Color(0xFFFFF3D6);
    final foreground = isDark
        ? const Color(0xFFFFD98A)
        : const Color(0xFF7A4E00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_problem, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            l10n.ticketPendingSync,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
