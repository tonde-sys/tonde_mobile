import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tonde/core/errors/error_view.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/controllers/feedback_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Historique « Mes retours ».
///
/// Le statut est la seule information qui compte ici : envoyer un retour dans
/// le vide décourage plus qu'il n'aide. Voir « Lu » puis « Traité » prouve que
/// quelqu'un l'a pris en main.
class MyFeedbackPage extends ConsumerWidget {
  const MyFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feedback = ref.watch(myFeedbackProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackHistoryTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(myFeedbackProvider.notifier).refresh(),
          child: feedback.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              error: error,
              onAction: () => ref.read(myFeedbackProvider.notifier).refresh(),
            ),
            data: (entries) => entries.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _FeedbackCard(entry: entries[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});

  final FeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryLabel(l10n, entry.category),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusChip(status: entry.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (entry.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    Icon(
                      star <= entry.rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: star <= entry.rating!
                          ? const Color(0xFFF5B301)
                          : colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(entry.message, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.review => l10n.feedbackCategoryReview,
      FeedbackCategory.bug => l10n.feedbackCategoryBug,
      FeedbackCategory.suggestion => l10n.feedbackCategorySuggestion,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // « Reçu » reste neutre, « Lu » et « Traité » passent au vert : la couleur
    // dit l'avancement sans qu'il faille lire le libellé.
    final (label, color) = switch (status) {
      FeedbackStatus.received => (
        l10n.feedbackStatusReceived,
        const Color(0xFF6B7280),
      ),
      FeedbackStatus.read => (l10n.feedbackStatusRead, const Color(0xFF1D9E75)),
      FeedbackStatus.resolved => (
        l10n.feedbackStatusResolved,
        const Color(0xFF1D9E75),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.forum_outlined, size: 56, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.feedbackHistoryEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.feedbackHistoryEmptyBody,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

