import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/core/security/secure_key_value_store.dart';
import 'package:tonde/features/auth/data/api_auth_service.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/organizations/data/repositories/api_organization_repository.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/api_ticket_service.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';

/// Adaptateur HTTP piloté par le test : aucune socket n'est ouverte.
///
/// On teste ici le CONTRAT (chemins, corps, codes d'erreur, mapping), pas le
/// transport : un vrai serveur rendrait ces vérifications lentes et fragiles
/// sans rien prouver de plus sur notre code.
final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Requêtes reçues, dans l'ordre.
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

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

({ApiClient client, _StubAdapter adapter, AuthTokenStore tokens}) _setup(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  String? accessToken,
  String? refreshToken,
}) {
  final adapter = _StubAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'));
  dio.httpClientAdapter = adapter;
  final tokens = AuthTokenStore(_MemorySecureStore());
  if (accessToken != null) {
    tokens.setAccessToken(accessToken);
  }
  if (refreshToken != null) {
    tokens.writeRefreshToken(refreshToken);
  }
  return (
    client: ApiClient(dio: dio, tokens: tokens),
    adapter: adapter,
    tokens: tokens,
  );
}

const _organization = Organization(
  id: 'org-1',
  name: 'Banque Horizon',
  type: OrganizationType.bank,
);

const _agency = Agency(
  id: 'ag-1',
  name: 'Agence Centre',
  address: 'Avenue de la Paix',
  waitingCount: 4,
);

const _service = AgencyService(
  id: 'sv-1',
  name: 'Dépôt',
  waitingCount: 4,
);

Map<String, Object?> _ticketPayload({
  String status = 'waiting',
  int position = 3,
}) {
  return <String, Object?>{
    'id': 't-1',
    'number': 'A-003',
    'status': status,
    'priority': 'standard',
    'agency_id': 'ag-1',
    'service_id': 'sv-1',
    'qr_token': 'qr-abc',
    'position': position,
    'total_in_queue': 5,
    'estimated_wait_minutes': 12,
    'created_at': '2026-11-17T08:30:00Z',
    'organization_id': 'org-1',
    'organization_name': 'Banque Horizon',
    'agency_name': 'Agence Centre',
    'service_name': 'Dépôt',
  };
}

void main() {
  group('ApiTicketService', () {
    test('aucun ticket actif est un état normal, pas une erreur', () async {
      final setup = _setup(
        (_) async => _json({'success': true, 'data': null}),
        accessToken: 'jeton',
      );
      final service = ApiTicketService(client: setup.client);

      expect(await service.activeTicket(), isNull);
      expect(setup.adapter.requests.single.path, '/tickets/active');
      expect(
        setup.adapter.requests.single.headers['Authorization'],
        'Bearer jeton',
      );
    });

    test('le ticket actif porte ses noms, son jeton QR et son statut', () async {
      final setup = _setup(
        (_) async => _json({'success': true, 'data': _ticketPayload()}),
        accessToken: 'jeton',
      );
      final service = ApiTicketService(client: setup.client);

      final ticket = await service.activeTicket();

      expect(ticket, isNotNull);
      expect(ticket!.id, 't-1');
      expect(ticket.number, 'A-003');
      expect(ticket.position, 3);
      expect(ticket.estimatedMinutes, 12);
      // Sans ces noms, l'écran n'aurait que des UUID à afficher.
      expect(ticket.organizationName, 'Banque Horizon');
      expect(ticket.agencyName, 'Agence Centre');
      expect(ticket.serviceName, 'Dépôt');
      expect(ticket.qrToken, 'qr-abc');
      expect(ticket.served, isFalse);
    });

    test('un ticket clôturé est marqué servi', () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'data': _ticketPayload(status: 'done', position: 0),
        }),
        accessToken: 'jeton',
      );

      final ticket = await ApiTicketService(client: setup.client).activeTicket();

      // C'est ce drapeau qui autorise la prise d'un nouveau ticket.
      expect(ticket!.served, isTrue);
      // La position 0 n'est pas corrigée : le client n'est plus dans la file.
      expect(ticket.position, 0);
    });

    test('la création envoie le triplet et un identifiant d\'idempotence',
        () async {
      final setup = _setup(
        (options) async {
          if (options.method == 'POST') {
            return _json(_ticketPayload());
          }
          return _json({'success': true, 'data': null});
        },
        accessToken: 'jeton',
      );
      final service = ApiTicketService(client: setup.client);

      final ticket = await service.createTicket(
        organization: _organization,
        agency: _agency,
        service: _service,
      );

      final request = setup.adapter.requests.single;
      expect(request.path, '/tickets');
      final body = request.data as Map<String, Object?>;
      expect(body['agency_id'], 'ag-1');
      expect(body['service_id'], 'sv-1');
      // Rejouer la même requête doit renvoyer le même ticket, pas en créer un
      // second : le format est contraint par le serveur (8 à 64 caractères).
      final actionId = body['client_action_id'] as String;
      expect(actionId.length, inInclusiveRange(8, 64));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(actionId), isTrue);
      expect(ticket.number, 'A-003');
    });

    test('un 409 TICKET_ALREADY_ACTIVE renvoie le ticket existant', () async {
      final setup = _setup(
        (options) async {
          if (options.method == 'POST') {
            return _json(
              {
                'detail': {
                  'code': 'TICKET_ALREADY_ACTIVE',
                  'message': 'Vous avez déjà un ticket actif (A-003).',
                  'active_ticket_id': 't-1',
                  'active_ticket_number': 'A-003',
                },
              },
              status: 409,
            );
          }
          return _json({'success': true, 'data': _ticketPayload()});
        },
        accessToken: 'jeton',
      );
      final service = ApiTicketService(client: setup.client);

      // L'invariant métier ne doit pas arriver à l'écran comme une panne : le
      // client doit voir SON ticket, pas un message d'erreur.
      await expectLater(
        service.createTicket(
          organization: _organization,
          agency: _agency,
          service: _service,
        ),
        throwsA(
          isA<TicketAlreadyActiveException>().having(
            (error) => error.existingTicket.number,
            'ticket existant',
            'A-003',
          ),
        ),
      );
    });

    test('l\'annulation relit le ticket actif puis le supprime', () async {
      final setup = _setup(
        (options) async {
          if (options.method == 'DELETE') {
            return _json({'success': true});
          }
          return _json({'success': true, 'data': _ticketPayload()});
        },
        accessToken: 'jeton',
      );

      await ApiTicketService(client: setup.client).cancelTicket();

      expect(
        setup.adapter.requests.map((r) => '${r.method} ${r.path}').toList(),
        ['GET /tickets/active', 'DELETE /tickets/t-1'],
      );
    });

    test('sans ticket actif, l\'annulation ne supprime rien', () async {
      final setup = _setup(
        (_) async => _json({'success': true, 'data': null}),
        accessToken: 'jeton',
      );

      await ApiTicketService(client: setup.client).cancelTicket();

      expect(setup.adapter.requests, hasLength(1));
      expect(setup.adapter.requests.single.method, 'GET');
    });

    test('le client ne clôture jamais son propre ticket', () async {
      final setup = _setup(
        (_) async => _json(const <String, Object?>{}),
        accessToken: 'jeton',
      );

      const ticket = Ticket(
        id: 't-1',
        number: 'A-003',
        position: 3,
        estimatedMinutes: 12,
        organizationId: 'org-1',
        organizationName: 'Banque Horizon',
        agencyId: 'ag-1',
        agencyName: 'Agence Centre',
      );
      await ApiTicketService(client: setup.client).markServed(ticket);

      // Aucun appel : seul le guichet termine un service. Lever une erreur ici
      // ferait croire à un échec de synchronisation côté écran.
      expect(setup.adapter.requests, isEmpty);
    });
  });

  group('ApiAuthService', () {
    test('la connexion stocke les deux jetons et retourne le profil', () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'access_token': 'acces',
          'refresh_token': 'rafraichissement',
          'token_type': 'bearer',
          'user': {
            'id': 'u-1',
            'name': 'Jospin Kanani',
            'email': 'jospin@example.com',
            'phone': null,
            'role': 'CLIENT',
            'language': 'fr',
            'is_verified': true,
          },
        }),
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      final user = await service.login(
        email: 'jospin@example.com',
        password: 'motdepasse',
      );

      expect(user.id, 'u-1');
      expect(user.email, 'jospin@example.com');
      // `SUPER_ADMIN` → « Super admin » : le rôle est un libellé, pas un code.
      expect(user.role, 'Client');
      expect(setup.tokens.accessToken, 'acces');
      expect(await setup.tokens.readRefreshToken(), 'rafraichissement');

      final request = setup.adapter.requests.single;
      expect(request.path, '/auth/login');
      // Route publique : présenter un jeton expiré y déclencherait un
      // renouvellement inutile.
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('un mot de passe refusé devient InvalidCredentialsException', () async {
      final setup = _setup(
        (_) async => _json(
          {
            'detail': {
              'code': 'INVALID_CREDENTIALS',
              'message': 'Email ou mot de passe incorrect',
            },
          },
          status: 401,
        ),
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      await expectLater(
        service.login(email: 'a@b.cd', password: 'faux'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      // Un 401 sur une route publique ne doit pas tenter de renouvellement.
      expect(setup.adapter.requests, hasLength(1));
    });

    test('un compte désactivé n\'est pas un mauvais mot de passe', () async {
      final setup = _setup(
        (_) async => _json(
          {
            'detail': {
              'code': 'ACCOUNT_DISABLED',
              'message': 'Ce compte est désactivé',
            },
          },
          status: 403,
        ),
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      // Réessayer ne servirait à rien : l'écran doit le dire.
      await expectLater(
        service.login(email: 'a@b.cd', password: 'bon'),
        throwsA(isA<AccountDisabledException>()),
      );
    });

    test('une adresse déjà prise est distinguée d\'une panne', () async {
      final setup = _setup(
        (_) async => _json(
          {
            'detail': {
              'code': 'EMAIL_EXISTS',
              'message': 'Cet email est déjà utilisé',
            },
          },
          status: 409,
        ),
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      await expectLater(
        service.register(
          name: 'Jean Test',
          email: 'jean@example.com',
          password: 'motdepasse',
        ),
        throwsA(isA<EmailAlreadyTakenException>()),
      );
      // L'inscription par e-mail a sa propre route : la racine attend un
      // numéro de téléphone.
      expect(setup.adapter.requests.single.path, '/auth/register/email');
    });

    test('sans jeton, aucune requête n\'est tentée au démarrage', () async {
      final setup = _setup((_) async => _json(const <String, Object?>{}));
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      expect(await service.currentUser(), isNull);
      expect(setup.adapter.requests, isEmpty);
    });

    test('la déconnexion révoque la session puis efface les jetons', () async {
      final setup = _setup(
        (_) async => _json({'success': true}),
        accessToken: 'acces',
        refreshToken: 'rafraichissement',
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      await service.logout();

      expect(setup.adapter.requests.single.path, '/auth/logout');
      expect(setup.tokens.accessToken, isNull);
      expect(await setup.tokens.readRefreshToken(), isNull);
    });

    test('une panne serveur à la déconnexion n\'empêche pas de sortir',
        () async {
      final setup = _setup(
        (_) async => _json({'detail': 'boom'}, status: 500),
        accessToken: 'acces',
        refreshToken: 'rafraichissement',
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      await service.logout();

      // Bloquer la déconnexion parce que le serveur est tombé laisserait
      // l'utilisateur prisonnier d'une session qu'il veut fermer.
      expect(setup.tokens.accessToken, isNull);
    });

    test('le profil n\'envoie que le nom : le reste n\'est pas modifiable',
        () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'data': {
            'id': 'u-1',
            'name': 'Nouveau Nom',
            'email': 'jospin@example.com',
            'phone': null,
            'role': 'CLIENT',
            'language': 'fr',
            'is_verified': true,
          },
        }),
        accessToken: 'acces',
      );
      final service = ApiAuthService(
        client: setup.client,
        tokens: setup.tokens,
      );

      final updated = await service.updateProfile(
        name: 'Nouveau Nom',
        email: 'autre@example.com',
        phone: '+257 00000000',
      );

      final body = setup.adapter.requests.single.data as Map<String, Object?>;
      // Envoyer l'e-mail donnerait un succès pour un changement non effectué.
      expect(body, {'name': 'Nouveau Nom'});
      expect(updated.name, 'Nouveau Nom');
    });
  });

  group('ApiClient', () {
    test('renouvelle le jeton une fois sur 401 puis rejoue la requête',
        () async {
      var calls = 0;
      final setup = _setup(
        (options) async {
          if (options.path == '/auth/refresh') {
            return _json({
              'success': true,
              'access_token': 'acces-2',
              'refresh_token': 'rafraichissement-2',
            });
          }
          calls++;
          if (calls == 1) {
            return _json({'detail': 'expiré'}, status: 401);
          }
          return _json({'success': true, 'data': null});
        },
        accessToken: 'acces-1',
        refreshToken: 'rafraichissement-1',
      );

      final payload = await setup.client.get('/tickets/active');

      expect(payload['success'], isTrue);
      expect(setup.tokens.accessToken, 'acces-2');
      expect(await setup.tokens.readRefreshToken(), 'rafraichissement-2');
      expect(
        setup.adapter.requests.map((r) => r.path).toList(),
        ['/tickets/active', '/auth/refresh', '/tickets/active'],
      );
    });

    test('un renouvellement refusé efface la session', () async {
      final setup = _setup(
        (options) async {
          if (options.path == '/auth/refresh') {
            return _json({'detail': 'révoqué'}, status: 401);
          }
          return _json({'detail': 'expiré'}, status: 401);
        },
        accessToken: 'acces-1',
        refreshToken: 'rafraichissement-1',
      );

      await expectLater(
        setup.client.get('/tickets/active'),
        throwsA(isA<ApiException>()),
      );
      expect(setup.tokens.accessToken, isNull);
      expect(await setup.tokens.readRefreshToken(), isNull);
    });

    test('une panne réseau pendant le renouvellement ne déconnecte pas',
        () async {
      final setup = _setup(
        (options) async {
          if (options.path == '/auth/refresh') {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'coupure',
            );
          }
          return _json({'detail': 'expiré'}, status: 401);
        },
        accessToken: 'acces-1',
        refreshToken: 'rafraichissement-1',
      );

      await expectLater(
        setup.client.get('/tickets/active'),
        throwsA(isA<ApiException>()),
      );
      // Perdre son ticket hors ligne à cause d'une coupure de trois secondes
      // serait absurde : la session reste intacte.
      expect(await setup.tokens.readRefreshToken(), 'rafraichissement-1');
    });
  });

  group('ApiOrganizationRepository', () {
    test('traduit le secteur en catégorie d\'affichage', () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'data': [
            {'id': 'o1', 'name': 'Banque', 'sector': 'bank'},
            {'id': 'o2', 'name': 'Clinique', 'sector': 'health'},
            {'id': 'o3', 'name': 'Université', 'sector': 'education'},
          ],
        }),
      );

      final organizations =
          await ApiOrganizationRepository(client: setup.client)
              .fetchOrganizations();

      expect(
        organizations.map((organization) => organization.type).toList(),
        [OrganizationType.bank, OrganizationType.health, OrganizationType.other],
      );
      // Routes publiques : un visiteur sans compte doit pouvoir les appeler.
      expect(
        setup.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('les agences portent leur adresse et le monde en attente', () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'data': [
            {
              'id': 'ag-1',
              'name': 'Agence Centre',
              'address': 'Avenue de la Paix',
              'city': 'Bujumbura',
              'is_open': true,
              'waiting_count': 7,
            },
          ],
        }),
      );

      final agencies =
          await ApiOrganizationRepository(client: setup.client)
              .fetchAgencies('org-1');

      expect(setup.adapter.requests.single.path,
          '/public/organizations/org-1/branches');
      expect(agencies.single.waitingCount, 7);
      expect(agencies.single.address, 'Avenue de la Paix');
    });

    test('les services portent le monde en attente par service', () async {
      final setup = _setup(
        (_) async => _json({
          'success': true,
          'data': [
            {
              'id': 'sv-1',
              'name': 'Dépôt',
              'description': 'Compte courant, carte, crédit',
              'waiting_count': 12,
            },
          ],
        }),
      );

      final services =
          await ApiOrganizationRepository(client: setup.client).fetchServices(
        organizationId: 'org-1',
        agencyId: 'ag-1',
      );

      // Le service appartient à l'agence : l'URL ne prend pas l'organisation.
      expect(setup.adapter.requests.single.path, '/branches/ag-1/services');
      expect(services.single.waitingCount, 12);
      expect(services.single.description, 'Compte courant, carte, crédit');
    });
  });

  group('ticketFromBackend', () {
    test('refuse une charge sans identifiant plutôt que d\'inventer', () {
      expect(ticketFromBackend(null), isNull);
      expect(ticketFromBackend(const <String, Object?>{}), isNull);
      expect(
        ticketFromBackend(const <String, Object?>{'number': 'A-001'}),
        isNull,
      );
    });
  });
}
