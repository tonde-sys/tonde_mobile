/// Service proposé par une agence (guichet thématique).
///
/// Un ticket porte toujours un service : c'est lui qui détermine la file dans
/// laquelle le client entre, donc sa position et son temps d'attente.
final class AgencyService {
  const AgencyService({
    required this.id,
    required this.name,
    required this.waitingCount,
    this.description = '',
  });

  final String id;
  final String name;

  /// Précision affichée sous le nom (« Compte courant, carte, crédit »).
  final String description;

  /// Nombre de personnes déjà en file pour ce service.
  final int waitingCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AgencyService &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.waitingCount == waitingCount;
  }

  @override
  int get hashCode => Object.hash(id, name, description, waitingCount);
}
