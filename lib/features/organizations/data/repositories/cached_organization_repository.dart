import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/organizations/data/repositories/organization_codec.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

/// Repository des organisations qui sert le cache quand le réseau manque.
///
/// Les organisations et les agences changent peu : les garder sur disque
/// permet de parcourir l'application et de consulter son ticket en mode
/// hors ligne, sans écran d'erreur.
final class CachedOrganizationRepository implements OrganizationRepository {
  CachedOrganizationRepository({
    required OrganizationRepository remote,
    required LocalCache cache,
    required bool Function() isOnline,
  }) : _remote = remote,
       _cache = cache,
       _isOnline = isOnline;

  static const String organizationsKey = 'organizations.list';

  static String agenciesKey(String organizationId) =>
      'agencies.$organizationId';

  static String servicesKey(String agencyId) => 'services.$agencyId';

  final OrganizationRepository _remote;
  final LocalCache _cache;
  final bool Function() _isOnline;

  /// Repository distant sous-jacent, exposé pour les vérifications de câblage.
  OrganizationRepository get remote => _remote;

  @override
  Future<List<Organization>> fetchOrganizations() async {
    if (_isOnline()) {
      try {
        final organizations = await _remote.fetchOrganizations();
        await _cache.write(organizationsKey, <Object?>[
          for (final organization in organizations)
            organizationToJson(organization),
        ]);
        return organizations;
      } on Object {
        // Réseau tombé pendant l'appel : on retombe sur le cache.
      }
    }
    final cached = decodeList(
      await _cache.read(organizationsKey),
      organizationFromJson,
    );
    if (cached.isNotEmpty) {
      return cached;
    }
    // Premier lancement sans réseau : il n'y a réellement rien à afficher,
    // l'écran de reprise est donc légitime ici. Ce qui revient est mis en
    // cache au passage, pour que la prochaine ouverture soit locale.
    final fetched = await _remote.fetchOrganizations();
    await _cache.write(organizationsKey, <Object?>[
      for (final organization in fetched) organizationToJson(organization),
    ]);
    return fetched;
  }

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async {
    final key = agenciesKey(organizationId);
    if (_isOnline()) {
      try {
        final agencies = await _remote.fetchAgencies(organizationId);
        await _cache.write(key, <Object?>[
          for (final agency in agencies) agencyToJson(agency),
        ]);
        return agencies;
      } on Object {
        // Idem : le cache prend le relais.
      }
    }
    final cached = decodeList(await _cache.read(key), agencyFromJson);
    if (cached.isNotEmpty) {
      return cached;
    }
    final fetched = await _remote.fetchAgencies(organizationId);
    await _cache.write(key, <Object?>[
      for (final agency in fetched) agencyToJson(agency),
    ]);
    return fetched;
  }

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async {
    final key = servicesKey(agencyId);
    if (_isOnline()) {
      try {
        final services = await _remote.fetchServices(
          organizationId: organizationId,
          agencyId: agencyId,
        );
        await _cache.write(key, <Object?>[
          for (final service in services) agencyServiceToJson(service),
        ]);
        return services;
      } on Object {
        // Le cache prend le relais : la liste des services bouge très peu.
      }
    }
    final cached = decodeList(await _cache.read(key), agencyServiceFromJson);
    if (cached.isNotEmpty) {
      return cached;
    }
    final fetched = await _remote.fetchServices(
      organizationId: organizationId,
      agencyId: agencyId,
    );
    await _cache.write(key, <Object?>[
      for (final service in fetched) agencyServiceToJson(service),
    ]);
    return fetched;
  }
}
