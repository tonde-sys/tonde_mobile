import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/organizations/data/repositories/organization_codec.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/ticket_codec.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Service de tickets qui survit à la perte du réseau.
///
/// Principe : le réseau est la source de vérité quand il répond, le cache
/// prend le relais sinon, et une prise de ticket hors ligne est mise en
/// attente puis rejouée au retour de la connexion. Aucun de ces chemins ne
/// produit d'écran d'erreur réseau pour une action critique.
final class CachedTicketService implements TicketService {
  CachedTicketService({
    required TicketService remote,
    required LocalCache cache,
    required bool Function() isOnline,
  }) : _remote = remote,
       _cache = cache,
       _isOnline = isOnline;

  static const String activeKey = 'ticket.active';
  static const String pendingKey = 'ticket.pending';

  final TicketService _remote;
  final LocalCache _cache;
  final bool Function() _isOnline;

  @override
  Future<Ticket?> activeTicket() async {
    if (_isOnline()) {
      try {
        final ticket = await _remote.activeTicket();
        if (ticket != null) {
          await _writeActive(ticket);
          return ticket;
        }
        // Le serveur dit « aucun ticket » : seul un ticket encore en attente
        // de synchronisation garde sa valeur locale, tout autre ticket
        // confirmé est périmé (servi, annulé ou expiré).
        final cached = await _readActive();
        if (cached != null && cached.pendingSync) {
          return cached;
        }
        await _cache.write(activeKey, null);
        return null;
      } on Object {
        // Réseau tombé pendant l'appel : on retombe sur le cache.
      }
    }
    return _readActive();
  }

  @override
  Future<Ticket> createTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    if (_isOnline()) {
      try {
        final ticket = await _remote.createTicket(
          organization: organization,
          agency: agency,
          service: service,
        );
        await _writeActive(ticket);
        return ticket;
      } on TicketAlreadyActiveException {
        // Invariant métier, pas une panne réseau : il doit remonter tel quel.
        rethrow;
      } on Object {
        // Bascule en mode hors ligne.
      }
    }

    final existing = await _readActive();
    if (existing != null && !existing.served) {
      throw TicketAlreadyActiveException(existing);
    }
    final pending = Ticket(
      number: 'L-${DateTime.now().millisecondsSinceEpoch % 100000}',
      position: service.waitingCount + 1,
      // Estimation locale, identique à celle du mock (une minute par
      // personne devant) : elle sera remplacée par la valeur du serveur.
      estimatedMinutes: service.waitingCount,
      organizationId: organization.id,
      organizationName: organization.name,
      agencyId: agency.id,
      agencyName: agency.name,
      serviceId: service.id,
      serviceName: service.name,
      pendingSync: true,
      issuedAt: DateTime.now(),
    );
    await _writeActive(pending);
    await _cache.write(pendingKey, <String, Object?>{
      'ticket': ticketToJson(pending),
      'organization': organizationToJson(organization),
      'agency': agencyToJson(agency),
      'service': agencyServiceToJson(service),
    });
    return pending;
  }

  /// Rejoue la prise de ticket mise en attente.
  ///
  /// Retourne le ticket confirmé par le serveur, ou null s'il n'y avait rien
  /// à synchroniser ou si le réseau est toujours absent. Ne lève jamais :
  /// un échec doit laisser l'action en attente, pas casser l'écran.
  Future<Ticket?> syncPending() async {
    if (!_isOnline()) {
      return null;
    }
    final document = await _cache.read(pendingKey);
    if (document is! Map) {
      return null;
    }
    final organization = organizationFromJson(document['organization']);
    final agency = agencyFromJson(document['agency']);
    if (organization == null || agency == null) {
      // Charge utile inexploitable : on la retire pour ne pas boucler.
      await _cache.write(pendingKey, null);
      return null;
    }
    // Une action mise en attente par une version antérieure ne porte pas de
    // service : on rejoue alors sur la file globale de l'agence plutôt que de
    // laisser le client bloqué sur un ticket jamais confirmé.
    final service =
        agencyServiceFromJson(document['service']) ??
        AgencyService(
          id: '${agency.id}-default',
          name: '',
          waitingCount: agency.waitingCount,
        );
    try {
      final ticket = await _remote.createTicket(
        organization: organization,
        agency: agency,
        service: service,
      );
      await _writeActive(ticket);
      await _cache.write(pendingKey, null);
      return ticket;
    } on TicketAlreadyActiveException catch (error) {
      // Un ticket existe déjà côté serveur : c'est lui qui fait foi.
      await _writeActive(error.existingTicket);
      await _cache.write(pendingKey, null);
      return error.existingTicket;
    } on Object {
      // Toujours hors ligne en pratique : on garde l'action en attente.
      return null;
    }
  }

  /// Nombre d'actions en attente de synchronisation (0 ou 1 : l'invariant
  /// produit n'autorise qu'un seul ticket actif).
  Future<int> pendingCount() async {
    final document = await _cache.read(pendingKey);
    return document == null ? 0 : 1;
  }

  /// Marque le ticket comme servi côté serveur **et** dans le cache.
  ///
  /// Les deux mémoires doivent s'accorder : si le serveur continue de croire
  /// que le client attend encore, il refusera le ticket suivant alors que
  /// l'écran, lui, affiche déjà « Terminé ».
  @override
  Future<void> markServed(Ticket ticket) async {
    final served = ticket.copyWith(served: true);
    if (_isOnline()) {
      try {
        await _remote.markServed(served);
      } on Object {
        // Le serveur reconciliera plus tard : l'état local fait foi pour la
        // session en cours, et un échec ne doit jamais bloquer le client.
      }
    }
    await _writeActive(served);
  }

  /// Annule le ticket actif.
  ///
  /// Le cache est vidé dans tous les cas : un ticket annulé ne doit jamais
  /// réapparaître au prochain démarrage, même si le serveur n'a pas pu être
  /// joint. L'échec réseau est donc volontairement avalé.
  @override
  Future<void> cancelTicket() async {
    if (_isOnline()) {
      try {
        await _remote.cancelTicket();
      } on Object {
        // Le serveur reconciliera à la prochaine ouverture de session.
      }
    }
    await _cache.write(activeKey, null);
    await _cache.write(pendingKey, null);
  }

  Future<Ticket?> _readActive() async =>
      ticketFromJson(await _cache.read(activeKey));

  Future<void> _writeActive(Ticket? ticket) =>
      _cache.write(activeKey, ticket == null ? null : ticketToJson(ticket));
}
