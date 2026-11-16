import 'package:tonde/features/tickets/domain/entities/ticket.dart';

/// Sérialisation du ticket pour le cache local.
///
/// Le format vit dans la couche `data` : le domaine ignore comment il est
/// persisté, et le contrat backend pourra imposer un autre mappage sans
/// toucher à [Ticket].
Map<String, Object?> ticketToJson(Ticket ticket) {
  return <String, Object?>{
    'number': ticket.number,
    'position': ticket.position,
    'estimatedMinutes': ticket.estimatedMinutes,
    'organizationId': ticket.organizationId,
    'organizationName': ticket.organizationName,
    'agencyId': ticket.agencyId,
    'agencyName': ticket.agencyName,
    'serviceId': ticket.serviceId,
    'serviceName': ticket.serviceName,
    'pendingSync': ticket.pendingSync,
    'served': ticket.served,
    'issuedAt': ticket.issuedAt?.toIso8601String(),
  };
}

/// Relit un ticket depuis le cache. Retourne null si le document est
/// incomplet : une entrée illisible ne doit jamais casser l'écran.
Ticket? ticketFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final number = document['number'];
  final organizationId = document['organizationId'];
  final agencyId = document['agencyId'];
  if (number is! String || organizationId is! String || agencyId is! String) {
    return null;
  }
  return Ticket(
    number: number,
    position: _asInt(document['position']),
    estimatedMinutes: _asInt(document['estimatedMinutes']),
    organizationId: organizationId,
    organizationName: _asString(document['organizationName']),
    agencyId: agencyId,
    agencyName: _asString(document['agencyName']),
    serviceId: _asNullableString(document['serviceId']),
    serviceName: _asNullableString(document['serviceName']),
    pendingSync: document['pendingSync'] == true,
    served: document['served'] == true,
    issuedAt: _asDate(document['issuedAt']),
  );
}

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

int _asInt(Object? value) => value is int ? value : 0;

String _asString(Object? value) => value is String ? value : '';

String? _asNullableString(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
}
