import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/core/security/secure_key_value_store.dart';
import 'package:tonde/features/notifications/data/push_registrar.dart';
import 'package:tonde/features/notifications/data/push_service.dart';

/// Adaptateur HTTP piloté par le test : aucune socket n'est ouverte.
final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
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

ResponseBody _ok() => ResponseBody.fromString(
  jsonEncode(<String, Object?>{'success': true}),
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

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

/// Service push pilotable : jeton courant et renouvellements à la demande.
final class _FakePushService implements PushService {
  _FakePushService({this.current});

  String? current;
  int deleteCalls = 0;
  final _refreshes = StreamController<String?>.broadcast();

  @override
  Future<bool> initialize() async => true;

  @override
  Future<String?> token() async => current;

  @override
  Stream<String?> get tokenRefreshes => _refreshes.stream;

  @override
  Future<void> deleteToken() async {
    deleteCalls++;
    current = null;
  }

  @override
  Stream<PushTap> get taps => const Stream<PushTap>.empty();

  @override
  Future<PushTap?> initialTap() async => null;

  void refresh(String? token) {
    current = token;
    _refreshes.add(token);
  }
}

({PushRegistrar registrar, _StubAdapter adapter, _FakePushService push}) _build({
  String? token = 'jeton-abc',
  Future<ResponseBody> Function(RequestOptions options)? handler,
}) {
  final adapter = _StubAdapter(handler ?? (_) async => _ok());
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'));
  dio.httpClientAdapter = adapter;
  final tokens = AuthTokenStore(_MemorySecureStore())
    ..setAccessToken('acces');
  final push = _FakePushService(current: token);
  return (
    registrar: PushRegistrar(
      service: push,
      client: ApiClient(dio: dio, tokens: tokens),
    ),
    adapter: adapter,
    push: push,
  );
}

void main() {
  group('PushRegistrar', () {
    test('enregistre le jeton de l’appareil auprès du serveur', () async {
      final harness = _build();

      await harness.registrar.register();

      final request = harness.adapter.requests.single;
      expect(request.path, PushRegistrar.path);
      expect(request.method, 'PUT');
      // Le corps porte aussi la plateforme et la version : on vérifie le
      // jeton, pas la forme exacte de l'enveloppe.
      expect(request.data, containsPair('fcm_token', 'jeton-abc'));
    });

    test('sans jeton, n’appelle pas le serveur', () async {
      // Push indisponible (configuration Firebase absente, Play Services
      // manquant) : il n'y a rien à enregistrer, et un appel à vide créerait
      // une erreur inutile dans les journaux du serveur.
      final harness = _build(token: null);

      await harness.registrar.register();

      expect(harness.adapter.requests, isEmpty);
    });

    test('ne renvoie pas deux fois le même jeton', () async {
      final harness = _build();

      await harness.registrar.register();
      await harness.registrar.register();

      // Un second démarrage ne doit pas réécrire la même valeur en base.
      expect(harness.adapter.requests, hasLength(1));
    });

    test('un jeton renouvelé est réenregistré', () async {
      final harness = _build();
      await harness.registrar.register();

      harness.push.refresh('jeton-nouveau');
      await pumpEventQueue();

      expect(harness.adapter.requests, hasLength(2));
      expect(
        harness.adapter.requests.last.data,
        containsPair('fcm_token', 'jeton-nouveau'),
      );
    });

    test('la déconnexion efface le jeton côté serveur et sur l’appareil', () async {
      final harness = _build();
      await harness.registrar.register();

      await harness.registrar.unregister();

      // L'ordre compte : le serveur d'abord, tant que la session est encore
      // valide — sinon l'appareil garderait le jeton d'un compte fermé.
      // `device_token` désigne l'appareil à retirer : sans lui, un compte à
      // deux téléphones verrait les deux se déconnecter.
      expect(
        harness.adapter.requests.last.data,
        allOf(
          containsPair('fcm_token', null),
          containsPair('device_token', 'jeton-abc'),
        ),
      );
      expect(harness.push.deleteCalls, 1);
    });

    test('un échec réseau n’interrompt pas la connexion, et se rejoue', () async {
      var failures = 1;
      final harness = _build(
        handler: (options) async {
          if (failures-- > 0) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'réseau coupé',
            );
          }
          return _ok();
        },
      );

      // Ne doit pas lever : l'utilisateur entre dans l'application même si le
      // serveur est injoignable à cet instant.
      await harness.registrar.register();
      expect(harness.adapter.requests, hasLength(1));

      // Le jeton n'a pas été retenu comme envoyé : le prochain essai repart.
      await harness.registrar.register();
      expect(harness.adapter.requests, hasLength(2));
    });

    test('un appui sans ticket est ignoré', () {
      // Le payload peut ne pas désigner de ticket (message de service) :
      // ouvrir un écran au hasard serait pire que ne rien faire.
      expect(PushTap.fromData(const <String, dynamic>{}), isNull);
      expect(PushTap.fromData(const <String, dynamic>{'ticket_id': ''}), isNull);
      expect(
        PushTap.fromData(const <String, dynamic>{'ticket_id': 't-9'}),
        const PushTap(ticketId: 't-9'),
      );
    });
  });
}
