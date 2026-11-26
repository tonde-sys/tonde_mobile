/// Erreurs applicatives exposées au reste de l'application.
///
/// Les messages sont destinés aux développeurs et aux logs ; ils ne doivent
/// jamais être affichés tels quels à l'utilisateur.
sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Aucune connexion réseau utilisable.
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Connexion réseau indisponible.',
    super.cause,
  });
}

/// Le serveur n'a pas répondu dans les délais.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({
    super.message = 'Le serveur ne répond pas dans les délais.',
    super.cause,
  });
}

/// La négociation TLS a échoué ; la validation n'est jamais désactivée.
final class SecureConnectionException extends AppException {
  const SecureConnectionException({
    super.message = 'Connexion sécurisée impossible (TLS).',
    super.cause,
  });
}

/// La requête a été annulée avant son achèvement.
final class RequestCancelledException extends AppException {
  const RequestCancelledException({
    super.message = 'Requête annulée.',
    super.cause,
  });
}

/// Le backend a répondu avec un statut hors du comportement attendu.
///
/// [code] est le code métier du serveur (`TICKET_ALREADY_ACTIVE`,
/// `GRACE_PERIOD_NOT_ELAPSED`, `EMAIL_EXISTS`…). Sans lui, l'application ne
/// pouvait distinguer « votre ticket est déjà actif » de « le serveur a
/// échoué » : les deux arrivaient en 4xx avec un message générique, et l'écran
/// affichait une panne là où le serveur donnait une consigne.
final class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    this.code,
    this.serverMessage,
    this.retryAfterSeconds,
    super.message = 'Réponse du serveur inattendue.',
    super.cause,
  });

  final int statusCode;

  /// Code métier renvoyé par le serveur, s'il en fournit un.
  final String? code;

  /// Message du serveur. Destiné à l'écran SEULEMENT s'il a été traduit par
  /// l'appelant : le backend répond en français, l'application parle trois
  /// langues. Utilisez [code] pour choisir un libellé traduit.
  final String? serverMessage;

  /// Délai d'attente imposé par le serveur, en secondes (429 surtout).
  ///
  /// Le backend le transmet dans le corps (`retry_after`, `retry_after_seconds`)
  /// et dans l'en-tête `Retry-After`. Sans lui, l'écran ne pouvait dire que
  /// « trop de tentatives » : l'utilisateur réessayait aussitôt, échouait, et
  /// concluait que l'application était cassée.
  final int? retryAfterSeconds;

  /// Vrai quand le serveur refuse la session (jeton absent, invalide, expiré).
  bool get isUnauthenticated => statusCode == 401;
}

/// Erreur non classifiée.
final class UnexpectedException extends AppException {
  const UnexpectedException({
    super.message = 'Erreur inattendue.',
    super.cause,
  });
}

/// L'intégration est bloquée en attendant un contrat backend documenté.
final class IntegrationBlockedException extends AppException {
  const IntegrationBlockedException({
    super.message = 'Intégration bloquée : contrat backend non fourni.',
    super.cause,
  });
}
