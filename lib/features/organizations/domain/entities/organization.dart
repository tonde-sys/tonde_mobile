/// Catégorie d'organisation affichée à l'utilisateur.
///
/// [other] n'est pas décoratif : le backend expose un champ `sector` libre
/// (`String(50)`), et toute valeur non reconnue retombait sur « Banque ». Une
/// université ou une administration s'affichait donc comme une banque, avec
/// l'icône et le libellé correspondants.
enum OrganizationType {
  bank,
  health,
  other;

  /// Traduit le `sector` du backend en catégorie d'affichage.
  static OrganizationType fromSector(Object? sector) {
    return switch (sector) {
      'bank' => OrganizationType.bank,
      'health' => OrganizationType.health,
      _ => OrganizationType.other,
    };
  }
}

/// Organisation dont l'adhésion de l'utilisateur est confirmée.
///
/// Le backend ne retourne que les organisations auxquelles l'utilisateur est
/// effectivement inscrit (invariant produit) ; le mobile n'a donc pas à
/// filtrer localement.
///
/// Les canaux de support sont **optionnels et vides par défaut** : une
/// institution qui n'a rien renseigné ne doit pas produire de bouton mort.
/// Ils viennent du bloc `support` de `/public/organizations` (L6).
final class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.type,
    this.supportPhone = '',
    this.supportWhatsapp = '',
    this.supportEmail = '',
    this.supportHours = '',
  });

  final String id;
  final String name;
  final OrganizationType type;

  /// Numéro à appeler, chiffres seuls. Vide si non renseigné.
  final String supportPhone;

  /// Numéro WhatsApp, chiffres seuls. Vide si non renseigné.
  final String supportWhatsapp;

  final String supportEmail;

  /// Horaires en texte libre (« Lun–Ven 8h–16h », « 24/7 »).
  final String supportHours;

  /// Vrai dès qu'au moins un canal est utilisable.
  bool get hasSupportContact =>
      supportPhone.isNotEmpty ||
      supportWhatsapp.isNotEmpty ||
      supportEmail.isNotEmpty;
}
