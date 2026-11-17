import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';
import 'package:tonde/features/organizations/presentation/organization_type_style.dart';

/// Détail d'une organisation : en-tête et liste de ses agences.
class OrganizationDetailPage extends ConsumerWidget {
  const OrganizationDetailPage({super.key, required this.organizationId});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final organizationsAsync = ref.watch(organizationsProvider);
    final agenciesAsync = ref.watch(agenciesProvider(organizationId));

    return Scaffold(
      appBar: AppBar(),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AsyncErrorView(
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (organizations) {
          final organization = _findById(organizations, organizationId);
          if (organization == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrganizationHeader(organization: organization),
              const SizedBox(height: 24),
              Text(
                l10n.agenciesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...agenciesAsync.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, stackTrace) => [
                  AsyncErrorView(
                    onRetry: () =>
                        ref.invalidate(agenciesProvider(organizationId)),
                  ),
                ],
                data: (agencies) => agencies.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: Text(l10n.agenciesEmpty)),
                        ),
                      ]
                    : [
                        for (final agency in agencies)
                          _AgencyTile(
                            agency: agency,
                            onTap: () => context.push(
                              AppRoutes.agencyServicesPath(
                                organizationId: organizationId,
                                agencyId: agency.id,
                              ),
                            ),
                          ),
                      ],
              ),
            ],
          );
        },
      ),
    );
  }

  static Organization? _findById(List<Organization> organizations, String id) {
    for (final organization in organizations) {
      if (organization.id == id) {
        return organization;
      }
    }
    return null;
  }
}

class _OrganizationHeader extends StatelessWidget {
  const _OrganizationHeader({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                organization.type.icon,
                size: 30,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    organization.type.label(l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AgencyTile extends StatelessWidget {
  const _AgencyTile({required this.agency, required this.onTap});

  final Agency agency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.location_on_outlined),
        title: Text(agency.name),
        subtitle: Text(agency.address),
        trailing: Semantics(
          label: l10n.queueCountSemantics(agency.waitingCount),
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${agency.waitingCount}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
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
