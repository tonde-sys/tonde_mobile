import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tracking/data/mock_queue_tracking_service.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

const _organization = Organization(
  id: 'org-1',
  name: 'Banque A',
  type: OrganizationType.bank,
);
const _agency = Agency(
  id: 'ag-1',
  name: 'Agence Centre',
  address: 'Avenue 1',
  waitingCount: 12,
);
const _otherAgency = Agency(
  id: 'ag-2',
  name: 'Agence Sud',
  address: 'Avenue 2',
  waitingCount: 3,
);

const _service = AgencyService(
  id: 'ag-1-account',
  name: 'Ouverture de compte',
  waitingCount: 12,
);

const _otherService = AgencyService(
  id: 'ag-2-cash',
  name: 'Retrait & dépôt',
  waitingCount: 3,
);

void main() {
  test('le service mock crée un ticket avec numéro et position', () async {
    final service = MockTicketService(latency: Duration.zero);

    expect(await service.activeTicket(), isNull);

    final ticket = await service.createTicket(
      organization: _organization,
      agency: _agency,
      service: _service,
    );

    expect(ticket.number, 'T-1042');
    expect(ticket.position, 13);
    // Une minute par personne devant soi.
    expect(ticket.estimatedMinutes, 12);
    expect(ticket.organizationName, 'Banque A');
    expect(ticket.agencyName, 'Agence Centre');
    expect(await service.activeTicket(), same(ticket));
  });

  test("l'invariant un seul ticket actif est respecté par le mock", () async {
    final service = MockTicketService(latency: Duration.zero);
    final first = await service.createTicket(
      organization: _organization,
      agency: _agency,
      service: _service,
    );

    expect(
      () => service.createTicket(
        organization: _organization,
        agency: _otherAgency,
        service: _otherService,
      ),
      throwsA(
        isA<TicketAlreadyActiveException>().having(
          (exception) => exception.existingTicket,
          'existingTicket',
          same(first),
        ),
      ),
    );
  });

  test('un ticket clos libère la place, même avec le cache interposé', () async {
    // Régression : la clôture n'était propagée qu'au cache local. Le
    // « serveur » continuait donc de croire que le client attendait, et la
    // prise du ticket suivant échouait sur un écran d'erreur réseau.
    final cache = MemoryLocalCache();
    final service = CachedTicketService(
      remote: MockTicketService(latency: Duration.zero, store: cache),
      cache: cache,
      isOnline: () => true,
    );

    final first = await service.createTicket(
      organization: _organization,
      agency: _agency,
      service: _service,
    );
    await service.saveStatus(first.copyWith(status: TicketStatus.done));

    // Le serveur a bien enregistré la fin de prise en charge.
    expect((await service.activeTicket())?.status, TicketStatus.done);

    final second = await service.createTicket(
      organization: _organization,
      agency: _otherAgency,
      service: _otherService,
    );
    expect(second.number, isNot(first.number));
    expect(second.isClosed, isFalse);
    expect(second.serviceName, 'Retrait & dépôt');
  });

  test('un ticket absent garde sa place et bloque la prise', () async {
    // Le client ne s'est pas présenté : le serveur lui laisse une fenêtre de
    // reprise. Libérer la place à ce moment-là lui ferait perdre son rang, et
    // son « Reprendre » échouerait sur un 409.
    final cache = MemoryLocalCache();
    final service = CachedTicketService(
      remote: MockTicketService(latency: Duration.zero, store: cache),
      cache: cache,
      isOnline: () => true,
    );

    final first = await service.createTicket(
      organization: _organization,
      agency: _agency,
      service: _service,
    );
    await service.saveStatus(
      first.copyWith(
        status: TicketStatus.absent,
        recoveryExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
      ),
    );

    final restored = await service.activeTicket();
    expect(restored?.status, TicketStatus.absent);
    expect(restored?.canResume, isTrue);

    await expectLater(
      service.createTicket(
        organization: _organization,
        agency: _otherAgency,
        service: _otherService,
      ),
      throwsA(isA<TicketAlreadyActiveException>()),
    );
  });

  test('la file simulée avance d’une personne par minute réelle', () async {
    final service = MockQueueTrackingService();
    expect(service.tick, const Duration(minutes: 1));

    // À chaque minute, un rang de moins et une minute de moins à attendre.
    final rapide = MockQueueTrackingService(
      tick: const Duration(milliseconds: 5),
    );
    final snapshots = <int>[];
    final subscription = rapide
        .watch(
          const Ticket(
            number: 'B-200',
            position: 4,
            estimatedMinutes: 3,
            organizationId: 'org-1',
            organizationName: 'Banque A',
            agencyId: 'ag-1',
            agencyName: 'Agence Centre',
            serviceName: 'Consultation',
          ),
        )
        .listen((update) => snapshots.add(update.snapshot.position));

    await Future<void>.delayed(const Duration(milliseconds: 30));
    await subscription.cancel();

    // 4 → 3 → 2 → 1 : un cran par minute, sans saut.
    expect(snapshots.take(4).toList(), [4, 3, 2, 1]);
  });
}
