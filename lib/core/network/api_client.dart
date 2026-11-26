import 'package:dio/dio.dart';
import 'package:tonde/core/errors/api_error_mapper.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/security/auth_token_store.dart';

/// Point d'entrée HTTP unique vers le backend.
///
/// Trois responsabilités, et trois seulement :
///   1. joindre le jeton d'accès à chaque appel authentifié ;
///   2. renouveler la session **une fois** sur 401, puis rejouer la requête ;
///   3. traduire les erreurs Dio en erreurs applicatives typées.
///
/// Le renouvellement est fait ici plutôt que dans un intercepteur Dio : la
/// logique « 401 → refresh → rejeu » doit être testable sans monter de pile
/// HTTP, et un intercepteur qui rejoue une requête est le genre de code qu'on
/// ne peut plus défaire ensuite (il s'applique aussi aux appels de refresh, aux
/// téléversements, aux flux…).
///
/// Toutes les réponses attendues sont des objets JSON. Un corps vide est
/// traité comme un objet vide : une route qui répond 204 n'est pas une erreur.
final class ApiClient {
  ApiClient({required Dio dio, required AuthTokenStore tokens})
    : _dio = dio,
      _tokens = tokens;

  final Dio _dio;
  final AuthTokenStore _tokens;

  /// Renouvellement en cours, partagé par les appels concurrents.
  ///
  /// Sans ce partage, cinq requêtes qui reçoivent un 401 en même temps
  /// déclencheraient cinq rotations de refresh token ; le backend révoque
  /// l'ancien à chaque rotation, donc quatre d'entre elles échoueraient et
  /// déconnecteraient l'utilisateur.
  Future<bool>? _refreshing;

  /// Jeton d'accès courant, exposé pour l'URL du WebSocket.
  String? get accessToken => _tokens.accessToken;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) {
    return _execute(
      (headers) => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      ),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _execute(
      (headers) => _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _execute(
      (headers) => _dio.patch<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
      authenticated: authenticated,
    );
  }

  /// `PUT` idempotent.
  ///
  /// Distinct de [patch] parce que le serveur l'exige : `PUT /auth/me/fcm-token`
  /// remplace la valeur entière, et rejouer l'appel après une coupure réseau
  /// doit donner le même résultat — ce que `PATCH` ne garantit pas.
  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _execute(
      (headers) => _dio.put<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) {
    return _execute(
      (headers) => _dio.delete<dynamic>(
        path,
        options: Options(headers: headers),
      ),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _execute(
    Future<Response<dynamic>> Function(Map<String, String> headers) send, {
    required bool authenticated,
    bool retried = false,
  }) async {
    final headers = <String, String>{};
    final token = authenticated ? _tokens.accessToken : null;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await send(headers);
      return _asMap(response.data);
    } on DioException catch (error) {
      // On ne renouvelle que si un jeton était réellement présenté : un 401 sur
      // une route publique (connexion refusée) n'a rien à rafraîchir, et le
      // faire transformerait « mot de passe incorrect » en « session expirée ».
      final canRefresh =
          authenticated && !retried && error.response?.statusCode == 401;
      if (canRefresh && await _refresh()) {
        return _execute(send, authenticated: authenticated, retried: true);
      }
      throw mapDioException(error);
    }
  }

  /// Renouvelle le jeton d'accès. Retourne false si la session est perdue.
  Future<bool> _refresh() {
    final inFlight = _refreshing;
    if (inFlight != null) {
      return inFlight;
    }
    final attempt = _performRefresh();
    _refreshing = attempt;
    return attempt.whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final document = _asMap(response.data);
      final access = document['access_token'];
      if (access is! String || access.isEmpty) {
        return false;
      }
      _tokens.setAccessToken(access);
      final rotated = document['refresh_token'];
      if (rotated is String && rotated.isNotEmpty) {
        await _tokens.writeRefreshToken(rotated);
      }
      return true;
    } on DioException catch (error) {
      // On n'efface la session que si le serveur a RÉPONDU qu'elle est morte.
      // Un échec réseau pendant le renouvellement ne doit pas déconnecter :
      // l'utilisateur perdrait son ticket hors ligne à cause d'une coupure de
      // quelques secondes.
      final status = error.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _tokens.clear();
      }
      return false;
    } on Object {
      return false;
    }
  }

  Map<String, dynamic> _asMap(Object? body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    if (body == null) {
      return <String, dynamic>{};
    }
    throw UnexpectedException(
      message: 'Réponse JSON attendue, reçu ${body.runtimeType}.',
    );
  }
}
