import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/data/mock_queue_tracking_service.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';
import 'package:tonde/features/tracking/data/websocket_queue_tracking_service.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';
import 'package:tonde/features/tracking/presentation/pages/queue_tracking_page.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

import '../../helpers/fakes.dart';

const _user = User(name: 'Jospin Kanani', username: 'jospin kanani');

const _ticket = Ticket(
  number: 'T-9999',
  position: 3,
  estimatedMinutes: 6,
  organizationId: 'org-4',
  organizationName: 'Clinique Espoir',
  agencyId: 'ag-4',
  agencyName: 'Agence Rohero',
);

final _snapshot = QueueSnapshot(
  ticketNumber: 'T-9999',
  position: 3,
  estimatedMinutes: 6,
  status: QueueStatus.waiting,
  updatedAt: DateTime(2026, 11, 13, 10, 30),
  calledNumber: 'T-9997',
  counterLabel: 'Guichet 3',
  qrPayload: 'tonde://ticket/T-9999?sig=DEMO',
);

/// Flux figé : émet une seule mise à jour puis se termine, sans timer résiduel.
class _StaticTrackingService implements QueueTrackingService {
  _StaticTrackingService(this.snapshot);

  final QueueSnapshot snapshot;

  @override
  Stream<QueueUpdate> watch(Ticket ticket) async* {
    yield QueueUpdate(snapshot: snapshot, source: QueueFeedSource.live);
  }
}

/// Fausse connexion socket pilotée par le test.
class _FakeSocket implements QueueSocket {
  final _controller = StreamController<dynamic>();

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void push(Object payload) => _controller.add(payload);

  void fail(Object error) => _controller.addError(error);
}

AppConfig _config() => AppConfig.parse(
  environmentName: 'dev',
  apiBaseUrlRaw: 'https://api.tonde.app',
  enableHttpLogging: false,
);

void main() {
  group('QueueSnapshot.fromJson', () {
    test('lit les clés du contrat et les variantes de statut', () {
      final snapshot = QueueSnapshot.fromJson({
        'ticket_number': 'B-138',
        'position': 4,
        'estimated_minutes': 8,
        'status': 'called',
        'called_number': 'B-135',
        'counter': 'Guichet 2',
        'qr_payload': 'tonde://ticket/B-138',
      });

      expect(snapshot.ticketNumber, 'B-138');
      expect(snapshot.position, 4);
      expect(snapshot.peopleAhead, 3);
      expect(snapshot.estimatedMinutes, 8);
      expect(snapshot.status, QueueStatus.called);
      expect(snapshot.calledNumber, 'B-135');
      expect(snapshot.counterLabel, 'Guichet 2');
    });

    test('retombe sur des valeurs sûres quand les champs manquent', () {
      final snapshot = QueueSnapshot.fromJson(const <String, dynamic>{});

      expect(snapshot.position, 1);
      expect(snapshot.estimatedMinutes, 0);
      expect(snapshot.status, QueueStatus.waiting);
      expect(snapshot.calledNumber, isNull);
    });

    test('accepte les graphies alternatives du statut', () {
      expect(
        QueueSnapshot.fromJson(const {'status': 'in_service'}).status,
        QueueStatus.inService,
      );
      expect(
        QueueSnapshot.fromJson(const {'status': 'no_show'}).status,
        QueueStatus.absent,
      );
      expect(
        QueueSnapshot.fromJson(const {'status': 'inconnu'}).status,
        QueueStatus.waiting,
      );
    });
  });

  group('MockQueueTrackingService', () {
    test('émet la position initiale puis fait avancer la file', () async {
      final service = MockQueueTrackingService(
        tick: const Duration(milliseconds: 20),
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(updates, hasLength(1));
      expect(updates.first.snapshot.position, 3);
      expect(updates.first.source, QueueFeedSource.live);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(updates.last.snapshot.position, lessThan(3));

      await subscription.cancel();
    });

    test('appelle le numéro puis passe en prise en charge', () async {
      const first = Ticket(
        number: 'T-2000',
        position: 1,
        estimatedMinutes: 2,
        organizationId: 'org-1',
        organizationName: 'Banque',
        agencyId: 'ag-1',
        agencyName: 'Agence Centre',
      );
      final service = MockQueueTrackingService(
        tick: const Duration(milliseconds: 10),
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(first).listen(updates.add);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(updates.first.snapshot.status, QueueStatus.called);
      expect(updates.first.snapshot.calledNumber, 'T-2000');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(updates.last.snapshot.status, QueueStatus.inService);

      await subscription.cancel();
    });

    test('fournit une charge utile de QR code', () async {
      final service = MockQueueTrackingService(
        tick: const Duration(seconds: 10),
      );
      final update = await service.watch(_ticket).first;

      expect(update.snapshot.qrPayload, contains('T-9999'));
      expect(update.snapshot.counterLabel, isNotNull);
    });
  });

  group('WebSocketQueueTrackingService', () {
    test('pousse les messages du socket en source directe', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        dio: Dio(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push(
        jsonEncode({
          'ticket_number': 'T-9999',
          'position': 2,
          'estimated_minutes': 4,
          'status': 'waiting',
          'called_number': 'T-9998',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates, hasLength(1));
      expect(updates.single.source, QueueFeedSource.live);
      expect(updates.single.snapshot.position, 2);

      await subscription.cancel();
    });

    test('ignore un message illisible sans casser le flux', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        dio: Dio(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push('pas du json');
      socket.push(jsonEncode({'ticket_number': 'T-9999', 'position': 1}));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates, hasLength(1));
      expect(updates.single.snapshot.position, 1);

      await subscription.cancel();
    });

    test('bascule en polling quand le socket tombe', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        dio: Dio(),
        connect: (_) => socket,
        pollInterval: const Duration(hours: 1),
        fetchSnapshot: (ticketNumber) async => {
          'ticket_number': ticketNumber,
          'position': 5,
          'estimated_minutes': 10,
          'status': 'waiting',
        },
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.fail(StateError('réseau coupé'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(updates, isNotEmpty);
      expect(updates.last.source, QueueFeedSource.polling);
      expect(updates.last.snapshot.position, 5);

      await subscription.cancel();
    });

    test('bascule en polling si la connexion échoue d\'emblée', () async {
      final service = WebSocketQueueTrackingService(
        config: _config(),
        dio: Dio(),
        connect: (_) => throw StateError('socket indisponible'),
        pollInterval: const Duration(hours: 1),
        fetchSnapshot: (ticketNumber) async => {
          'ticket_number': ticketNumber,
          'position': 7,
          'status': 'waiting',
        },
      );
      final update = await service.watch(_ticket).first;

      expect(update.source, QueueFeedSource.polling);
      expect(update.snapshot.position, 7);
    });
  });

  group('QueueTrackingPage', () {
    testWidgets('affiche ticket, statut, numéro appelé et QR code', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ticketServiceProvider.overrideWithValue(
              FakeTicketService(ticket: _ticket),
            ),
            queueTrackingServiceProvider.overrideWithValue(
              _StaticTrackingService(_snapshot),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const QueueTrackingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('T-9999'), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('T-9997'), findsOneWidget);
      expect(find.text('Guichet 3'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('le bouton « See my position » ouvre le suivi', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationRepositoryProvider.overrideWithValue(
              MockOrganizationRepository(latency: Duration.zero),
            ),
            authServiceProvider.overrideWithValue(
              FakeAuthService(current: _user),
            ),
            ticketServiceProvider.overrideWithValue(
              FakeTicketService(ticket: _ticket),
            ),
            queueTrackingServiceProvider.overrideWithValue(
              _StaticTrackingService(_snapshot),
            ),
          ],
          child: const TondeApp(),
        ),
      );
      await tester.pumpAndSettle();

      final cta = find.text('See my position').first;
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.byType(QueueTrackingPage), findsOneWidget);
      expect(find.text('T-9997'), findsOneWidget);
    });
  });
}
