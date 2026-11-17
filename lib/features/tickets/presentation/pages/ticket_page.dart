import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/dashboard/presentation/widgets/pending_sync_chip.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Confirmation de la prise de ticket pour un service précis.
///
/// Le parcours est volontairement linéaire : organisation → agence → service
/// → confirmation. Le service est porté par l'URL, donc revenir en arrière ne
/// fait jamais perdre le choix du client.
class TicketPage extends ConsumerStatefulWidget {
  const TicketPage({
    super.key,
    required this.organizationId,
    required this.agencyId,
    required this.serviceId,
  });

  final String organizationId;
  final String agencyId;
  final String serviceId;

  @override
  ConsumerState<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends ConsumerState<TicketPage> {
  /// Numéro du ticket pris **depuis cet écran**.
  ///
  /// Sa confirmation reste affichée même si la démo le marque servi entre
  /// temps. À l'inverse, un ticket servi lors d'une session précédente ne
  /// détourne plus le parcours : le client venu reprendre un ticket voit bien
  /// le bouton de prise, et non la confirmation d'un passage déjà terminé.
  String? _justTaken;

  @override
  Widget build(BuildContext context) {
    final organizationId = widget.organizationId;
    final agencyId = widget.agencyId;
    final organizationsAsync = ref.watch(organizationsProvider);
    final agenciesAsync = ref.watch(agenciesProvider(organizationId));
    final servicesAsync = ref.watch(
      servicesProvider((organizationId: organizationId, agencyId: agencyId)),
    );
    final ticketAsync = ref.watch(activeTicketProvider);

    return Scaffold(
      appBar: AppBar(),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AsyncErrorView(
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (organizations) => agenciesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AsyncErrorView(
            onRetry: () => ref.invalidate(agenciesProvider(organizationId)),
          ),
          data: (agencies) => servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => AsyncErrorView(
              onRetry: () => ref.invalidate(
                servicesProvider((
                  organizationId: organizationId,
                  agencyId: agencyId,
                )),
              ),
            ),
            data: (services) {
              final organization = _findOrganization(organizations);
              final agency = _findAgency(agencies);
              final service = _findService(services);
              if (organization == null || agency == null) {
                return const SizedBox.shrink();
              }
              if (service == null) {
                return _ServiceGone(onBack: () => context.pop());
              }
              return ticketAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => AsyncErrorView(
                  onRetry: () => ref.invalidate(activeTicketProvider),
                ),
                data: (ticket) {
                  // Un ticket déjà servi ne bloque plus la prise : le client
                  // peut en reprendre un immédiatement.
                  final blocking = ticket != null && !ticket.served;
                  // Deux cas gardent l'écran de confirmation : le ticket encore
                  // en attente de **cette** agence, et celui que le client vient
                  // de prendre ici. Un ticket servi lors d'un passage antérieur
                  // rend la main au parcours de prise, sinon le client ne peut
                  // plus reprendre de ticket depuis le choix du service.
                  final showConfirmation =
                      ticket != null &&
                      ticket.agencyId == agency.id &&
                      (!ticket.served || ticket.number == _justTaken);
                  if (showConfirmation) {
                    return _SuccessView(ticket: ticket);
                  }
                  if (blocking) {
                    return _ConflictView(
                      ticket: ticket,
                      onViewTicket: () => context.push(
                        AppRoutes.queueTracking,
                      ),
                    );
                  }
                  return _TakeTicketView(
                    organization: organization,
                    agency: agency,
                    service: service,
                    onTakeTicket: () async {
                      await ref
                          .read(activeTicketProvider.notifier)
                          .takeTicket(
                            organization: organization,
                            agency: agency,
                            service: service,
                          );
                      final created = ref.read(activeTicketProvider).value;
                      if (!mounted || created == null || created.served) {
                        return;
                      }
                      setState(() => _justTaken = created.number);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Organization? _findOrganization(List<Organization> organizations) {
    for (final organization in organizations) {
      if (organization.id == widget.organizationId) {
        return organization;
      }
    }
    return null;
  }

  Agency? _findAgency(List<Agency> agencies) {
    for (final agency in agencies) {
      if (agency.id == widget.agencyId) {
        return agency;
      }
    }
    return null;
  }

  AgencyService? _findService(List<AgencyService> services) {
    for (final service in services) {
      if (service.id == widget.serviceId) {
        return service;
      }
    }
    return null;
  }
}

class _TakeTicketView extends StatelessWidget {
  const _TakeTicketView({
    required this.organization,
    required this.agency,
    required this.service,
    required this.onTakeTicket,
  });

  final Organization organization;
  final Agency agency;
  final AgencyService service;
  final VoidCallback onTakeTicket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        organization.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        agency.address,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.detailsService,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.queueAhead(service.waitingCount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onTakeTicket,
            child: Text(l10n.takeTicket),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.changeService),
        ),
      ],
    );
  }
}

class _ServiceGone extends StatelessWidget {
  const _ServiceGone({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.serviceUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onBack, child: Text(l10n.changeService)),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends ConsumerStatefulWidget {
  const _SuccessView({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends ConsumerState<_SuccessView> {
  bool _cancelling = false;

  Ticket get _ticket => widget.ticket;

  /// Annulation depuis l'écran de confirmation : la place repart dans la file
  /// et l'accueil redevient vide, prêt pour un nouveau ticket.
  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.detailsCancelTitle(_ticket.number)),
        content: Text(l10n.detailsCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.detailsCancelKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.detailsCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    await ref.read(activeTicketProvider.notifier).cancelTicket();
    if (!mounted) {
      return;
    }
    setState(() => _cancelling = false);
    context.go(AppRoutes.home);
    messenger.showSnackBar(SnackBar(content: Text(l10n.detailsCancelled)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticket = _ticket;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = ticket.pendingSync;
    final accent = pending
        ? (isDark ? const Color(0xFFFFD98A) : const Color(0xFF7A4E00))
        : colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(
          pending ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
          size: 64,
          color: accent,
        ),
        const SizedBox(height: 16),
        Text(
          ticket.served
              ? l10n.ticketServed
              : (pending ? l10n.ticketPendingTitle : l10n.ticketActiveTitle),
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  ticket.number,
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.ticketNumberLabel, style: textTheme.bodyMedium),
                if (ticket.serviceName != null &&
                    ticket.serviceName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ticket.serviceName!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (pending) ...[
                  const SizedBox(height: 12),
                  const PendingSyncChip(),
                ],
                // Position 0 = le client n'est pas (ou plus) dans la file :
                // ticket déjà appelé, servi, ou file momentanément indisponible.
                // Afficher « Position 0 » serait un rang, et faux.
                if (!ticket.served && ticket.position > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.ticketPositionLabel(ticket.position),
                    style: textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          ticket.served
              ? l10n.ticketServedNote
              : (pending
                    ? l10n.ticketPendingNote
                    : l10n.ticketSuccessNote(ticket.agencyName)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.backToDashboard),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _cancelling ? null : _cancel,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: _cancelling
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.error,
                  ),
                )
              : Text(l10n.detailsCancel),
        ),
      ],
    );
  }
}

class _ConflictView extends StatelessWidget {
  const _ConflictView({required this.ticket, required this.onViewTicket});

  final Ticket ticket;
  final VoidCallback onViewTicket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.warning_amber_rounded, size: 64, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          l10n.ticketConflictTitle,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.ticketConflictBody(ticket.agencyName, ticket.number),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          ticket.organizationName,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onViewTicket, child: Text(l10n.viewMyTicket)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backToAgencies),
        ),
      ],
    );
  }
}
