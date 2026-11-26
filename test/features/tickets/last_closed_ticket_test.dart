import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_codec.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';

import '../../helpers/fakes.dart';

const _organization = Organization(
  id: 'org-1',
  name: 'Banque Horizon',
  type: OrganizationType.bank,
);

const _agency = Agency(
  id: 'ag-1',
  name: 'Agence Centre',
  address: "Boulevard de l'Uprona",
  waitingCount: 4,
);

const _service = AgencyService(
  id: 'ag-1-account',
  name: 'Ouverture de compte',
  waitingCount: 4,
);

Ticket _ticket({TicketStatus status = TicketStatus.waiting}) => Ticket(
  id: 't-1',
  number: 'T-0001',
  position: 2,
  estimatedMinutes: 5,
  organizationId: _organization.id,
  organizationName: _organization.name,
  agencyId: _agency.id,
  agencyName: _agency.name,
  serviceId: _service.id,
  serviceName: _service.name,
  status: status,
);

/// Service en ligne dont le « serveur » est un faux pilotable.
({CachedTicketService service, FakeTicketService remote}) _build(
  LocalCache cache,
) {
  final remote = FakeTicketService();
  final service = CachedTicketService(
    remote: remote,
    cache: cache,
    isOnline: () => true,
  );
  return (service: service, remote: remote);
}

Future<Ticket> _take(CachedTicketService service) => service.createTicket(
  organization: _organization,
  agency: _agency,
  service: _service,
);

void main() {
  group('avis de clôture', () {
    test('mémorise le ticket que le serveur ne connaît plus', () async {
      final cache = MemoryLocalCache();
      final harness = _build(cache);
      final created = await _take(harness.service);

      // Le ticket quitte la file côté serveur : servi, expiré ou retiré.
      harness.remote.ticket = null;

      expect(await harness.service.activeTicket(), isNull);
      final closed = await harness.service.lastClosedTicket();

      expect(closed, isNotNull);
      expect(closed!.number, created.number);
      // Le statut est conservé : c'est lui qui choisit les mots à l'écran.
      expect(closed.status, TicketStatus.waiting);
    });

    test('un nouveau venu n’a aucun avis', () async {
      final harness = _build(MemoryLocalCache());

      expect(await harness.service.activeTicket(), isNull);
      expect(await harness.service.lastClosedTicket(), isNull);
    });

    test('une annulation volontaire n’en laisse pas', () async {
      final harness = _build(MemoryLocalCache());
      await _take(harness.service);

      // Le client a annulé lui-même : lui expliquer la disparition de son
      // ticket serait au mieux inutile, au pire inquiétant.
      await harness.service.cancelTicket();

      expect(await harness.service.lastClosedTicket(), isNull);
    });

    test('reprendre un ticket efface l’avis précédent', () async {
      final cache = MemoryLocalCache();
      final harness = _build(cache);
      await _take(harness.service);
      harness.remote.ticket = null;
      await harness.service.activeTicket();
      expect(await harness.service.lastClosedTicket(), isNotNull);

      harness.remote.ticket = _ticket();
      await harness.service.activeTicket();
      await harness.service.saveStatus(_ticket(status: TicketStatus.called));

      expect(await harness.service.lastClosedTicket(), isNull);
    });

    test('un avis de plus d’un jour n’est plus affiché', () async {
      final cache = MemoryLocalCache();
      final harness = _build(cache);
      // Entrée vieillie à la main : le service n'écrit que du frais.
      await cache.write(CachedTicketService.lastClosedKey, <String, Object?>{
        'ticket': ticketToJson(_ticket()),
        'closed_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
      });

      expect(await harness.service.lastClosedTicket(), isNull);
      // L'entrée périmée est retirée au passage : elle ne reviendra pas.
      expect(await cache.read(CachedTicketService.lastClosedKey), isNull);
    });

    test('le ticket clos est retiré du cache actif', () async {
      final cache = MemoryLocalCache();
      final harness = _build(cache);
      await _take(harness.service);
      harness.remote.ticket = null;
      await harness.service.activeTicket();

      // Sinon l'application rouvrirait sur un ticket fantôme, et le serveur
      // refuserait le suivant au nom de l'invariant « un seul ticket actif ».
      expect(await cache.read(CachedTicketService.activeKey), isNull);
    });
  });
}
