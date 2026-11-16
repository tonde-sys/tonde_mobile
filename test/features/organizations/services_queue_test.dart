import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';

void main() {
  test('chaque service affiche entre 10 et 20 personnes en file', () async {
    final repository = MockOrganizationRepository(latency: Duration.zero);
    final organizations = await repository.fetchOrganizations();

    var checked = 0;
    for (final organization in organizations) {
      final agencies = await repository.fetchAgencies(organization.id);
      for (final agency in agencies) {
        final services = await repository.fetchServices(
          organizationId: organization.id,
          agencyId: agency.id,
        );
        expect(services, isNotEmpty, reason: '${agency.name} sans service');
        for (final service in services) {
          expect(
            service.waitingCount,
            inInclusiveRange(10, 20),
            reason:
                '${organization.name} / ${agency.name} / ${service.name} : '
                '${service.waitingCount} personnes',
          );
          checked++;
        }
      }
    }
    // Garde-fou : le test doit réellement parcourir le catalogue.
    expect(checked, greaterThan(20));
  });

  test('la file d’un service est stable d’un appel à l’autre', () async {
    final repository = MockOrganizationRepository(latency: Duration.zero);
    final first = await repository.fetchServices(
      organizationId: 'org-horizon',
      agencyId: 'hor-1',
    );
    final second = await repository.fetchServices(
      organizationId: 'org-horizon',
      agencyId: 'hor-1',
    );

    expect(
      first.map((service) => service.waitingCount).toList(),
      second.map((service) => service.waitingCount).toList(),
    );
  });
}
