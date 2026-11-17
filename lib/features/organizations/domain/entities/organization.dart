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
/// filtrer localement. Les champs supplémentaires seront ajoutés uniquement
/// selon le contrat backend.
final class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final OrganizationType type;
}
