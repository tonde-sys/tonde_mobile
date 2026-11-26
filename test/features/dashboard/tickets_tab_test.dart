import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/dashboard/presentation/pages/tickets_tab.dart';
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

/// Flux figé : la simulation réelle pose un minuteur d'une minute que le test
/// ne doit pas laisser tourner après la fin du scénario.
class _StaticTracking implements QueueTrackingService {
  _StaticTracking({this.position});

  /// Rang imposé par le flux, quand il diffère de celui du ticket.
  final int? position;

  @override
  Stream<QueueUpdate> watch(Ticket ticket) async* {
    final current = position ?? ticket.position;
    yield QueueUpdate(
      snapshot: QueueSnapshot(
        ticketNumber: ticket.number,
        position: current,
        estimatedMinutes: current - 1,
        status: QueueStatus.waiting,
        updatedAt: DateTime(2026, 11, 16, 11, 30),
        calledNumber: 'T-1041',
        counterLabel: 'Guichet 2',
      ),
      source: QueueFeedSource.live,
    );
  }
}

const _organization = Organization(
  id: 'org-horizon',
  name: 'Banque Horizon',
  type: OrganizationType.bank,
);
const _agency = Agency(
  id: 'hor-1',
  name: 'Agence Bujumbura Centre',
  address: "Boulevard de l'Uprona, Bujumbura",
  waitingCount: 18,
);
const _service = AgencyService(
  id: 'hor-1-account',
  name: 'Ouverture de compte',
  waitingCount: 20,
);

/// Prépare le « serveur » avec un ticket déjà pris en charge.
///
/// `runAsync` sort du temps simulé : sans lui, les délais du dépôt fictif ne
/// se résoudraient jamais et le test resterait bloqué.
Future<MockTicketService> _servedTicket(WidgetTester tester) async {
  final service = MockTicketService(latency: Duration.zero);
  await tester.runAsync(() async {
    final ticket = await service.createTicket(
      organization: _organization,
      agency: _agency,
      service: _service,
    );
    await service.saveStatus(ticket.copyWith(status: TicketStatus.done));
  });
  return service;
}

Future<void> _pumpTab(
  WidgetTester tester,
  MockTicketService service, {
  QueueTrackingService? tracking,
}) async {
  final container = ProviderContainer(
    overrides: [
      ticketServiceProvider.overrideWithValue(service),
      queueTrackingServiceProvider.overrideWithValue(
        tracking ?? _StaticTracking(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const Scaffold(body: TicketsTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un ticket en attente affiche sa position dans la file', (
    tester,
  ) async {
    final service = MockTicketService(latency: Duration.zero);
    await tester.runAsync(
      () => service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      ),
    );

    await _pumpTab(tester, service);

    expect(find.text('Ticket actif'), findsOneWidget);
    expect(find.text('Position dans la file : 21'), findsOneWidget);
    expect(find.text('Voir ma position'), findsOneWidget);
  });

  testWidgets('la position affichée est celle du flux, pas celle du ticket', (
    tester,
  ) async {
    final service = MockTicketService(latency: Duration.zero);
    await tester.runAsync(
      () => service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      ),
    );

    // Le ticket a été émis au rang 21 ; la file a avancé depuis.
    await _pumpTab(tester, service, tracking: _StaticTracking(position: 5));

    expect(find.text('Position dans la file : 5'), findsOneWidget);
    expect(find.text('Position dans la file : 21'), findsNothing);
  });

  testWidgets('un ticket servi annonce la fin et propose un nouveau ticket', (
    tester,
  ) async {
    final service = await _servedTicket(tester);

    await _pumpTab(tester, service);

    // La place est rendue : plus de position à suivre, et la reprise est
    // accessible sans repasser par le tableau de bord.
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Ticket actif'), findsNothing);
    expect(find.textContaining('Position dans la file'), findsNothing);
    expect(find.text('Prendre un ticket'), findsOneWidget);
    expect(find.text('Voir ma position'), findsNothing);
  });
}
