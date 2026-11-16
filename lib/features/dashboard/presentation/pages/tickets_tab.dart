import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/dashboard/presentation/widgets/pending_sync_chip.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
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
                  onRetry: () => ref.invalidate(activeTicketProvider),
                ),
                data: (ticket) {
                  if (ticket == null) {
                    return _EmptyState();
                  }
                  // La position affichée est celle du flux temps réel, comme
                  // sur la carte du tableau de bord : sinon l'onglet montre un
                  // rang figé pendant que la file avance, et les deux écrans
                  // se contredisent.
                  final snapshot = ticket.served || ticket.pendingSync
                      ? null
                      : ref.watch(queueTrackingProvider(ticket)).value?.snapshot;
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
                                // Un ticket servi n'est plus « actif » : la
                                // place est rendue, l'écran le dit au lieu de
                                // laisser croire que la file attend encore.
                                ticket.served
                                    ? l10n.ticketServed
                                    : l10n.ticketActiveTitle,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: ticket.served
                                          ? colorScheme.onSurfaceVariant
                                          : Colors.green,
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
                              if (ticket.served)
                                Text(
                                  l10n.ticketServedNote,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                )
                              else
                                Text(
                                  l10n.ticketPositionLabel(position),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ticket.served
                                    ? FilledButton.icon(
                                        onPressed: () =>
                                            context.push(AppRoutes.organizations),
                                        icon: const Icon(
                                          Icons.confirmation_number_outlined,
                                        ),
                                        label: Text(l10n.heroCta),
                                      )
                                    : FilledButton.icon(
                                        onPressed: () =>
                                            context.push(AppRoutes.queueTracking),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        label: Text(l10n.seePosition),
                                      ),
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noActiveTicket,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.noActiveTicketBody,
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
