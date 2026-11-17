/// Utilisateur connecté à l'application.
///
/// Le backend identifie un compte par son **e-mail** (ou son téléphone pour
/// l'inscription par OTP) : il n'existe pas de « nom d'utilisateur » côté
/// serveur. Le mobile portait un champ `username` obligatoire, ce qui obligeait
/// à inventer une valeur à l'inscription et rendait le profil incohérent avec la
/// base. L'identité stable est désormais [id] — fourni par le serveur — et
/// [email] / [phone] sont les identifiants de connexion.
final class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.organization,
    this.createdAt,
  });

  /// Identifiant serveur. Stable : il ne change ni au renommage ni au
  /// changement d'e-mail, et c'est lui qui rattache les tickets au compte.
  final String id;

  /// Nom complet affiché à l'utilisateur.
  final String name;

  /// Adresse e-mail, identifiant de connexion d'un compte créé par e-mail.
  final String? email;

  /// Numéro de téléphone, identifiant de connexion d'un compte créé par OTP.
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
    String? id,
    String? name,
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
      id: id ?? this.id,
      name: name ?? this.name,
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
