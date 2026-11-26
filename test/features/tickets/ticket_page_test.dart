import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

import '../../helpers/fakes.dart';

const _user = User(id: 'u-test', name: 'Test', email: 'test@example.com');

/// Flux figé : évite de laisser un minuteur de simulation derrière lui.
class _StaticTracking implements QueueTrackingService {
  @override
  Stream<QueueUpdate> watch(Ticket ticket) async* {
    yield QueueUpdate(
      snapshot: QueueSnapshot(
        ticketNumber: ticket.number,
        position: ticket.position,
        estimatedMinutes: ticket.estimatedMinutes,
        status: QueueStatus.waiting,
        updatedAt: DateTime(2026, 11, 15, 11, 34),
        calledNumber: 'T-1041',
        counterLabel: 'Guichet 2',
      ),
      source: QueueFeedSource.live,
    );
  }
}

Future<void> _openHorizonDetail(
  WidgetTester tester, {
  MockTicketService? tickets,
}) async {
  final container = ProviderContainer(
    overrides: [
      organizationRepositoryProvider.overrideWithValue(
        MockOrganizationRepository(latency: Duration.zero),
      ),
      ticketServiceProvider.overrideWithValue(
        tickets ?? MockTicketService(latency: Duration.zero),
      ),
      queueTrackingServiceProvider.overrideWithValue(_StaticTracking()),
      authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TondeApp()),
  );
  await tester.pumpAndSettle();

  container.read(appRouterProvider).go('/organizations');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Banque Horizon'));
  await tester.pumpAndSettle();
}

/// Files réelles du référentiel pour une agence de Banque Horizon.
///
/// `runAsync` sort du temps simulé du test : sans lui, l'attente du dépôt
/// fictif ne se résoudrait jamais et le test resterait bloqué.
Future<List<AgencyService>> _horizonServices(
  WidgetTester tester,
  String agencyId,
) async {
  const repository = MockOrganizationRepository(latency: Duration.zero);
  final services = await tester.runAsync(
    () => repository.fetchServices(
      organizationId: 'org-horizon',
      agencyId: agencyId,
    ),
  );
  return services!;
}

/// Agences réelles de Banque Horizon (files comprises).
Future<List<Agency>> _horizonAgencies(WidgetTester tester) async {
  const repository = MockOrganizationRepository(latency: Duration.zero);
  final agencies = await tester.runAsync(
    () => repository.fetchAgencies('org-horizon'),
  );
  return agencies!;
}

void main() {
  testWidgets('chaque agence affiche le nombre de personnes en file', (
    tester,
  ) async {
    await _openHorizonDetail(tester);

    // Les files sont générées par le référentiel : on lit la source plutôt que
    // de figer des nombres qui changeraient à chaque réglage de la démo.
    final agencies = await _horizonAgencies(tester);
    expect(agencies, isNotEmpty);
    for (final agency in agencies) {
      expect(
        find.text('${agency.waitingCount}'),
        findsWidgets,
        reason: 'file de ${agency.name}',
      );
    }
  });

  testWidgets('toucher une agence affiche ses services', (tester) async {
    await _openHorizonDetail(tester);

    await tester.tap(find.text('Agence Bujumbura Centre'));
    await tester.pumpAndSettle();

    final services = await _horizonServices(tester, 'hor-1');

    // Le choix du service est l'étape obligatoire avant tout ticket.
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Ouverture de compte'), findsOneWidget);
    expect(find.text('Retrait & dépôt'), findsOneWidget);
    expect(find.text('Virement'), findsOneWidget);
    expect(find.text('Crédit & financement'), findsOneWidget);
    expect(
      find.text('${services.first.waitingCount} people ahead of you'),
      findsOneWidget,
    );
  });

  testWidgets('prendre un ticket affiche numéro, service et position', (
    tester,
  ) async {
    await _openHorizonDetail(tester);

    await tester.tap(find.text('Agence Bujumbura Centre'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ouverture de compte'));
    await tester.pumpAndSettle();

    final services = await _horizonServices(tester, 'hor-1');
    final ahead = services.first.waitingCount;

    expect(find.text('$ahead people ahead of you'), findsOneWidget);
    expect(find.text('Take a ticket'), findsOneWidget);

    await tester.tap(find.text('Take a ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Active ticket'), findsOneWidget);
    expect(find.text('T-1042'), findsOneWidget);
    expect(find.text('Ouverture de compte'), findsOneWidget);
    expect(
      find.text('Position in the queue: ${ahead + 1}'),
      findsOneWidget,
    );
  });

  testWidgets('un second ticket est refusé et le conflit est affiché', (
    tester,
  ) async {
    await _openHorizonDetail(tester);

    await tester.tap(find.text('Agence Bujumbura Centre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouverture de compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a ticket'));
    await tester.pumpAndSettle();

    // Retour au tableau de bord, puis reprise du parcours depuis la liste
    // des organisations.
    await tester.tap(find.text('Back to dashboard'));
    await tester.pumpAndSettle();

    final viewAll = find.text('View all');
    await tester.scrollUntilVisible(
      viewAll,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(viewAll);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Banque Horizon'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agence Gitega'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouverture de compte'));
    await tester.pumpAndSettle();

    expect(find.text('You already have an active ticket'), findsOneWidget);
    expect(
      find.text(
        'Only one active ticket at a time. '
        'Your ticket: T-1042 — Agence Bujumbura Centre.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('View my ticket'));
    await tester.pumpAndSettle();

    expect(find.text('T-1042'), findsOneWidget);
  });

  testWidgets('un ticket déjà servi ne détourne plus la prise de ticket', (
    tester,
  ) async {
    // Session précédente : le client est déjà passé au guichet.
    final tickets = MockTicketService(latency: Duration.zero);
    await tester.runAsync(() async {
      const repository = MockOrganizationRepository(latency: Duration.zero);
      final agencies = await repository.fetchAgencies('org-horizon');
      final services = await repository.fetchServices(
        organizationId: 'org-horizon',
        agencyId: 'hor-1',
      );
      final previous = await tickets.createTicket(
        organization: const Organization(
          id: 'org-horizon',
          name: 'Banque Horizon',
          type: OrganizationType.bank,
        ),
        agency: agencies.first,
        service: services.first,
      );
      await tickets.saveStatus(previous.copyWith(status: TicketStatus.done));
    });

    await _openHorizonDetail(tester, tickets: tickets);
    await tester.tap(find.text('Agence Bujumbura Centre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouverture de compte'));
    await tester.pumpAndSettle();

    // Le passage est terminé : l'écran propose bien de reprendre un ticket,
    // au lieu d'afficher la confirmation d'un ticket déjà servi.
    expect(find.text('Take a ticket'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
  });
}
