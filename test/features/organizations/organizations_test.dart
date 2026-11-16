import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/organizations/data/repositories/cached_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';

void main() {
  test("l'entité Organization porte un identifiant, un nom et un type", () {
    const organization = Organization(
      id: 'org-1',
      name: 'Banque A',
      type: OrganizationType.bank,
    );

    expect(organization.id, 'org-1');
    expect(organization.name, 'Banque A');
    expect(organization.type, OrganizationType.bank);
  });

  test("l'entité Agency porte identifiant, nom, adresse et file d'attente", () {
    const agency = Agency(
      id: 'ag-1',
      name: 'Agence Centre',
      address: 'Avenue 1',
      waitingCount: 4,
    );

    expect(agency.id, 'ag-1');
    expect(agency.name, 'Agence Centre');
    expect(agency.address, 'Avenue 1');
    expect(agency.waitingCount, 4);
  });

  test('le mock retourne des organisations fictives', () async {
    const repository = MockOrganizationRepository(latency: Duration.zero);

    final organizations = await repository.fetchOrganizations();

    expect(organizations, isNotEmpty);
    expect(
      organizations.map((organization) => organization.name),
      contains('Banque Horizon'),
    );
  });

  test("le mock retourne les agences d'une organisation", () async {
    const repository = MockOrganizationRepository(latency: Duration.zero);

    final agencies = await repository.fetchAgencies('org-horizon');

    expect(agencies, isNotEmpty);
    expect(
      agencies.map((agency) => agency.name),
      contains('Agence Bujumbura Centre'),
    );
  });

  test(
    'le mock retourne une liste vide pour une organisation inconnue',
    () async {
      const repository = MockOrganizationRepository(latency: Duration.zero);

      final agencies = await repository.fetchAgencies('org-inconnue');

      expect(agencies, isEmpty);
    },
  );

  test('le provider expose le repository hors ligne adossé au mock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Le mock n'est plus exposé directement : il est enveloppé par la couche
    // de cache qui rend le catalogue consultable hors ligne.
    final repository = container.read(organizationRepositoryProvider);
    expect(repository, isA<CachedOrganizationRepository>());
    expect(
      (repository as CachedOrganizationRepository).remote,
      isA<MockOrganizationRepository>(),
    );
  });
}
