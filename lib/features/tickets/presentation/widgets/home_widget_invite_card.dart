import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_driver.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_invite.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Propose d'épingler le widget juste après la prise d'un ticket.
///
/// C'est le seul moment où la proposition a un sens : le client vient de
/// recevoir un numéro et va devoir surveiller son tour. Une feuille modale
/// retarderait l'écran qu'il veut lire ; cette carte s'insère sous le numéro
/// et laisse le bouton principal intact.
///
/// Elle disparaît d'elle-même quand le lanceur ne sait pas épingler (iOS,
/// certains lanceurs Android) : proposer une action impossible est pire que
/// de ne rien proposer.
class HomeWidgetInviteCard extends ConsumerWidget {
  const HomeWidgetInviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(homeWidgetInviteProvider) != HomeWidgetInvite.undecided) {
      return const SizedBox.shrink();
    }
    if (!(ref.watch(homeWidgetPinSupportedProvider).value ?? false)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.widgets_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.homeWidgetInviteTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeWidgetInviteBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      ref.read(homeWidgetInviteProvider.notifier).dismiss(),
                  child: Text(l10n.homeWidgetInviteLater),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    // Capturé avant l'attente : après, le contexte peut avoir
                    // été démonté (le client peut quitter l'écran entre-temps).
                    final messenger = ScaffoldMessenger.of(context);
                    final requested = await ref
                        .read(homeWidgetBridgeProvider)
                        .requestPin();
                    await ref.read(homeWidgetInviteProvider.notifier).accept();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          requested
                              ? l10n.homeWidgetPinConfirm
                              : l10n.homeWidgetPinUnsupported,
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.homeWidgetInviteAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
