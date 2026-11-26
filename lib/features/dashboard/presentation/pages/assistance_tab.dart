import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/controllers/feedback_providers.dart';
import 'package:tonde/features/assistance/presentation/widgets/contact_sheet.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/presentation/cancel_ticket_dialog.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tickets/presentation/ticket_error_message.dart';
import 'package:tonde/features/tickets/presentation/ticket_status_display.dart';
import 'package:tonde/features/tracking/presentation/widgets/queue_status_badge.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Onglet Assistance — le centre d'aide.
///
/// Trois portes, dans l'ordre où un client se les pose : mon institution (le
/// service, la file, mon ticket), TONDE (l'application, mon compte), puis les
/// réponses écrites. Le contact vient **avant** la FAQ : quelqu'un qui ouvre cet
/// écran est souvent bloqué maintenant, pas en train de se documenter.
class AssistanceTab extends ConsumerStatefulWidget {
  const AssistanceTab({super.key});

  @override
  ConsumerState<AssistanceTab> createState() => _AssistanceTabState();
}

class _AssistanceTabState extends ConsumerState<AssistanceTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Entrée en cascade des cartes : chaque carte démarre un peu après la
  /// précédente. L'animation est **courte et non bloquante** — une aide doit
  /// s'ouvrir vite, pas se donner en spectacle.
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.helpCenterTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.helpCenterQuestion,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const _MyTicketSection(),
          const SizedBox(height: 16),
          _staggered(
            0,
            _HelpCard(
              icon: Icons.apartment_rounded,
              title: l10n.helpInstitutionTitle,
              body: l10n.helpInstitutionBody,
              action: l10n.helpInstitutionAction,
              onTap: () => showInstitutionContactSheet(context),
            ),
          ),
          _staggered(
            1,
            _HelpCard(
              icon: Icons.support_agent_rounded,
              title: l10n.helpTondeTitle,
              body: l10n.helpTondeBody,
              action: l10n.helpTondeAction,
              emphasized: true,
              onTap: () => showTondeContactSheet(context),
            ),
          ),
          _staggered(
            2,
            _HelpCard(
              icon: Icons.quiz_outlined,
              title: l10n.assistanceFaq,
              body: l10n.helpFaqBody,
              action: l10n.helpFaqAction,
              onTap: () => context.push(AppRoutes.faq),
            ),
          ),
          const SizedBox(height: 8),
          _staggered(3, const _FeedbackSection()),
          const SizedBox(height: 24),
          const _ServiceStatusCard(),
        ],
      ),
    );
  }
}

// ── Carte d'aide ──────────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  /// Met en avant le canal TONDE : c'est celui qui traite les problèmes
  /// techniques, la raison la plus fréquente d'ouvrir cet écran.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = emphasized ? scheme.primaryContainer : scheme.surface;
    final foreground = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: emphasized
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: emphasized
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.75)
                            : scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$action →',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: emphasized
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.5)
                    : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mon ticket ────────────────────────────────────────────────────────────────

/// Raccourcis vers le ticket en cours.
///
/// La section disparaît entièrement quand il n'y a pas de ticket : un client
/// sans ticket qui ouvre l'assistance cherche de l'aide, pas un rappel qu'il
/// n'a rien en cours.
class _MyTicketSection extends ConsumerStatefulWidget {
  const _MyTicketSection();

  @override
  ConsumerState<_MyTicketSection> createState() => _MyTicketSectionState();
}

class _MyTicketSectionState extends ConsumerState<_MyTicketSection> {
  bool _busy = false;

  Future<void> _resume(Ticket ticket) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(activeTicketProvider.notifier).resumeTicket();
      messenger.showSnackBar(SnackBar(content: Text(l10n.resumeSuccess)));
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(resumeErrorMessage(l10n, error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel(Ticket ticket) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmCancelTicket(context, number: ticket.number)) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = true);
    await ref.read(activeTicketProvider.notifier).cancelTicket();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.detailsCancelled)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticket = ref.watch(activeTicketProvider).value;

    if (ticket == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.number,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                QueueStatusBadge(status: queueStatusOf(ticket.status)),
              ],
            ),
            if (ticket.counterLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                ticket.counterLabel!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => context.push(AppRoutes.queueTracking),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(l10n.seePosition),
                ),
                if (ticket.canResume)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _resume(ticket),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text(l10n.resumeTicket),
                  ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _cancel(ticket),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.detailsCancel),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Retours ───────────────────────────────────────────────────────────────────

class _FeedbackSection extends ConsumerWidget {
  const _FeedbackSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = ref.watch(myFeedbackProvider).value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.helpFeedbackTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.helpFeedbackBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.assistanceGiveFeedback),
                subtitle: Text(l10n.assistanceGiveFeedbackBody),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '${AppRoutes.feedbackNew}?categorie=${FeedbackCategory.review.wire}',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.assistanceReportBug),
                subtitle: Text(l10n.assistanceReportBugBody),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '${AppRoutes.feedbackNew}?categorie=${FeedbackCategory.bug.wire}',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(l10n.feedbackHistoryTitle),
                subtitle: Text(l10n.assistanceMyFeedbackBody),
                // La pastille évite d'ouvrir l'historique pour découvrir qu'il
                // est vide.
                trailing: count == 0
                    ? const Icon(Icons.chevron_right)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Badge(label: Text('$count')),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                onTap: () => context.push(AppRoutes.myFeedback),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── État du service ───────────────────────────────────────────────────────────

/// Sonde `/health` + version de l'application.
///
/// C'est un diagnostic, pas une promesse : « joignable » veut dire que le
/// serveur a répondu à l'instant, pas que la file fonctionne. Le libellé reste
/// donc factuel, et la version permet au support de savoir quoi corriger.
class _ServiceStatusCard extends ConsumerWidget {
  const _ServiceStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reachable = ref.watch(serviceReachableProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.assistanceServiceStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  reachable.when(
                    loading: () => Text(
                      l10n.assistanceServiceStatus,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    error: (_, _) => Text(l10n.serviceUnreachable),
                    data: (isUp) => Text(
                      isUp ? l10n.serviceReachable : l10n.serviceUnreachable,
                      style: TextStyle(
                        color: isUp
                            ? const Color(0xFF1D9E75)
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.appVersion(kAppVersion),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
