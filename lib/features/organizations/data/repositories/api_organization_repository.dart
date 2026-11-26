import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

/// Catalogue des organisations, agences et services, lu sur le backend.
///
/// Les trois routes utilisées sont **publiques** et volontairement appelées sans
/// jeton (`authenticated: false`) : un visiteur qui n'a pas encore de compte doit
/// pouvoir consulter l'offre. Présenter un jeton expiré y déclencherait un
/// renouvellement inutile, et un renouvellement refusé déconnecterait
/// l'utilisateur depuis un écran qui n'a rien demandé.
///
/// Aucun état conservé : la mise en cache hors ligne est le rôle de
/// [CachedOrganizationRepository], qui enveloppe ce repository.
final class ApiOrganizationRepository implements OrganizationRepository {
  ApiOrganizationRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<List<Organization>> fetchOrganizations() async {
    final payload = await _client.get(
      '/public/organizations',
      authenticated: false,
    );
    return _list(payload).map(_organizationFrom).nonNulls.toList();
  }

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async {
    final payload = await _client.get(
      '/public/organizations/$organizationId/branches',
      authenticated: false,
    );
    return _list(payload).map(_agencyFrom).nonNulls.toList();
  }

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async {
    // Le service appartient à une agence, pas à l'organisation : l'URL ne prend
    // que l'agence. `organizationId` reste dans la signature parce que le
    // domaine le porte, mais le serveur n'en a pas besoin — l'ignorer vaut
    // mieux que d'inventer un filtre que personne n'applique.
    final payload = await _client.get(
      '/branches/$agencyId/services',
      authenticated: false,
    );
    return _list(payload).map(_serviceFrom).nonNulls.toList();
  }

  /// Le backend enveloppe toutes ses listes dans `{success, data}`.
  static List<Object?> _list(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is List ? data : const <Object?>[];
  }
}

Organization? _organizationFrom(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
    return null;
  }
  final support = document['support'];
  final supportMap = support is Map ? support : const <String, Object?>{};
  return Organization(
    id: id,
    name: name,
    // `sector` est une chaîne libre côté serveur : tout ce qui n'est ni « bank »
    // ni « health » tombe sur `other` au lieu d'être présenté comme une banque.
    type: OrganizationType.fromSector(document['sector']),
    supportPhone: _digits(_asString(supportMap['phone'])),
    supportWhatsapp: _digits(_asString(supportMap['whatsapp'])),
    supportEmail: _asString(supportMap['email']),
    supportHours: _asString(supportMap['hours']),
  );
}

/// Ne garde que les chiffres d'un numéro saisi avec `+`, espaces ou tirets :
/// `tel:` et `wa.me` n'acceptent rien d'autre.
String _digits(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

Agency? _agencyFrom(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
    return null;
  }
  return Agency(
    id: id,
    name: name,
    address: _asString(document['address']),
    waitingCount: _asInt(document['waiting_count']),
  );
}

AgencyService? _serviceFrom(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
    return null;
  }
  return AgencyService(
    id: id,
    name: name,
    description: _asString(document['description']),
    waitingCount: _asInt(document['waiting_count']),
  );
}

String _asString(Object? value) => value is String ? value : '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return 0;
}
