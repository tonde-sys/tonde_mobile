import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/tickets/data/ticket_codec.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';

Ticket _ticket({
  TicketStatus status = TicketStatus.waiting,
  DateTime? recoveryExpiresAt,
  int missedCount = 0,
}) {
  return Ticket(
    id: 't-1',
    number: 'A-003',
    position: 3,
    estimatedMinutes: 12,
    organizationId: 'org-1',
    organizationName: 'Banque Horizon',
    agencyId: 'ag-1',
    agencyName: 'Agence Centre',
    serviceId: 'sv-1',
    serviceName: 'Dépôt',
    status: status,
    recoveryExpiresAt: recoveryExpiresAt,
    missedCount: missedCount,
    counterLabel: 'Guichet 3',
    totalInQueue: 18,
    issuedAt: DateTime.utc(2026, 11, 22, 9, 30),
  );
}

void main() {
  group('TicketStatus', () {
    test('relit chaque statut du contrat backend', () {
      // Les valeurs sont celles de `TicketStatus` côté FastAPI. Une faute de
      // frappe ici ne casserait aucun test de rendu : elle ferait simplement
      // retomber tous les tickets en « en attente ».
      expect(TicketStatus.fromWire('waiting'), TicketStatus.waiting);
      expect(TicketStatus.fromWire('called'), TicketStatus.called);
      expect(TicketStatus.fromWire('serving'), TicketStatus.serving);
      expect(TicketStatus.fromWire('absent'), TicketStatus.absent);
      expect(TicketStatus.fromWire('transferred'), TicketStatus.transferred);
      expect(TicketStatus.fromWire('incomplete'), TicketStatus.incomplete);
      expect(TicketStatus.fromWire('done'), TicketStatus.done);
      expect(TicketStatus.fromWire('cancelled'), TicketStatus.cancelled);
    });

    test('tolère les graphies historiques et la casse', () {
      expect(TicketStatus.fromWire('CALLED'), TicketStatus.called);
      expect(TicketStatus.fromWire('in_service'), TicketStatus.serving);
      expect(TicketStatus.fromWire('no_show'), TicketStatus.absent);
      expect(TicketStatus.fromWire('completed'), TicketStatus.done);
      expect(TicketStatus.fromWire('canceled'), TicketStatus.cancelled);
      // `expired` n'existe pas côté serveur : une fenêtre de reprise dépassée
      // se termine en `cancelled`, et un cache ancien doit rester cohérent.
      expect(TicketStatus.fromWire('expired'), TicketStatus.cancelled);
    });

    test('une valeur inconnue ne libère pas la place', () {
      // Bloquer à tort se répare (le client annule) ; libérer à tort laisserait
      // le serveur refuser le ticket suivant avec un 409 incompréhensible.
      expect(TicketStatus.fromWire('quantum'), TicketStatus.waiting);
      expect(TicketStatus.fromWire(null), TicketStatus.waiting);
    });

    test('seuls done et cancelled ferment le ticket', () {
      final closed = TicketStatus.values.where((status) => status.isClosed);
      expect(closed, unorderedEquals([TicketStatus.done, TicketStatus.cancelled]));

      // Un client absent reste actif : le serveur lui garde sa place le temps
      // de la fenêtre de reprise.
      expect(TicketStatus.absent.isClosed, isFalse);
      expect(TicketStatus.absent.canResume, isTrue);
      expect(TicketStatus.transferred.isQueued, isTrue);
      expect(TicketStatus.called.isAtCounter, isTrue);
    });
  });

  group('Ticket', () {
    test('un ticket absent peut reprendre tant que la fenêtre est ouverte', () {
      final deadline = DateTime.utc(2026, 11, 22, 10, 32);
      final ticket = _ticket(
        status: TicketStatus.absent,
        recoveryExpiresAt: deadline,
      );

      expect(ticket.canResumeAt(deadline.subtract(const Duration(minutes: 1))), isTrue);
      expect(ticket.canResumeAt(deadline), isFalse);
      expect(ticket.canResumeAt(deadline.add(const Duration(seconds: 1))), isFalse);
      expect(ticket.isClosed, isFalse);
    });

    test('sans échéance connue, la reprise reste proposée', () {
      // Un serveur antérieur à la fenêtre de reprise n'envoie pas d'échéance :
      // masquer le bouton priverait le client de son seul recours.
      final ticket = _ticket(status: TicketStatus.absent);
      expect(ticket.canResumeAt(DateTime.utc(2030)), isTrue);
    });

    test('un ticket appelé ne propose pas de reprise', () {
      final ticket = _ticket(status: TicketStatus.called);
      expect(ticket.canResume, isFalse);
      expect(ticket.isAtCounter, isTrue);
    });
  });

  group('ticketCodec', () {
    test('conserve le statut et la fenêtre de reprise', () {
      final deadline = DateTime.utc(2026, 11, 22, 10, 32);
      final ticket = _ticket(
        status: TicketStatus.absent,
        recoveryExpiresAt: deadline,
        missedCount: 1,
      );

      final restored = ticketFromJson(ticketToJson(ticket));

      expect(restored, isNotNull);
      expect(restored!.status, TicketStatus.absent);
      expect(restored.recoveryExpiresAt, deadline);
      expect(restored.missedCount, 1);
      expect(restored.counterLabel, 'Guichet 3');
      expect(restored.totalInQueue, 18);
      expect(restored, ticket);
    });

    test('relit un cache écrit avant le statut', () {
      // Ces entrées ne portent que le booléen `served`. Les relire en « en
      // attente » ferait réapparaître un ticket terminé comme actif.
      final served = ticketFromJson(<String, Object?>{
        'number': 'A-003',
        'organizationId': 'org-1',
        'agencyId': 'ag-1',
        'served': true,
      });
      expect(served!.status, TicketStatus.done);

      final active = ticketFromJson(<String, Object?>{
        'number': 'A-003',
        'organizationId': 'org-1',
        'agencyId': 'ag-1',
      });
      expect(active!.status, TicketStatus.waiting);
    });
  });
}
