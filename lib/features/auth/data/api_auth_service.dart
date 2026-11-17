import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/core/security/auth_token_store.dart';
import 'package:tonde/features/auth/data/api_user_mapper.dart';
import 'package:tonde/features/auth/data/user_codec.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';

/// Service d'authentification adossé au backend.
///
/// Le serveur est la seule autorité sur la session : deux jetons, un accès
/// court et un rafraîchissement long, renouvelés par [ApiClient]. Ce service ne
/// décide jamais qu'une session est valide — il demande.
///
/// Le profil est mis en cache localement pour qu'une application rouverte sans
/// réseau affiche le tableau de bord au lieu de l'écran de connexion : c'est le
/// même compromis que pour les tickets, et la session reste invérifiable
/// jusqu'au premier appel réussi.
final class ApiAuthService implements AuthService {
  ApiAuthService({
    required ApiClient client,
    required AuthTokenStore tokens,
    LocalCache? cache,
  }) : _client = client,
       _tokens = tokens,
       _cache = cache;

  /// Clé de cache partagée avec le service de démonstration : basculer de l'un
  /// à l'autre ne doit pas déconnecter l'utilisateur.
  static const String sessionKey = 'session.user';

  final ApiClient _client;
  final AuthTokenStore _tokens;
  final LocalCache? _cache;

  User? _current;

  @override
  Future<User?> currentUser() async {
    // Aucun jeton d'aucune sorte : inutile d'appeler le serveur pour qu'il
    // réponde 401. C'est le cas au tout premier lancement.
    final hasSession =
        _tokens.accessToken != null ||
        (await _tokens.readRefreshToken()) != null;
    if (!hasSession) {
      return null;
    }
    try {
      final payload = await _client.get('/auth/me');
      final user = userFromTokenPayload(payload['data']);
      if (user != null) {
        await _writeSession(user);
        return user;
      }
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        // Session réellement refusée (le renouvellement a échoué) : jetons
        // morts, on nettoie plutôt que de garder un profil fantôme.
        await _tokens.clear();
        await _writeSession(null);
        return null;
      }
      // 5xx ou 403 : le serveur a répondu, mais pas « session invalide ».
      // Un profil en cache vaut mieux qu'un écran de connexion qui ferait
      // croire à une déconnexion.
      return _readSession();
    } on AppException {
      // Réseau injoignable : profil en cache, session intacte.
      return _readSession();
    }
    return _readSession();
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _client.post(
        '/auth/login',
        body: <String, Object?>{'email': email.trim(), 'password': password},
        authenticated: false,
      );
      return await _adoptSession(payload);
    } on ApiException catch (error) {
      if (error.code == 'INVALID_CREDENTIALS' || error.isUnauthenticated) {
        throw const InvalidCredentialsException();
      }
      if (error.code == 'ACCOUNT_DISABLED') {
        throw const AccountDisabledException();
      }
      if (error.code == 'ACCOUNT_LOCKED') {
        throw const AccountLockedException();
      }
      rethrow;
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _client.post(
        // `/register/email`, et non `/register` : la route par téléphone occupe
        // la racine et attend un numéro.
        '/auth/register/email',
        body: <String, Object?>{
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
        authenticated: false,
      );
      return await _adoptSession(payload);
    } on ApiException catch (error) {
      if (error.code == 'EMAIL_EXISTS') {
        throw const EmailAlreadyTakenException();
      }
      // `VALIDATION_ERROR` (mot de passe trop court, nom trop bref) remonte tel
      // quel : l'écran doit afficher la contrainte réelle, pas « adresse déjà
      // utilisée » qui enverrait l'utilisateur modifier le mauvais champ.
      rethrow;
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organization,
  }) async {
    // Le backend ne modifie que le nom (et la langue) : envoyer e-mail ou
    // téléphone serait ignoré en silence, et l'écran afficherait un succès
    // pour un changement qui n'a pas eu lieu.
    final body = <String, Object?>{};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }
    if (body.isEmpty) {
      // Rien à envoyer : on rend le profil connu. S'il est inconnu, c'est qu'on
      // n'est pas connecté — inutile d'interroger le serveur pour l'apprendre.
      final current = _current ?? await _readSession();
      if (current == null) {
        throw const NotAuthenticatedException();
      }
      return current;
    }
    // Avec un corps, le serveur est seul juge : il répond 401 si la session
    // n'est plus valide. Exiger un profil déjà en mémoire ferait échouer une
    // modification légitime après un simple redémarrage de l'application.
    final payload = await _client.patch('/auth/me', body: body);
    final updated = userFromTokenPayload(payload['data']);
    if (updated == null) {
      throw const UnexpectedException(
        message: 'Profil renvoyé illisible après mise à jour.',
      );
    }
    await _writeSession(updated);
    return updated;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        // Révoque la session côté serveur : sans cela le refresh token resterait
        // valide des semaines après une déconnexion, ce qui est exactement ce
        // qu'un utilisateur croit avoir annulé.
        await _client.post(
          '/auth/logout',
          body: <String, Object?>{'refresh_token': refreshToken},
          authenticated: false,
        );
      } on Object {
        // Serveur injoignable : on efface quand même localement. La session
        // expirera d'elle-même ; bloquer la déconnexion serait pire.
      }
    }
    await _tokens.clear();
    await _writeSession(null);
  }

  /// Enregistre les jetons renvoyés par le serveur et retourne le profil.
  Future<User> _adoptSession(Map<String, dynamic> payload) async {
    final access = payload['access_token'];
    final refresh = payload['refresh_token'];
    if (access is! String || access.isEmpty) {
      throw const UnexpectedException(
        message: 'Réponse d\'authentification sans jeton d\'accès.',
      );
    }
    _tokens.setAccessToken(access);
    if (refresh is String && refresh.isNotEmpty) {
      await _tokens.writeRefreshToken(refresh);
    }
    final user = userFromTokenPayload(payload['user']);
    if (user == null) {
      throw const UnexpectedException(
        message: 'Réponse d\'authentification sans profil exploitable.',
      );
    }
    await _writeSession(user);
    return user;
  }

  Future<User?> _readSession() async {
    final cache = _cache;
    if (cache == null) {
      return null;
    }
    final restored = userFromJson(await cache.read(sessionKey));
    _current = restored;
    return restored;
  }

  Future<void> _writeSession(User? user) async {
    _current = user;
    final cache = _cache;
    if (cache == null) {
      return;
    }
    await cache.write(sessionKey, user == null ? null : userToJson(user));
  }
}
