import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';

/// Accès aux organisations de l'utilisateur.
abstract interface class OrganizationRepository {
  /// Retourne les organisations dont l'adhésion de l'utilisateur est
  /// confirmée (garantie backend).
  ///
  /// Le mappage vers l'endpoint réel sera défini par le contrat backend
  /// (OpenAPI/documentation validée) ; aucun endpoint n'est inventé ici.
  Future<List<Organization>> fetchOrganizations();

  /// Retourne les agences de l'organisation [organizationId].
  Future<List<Agency>> fetchAgencies(String organizationId);

  /// Retourne les services proposés par [agencyId].
  ///
  /// Le service est obligatoire pour prendre un ticket : sans lui, le mobile
  /// ne saurait pas dans quelle file placer le client.
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  });
}
