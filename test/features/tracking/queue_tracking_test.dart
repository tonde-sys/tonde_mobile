import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/core/security/secure_key_value_store.dart';
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

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

const _ticket = Ticket(
  id: 't-9999',
  qrToken: 'tonde://ticket/T-9999?sig=DEMO',
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

  /// Messages émis par le client (ping de maintien de connexion).
  final sent = <String>[];

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void send(String message) => sent.add(message);

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

/// Stockage sécurisé en mémoire : les tests n'ont pas de trousseau.
final class _MemorySecureStore implements SecureKeyValueStore {
  final _values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async => _values.remove(key);
}

/// Client applicatif prêt à l'emploi, avec un jeton en mémoire.
///
/// Le socket porte le jeton en paramètre de requête : sans lui, l'URL ne peut
/// pas être construite et le service bascule directement en repli.
ApiClient _client({String? token = 'jeton-de-test'}) {
  final tokens = AuthTokenStore(_MemorySecureStore());
  if (token != null) {
    tokens.setAccessToken(token);
  }
  return ApiClient(dio: Dio(), tokens: tokens);
}

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
        client: _client(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push(
        jsonEncode({
          'type': 'queue_update',
          'ticket_number': 'T-9999',
          'position': 2,
          'estimated_wait_minutes': 4,
          'status': 'waiting',
          'current_called_number': 'T-9998',
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
        client: _client(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push('pas du json');
      socket.push(
        jsonEncode({
          'type': 'queue_update',
          'ticket_number': 'T-9999',
          'position': 1,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates, hasLength(1));
      expect(updates.single.snapshot.position, 1);

      await subscription.cancel();
    });

    test('un message de position ne fait pas regresser le statut', () async {
      // Les `queue_update` pousses en direct ne transportent PAS le statut :
      // seul le snapshot de connexion le porte. Sans memoire du statut, chaque
      // mouvement de file ramenerait un ticket appele a « en attente ».
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push(
        jsonEncode({
          'type': 'queue_update',
          'ticket_number': 'T-9999',
          'status': 'called',
          'position': 1,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(updates.last.snapshot.status, QueueStatus.called);

      socket.push(jsonEncode({'type': 'queue_update', 'position': 1}));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates.last.snapshot.status, QueueStatus.called);
      expect(updates.last.snapshot.position, 1);

      await subscription.cancel();
    });

    test('« votre tour » appelle le client avec son guichet', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(),
        connect: (_) => socket,
      );
      final update = service.watch(_ticket).first;

      socket.push(
        jsonEncode({
          'type': 'your_turn',
          'ticket_id': 't-9999',
          'ticket_number': 'T-9999',
          'counter_name': 'Guichet 4',
          'timeout_seconds': 180,
        }),
      );

      final snapshot = (await update).snapshot;
      expect(snapshot.status, QueueStatus.called);
      expect(snapshot.counterLabel, 'Guichet 4');
      // Le QR vient du ticket, jamais du flux : sans ce repli, l'ecran
      // perdrait le code a la premiere mise a jour.
      expect(snapshot.qrPayload, _ticket.qrToken);
    });

    test('la cloture du service termine le suivi', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(),
        connect: (_) => socket,
      );
      final update = service.watch(_ticket).first;

      socket.push(
        jsonEncode({'type': 'ticket_done', 'ticket_number': 'T-9999'}),
      );

      final snapshot = (await update).snapshot;
      expect(snapshot.status, QueueStatus.done);
      // « Termine » est un etat terminal : c'est lui qui libere le client et
      // lui permet de reprendre un ticket.
      expect(snapshot.isTerminal, isTrue);
    });

    test('un numero appele dans la salle ne change pas notre statut', () async {
      // `ticket_called` est diffuse a toute la salle : il concerne souvent un
      // autre client. Le traiter comme « votre tour » ferait lever du siege a
      // quiconque attend.
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(),
        connect: (_) => socket,
      );
      final updates = <QueueUpdate>[];
      final subscription = service.watch(_ticket).listen(updates.add);

      socket.push(
        jsonEncode({
          'type': 'queue_update',
          'ticket_number': 'T-9999',
          'status': 'waiting',
          'position': 3,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      socket.push(
        jsonEncode({
          'type': 'ticket_called',
          'called_number': 'T-0001',
          'counter_name': 'Guichet 1',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates.last.snapshot.status, QueueStatus.waiting);
      expect(updates.last.snapshot.calledNumber, 'T-0001');

      await subscription.cancel();
    });

    test('sans jeton, le service ne tente pas un socket voue au refus', () async {
      var attempts = 0;
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(token: null),
        connect: (_) {
          attempts++;
          return _FakeSocket();
        },
        pollOverride: (ticket) async => {
          'ticket_number': ticket.number,
          'position': 2,
          'status': 'waiting',
        },
      );

      final update = await service.watch(_ticket).first;

      expect(attempts, 0);
      expect(update.source, QueueFeedSource.polling);
    });

    test('bascule en polling quand le socket tombe', () async {
      final socket = _FakeSocket();
      final service = WebSocketQueueTrackingService(
        config: _config(),
        client: _client(),
        connect: (_) => socket,
        pollInterval: const Duration(hours: 1),
        pollOverride: (ticket) async => {
          'ticket_number': ticket.number,
          'position': 5,
          'estimated_wait_minutes': 10,
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
        client: _client(),
        connect: (_) => throw StateError('socket indisponible'),
        pollInterval: const Duration(hours: 1),
        pollOverride: (ticket) async => {
          'ticket_number': ticket.number,
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
