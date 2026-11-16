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
final class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    super.message = 'Réponse du serveur inattendue.',
    super.cause,
  });

  final int statusCode;
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
