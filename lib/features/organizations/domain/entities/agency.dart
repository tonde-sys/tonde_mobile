/// Agence (point de service) d'une organisation.
final class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.address,
    required this.waitingCount,
  });

  final String id;
  final String name;
  final String address;

  /// Nombre de personnes ayant déjà pris un ticket (fourni par le mock en
  /// démo ; viendra du backend réel dès que le contrat sera disponible).
  final int waitingCount;
}
