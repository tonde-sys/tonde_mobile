/// Catégorie d'organisation affichée à l'utilisateur.
enum OrganizationType { bank, health }

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
