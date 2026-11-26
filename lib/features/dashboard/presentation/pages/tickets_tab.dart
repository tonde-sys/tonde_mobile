import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/dashboard/presentation/widgets/pending_sync_chip.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tickets/presentation/ticket_error_message.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Onglet Tickets : ticket actif ou état vide.
class TicketsTab extends ConsumerWidget {
  const TicketsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final ticketAsync = ref.watch(activeTicketProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tabTickets,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ticketAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => AsyncErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(activeTicketProvider),
                ),
                data: (ticket) {
                  if (ticket == null) {
                    return _EmptyState(
                      closed: ref.watch(lastClosedTicketProvider).value,
                    );
                  }
                  // La position affichée est celle du flux temps réel, comme
                  // sur la carte du tableau de bord : sinon l'onglet montre un
                  // rang figé pendant que la file avance, et les deux écrans
                  // se contredisent.
                  final snapshot = ticket.isClosed || ticket.pendingSync
                      ? null
                      : ref
                            .watch(
                              queueTrackingProvider(QueueTrackingKey(ticket)),
                            )
                            .value
                            ?.snapshot;
                  final position = snapshot?.position ?? ticket.position;
                  return ListView(
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // L'en-tête dit l'état réel, pas une catégorie
                                // générique : un client appelé ou absent doit
                                // lire sa situation, pas « Ticket actif ».
                                switch (ticket.status) {
                                  TicketStatus.called =>
                                    l10n.trackingStatusCalled,
                                  TicketStatus.serving =>
                                    l10n.trackingStatusInService,
                                  TicketStatus.absent =>
                                    l10n.trackingStatusAbsent,
                                  TicketStatus.done ||
                                  TicketStatus.cancelled => l10n.ticketServed,
                                  _ => l10n.ticketActiveTitle,
                                },
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: switch (ticket.status) {
                                        TicketStatus.absent => const Color(
                                          0xFFD4537E,
                                        ),
                                        TicketStatus.done ||
                                        TicketStatus.cancelled =>
                                          colorScheme.onSurfaceVariant,
                                        _ => Colors.green,
                                      },
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ticket.number,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (ticket.pendingSync) ...[
                                const SizedBox(height: 8),
                                const PendingSyncChip(),
                              ],
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.account_balance_outlined,
                                text: ticket.organizationName,
                              ),
                              const SizedBox(height: 4),
                              _InfoRow(
                                icon: Icons.location_on_outlined,
                                text: ticket.agencyName,
                              ),
                              const SizedBox(height: 12),
                              if (ticket.isClosed)
                                Text(
                                  l10n.ticketServedNote,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                )
                              else if (position > 0)
                                Text(
                                  l10n.ticketPositionLabel(position),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: _TicketAction(ticket: ticket),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.closed});

  /// Ticket qui vient de cesser d'être actif, s'il y en a un.
  final Ticket? closed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final closed = this.closed;

    // Même distinction que sur l'accueil : un ticket arrivé au guichet a été
    // servi, il n'a pas expiré. C'est le dernier écran que le client consulte
    // après son passage, autant qu'il y lise la vérité.
    final wasServed =
        closed != null &&
        (closed.status == TicketStatus.serving ||
            closed.status == TicketStatus.done);

    final title = closed == null
        ? l10n.noActiveTicket
        : wasServed
        ? l10n.ticketClosedServedTitle
        : l10n.ticketClosedExpiredTitle;
    final body = closed == null
        ? l10n.noActiveTicketBody
        : wasServed
        ? l10n.ticketClosedServedBody(closed.number)
        : l10n.ticketClosedExpiredBody(closed.number);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            closed == null
                ? Icons.confirmation_number_outlined
                : wasServed
                ? Icons.task_alt
                : Icons.hourglass_disabled_outlined,
            size: 56,
            color: closed == null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.organizations),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: Text(l10n.heroCta),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// Action principale de l'onglet, selon l'état réel du ticket.
///
/// Même logique que la bannière d'accueil : la reprise est une action
/// asynchrone qui peut être refusée par le serveur, elle a donc besoin d'un
/// état d'attente et d'un retour d'erreur — ce qu'un simple bouton de
/// navigation ne demande pas.
class _TicketAction extends ConsumerStatefulWidget {
  const _TicketAction({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_TicketAction> createState() => _TicketActionState();
}

class _TicketActionState extends ConsumerState<_TicketAction> {
  bool _busy = false;

  Future<void> _resume() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(activeTicketProvider.notifier).resumeTicket();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.resumeSuccess)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(resumeErrorMessage(l10n, error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticket = widget.ticket;

    if (ticket.canResume) {
      return FilledButton.icon(
        onPressed: _busy ? null : _resume,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restart_alt),
        label: Text(l10n.resumeTicket),
      );
    }
    if (ticket.isClosed) {
      return FilledButton.icon(
        onPressed: () => context.push(AppRoutes.organizations),
        icon: const Icon(Icons.confirmation_number_outlined),
        label: Text(l10n.heroCta),
      );
    }
    return FilledButton.icon(
      onPressed: () => context.push(AppRoutes.queueTracking),
      icon: const Icon(Icons.visibility_outlined),
      label: Text(l10n.seePosition),
    );
  }
}
