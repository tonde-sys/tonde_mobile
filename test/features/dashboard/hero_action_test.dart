import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';

import '../../helpers/fakes.dart';

const _user = User(id: 'u-1', name: 'Test', email: 'test@example.com');

Ticket _ticket({
  TicketStatus status = TicketStatus.waiting,
  DateTime? recoveryExpiresAt,
}) {
  return Ticket(
    id: 't-1',
    number: 'T-9999',
    position: 3,
    estimatedMinutes: 6,
    organizationId: 'org-4',
    organizationName: 'Clinique Espoir',
    agencyId: 'ag-4',
    agencyName: 'Agence Rohero',
    status: status,
    recoveryExpiresAt: recoveryExpiresAt,
  );
}

Finder _inHome(Finder matching) =>
    find.descendant(of: find.byType(HomeTab), matching: matching);

Future<FakeTicketService> _pump(
  WidgetTester tester,
  Ticket? ticket, {
  QueueStatus feedStatus = QueueStatus.waiting,
  Ticket? lastClosed,
  DateTime? pausedUntil,
}) async {
  final tickets = FakeTicketService(ticket: ticket, lastClosed: lastClosed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(
          MockOrganizationRepository(latency: Duration.zero),
        ),
        authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
        ticketServiceProvider.overrideWithValue(tickets),
        queueTrackingServiceProvider.overrideWithValue(
          StaticQueueTrackingService(
            snapshot: ticket == null
                ? null
                : QueueSnapshot(
                    ticketNumber: ticket.number,
                    position: ticket.position,
                    estimatedMinutes: ticket.estimatedMinutes,
                    status: feedStatus,
                    updatedAt: DateTime(2026, 11, 23, 12),
                    counterLabel: 'Guichet 2',
                    pausedCounters: pausedUntil == null
                        ? const []
                        : [CounterPauseInfo(name: 'Guichet 2', pausedUntil: pausedUntil)],
                  ),
          ),
        ),
      ],
      child: const TondeApp(),
    ),
  );
  await tester.pumpAndSettle();
  return tickets;
}

void main() {
  testWidgets('sans ticket, la bannière propose d’en prendre un', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(_inHome(find.text('Take a ticket')), findsOneWidget);
    expect(_inHome(find.text('See my position')), findsNothing);
  });

  testWidgets('avec un ticket en attente, la bannière mène au suivi', (
    tester,
  ) async {
    // Le défaut d'origine : la bannière proposait « Prendre un ticket » alors
    // que le serveur en refusait un second. L'utilisateur découvrait
    // l'invariant métier sous forme d'erreur.
    await _pump(tester, _ticket());

    expect(_inHome(find.text('See my position')), findsOneWidget);
    expect(_inHome(find.text('Take a ticket')), findsNothing);
    expect(_inHome(find.text("You're in the queue")), findsOneWidget);
  });

  testWidgets('un ticket clos ramène la bannière à la prise de ticket', (
    tester,
  ) async {
    await _pump(
      tester,
      _ticket(status: TicketStatus.done),
      feedStatus: QueueStatus.done,
    );

    expect(_inHome(find.text('Take a ticket')), findsOneWidget);
    expect(_inHome(find.text('See my position')), findsNothing);
  });

  testWidgets('un ticket absent propose de le reprendre', (tester) async {
    final deadline = DateTime.now().add(const Duration(minutes: 20));
    final tickets = await _pump(
      tester,
      _ticket(status: TicketStatus.absent, recoveryExpiresAt: deadline),
      feedStatus: QueueStatus.absent,
    );

    expect(_inHome(find.text('Resume my ticket')), findsOneWidget);
    // L'échéance est affichée : le client sait jusqu'à quand il peut revenir.
    expect(
      _inHome(find.textContaining('Resume your ticket before')),
      findsOneWidget,
    );

    await tester.tap(_inHome(find.text('Resume my ticket')));
    await tester.pumpAndSettle();

    expect(tickets.resumeCalls, 1);
    expect(tickets.ticket?.status, TicketStatus.waiting);
    // La bannière suit l'état : le client est de nouveau dans la file.
    expect(_inHome(find.text('See my position')), findsOneWidget);
    expect(_inHome(find.text('Resume my ticket')), findsNothing);
  });

  testWidgets('une fenêtre de reprise dépassée ne propose plus la reprise', (
    tester,
  ) async {
    // Le serveur refuserait avec RECOVERY_WINDOW_EXPIRED : proposer le bouton
    // mènerait droit à un échec. Le ticket reste affiché jusqu'au prochain
    // rafraîchissement, qui le verra annulé côté serveur.
    await _pump(
      tester,
      _ticket(
        status: TicketStatus.absent,
        recoveryExpiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      feedStatus: QueueStatus.absent,
    );

    expect(_inHome(find.text('Resume my ticket')), findsNothing);
    expect(_inHome(find.text('Take a ticket')), findsNothing);
    expect(_inHome(find.text('See my position')), findsOneWidget);
  });

  testWidgets('un ticket disparu explique sa disparition', (tester) async {
    // `GET /tickets/active` répond null aussi bien pour un nouveau venu que
    // pour un client dont le ticket vient d'être retiré de la file. Sans la
    // note de clôture, le second lit « aucun ticket actif » et croit avoir
    // perdu sa place.
    await _pump(tester, null, lastClosed: _ticket());

    expect(_inHome(find.text('Your ticket has expired')), findsOneWidget);
    expect(
      _inHome(find.textContaining('Ticket T-9999 is no longer in the queue')),
      findsOneWidget,
    );
    expect(_inHome(find.text('No active ticket')), findsNothing);
  });

  testWidgets('un ticket clôturé au guichet annonce la fin du passage', (
    tester,
  ) async {
    // Un client servi n'a pas « expiré » : le mot compte, c'est la seule
    // chose qu'il retiendra de l'écran.
    await _pump(
      tester,
      null,
      lastClosed: _ticket(status: TicketStatus.done),
    );

    expect(_inHome(find.text('Your visit is complete')), findsOneWidget);
    expect(_inHome(find.text('Your ticket has expired')), findsNothing);
  });

  testWidgets('une pause de guichet affiche l\'heure de reprise locale', (
    tester,
  ) async {
    // `paused_until` arrive en UTC. Sur une machine à UTC+2 (Bujumbura),
    // oublier `toLocal()` annoncerait une reprise deux heures trop tôt — et le
    // client se présenterait devant un guichet encore fermé.
    final until = DateTime.utc(2026, 11, 23, 12, 45);
    await _pump(tester, _ticket(), pausedUntil: until);

    // Même formateur que la carte : l'assertion porte sur la conversion, pas
    // sur le format d'heure de la langue active.
    final expected = MaterialLocalizations.of(
      tester.element(find.byType(HomeTab)),
    ).formatTimeOfDay(TimeOfDay.fromDateTime(until.toLocal()));

    expect(_inHome(find.textContaining(expected)), findsOneWidget);
  });
}
