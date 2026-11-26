import 'package:flutter/material.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Questions fréquentes, dans l'ordre chronologique d'un passage.
///
/// Page dédiée plutôt que section dépliée dans l'onglet : à six entrées, la
/// liste dépassait deux écrans et repoussait le contact — ce qu'on vient
/// chercher quand on est bloqué devant un guichet.
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final entries = <(String, String)>[
      (l10n.faqTakeTicketTitle, l10n.faqTakeTicketBody),
      (l10n.faqAbsentTitle, l10n.faqAbsentBody),
      (l10n.faqExpiredTitle, l10n.faqExpiredBody),
      (l10n.faqPausedTitle, l10n.faqPausedBody),
      (l10n.faqNotificationsTitle, l10n.faqNotificationsBody),
      (l10n.faqTwoTicketsTitle, l10n.faqTwoTicketsBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistanceFaq)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              l10n.faqIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0) const Divider(height: 1),
                    ExpansionTile(
                      // Pas de clé de persistance : une réponse ouverte ne doit
                      // pas rouvrir seule à la prochaine visite, ce serait du
                      // bruit.
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        entries[index].$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[index].$2,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
