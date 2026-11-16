import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Étape intermédiaire entre l'agence et le ticket : le choix du service.
///
/// Un ticket n'a de sens que rattaché à une file, et une agence en gère
/// plusieurs (« Ouverture de compte » et « Retrait & dépôt » ne font pas la
/// même queue). Le client choisit donc son service ici, puis confirme sur
/// l'écran suivant.
class AgencyServicesPage extends ConsumerWidget {
  const AgencyServicesPage({
    super.key,
    required this.organizationId,
    required this.agencyId,
  });

  final String organizationId;
  final String agencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final organizationsAsync = ref.watch(organizationsProvider);
    final agenciesAsync = ref.watch(agenciesProvider(organizationId));
    final servicesAsync = ref.watch(
      servicesProvider((organizationId: organizationId, agencyId: agencyId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.servicesTitle)),
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
          data: (agencies) {
            final organization = _findOrganization(organizations);
            final agency = _findAgency(agencies);
            if (organization == null || agency == null) {
              return const SizedBox.shrink();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _AgencyHeader(organization: organization, agency: agency),
                const SizedBox(height: 20),
                Text(
                  l10n.servicesChooseHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ...servicesAsync.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (error, stackTrace) => [
                    AsyncErrorView(
                      onRetry: () => ref.invalidate(
                        servicesProvider((
                          organizationId: organizationId,
                          agencyId: agencyId,
                        )),
                      ),
                    ),
                  ],
                  data: (services) => services.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(child: Text(l10n.servicesEmpty)),
                          ),
                        ]
                      : [
                          for (final service in services)
                            _ServiceTile(
                              service: service,
                              onTap: () => context.push(
                                AppRoutes.agencyTicketPath(
                                  organizationId: organizationId,
                                  agencyId: agencyId,
                                  serviceId: service.id,
                                ),
                              ),
                            ),
                        ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Organization? _findOrganization(List<Organization> organizations) {
    for (final organization in organizations) {
      if (organization.id == organizationId) {
        return organization;
      }
    }
    return null;
  }

  Agency? _findAgency(List<Agency> agencies) {
    for (final agency in agencies) {
      if (agency.id == agencyId) {
        return agency;
      }
    }
    return null;
  }
}

class _AgencyHeader extends StatelessWidget {
  const _AgencyHeader({required this.organization, required this.agency});

  final Organization organization;
  final Agency agency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isBank = organization.type == OrganizationType.bank;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                isBank
                    ? Icons.account_balance_outlined
                    : Icons.local_hospital_outlined,
                size: 22,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agency.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    organization.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agency.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l10n.queueCountSemantics(agency.waitingCount),
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${agency.waitingCount}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final AgencyService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        title: Text(
          service.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.queueAhead(service.waitingCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
