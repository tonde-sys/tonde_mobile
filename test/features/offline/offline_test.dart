import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/data/mock_auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/dashboard/presentation/widgets/offline_banner.dart';
import 'package:tonde/features/organizations/data/repositories/cached_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/mock_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';
import 'package:tonde/features/tickets/presentation/controllers/pending_sync_controller.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';

import '../../helpers/fakes.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

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

/// Service adossé à un mock sans latence et à un drapeau réseau pilotable.
({CachedTicketService service, void Function(bool) setOnline}) _buildService(
  LocalCache cache, {
  bool online = true,
}) {
  var isOnline = online;
  final service = CachedTicketService(
    remote: MockTicketService(latency: Duration.zero),
    cache: cache,
    isOnline: () => isOnline,
  );
  return (service: service, setOnline: (value) => isOnline = value);
}

void main() {
  group('CachedTicketService', () {
    test(
      'relit le ticket confirmé depuis le cache une fois hors ligne',
      () async {
        final cache = MemoryLocalCache();
        final harness = _buildService(cache);
        final created = await harness.service.createTicket(
          organization: _organization,
          agency: _agency,
          service: _service,
        );
        expect(created.pendingSync, isFalse);
        expect(created.number, startsWith('T-'));

        harness.setOnline(false);
        final offline = await harness.service.activeTicket();

        expect(offline, isNotNull);
        expect(offline!.number, created.number);
        expect(offline.position, created.position);
      },
    );

    test('hors ligne, la prise de ticket est enregistrée en attente', () async {
      final cache = MemoryLocalCache();
      final harness = _buildService(cache, online: false);

      final ticket = await harness.service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );

      expect(ticket.pendingSync, isTrue);
      // Numéro local : il ne doit jamais être confondu avec un numéro serveur.
      expect(ticket.number, startsWith('L-'));
      expect(ticket.position, _agency.waitingCount + 1);
      expect(await harness.service.pendingCount(), 1);

      // Le ticket en attente est bien celui qu'on relit au redémarrage.
      final reread = await harness.service.activeTicket();
      expect(reread?.number, ticket.number);
      expect(reread?.pendingSync, isTrue);
    });

    test(
      'hors ligne, un second ticket est refusé par l\'invariant métier',
      () async {
        final harness = _buildService(MemoryLocalCache(), online: false);
        await harness.service.createTicket(
          organization: _organization,
          agency: _agency,
          service: _service,
        );

        await expectLater(
          harness.service.createTicket(
            organization: _organization,
            agency: _agency,
            service: _service,
          ),
          throwsA(isA<TicketAlreadyActiveException>()),
        );
      },
    );

    test('la reconnexion confirme le ticket en attente', () async {
      final cache = MemoryLocalCache();
      final harness = _buildService(cache, online: false);
      final pending = await harness.service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );

      harness.setOnline(true);
      final synced = await harness.service.syncPending();

      expect(synced, isNotNull);
      expect(synced!.pendingSync, isFalse);
      expect(synced.number, startsWith('T-'));
      expect(synced.number, isNot(pending.number));
      expect(await harness.service.pendingCount(), 0);
      expect((await harness.service.activeTicket())?.number, synced.number);
    });

    test(
      'sans réseau, la synchronisation ne consomme pas l\'attente',
      () async {
        final harness = _buildService(MemoryLocalCache(), online: false);
        await harness.service.createTicket(
          organization: _organization,
          agency: _agency,
          service: _service,
        );

        expect(await harness.service.syncPending(), isNull);
        expect(await harness.service.pendingCount(), 1);
      },
    );

    test('un cache illisible est traité comme vide', () async {
      final cache = MemoryLocalCache();
      await cache.write(CachedTicketService.activeKey, <String, Object?>{
        'number': 42,
      });

      final harness = _buildService(cache, online: false);

      expect(await harness.service.activeTicket(), isNull);
    });
  });

  group('CachedOrganizationRepository', () {
    test('sert le catalogue depuis le cache hors ligne', () async {
      final cache = MemoryLocalCache();
      var isOnline = true;
      final repository = CachedOrganizationRepository(
        remote: const MockOrganizationRepository(latency: Duration.zero),
        cache: cache,
        isOnline: () => isOnline,
      );

      final online = await repository.fetchOrganizations();
      expect(online, isNotEmpty);

      isOnline = false;
      final offline = await repository.fetchOrganizations();

      expect(offline.length, online.length);
      expect(offline.first.name, online.first.name);

      final agencies = await repository.fetchAgencies(online.first.id);
      expect(agencies, isNotEmpty);
    });
  });

  group('Session hors ligne', () {
    test('la session est restaurée depuis le cache au redémarrage', () async {
      final cache = MemoryLocalCache();
      final first = MockAuthService(latency: Duration.zero, cache: cache);
      await first.login(
        email: MockAuthService.demoEmail,
        password: MockAuthService.demoPassword,
      );

      // Nouveau service = redémarrage de l'application : la mémoire est vide.
      final restarted = MockAuthService(latency: Duration.zero, cache: cache);

      final restored = await restarted.currentUser();
      expect(restored, isNotNull);
      expect(restored!.email, MockAuthService.demoEmail);
      expect(restored.name, 'Jospin Kanani');
    });

    test('la déconnexion efface la session persistée', () async {
      final cache = MemoryLocalCache();
      final service = MockAuthService(latency: Duration.zero, cache: cache);
      await service.login(
        email: MockAuthService.demoEmail,
        password: MockAuthService.demoPassword,
      );
      await service.logout();

      final restarted = MockAuthService(latency: Duration.zero, cache: cache);
      expect(await restarted.currentUser(), isNull);
    });

    test('sans cache, le service reste purement en mémoire', () async {
      final service = MockAuthService(latency: Duration.zero);
      await service.login(
        email: MockAuthService.demoEmail,
        password: MockAuthService.demoPassword,
      );

      final restarted = MockAuthService(latency: Duration.zero);
      expect(await restarted.currentUser(), isNull);
    });
  });

  group('MockTicketService', () {
    test('se souvient de son ticket entre deux exécutions', () async {
      final store = MemoryLocalCache();
      final first = MockTicketService(latency: Duration.zero, store: store);
      final created = await first.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );

      // Nouvelle instance = redémarrage du « serveur ».
      final restarted = MockTicketService(latency: Duration.zero, store: store);

      final restored = await restarted.activeTicket();
      expect(restored?.number, created.number);
      expect(restored?.pendingSync, isFalse);
    });

    test('sans cache, il oublie tout au redémarrage', () async {
      final first = MockTicketService(latency: Duration.zero);
      await first.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );

      final restarted = MockTicketService(latency: Duration.zero);
      expect(await restarted.activeTicket(), isNull);
    });
  });

  group('Reprise au démarrage', () {
    test('un ticket en attente est rejoué si le réseau est déjà là', () async {
      final cache = MemoryLocalCache();
      final offline = _buildService(cache, online: false);
      final pending = await offline.service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );
      expect(pending.pendingSync, isTrue);

      // Redémarrage : nouveau service, même cache, réseau disponible.
      final restarted = _buildService(cache, online: true);
      final container = ProviderContainer(
        overrides: [
          ticketServiceProvider.overrideWithValue(restarted.service),
          connectivityProvider.overrideWith(
            (ref) => Stream<List<ConnectivityResult>>.value(const [
              ConnectivityResult.wifi,
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ticket = await container.read(activeTicketProvider.future);

      expect(ticket, isNotNull);
      expect(ticket!.pendingSync, isFalse);
      expect(ticket.number, startsWith('T-'));
      expect(await restarted.service.pendingCount(), 0);
    });
  });

  group('Interface hors ligne', () {
    List<Override> overrides({
      List<ConnectivityResult>? connectivity,
      int? pendingCount,
      Ticket? ticket,
    }) => [
      organizationRepositoryProvider.overrideWithValue(
        const MockOrganizationRepository(latency: Duration.zero),
      ),
      authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
      ticketServiceProvider.overrideWithValue(
        FakeTicketService(ticket: ticket),
      ),
      if (connectivity != null)
        connectivityProvider.overrideWith(
          (ref) => Stream<List<ConnectivityResult>>.value(connectivity),
        ),
      if (pendingCount != null)
        pendingSyncCountProvider.overrideWithValue(pendingCount),
    ];

    testWidgets('affiche le bandeau quand le réseau tombe', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(connectivity: [ConnectivityResult.none]),
          child: const TondeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Offline mode — Showing local data'), findsOneWidget);
    });

    testWidgets('reste muet quand le réseau est disponible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(connectivity: [ConnectivityResult.wifi]),
          child: const TondeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline mode'), findsNothing);
      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('signale une action en attente de synchronisation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(
            connectivity: [ConnectivityResult.wifi],
            pendingCount: 1,
          ),
          child: const TondeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waiting to sync'), findsOneWidget);
    });

    testWidgets('marque le ticket pris hors ligne comme non synchronisé', (
      tester,
    ) async {
      const pendingTicket = Ticket(
        number: 'L-48210',
        position: 5,
        estimatedMinutes: 10,
        organizationId: 'org-1',
        organizationName: 'Banque Horizon',
        agencyId: 'ag-1',
        agencyName: 'Agence Centre',
        pendingSync: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(
            connectivity: [ConnectivityResult.none],
            ticket: pendingTicket,
          ),
          child: const TondeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(HomeTab),
          matching: find.text('Not synced'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HomeTab),
          matching: find.text('L-48210'),
        ),
        findsOneWidget,
      );
    });
  });
}
