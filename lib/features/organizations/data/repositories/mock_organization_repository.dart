import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

/// Données fictives approuvées par Vizane (2026-11-09) pour la démo à
/// présenter. Tout est en mémoire : aucun endpoint, payload ou contrat
/// backend n'est inventé. À remplacer par l'implémentation Dio dès
/// réception du contrat backend réel (voir DECISIONS.md).
final class MockOrganizationRepository implements OrganizationRepository {
  const MockOrganizationRepository({
    this.latency = const Duration(milliseconds: 400),
  });

  /// Délai artificiel pour rendre les états de chargement visibles en démo.
  final Duration latency;

  static const List<Organization> _organizations = [
    Organization(
      id: 'org-horizon',
      name: 'Banque Horizon',
      type: OrganizationType.bank,
    ),
    Organization(
      id: 'org-aurore',
      name: 'Microfinance Aurore',
      type: OrganizationType.bank,
    ),
    Organization(
      id: 'org-solidarite',
      name: 'Banque Solidarité',
      type: OrganizationType.bank,
    ),
    Organization(
      id: 'org-espoir',
      name: 'Clinique Espoir',
      type: OrganizationType.health,
    ),
    Organization(
      id: 'org-ubuzima',
      name: 'Polyclinique Ubuzima',
      type: OrganizationType.health,
    ),
  ];

  static const Map<String, List<Agency>> _agencies = {
    'org-horizon': [
      Agency(
        id: 'hor-1',
        name: 'Agence Bujumbura Centre',
        address: "Boulevard de l'Uprona, Bujumbura",
        waitingCount: 18,
      ),
      Agency(
        id: 'hor-2',
        name: 'Agence Gitega',
        address: 'Avenue de la Cathédrale, Gitega',
        waitingCount: 12,
      ),
      Agency(
        id: 'hor-3',
        name: 'Agence Ngozi',
        address: 'Rue du Marché, Ngozi',
        waitingCount: 15,
      ),
    ],
    'org-aurore': [
      Agency(
        id: 'aur-1',
        name: 'Agence Kamenge',
        address: 'Avenue Mwaro, Bujumbura',
        waitingCount: 11,
      ),
      Agency(
        id: 'aur-2',
        name: 'Agence Kinama',
        address: "Rue de l'École, Bujumbura",
        waitingCount: 14,
      ),
    ],
    'org-solidarite': [
      Agency(
        id: 'sol-1',
        name: 'Agence Rohero',
        address: 'Chaussée Prince Louis Rwagasore, Bujumbura',
        waitingCount: 16,
      ),
      Agency(
        id: 'sol-2',
        name: 'Agence Mutakura',
        address: 'Avenue du Large, Bujumbura',
        waitingCount: 10,
      ),
    ],
    'org-espoir': [
      Agency(
        id: 'esp-1',
        name: 'Centre Bujumbura',
        address: 'Avenue du Stade, Bujumbura',
        waitingCount: 20,
      ),
      Agency(
        id: 'esp-2',
        name: 'Antenne Gatumba',
        address: 'Route Nationale 5, Gatumba',
        waitingCount: 13,
      ),
    ],
    'org-ubuzima': [
      Agency(
        id: 'ubu-1',
        name: 'Site Gitega',
        address: "Rue de l'Hôpital, Gitega",
        waitingCount: 10,
      ),
      Agency(
        id: 'ubu-2',
        name: 'Site Ngozi',
        address: 'Avenue du Centre, Ngozi',
        waitingCount: 17,
      ),
    ],
  };

  /// Catalogue des services par organisation : (identifiant, nom, précision).
  ///
  /// Le catalogue est porté par l'organisation — une banque ne propose pas les
  /// mêmes guichets qu'une clinique — et instancié agence par agence.
  static const Map<String, List<(String, String, String)>> _serviceCatalog = {
    'org-horizon': [
      ('account', 'Ouverture de compte', 'Compte courant, épargne, carte'),
      ('cash', 'Retrait & dépôt', 'Opérations au guichet et change'),
      ('transfer', 'Virement', 'Virements nationaux et internationaux'),
      ('credit', 'Crédit & financement', 'Crédit personnel et habitat'),
    ],
    'org-aurore': [
      ('account', 'Ouverture de compte', 'Compte épargne et carte'),
      ('credit', 'Micro-crédit', 'Crédit de groupe et crédit individuel'),
      ('transfer', 'Virement', "Transfert d'argent et paiement"),
    ],
    'org-solidarite': [
      ('cash', 'Retrait & dépôt', 'Opérations en espèces'),
      ('transfer', 'Virement', 'Virements et paiements'),
      ('change', 'Change', 'Devises et opérations au guichet'),
    ],
    'org-espoir': [
      ('consult', 'Consultation générale', 'Médecine générale et suivi'),
      ('lab', 'Laboratoire', 'Analyses et prélèvements'),
      ('pharma', 'Pharmacie', 'Délivrance des médicaments'),
      ('maternity', 'Maternité', 'Suivi de grossesse et accouchement'),
    ],
    'org-ubuzima': [
      ('consult', 'Consultation', 'Médecine générale et spécialisée'),
      ('imaging', 'Imagerie', 'Échographie et radiologie'),
      ('vaccine', 'Vaccination', 'Vaccins enfants et adultes'),
    ],
  };

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<Organization>> fetchOrganizations() async {
    await _wait();
    return _organizations;
  }

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async {
    await _wait();
    return _agencies[organizationId] ?? const [];
  }

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async {
    await _wait();
    final catalog = _serviceCatalog[organizationId] ?? const [];
    final queue = _agencyQueue(organizationId, agencyId);
    return [
      for (var index = 0; index < catalog.length; index++)
        AgencyService(
          id: '$agencyId-${catalog[index].$1}',
          name: catalog[index].$2,
          description: catalog[index].$3,
          // Chaque service tient une file de 10 à 20 personnes : en dessous,
          // la démonstration ne montre pas l'attente ; au-delà, elle décourage.
          // Le calcul reste déterministe, donc stable d'un affichage à l'autre.
          waitingCount: 10 + ((queue * 3 + index * 7) % 11),
        ),
    ];
  }

  static int _agencyQueue(String organizationId, String agencyId) {
    for (final agency in _agencies[organizationId] ?? const <Agency>[]) {
      if (agency.id == agencyId) {
        return agency.waitingCount;
      }
    }
    return 0;
  }
}
