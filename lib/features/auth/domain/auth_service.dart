import 'package:tonde/features/auth/domain/user.dart';

/// Accès à la session : connexion, inscription, déconnexion.
///
/// L'identifiant de connexion est l'**e-mail** : c'est ce que le backend
/// accepte (`POST /auth/login`), et c'est la seule adresse que le compte porte
/// de façon certaine. Le mock de démonstration suit le même contrat pour que
/// les écrans et les tests ne dépendent pas du mode d'exécution.
abstract interface class AuthService {
  /// Retourne l'utilisateur connecté, ou null si personne n'est connecté.
  ///
  /// En mode backend, la session est restaurée depuis le refresh token : un
  /// utilisateur qui rouvre l'application n'a pas à ressaisir son mot de passe.
  Future<User?> currentUser();

  /// Authentifie [email] avec [password].
  ///
  /// Lève [InvalidCredentialsException] si les identifiants sont refusés.
  Future<User> login({required String email, required String password});

  /// Crée un compte et connecte l'utilisateur.
  ///
  /// Lève [EmailAlreadyTakenException] si l'adresse est déjà utilisée.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  /// Met à jour les informations du profil de l'utilisateur connecté.
  ///
  /// Renvoie le profil mis à jour. Les champs non fournis sont conservés.
  /// Lève [NotAuthenticatedException] si aucun utilisateur n'est connecté.
  ///
  /// Tous les champs restent dans la signature parce que l'écran de profil les
  /// présente, mais le backend ne sait aujourd'hui modifier que le nom : les
  /// implémentations qui parlent au serveur n'envoient que celui-ci et
  /// renvoient le profil tel que le serveur le voit.
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

/// Levée quand le compte existe mais a été désactivé par un administrateur.
///
/// Distincte de [InvalidCredentialsException] : réessayer ne servira à rien, et
/// un message « mot de passe incorrect » enverrait l'utilisateur réinitialiser
/// un mot de passe qui n'a aucun problème.
final class AccountDisabledException implements Exception {
  const AccountDisabledException();
}

/// Levée quand le compte est temporairement bloqué après trop d'échecs.
///
/// Le serveur bloque pour une durée limitée : l'écran doit dire d'attendre, pas
/// de vérifier ses identifiants.
final class AccountLockedException implements Exception {
  const AccountLockedException();
}

/// Levée quand l'adresse e-mail demandée est déjà utilisée.
final class EmailAlreadyTakenException implements Exception {
  const EmailAlreadyTakenException();
}

/// Levée quand une action requiert une session active.
final class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
}
