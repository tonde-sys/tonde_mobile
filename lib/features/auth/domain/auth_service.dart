import 'package:tonde/features/auth/domain/user.dart';

/// Accès à la session : connexion, inscription, déconnexion.
///
/// Dans l'application réelle, l'authentification est assurée par le backend
/// (tokens, expiration, révocation). Le mock reproduit une session simple en
/// mémoire pour la démo.
abstract interface class AuthService {
  /// Retourne l'utilisateur connecté, ou null si personne n'est connecté.
  Future<User?> currentUser();

  /// Authentifie [username] avec [password].
  ///
  /// Lève [InvalidCredentialsException] si les identifiants sont refusés.
  Future<User> login({required String username, required String password});

  /// Crée un compte et connecte l'utilisateur.
  ///
  /// Lève [UsernameAlreadyTakenException] si le nom d'utilisateur existe déjà.
  Future<User> register({
    required String name,
    required String username,
    required String password,
  });

  /// Met à jour les informations du profil de l'utilisateur connecté.
  ///
  /// Renvoie le profil mis à jour. Les champs non fournis sont conservés.
  /// Lève [NotAuthenticatedException] si aucun utilisateur n'est connecté.
  Future<User> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organization,
  });

  /// Déconnecte l'utilisateur courant.
  Future<void> logout();
}

/// Levée quand les identifiants de connexion sont refusés.
final class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

/// Levée quand le nom d'utilisateur demandé est déjà pris.
final class UsernameAlreadyTakenException implements Exception {
  const UsernameAlreadyTakenException();
}

/// Levée quand une action requiert une session active.
final class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
}
