import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/controllers/feedback_providers.dart';
import 'package:tonde/features/assistance/presentation/feedback_error_message.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Formulaire de retour : avis, problème ou suggestion.
///
/// Un seul écran pour les trois catégories. Les séparer aurait produit trois
/// formulaires identiques à un libellé près, et trois endroits où corriger la
/// même règle de longueur de message.
class FeedbackFormPage extends ConsumerStatefulWidget {
  const FeedbackFormPage({super.key, required this.category});

  final FeedbackCategory category;

  @override
  ConsumerState<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends ConsumerState<FeedbackFormPage> {
  /// Même plancher que l'API : en dessous, le serveur refuse, et le client
  /// découvrirait la règle par un aller-retour réseau inutile.
  static const int _minLength = 20;
  static const int _maxLength = 1000;

  late FeedbackCategory _category = widget.category;
  final TextEditingController _message = TextEditingController();
  int? _rating;
  bool _sending = false;

  /// Vrai une fois le retour accepté par le serveur.
  ///
  /// On ne ferme plus l'écran d'un coup : un formulaire qui disparaît laisse le
  /// doute (« est-ce parti ? »). L'écran de remerciement répond, puis laisse le
  /// client fermer lui-même.
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  int get _length => _message.text.trim().length;

  bool get _canSubmit => _length >= _minLength && !_sending;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ticket = ref.read(activeTicketProvider).value;

    setState(() => _sending = true);
    try {
      await ref
          .read(myFeedbackProvider.notifier)
          .submit(
            buildDraft(
              category: _category,
              message: _message.text.trim(),
              rating: _rating,
              // Rattacher le retour au passage en cours donne au support le
              // service, l'agence et l'heure — sans quoi il doit deviner de
              // quel guichet parle le client.
              orgId: ticket?.organizationId,
              ticketId: ticket?.id,
              locale: Localizations.localeOf(context).languageCode,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(feedbackErrorMessage(l10n, error))),
      );
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String get _title => switch (_category) {
    FeedbackCategory.review => AppLocalizations.of(context).feedbackReviewTitle,
    FeedbackCategory.bug => AppLocalizations.of(context).feedbackBugTitle,
    FeedbackCategory.suggestion =>
      AppLocalizations.of(context).assistanceGiveFeedback,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_sent) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: SafeArea(
          child: _ThankYou(onClose: () => Navigator.of(context).pop()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.feedbackIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.feedbackCategory,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final category in FeedbackCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(l10n, category)),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  l10n.feedbackRating,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.feedbackRatingHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    // Re-toucher la même étoile retire la note : sans cela, une
                    // note choisie par erreur ne pourrait plus être effacée.
                    onPressed: () =>
                        setState(() => _rating = _rating == star ? null : star),
                    tooltip: '$star',
                    icon: Icon(
                      _rating != null && star <= _rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _rating != null && star <= _rating!
                          ? const Color(0xFFF5B301)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              maxLines: 6,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.feedbackMessage,
                hintText: l10n.feedbackMessageHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                counterText: l10n.feedbackMessageCounter(_length),
                helperText: _length == 0 || _length >= _minLength
                    ? null
                    : l10n.feedbackMessageTooShort(_minLength - _length),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.feedbackPrivacyNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.feedbackSubmit),
            ),
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

/// Écran de remerciement après un envoi accepté.
///
/// L'animation est volontairement courte (600 ms) et joue une seule fois : elle
/// confirme que le message est parti, elle ne retient personne.
class _ThankYou extends StatelessWidget {
  const _ThankYou({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const green = Color(0xFF1D9E75);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                // `easeOutBack` dépasse 1 en fin de course : sans borne,
                // `Opacity` lèverait une assertion.
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.feedbackThanksTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.feedbackThanksBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onClose,
                child: Text(l10n.supportClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
