/// Ticket actif de l'utilisateur.
final class Ticket {
  const Ticket({
    required this.number,
    required this.position,
    required this.estimatedMinutes,
    required this.organizationId,
    required this.organizationName,
    required this.agencyId,
    required this.agencyName,
    this.id,
    this.qrToken,
    this.serviceId,
    this.serviceName,
    this.pendingSync = false,
    this.served = false,
    this.issuedAt,
  });

  /// Identifiant serveur du ticket.
  ///
  /// Nul tant que le ticket n'a pas été confirmé (prise hors ligne). C'est lui
  /// qui ouvre le suivi temps réel : `GET /tickets/{id}` et le WebSocket
  /// `/tickets/ws/queue/{id}` prennent un identifiant, pas un numéro — le
  /// numéro n'est unique que dans un service, et deux agences peuvent émettre
  /// « A-001 » le même jour.
  final String? id;

  final String number;
  final int position;

  /// Jeton du QR code, signé par le serveur (`qr_token`).
  ///
  /// Vient du ticket et non du flux WebSocket : les messages de file ne le
  /// transportent pas, et un écran de suivi sans QR obligerait le client à
  /// rouvrir son ticket pour le présenter au guichet.
  final String? qrToken;

  /// Date et heure d'émission du ticket.
  ///
  /// Nullable : les tickets déjà présents dans le cache avant l'ajout de ce
  /// champ n'ont pas d'horodatage, et l'écran de détail masque simplement la
  /// ligne plutôt que d'afficher une date inventée.
  final DateTime? issuedAt;

  /// Temps d'attente estimé en minutes, calculé par le serveur.
  /// Fourni par le mock en démo ; viendra du backend réel dès que le
  /// contrat sera disponible.
  final int? estimatedMinutes;
  final String organizationId;
  final String organizationName;
  final String agencyId;
  final String agencyName;

  /// Service demandé au moment de la prise du ticket.
  ///
  /// Nullable : les tickets mis en cache avant l'introduction du choix du
  /// service n'en portent pas. L'écran masque alors simplement la ligne.
  final String? serviceId;
  final String? serviceName;

  /// Vrai quand le ticket a été pris sans réseau et n'a pas encore été
  /// confirmé par le serveur.
  ///
  /// Un ticket en attente porte un numéro local préfixé `L-` : il ne doit
  /// jamais être présenté au guichet, et son suivi temps réel n'a pas de sens
  /// tant que la synchronisation n'a pas eu lieu.
  final bool pendingSync;

  /// Vrai quand le client est déjà passé au guichet (pris en charge ou
  /// absent). Un ticket servi ne bloque plus la prise d'un nouveau ticket :
  /// l'invariant « un seul ticket actif » ne concerne que les tickets encore
  /// en attente.
  final bool served;

  Ticket copyWith({bool? served, String? id, String? qrToken}) {
    return Ticket(
      id: id ?? this.id,
      number: number,
      position: position,
      estimatedMinutes: estimatedMinutes,
      organizationId: organizationId,
      organizationName: organizationName,
      agencyId: agencyId,
      agencyName: agencyName,
      serviceId: serviceId,
      serviceName: serviceName,
      pendingSync: pendingSync,
      served: served ?? this.served,
      issuedAt: issuedAt,
      qrToken: qrToken ?? this.qrToken,
    );
  }

  // Égalité par valeur : le ticket sert de clé de famille Riverpod pour le
  // suivi temps réel, et deux reconstructions du même ticket ne doivent pas
  // rouvrir une connexion.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Ticket &&
        other.id == id &&
        other.number == number &&
        other.position == position &&
        other.estimatedMinutes == estimatedMinutes &&
        other.organizationId == organizationId &&
        other.organizationName == organizationName &&
        other.agencyId == agencyId &&
        other.agencyName == agencyName &&
        other.serviceId == serviceId &&
        other.serviceName == serviceName &&
        other.pendingSync == pendingSync &&
        other.served == served &&
        other.issuedAt == issuedAt &&
        other.qrToken == qrToken;
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    position,
    estimatedMinutes,
    organizationId,
    organizationName,
    agencyId,
    agencyName,
    serviceId,
    serviceName,
    pendingSync,
    served,
    issuedAt,
    qrToken,
  );
}
