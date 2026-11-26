import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/presentation/home_widget_state.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Instant de référence des tests : l'heure affichée doit être reproductible.
final DateTime _now = DateTime(2026, 11, 24, 11, 34);

AppLocalizations _l10n([String language = 'fr']) =>
    lookupAppLocalizations(Locale(language));

Ticket _ticket({
  String number = 'A-014',
  int position = 3,
  int? estimatedMinutes = 12,
  TicketStatus status = TicketStatus.waiting,
  bool pendingSync = false,
  bool queueDegraded = false,
  String? counterLabel,
}) {
  return Ticket(
    id: 't-1',
    number: number,
    position: position,
    estimatedMinutes: estimatedMinutes,
    organizationId: 'org-1',
    organizationName: 'TONDE',
    agencyId: 'agency-1',
    agencyName: 'Agence Centre',
    serviceId: 'svc-1',
    serviceName: 'Caisse',
    status: status,
    pendingSync: pendingSync,
    queueDegraded: queueDegraded,
    counterLabel: counterLabel,
  );
}

QueueSnapshot _snapshot({
  int position = 3,
  int? estimatedMinutes = 12,
  QueueStatus status = QueueStatus.waiting,
  String? counterLabel,
  List<CounterPauseInfo> pausedCounters = const [],
}) {
  return QueueSnapshot(
    ticketNumber: 'A-014',
    position: position,
    estimatedMinutes: estimatedMinutes,
    status: status,
    updatedAt: _now,
    counterLabel: counterLabel,
    pausedCounters: pausedCounters,
  );
}

void main() {
  group('aucun ticket', () {
    test('un ticket absent donne l\'invitation à en prendre un', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: null,
        now: _now,
      );

      expect(state.hasTicket, isFalse);
      expect(state.emptyTitle, 'Aucun ticket');
      expect(state.emptyBody, 'Touchez pour en prendre un');
      // Rien d'autre ne doit filtrer : le widget afficherait un numéro vide
      // au-dessus de l'invitation.
      expect(state.number, isEmpty);
      expect(state.status, isEmpty);
      expect(state.updated, isEmpty);
    });

    test('un ticket clos ne laisse pas de trace sur le widget', () {
      for (final status in [TicketStatus.done, TicketStatus.cancelled]) {
        final state = homeWidgetStateFor(
          l10n: _l10n(),
          ticket: _ticket(status: status),
          now: _now,
        );

        expect(state.hasTicket, isFalse, reason: 'statut $status');
      }
    });
  });

  group('ticket en attente', () {
    test('affiche le numéro, l\'agence, la position et l\'attente', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(),
        now: _now,
      );

      expect(state.hasTicket, isTrue);
      expect(state.number, 'A-014');
      expect(state.agency, 'Agence Centre');
      expect(state.status, 'En attente');
      expect(state.position, 'Position 3');
      expect(state.eta, '≈ 12 min');
      expect(state.updated, 'Mis à jour à 11:34');
    });

    test('l\'instantané du flux prime sur le ticket', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(position: 9, estimatedMinutes: 40),
        snapshot: _snapshot(position: 2, estimatedMinutes: 7),
        now: _now,
      );

      expect(state.position, 'Position 2');
      expect(state.eta, '≈ 7 min');
    });

    test('une file dégradée masque la position mais garde l\'attente', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(position: 0, queueDegraded: true),
        now: _now,
      );

      expect(state.position, isEmpty);
      expect(state.eta, '≈ 12 min');
    });

    test('une position nulle n\'est pas affichée', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(position: 0),
        now: _now,
      );

      expect(state.position, isEmpty);
    });

    test('sans estimation fiable, aucune durée n\'est inventée', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(estimatedMinutes: null),
        now: _now,
      );

      expect(state.eta, isEmpty);
    });

    test('une estimation nulle n\'est jamais écrite « 0 min »', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(estimatedMinutes: 0),
        now: _now,
      );

      expect(state.eta, isEmpty);
    });

    test('un guichet en pause remplace l\'attente estimée', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(),
        // Heure locale construite telle quelle : le test ne dépend pas du
        // fuseau de la machine qui l'exécute.
        snapshot: _snapshot(
          pausedCounters: [
            CounterPauseInfo(
              name: 'Guichet 3',
              pausedUntil: DateTime(2026, 11, 24, 14, 45),
            ),
          ],
        ),
        now: _now,
      );

      // L'attente cède la place : une durée à côté d'un guichet fermé se
      // lirait comme un retard.
      expect(state.eta, 'Pause jusqu\'à 14:45');
      expect(state.status, 'En attente');
      expect(state.position, 'Position 3');
    });

    test('sans heure de reprise, la pause est annoncée seule', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(),
        snapshot: _snapshot(
          pausedCounters: [const CounterPauseInfo(name: 'Guichet 3')],
        ),
        now: _now,
      );

      expect(state.eta, 'Guichet en pause');
    });
  });

  group('appel au guichet', () {
    test('le statut nomme le guichet, la position disparaît', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(status: TicketStatus.called, counterLabel: 'Guichet 3'),
        snapshot: _snapshot(status: QueueStatus.called),
        now: _now,
      );

      expect(state.status, 'Appelé · Guichet 3');
      // Une position n'a plus de sens quand le tour est arrivé.
      expect(state.position, isEmpty);
      expect(state.eta, isEmpty);
    });

    test('sans guichet connu, le statut reste seul', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(status: TicketStatus.called),
        snapshot: _snapshot(status: QueueStatus.called),
        now: _now,
      );

      expect(state.status, 'Appelé');
    });

    test('en cours de service, le guichet reste affiché', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(status: TicketStatus.serving, counterLabel: 'Guichet 1'),
        now: _now,
      );

      expect(state.status, 'En cours · Guichet 1');
    });

    test('absent : le statut seul, sans rang ni attente', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(status: TicketStatus.absent),
        now: _now,
      );

      expect(state.status, 'Absent');
      expect(state.position, isEmpty);
      expect(state.eta, isEmpty);
    });
  });

  group('ticket pris hors ligne', () {
    test('annonce qu\'il n\'est pas synchronisé et ne promet aucun rang', () {
      final state = homeWidgetStateFor(
        l10n: _l10n(),
        ticket: _ticket(number: 'L-0001', pendingSync: true),
        now: _now,
      );

      expect(state.hasTicket, isTrue);
      expect(state.number, 'L-0001');
      expect(state.status, 'Non synchronisé');
      expect(state.position, isEmpty);
      expect(state.eta, isEmpty);
    });
  });

  group('langues', () {
    test('les textes suivent la langue demandée', () {
      final state = homeWidgetStateFor(
        l10n: _l10n('en'),
        ticket: _ticket(),
        now: _now,
      );

      expect(state.status, 'Waiting');
      expect(state.position, 'Position 3');
      expect(state.updated, 'Updated at 11:34');
    });

    test('le kirundi a ses propres libellés', () {
      final empty = homeWidgetStateFor(
        l10n: _l10n('rn'),
        ticket: null,
        now: _now,
      );

      expect(empty.emptyTitle, 'Nta tike');
      expect(empty.emptyBody, 'Kanda ufate itike');
    });
  });
}
