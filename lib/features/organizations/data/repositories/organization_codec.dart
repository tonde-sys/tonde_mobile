import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';

/// Sérialisation des organisations et de leurs agences pour le cache local.

Map<String, Object?> organizationToJson(Organization organization) {
  return <String, Object?>{
    'id': organization.id,
    'name': organization.name,
    'type': organization.type.name,
  };
}

Organization? organizationFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || name is! String) {
    return null;
  }
  return Organization(
    id: id,
    name: name,
    type: _typeFromName(document['type']),
  );
}

Map<String, Object?> agencyToJson(Agency agency) {
  return <String, Object?>{
    'id': agency.id,
    'name': agency.name,
    'address': agency.address,
    'waitingCount': agency.waitingCount,
  };
}

Agency? agencyFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || name is! String) {
    return null;
  }
  final waitingCount = document['waitingCount'];
  return Agency(
    id: id,
    name: name,
    address: document['address'] is String ? document['address'] as String : '',
    waitingCount: waitingCount is int ? waitingCount : 0,
  );
}

Map<String, Object?> agencyServiceToJson(AgencyService service) {
  return <String, Object?>{
    'id': service.id,
    'name': service.name,
    'description': service.description,
    'waitingCount': service.waitingCount,
  };
}

AgencyService? agencyServiceFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || name is! String) {
    return null;
  }
  final waitingCount = document['waitingCount'];
  return AgencyService(
    id: id,
    name: name,
    description: document['description'] is String
        ? document['description'] as String
        : '',
    waitingCount: waitingCount is int ? waitingCount : 0,
  );
}

/// Convertit une liste JSON en liste typée, en ignorant les entrées invalides.
List<T> decodeList<T>(Object? document, T? Function(Object?) decode) {
  if (document is! List) {
    return <T>[];
  }
  final decoded = <T>[];
  for (final entry in document) {
    final value = decode(entry);
    if (value != null) {
      decoded.add(value);
    }
  }
  return decoded;
}

OrganizationType _typeFromName(Object? name) {
  return OrganizationType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => OrganizationType.bank,
  );
}
