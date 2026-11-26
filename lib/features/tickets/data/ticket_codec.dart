import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';

/// Sérialisation du ticket pour le cache local.
///
/// Le format vit dans la couche `data` : le domaine ignore comment il est
/// persisté, et le contrat backend pourra imposer un autre mappage sans
/// toucher à [Ticket].
Map<String, Object?> ticketToJson(Ticket ticket) {
  return <String, Object?>{
    'id': ticket.id,
    'number': ticket.number,
    'position': ticket.position,
    'estimatedMinutes': ticket.estimatedMinutes,
    'organizationId': ticket.organizationId,
    'organizationName': ticket.organizationName,
    'agencyId': ticket.agencyId,
    'agencyName': ticket.agencyName,
    'serviceId': ticket.serviceId,
    'serviceName': ticket.serviceName,
    'qrToken': ticket.qrToken,
    'pendingSync': ticket.pendingSync,
    'status': ticket.status.wire,
    'counterLabel': ticket.counterLabel,
    'totalInQueue': ticket.totalInQueue,
    'recoveryExpiresAt': ticket.recoveryExpiresAt?.toIso8601String(),
    'missedCount': ticket.missedCount,
    'queueDegraded': ticket.queueDegraded,
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
    id: _asNullableString(document['id']),
    number: number,
    position: _asInt(document['position']),
    estimatedMinutes: _asNullableInt(document['estimatedMinutes']),
    organizationId: organizationId,
    organizationName: _asString(document['organizationName']),
    agencyId: agencyId,
    agencyName: _asString(document['agencyName']),
    serviceId: _asNullableString(document['serviceId']),
    serviceName: _asNullableString(document['serviceName']),
    qrToken: _asNullableString(document['qrToken']),
    pendingSync: document['pendingSync'] == true,
    status: _status(document),
    counterLabel: _asNullableString(document['counterLabel']),
    totalInQueue: _asNullableInt(document['totalInQueue']),
    recoveryExpiresAt: _asDate(document['recoveryExpiresAt']),
    missedCount: _asInt(document['missedCount']),
    queueDegraded: document['queueDegraded'] == true,
    issuedAt: _asDate(document['issuedAt']),
  );
}

/// Statut relu, avec repli sur l'ancien booléen `served`.
///
/// Un cache écrit avant l'introduction de [TicketStatus] ne porte que
/// `served` : le relire en `done` évite qu'un ticket terminé réapparaisse
/// comme actif après une mise à jour de l'application.
TicketStatus _status(Map document) {
  final raw = document['status'];
  if (raw is String && raw.isNotEmpty) {
    return TicketStatus.fromWire(raw);
  }
  return document['served'] == true ? TicketStatus.done : TicketStatus.waiting;
}

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

int _asInt(Object? value) => value is int ? value : 0;

int? _asNullableInt(Object? value) => value is int ? value : null;

String _asString(Object? value) => value is String ? value : '';

String? _asNullableString(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
}
