import 'dart:math';

import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Client de tickets adossé au backend.
///
/// Ne conserve aucun état : le serveur est la source de vérité, et le cache
/// hors ligne est tenu par [CachedTicketService], qui enveloppe ce service.
final class ApiTicketService implements TicketService {
  ApiTicketService({required ApiClient client, Random? random})
    : _client = client,
      _random = random ?? Random();

  final ApiClient _client;
  final Random _random;

  @override
  Future<Ticket?> activeTicket() async {
    final payload = await _client.get('/tickets/active');
    return ticketFromBackend(payload['data']);
  }

  @override
  Future<Ticket> createTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    try {
      final payload = await _client.post(
        '/tickets',
        body: <String, Object?>{
          'agency_id': agency.id,
          'service_id': service.id,
          // Le serveur rejoue la même requête au lieu d'en créer une seconde si
          // le réseau a coupé la réponse sans couper la requête. Sans cet
          // identifiant, un client qui insiste se retrouve avec deux tickets
          // (ou un 409 qu'il ne comprend pas).
          'client_action_id': _newActionId(),
        },
      );
      final ticket = ticketFromBackend(payload);
      if (ticket == null) {
        throw const UnexpectedException(
          message: 'Réponse de création sans ticket exploitable.',
        );
      }
      return ticket;
    } on ApiException catch (error) {
      if (error.code != 'TICKET_ALREADY_ACTIVE') {
        rethrow;
      }
      // Le serveur refuse parce qu'un ticket existe déjà : c'est l'invariant
      // métier, pas une panne. On va le chercher pour l'afficher — l'écran a
      // besoin du ticket complet, pas d'un message d'erreur.
      final existing = await activeTicket();
      if (existing == null) {
        // Course perdue : le ticket a été clôturé entre le refus et la lecture.
        // Relancer la création donnerait le même 409 en boucle, donc on remonte
        // l'erreur d'origine plutôt que d'inventer un ticket.
        rethrow;
      }
      throw TicketAlreadyActiveException(existing);
    }
  }

  /// Le client ne modifie jamais l'état de son propre ticket.
  ///
  /// Seul le guichet fait avancer la machine à états (`POST /tickets/{id}/done`
  /// est réservé aux agents) ; le mobile apprend les transitions par le
  /// WebSocket. Cet appel n'a donc rien à envoyer : lever une erreur ferait
  /// croire à un échec de synchronisation alors que le cache local est le seul
  /// à devoir être mis à jour.
  @override
  Future<void> saveStatus(Ticket ticket) async {}

  /// Le serveur ne garde aucune mémoire de ce que le client a vu : il ne sait
  /// dire que « un ticket » ou « aucun ticket ». C'est donc le cache local qui
  /// répond, et cette implémentation n'a rien à ajouter.
  @override
  Future<Ticket?> lastClosedTicket() async => null;

  @override
  Future<void> cancelTicket() async {
    // `DELETE /tickets/{id}` prend un identifiant ; l'interface n'en transporte
    // pas. On relit le ticket actif plutôt que de garder un identifiant en
    // mémoire : un cache local périmé annulerait le mauvais ticket, et cette
    // action est irréversible.
    final active = await activeTicket();
    final id = active?.id;
    if (id == null) {
      return;
    }
    await _client.delete('/tickets/$id');
  }

  @override
  Future<Ticket> resumeTicket(Ticket ticket) async {
    final id = ticket.id;
    if (id == null) {
      throw const UnexpectedException(
        message: 'Un ticket non confirmé ne peut pas revenir en file.',
      );
    }
    // Le serveur répond `{success, ticket_id, queue_degraded, …}` : il ne
    // renvoie pas le ticket complet. On relit donc le ticket actif pour
    // récupérer la nouvelle position — le retour en fin de tranche la change,
    // et c'est justement ce que le client veut voir.
    await _client.post('/tickets/$id/return');
    try {
      final refreshed = await activeTicket();
      if (refreshed != null) {
        return refreshed;
      }
    } on Object {
      // La reprise a réussi mais la relecture a échoué : mieux vaut un état
      // local approximatif qu'un message d'erreur sur une action réussie.
    }
    return ticket.copyWith(
      status: TicketStatus.waiting,
      clearRecoveryExpiresAt: true,
    );
  }

  /// Identifiant d'idempotence conforme au format attendu par le serveur
  /// (`[A-Za-z0-9_-]{8,64}`).
  String _newActionId() {
    final buffer = StringBuffer('mob-');
    for (var index = 0; index < 20; index++) {
      buffer.write(_random.nextInt(36).toRadixString(36));
    }
    return buffer.toString();
  }
}

/// Traduit un ticket du backend vers le domaine, ou null si la charge est vide.
///
/// Le backend renvoie des statuts en minuscules (`waiting`, `called`, `done`…)
/// et une position `0` quand le client n'est pas dans une file — ticket appelé,
/// servi, ou file Redis indisponible. La position n'est donc pas corrigée en 1 :
/// afficher « 1er » à un client déjà au guichet serait faux.
Ticket? ticketFromBackend(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final number = document['number'];
  if (id is! String || id.isEmpty || number is! String || number.isEmpty) {
    return null;
  }
  return Ticket(
    id: id,
    number: number,
    position: _asInt(document['position']),
    estimatedMinutes: _asNullableInt(document['estimated_wait_minutes']),
    organizationId: _asString(document['organization_id']),
    organizationName: _asString(document['organization_name']),
    agencyId: _asString(document['agency_id']),
    agencyName: _asString(document['agency_name']),
    serviceId: _asNullableString(document['service_id']),
    serviceName: _asNullableString(document['service_name']),
    qrToken: _asNullableString(document['qr_token']),
    // Le statut vient du serveur, sans interprétation : c'est lui qui décide
    // si le ticket bloque encore la prise d'un nouveau, et qui distingue un
    // client appelé d'un client absent.
    status: TicketStatus.fromWire(document['status']),
    counterLabel: _asNullableString(document['counter_name']),
    totalInQueue: _asNullableInt(document['total_in_queue']),
    recoveryExpiresAt: _asDate(document['recovery_expires_at']),
    missedCount: _asInt(document['missed_count']),
    queueDegraded: document['queue_degraded'] == true,
    issuedAt: _asDate(document['created_at']),
  );
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Un ETA absent reste absent : le mobile ne doit jamais inventer « 0 min ».
int? _asNullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

String _asString(Object? value) => value is String ? value : '';

String? _asNullableString(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
}

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
