import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/features/tickets/presentation/controllers/pending_sync_controller.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Bandeau discret d'état hors ligne, placé juste au-dessus de la navigation.
///
/// Trois situations : réseau présent et rien en attente (aucun bandeau),
/// réseau absent (les données affichées viennent du cache), action en attente
/// de synchronisation. Aucune de ces situations ne remplace l'écran : le
/// contenu local reste consultable et les actions critiques sont enregistrées.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(isOnlineProvider);
    final pending = ref.watch(pendingSyncCountProvider);

    if (online && pending == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color background;
    final Color foreground;
    final IconData icon;
    final String message;

    if (online) {
      background = theme.colorScheme.secondaryContainer;
      foreground = theme.colorScheme.onSecondaryContainer;
      icon = Icons.sync;
      message = l10n.offlinePendingSync;
    } else {
      // Ambre : lisible sur fond clair comme sombre, sans crier (ce n'est pas
      // une erreur, c'est un mode de fonctionnement).
      background = isDark ? const Color(0xFF3A2E12) : const Color(0xFFFFF3D6);
      foreground = isDark ? const Color(0xFFFFD98A) : const Color(0xFF7A4E00);
      icon = Icons.cloud_off_outlined;
      message = pending == 0
          ? '${l10n.offlineMode} — ${l10n.offlineLocalData}'
          : '${l10n.offlineMode} — ${l10n.offlinePendingActions(pending)}';
    }

    return Material(
      color: background,
      child: InkWell(
        // Relance manuelle de la synchronisation quand le réseau est revenu.
        onTap: online
            ? () => ref.read(activeTicketProvider.notifier).syncPending()
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (online) Icon(Icons.refresh, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
