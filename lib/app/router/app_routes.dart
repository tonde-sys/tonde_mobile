/// Chemins de navigation de l'application.
abstract final class AppRoutes {
  /// Écran d'attente affiché tant que la session n'est pas résolue.
  ///
  /// Il n'est visible qu'au tout premier lancement, ou lorsque la réponse du
  /// serveur tarde : c'est lui qui empêche l'écran de connexion d'apparaître
  /// puis de disparaître quand un utilisateur est déjà connecté.
  static const String startup = '/demarrage';

  static const String home = '/';
  static const String login = '/connexion';
  static const String register = '/inscription';
  static const String organizations = '/organizations';
  static const String organizationDetail = '/organizations/:id';

  /// Étape 1 : les services de l'agence choisie.
  static const String agencyServices =
      '/organizations/:organizationId/agencies/:agencyId';

  /// Étape 2 : confirmation de la prise de ticket pour un service donné.
  static const String agencyTicket =
      '/organizations/:organizationId/agencies/:agencyId/services/:serviceId';

  static const String foundation = '/socle';
  static const String profile = '/profil';
  static const String profileEdit = '/profil/modifier';
  static const String queueTracking = '/tickets/suivi';

  /// Formulaire de retour. La catégorie passe en paramètre de requête
  /// (`?categorie=bug`) plutôt qu'en `extra` : un lien partagé ou rouvert
  /// après redémarrage garde ainsi la bonne catégorie, alors que `extra` est
  /// perdu dès que la route est reconstruite.
  static const String feedbackNew = '/assistance/avis';

  /// Historique « Mes retours ».
  static const String myFeedback = '/assistance/mes-retours';

  /// Questions fréquentes du centre d'aide.
  static const String faq = '/assistance/faq';

  static String organizationDetailPath(String organizationId) =>
      '/organizations/$organizationId';

  static String agencyServicesPath({
    required String organizationId,
    required String agencyId,
  }) => '/organizations/$organizationId/agencies/$agencyId';

  static String agencyTicketPath({
    required String organizationId,
    required String agencyId,
    required String serviceId,
  }) => '/organizations/$organizationId/agencies/$agencyId/services/$serviceId';
}
