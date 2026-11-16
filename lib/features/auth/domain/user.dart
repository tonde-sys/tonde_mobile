/// Utilisateur connecté à l'application.
final class User {
  const User({
    required this.name,
    required this.username,
    this.email,
    this.phone,
    this.role,
    this.organization,
    this.createdAt,
  });

  /// Nom complet affiché à l'utilisateur.
  final String name;

  /// Identifiant de connexion, normalisé en minuscules.
  final String username;

  /// Adresse e-mail de l'utilisateur.
  final String? email;

  /// Numéro de téléphone.
  final String? phone;

  /// Rôle dans l'organisation (ex. Agent, Superviseur, Client).
  final String? role;

  /// Organisation / agence de rattachement.
  final String? organization;

  /// Date de création du compte (ISO 8601).
  final String? createdAt;

  /// Retourne une copie avec les champs mis à jour.
  ///
  /// Les paramètres à `null` conservent la valeur existante ; pour effacer
  /// un champ, utilisez [clear] ou transmettez une chaîne vide.
  User copyWith({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? role,
    String? organization,
    String? createdAt,
    bool clearEmail = false,
    bool clearPhone = false,
    bool clearRole = false,
    bool clearOrganization = false,
  }) {
    return User(
      name: name ?? this.name,
      username: username ?? this.username,
      email: clearEmail ? null : (email ?? this.email),
      phone: clearPhone ? null : (phone ?? this.phone),
      role: clearRole ? null : (role ?? this.role),
      organization: clearOrganization
          ? null
          : (organization ?? this.organization),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
