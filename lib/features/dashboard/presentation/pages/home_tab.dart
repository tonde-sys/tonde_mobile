import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/dashboard/presentation/widgets/animated_sphere.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tickets/presentation/ticket_error_message.dart';
import 'package:tonde/features/tickets/presentation/widgets/ticket_pass_card.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';
import 'package:tonde/features/organizations/presentation/organization_type_style.dart';

/// Onglet Accueil du tableau de bord.
class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.onNotifications,
    required this.onAssistance,
  });

  final VoidCallback onNotifications;
  final VoidCallback onAssistance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final ticketAsync = ref.watch(activeTicketProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    return SafeArea(
      child: Column(
        children: [
          // L'en-tête est hors de la zone défilante : le nom de
          // l'application, les alertes et l'accès au profil restent à portée
          // de pouce quelle que soit la position dans la page.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _Header(
              onNotifications: onNotifications,
              unreadNotifications: unread,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _HeroBanner(
                  onTakeTicket: () => context.push(AppRoutes.organizations),
                  onViewPosition: () => context.push(AppRoutes.queueTracking),
                ),
                const SizedBox(height: 20),
                ticketAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => AsyncErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(activeTicketProvider),
                  ),
                  data: (ticket) {
                    if (ticket == null) {
                      // La note de clôture n'existe qu'après la disparition
                      // d'un ticket ; le service l'efface dès qu'un nouveau
                      // ticket est actif, et au bout d'un jour.
                      return _NoTicketCard(
                        closed: ref.watch(lastClosedTicketProvider).value,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TicketPassCard(
                          ticket: ticket,
                          onTap: () => context.push(AppRoutes.queueTracking),
                        ),
                        // Un client absent doit savoir jusqu'à quand il peut
                        // revenir : sans cette échéance, il découvre le refus
                        // au moment où il appuie sur « Reprendre ».
                        if (ticket.canResume) ...[
                          const SizedBox(height: 8),
                          _AbsentNotice(ticket: ticket),
                        ],
                        const SizedBox(height: 6),
                        // Un ticket clos ne bloque plus : c'est la bannière
                        // qui propose d'en reprendre un, un seul bouton suffit.
                        if (!ticket.isClosed)
                          _CancelTicketButton(ticket: ticket),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _OrganizationsSection(),
                const SizedBox(height: 24),
                _HelpBanner(onContact: onAssistance),
                const SizedBox(height: 8),
                Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onNotifications,
    required this.unreadNotifications,
  });

  final VoidCallback onNotifications;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 40,
            height: 40,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                l10n.tagline,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.tabNotifications,
          onPressed: onNotifications,
          icon: Badge(
            isLabelVisible: unreadNotifications > 0,
            label: Text('$unreadNotifications'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: 4),
        const _Avatar(),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      radius: 18,
      onTap: () => context.push(AppRoutes.profile),
    );
  }
}

/// Bannière d'accueil, dont l'action suit l'état réel du client.
///
/// Trois situations, trois boutons : sans ticket on en prend un, avec un ticket
/// actif on va voir sa position, avec un ticket absent on le reprend. Un
/// « Prendre un ticket » figé obligeait le client à retenter une prise que le
/// serveur refusait ensuite — l'invariant « un seul ticket actif » se
/// découvrait donc sous forme d'erreur.
class _HeroBanner extends ConsumerStatefulWidget {
  const _HeroBanner({required this.onTakeTicket, required this.onViewPosition});

  final VoidCallback onTakeTicket;
  final VoidCallback onViewPosition;

  @override
  ConsumerState<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<_HeroBanner> {
  bool _resuming = false;

  Future<void> _resume() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _resuming = true);
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
        setState(() => _resuming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final ticket = ref.watch(activeTicketProvider).value;

    final canResume = ticket != null && ticket.canResume;
    final hasActive = ticket != null && !ticket.isClosed;

    final String label;
    final IconData icon;
    final VoidCallback onPressed;
    if (canResume) {
      label = l10n.resumeTicket;
      icon = Icons.restart_alt;
      onPressed = _resume;
    } else if (hasActive) {
      label = l10n.seePosition;
      icon = Icons.visibility_outlined;
      onPressed = widget.onViewPosition;
    } else {
      label = l10n.heroCta;
      icon = Icons.confirmation_number_outlined;
      onPressed = widget.onTakeTicket;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.tertiary],
          ),
        ),
        child: Stack(
          children: [
            // Sphère holographique décorative, dans le coin supérieur droit.
            const Positioned(
              top: -46,
              right: -46,
              child: Opacity(
                opacity: 0.55,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: AnimatedSphereWidget(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasActive
                        ? Icons.confirmation_number_outlined
                        : Icons.groups_rounded,
                    size: 48,
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasActive ? l10n.heroTitleActive : l10n.heroTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasActive ? l10n.heroBodyActive : l10n.heroBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                    ),
                    onPressed: _resuming ? null : onPressed,
                    icon: _resuming
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(icon),
                    label: Text(label),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rappel de la fenêtre de reprise d'un ticket absent.
class _AbsentNotice extends StatelessWidget {
  const _AbsentNotice({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final deadline = ticket.recoveryExpiresAt;
    // L'échéance arrive en UTC : sans conversion, un client de Bujumbura
    // lirait une heure décalée de deux heures et se présenterait trop tard.
    final text = deadline == null
        ? l10n.trackingStatusAbsent
        : l10n.ticketAbsentNote(
            MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(deadline.toLocal())),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_outlined, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte affichée quand aucun ticket n'est actif.
///
/// Deux situations très différentes se ressemblent ici : le client n'a jamais
/// pris de ticket, ou son ticket vient de quitter la file. La seconde mérite
/// une explication — sans elle, il découvre la carte d'un nouvel arrivant et
/// croit avoir perdu sa place à cause d'un défaut de l'application.
///
/// Le bouton reste dans la bannière : cette carte informe, elle n'agit pas.
class _NoTicketCard extends StatelessWidget {
  const _NoTicketCard({this.closed});

  /// Ticket qui vient de cesser d'être actif, s'il y en a un.
  final Ticket? closed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final closed = this.closed;

    // Un ticket arrivé au guichet a été servi : il n'a pas « expiré ». Les
    // deux cas ne peuvent pas partager le même mot, c'est la seule chose que
    // le client retiendra.
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              closed == null
                  ? Icons.confirmation_number_outlined
                  : wasServed
                  ? Icons.task_alt
                  : Icons.hourglass_disabled_outlined,
              size: 40,
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
          ],
        ),
      ),
    );
  }
}

/// Annulation du ticket depuis l'accueil.
///
/// L'action vit sous la carte, pas dedans : elle est destructrice, elle ne
/// doit donc pas être confondue avec l'ouverture du détail. Elle demande
/// toujours confirmation avant de rendre la place à la file.
class _CancelTicketButton extends ConsumerStatefulWidget {
  const _CancelTicketButton({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_CancelTicketButton> createState() =>
      _CancelTicketButtonState();
}

class _CancelTicketButtonState extends ConsumerState<_CancelTicketButton> {
  bool _busy = false;

  Future<void> _confirmAndCancel() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ticketCancelQuestion),
        content: Text(l10n.ticketCancelBody(widget.ticket.number)),
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
    final scheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: _busy ? null : _confirmAndCancel,
      style: TextButton.styleFrom(foregroundColor: scheme.error),
      icon: _busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.error,
              ),
            )
          : const Icon(Icons.cancel_outlined, size: 18),
      label: Text(l10n.detailsCancel),
    );
  }
}

class _OrganizationsSection extends ConsumerWidget {
  const _OrganizationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final organizationsAsync = ref.watch(organizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.myOrganizations,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.organizations),
              child: Text(l10n.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        organizationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          data: (organizations) => SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: organizations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final organization = organizations[index];
                return _OrganizationMiniCard(
                  organization: organization,
                  onTap: () => context.push(
                    AppRoutes.organizationDetailPath(organization.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizationMiniCard extends StatelessWidget {
  const _OrganizationMiniCard({
    required this.organization,
    required this.onTap,
  });

  final Organization organization;

  /// Ouvre le parcours de prise de ticket : agences, puis services.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 150,
      child: Semantics(
        button: true,
        label: '${organization.name} · ${l10n.heroCta}',
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          organization.type.icon,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    organization.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    organization.type.label(l10n),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.info_outline, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.needHelp,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  l10n.helpBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.onPrimaryContainer,
              foregroundColor: colorScheme.primaryContainer,
            ),
            onPressed: onContact,
            icon: const Icon(Icons.headset_mic_outlined, size: 18),
            label: Text(l10n.contact),
          ),
        ],
      ),
    );
  }
}
