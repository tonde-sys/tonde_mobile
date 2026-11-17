import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Message affichable pour un échec d'authentification.
///
/// Les deux écrans concernés affichaient auparavant un message unique
/// (« identifiants incorrects ») pour TOUTE erreur : un serveur injoignable, un
/// compte désactivé et un mot de passe faux se ressemblaient. L'utilisateur
/// changeait alors son mot de passe pour rien, ou réessayait indéfiniment une
/// connexion impossible.
///
/// Le message du serveur n'est utilisé qu'en dernier recours : le backend
/// répond en français, l'application parle trois langues.
String authErrorMessage(AppLocalizations l10n, Object? error) {
  return switch (error) {
    null => '',
    InvalidCredentialsException() => l10n.invalidCredentials,
    AccountDisabledException() => l10n.accountDisabled,
    AccountLockedException() => l10n.accountLocked,
    EmailAlreadyTakenException() => l10n.emailTaken,
    NetworkException() || RequestTimeoutException() => l10n.networkError,
    // Validation côté serveur (mot de passe trop court, nom trop bref) : le
    // message porte la contrainte exacte, la traduire ici la perdrait.
    ApiException(:final serverMessage?) => serverMessage,
    _ => l10n.authErrorGeneric,
  };
}
