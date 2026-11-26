import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/ticket_codec.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Service fictif approuvé par Vizane (2026-11-09) pour la démo.
///
/// Il simule le backend : depuis le lot 15, il conserve son ticket actif dans
/// le cache local quand un [LocalCache] lui est fourni. Sans cela, un
/// redémarrage faisait croire au mobile que le serveur avait annulé le ticket,
/// et la démo contredisait la promesse « relancer l'application et retrouver
/// son ticket ». À remplacer par le client backend réel (Phase 3).
final class MockTicketService implements TicketService {
  MockTicketService({
    this.latency = const Duration(milliseconds: 600),
    LocalCache? store,
  }) : _store = store;

  /// Clé distincte de celle du cache applicatif : le « serveur » a sa propre
  /// mémoire, elle ne doit pas être confondue avec le cache d'affichage.
  static const String ticketKey = 'mock.activeTicket';

  /// Délai artificiel pour rendre la prise de ticket perceptible en démo.
  final Duration latency;

  final LocalCache? _store;

  Ticket? _active;
  int _sequence = 1041;

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<Ticket?> activeTicket() async {
    await _wait();
    return _current();
  }

  @override
  Future<Ticket> createTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    await _wait();
    final existing = await _current();
    // Un ticket encore actif bloque la prise ; un ticket clos non.
    if (existing != null && !existing.isClosed) {
      throw TicketAlreadyActiveException(existing);
    }
    final sequence = ++_sequence;
    final ticket = Ticket(
      id: 'mock-$sequence',
      number: 'T-$sequence',
      position: service.waitingCount + 1,
      // Une minute par personne devant soi, comme au guichet.
      estimatedMinutes: service.waitingCount,
      organizationId: organization.id,
      organizationName: organization.name,
      agencyId: agency.id,
      agencyName: agency.name,
      serviceId: service.id,
      serviceName: service.name,
      qrToken: 'mock-qr-$sequence',
      issuedAt: DateTime.now(),
    );
    _active = ticket;
    await _store?.write(ticketKey, ticketToJson(ticket));
    return ticket;
  }

  @override
  Future<void> saveStatus(Ticket ticket) async {
    await _wait();
    // Le service fait foi : enregistrer un état déjà courant ne change rien,
    // et enregistrer un ticket clos le libère. L'appelant n'a pas à y penser.
    _active = ticket;
    await _store?.write(ticketKey, ticketToJson(ticket));
  }

  @override
  Future<void> cancelTicket() async {
    await _wait();
    _active = null;
    await _store?.write(ticketKey, null);
  }

  @override
  Future<Ticket?> lastClosedTicket() async => null;

  @override
  Future<Ticket> resumeTicket(Ticket ticket) async {
    await _wait();
    // Le vrai serveur replace le ticket en fin de tranche ; la démo se
    // contente de le remettre dans la file à la position qu'il occupait.
    final resumed = ticket.copyWith(
      status: TicketStatus.waiting,
      clearRecoveryExpiresAt: true,
      position: ticket.position > 0 ? ticket.position : 1,
    );
    _active = resumed;
    await _store?.write(ticketKey, ticketToJson(resumed));
    return resumed;
  }

  /// Ticket courant du « serveur », restauré depuis le cache au besoin.
  Future<Ticket?> _current() async {
    final current = _active;
    if (current != null) {
      return current;
    }
    final store = _store;
    if (store == null) {
      return null;
    }
    final restored = ticketFromJson(await store.read(ticketKey));
    _active = restored;
    return restored;
  }
}
