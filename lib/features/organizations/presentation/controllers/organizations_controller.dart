import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';

/// Liste des organisations dont l'adhésion de l'utilisateur est confirmée.
final organizationsProvider =
    AsyncNotifierProvider<OrganizationsNotifier, List<Organization>>(
      OrganizationsNotifier.new,
    );

class OrganizationsNotifier extends AsyncNotifier<List<Organization>> {
  @override
  Future<List<Organization>> build() {
    return ref.watch(organizationRepositoryProvider).fetchOrganizations();
  }
}

/// Agences d'une organisation donnée.
final agenciesProvider =
    AsyncNotifierProvider.family<AgenciesNotifier, List<Agency>, String>(
      AgenciesNotifier.new,
    );

class AgenciesNotifier extends AsyncNotifier<List<Agency>> {
  AgenciesNotifier(this.organizationId);

  final String organizationId;

  @override
  Future<List<Agency>> build() {
    return ref
        .watch(organizationRepositoryProvider)
        .fetchAgencies(organizationId);
  }
}

/// Clé d'accès aux services d'une agence.
typedef ServicesQuery = ({String organizationId, String agencyId});

/// Services proposés par une agence.
final servicesProvider =
    AsyncNotifierProvider.family<ServicesNotifier, List<AgencyService>, ServicesQuery>(
      ServicesNotifier.new,
    );

class ServicesNotifier extends AsyncNotifier<List<AgencyService>> {
  ServicesNotifier(this.query);

  final ServicesQuery query;

  @override
  Future<List<AgencyService>> build() {
    return ref
        .watch(organizationRepositoryProvider)
        .fetchServices(
          organizationId: query.organizationId,
          agencyId: query.agencyId,
        );
  }
}
