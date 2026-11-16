/// Chemins de navigation de l'application.
abstract final class AppRoutes {
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
