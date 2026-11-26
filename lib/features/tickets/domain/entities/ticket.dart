import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';

/// Ticket de l'utilisateur, tel que le serveur le décrit.
///
/// L'objet mêle deux natures de données, et la distinction compte :
///  * ce qui **identifie** le ticket et ne bouge plus — identifiant, numéro,
///    agence, service, QR. C'est ce que le flux de suivi utilise comme clé ;
///  * ce qui **décrit son état à un instant donné** — statut, position,
///    attente, guichet, fenêtre de reprise. Ces valeurs sont rafraîchies à
///    chaque réponse du serveur et à chaque événement temps réel.
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
    this.status = TicketStatus.waiting,
    this.issuedAt,
    this.counterLabel,
    this.totalInQueue,
    this.recoveryExpiresAt,
    this.missedCount = 0,
    this.queueDegraded = false,
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

  /// Temps d'attente estimé en minutes, calculé par le serveur (AWTE).
  ///
  /// Null quand aucune prévision fiable n'existe : l'écran affiche alors
  /// « Estimation en cours », jamais « 0 min ».
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

  /// État du ticket dans la machine à états du serveur.
  final TicketStatus status;

  /// Guichet qui a appelé le ticket, si le serveur le connaît.
  ///
  /// Vient de `counter_name` : sans lui, le client qui reçoit « votre tour »
  /// doit chercher son numéro sur tous les écrans de l'agence.
  final String? counterLabel;

  /// Nombre total de tickets dans la file au moment de la réponse.
  ///
  /// Distinct de [position] : la position dit « combien devant moi », ce
  /// total dit « combien dans la file ». Le widget d'accueil affiche les deux.
  final int? totalInQueue;

  /// Fin de la fenêtre pendant laquelle un client absent peut revenir en file.
  ///
  /// Valeur **serveur**, jamais recalculée : `called_at + 90 s` dépend de
  /// réglages qui changent, et un client qui se fie à un calcul local se
  /// présente après la fermeture de sa fenêtre.
  final DateTime? recoveryExpiresAt;

  /// Nombre d'absences déjà enregistrées pour ce ticket.
  final int missedCount;

  /// Vrai quand le ticket existe en base mais n'a pas pu rejoindre la file
  /// Redis : la position vaut alors 0 et n'a pas de sens à afficher.
  final bool queueDegraded;

  /// Vrai quand le ticket ne bloque plus la prise d'un nouveau.
  bool get isClosed => status.isClosed;

  /// Vrai quand le client est attendu, ou déjà pris en charge, au guichet.
  bool get isAtCounter => status.isAtCounter;

  /// Vrai quand le client peut encore demander à revenir en file.
  ///
  /// [now] est injectable pour que l'écran puisse recompter sans attendre un
  /// tick, et pour que les tests n'aient pas à attendre une vraie horloge.
  bool canResumeAt(DateTime now) {
    if (!status.canResume) {
      return false;
    }
    final deadline = recoveryExpiresAt;
    return deadline == null || deadline.isAfter(now);
  }

  /// Vrai quand le client peut demander à revenir en file, maintenant.
  bool get canResume => canResumeAt(DateTime.now());

  Ticket copyWith({
    String? id,
    String? qrToken,
    int? position,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
    bool? pendingSync,
    TicketStatus? status,
    String? counterLabel,
    int? totalInQueue,
    DateTime? recoveryExpiresAt,
    bool clearRecoveryExpiresAt = false,
    int? missedCount,
    bool? queueDegraded,
  }) {
    return Ticket(
      id: id ?? this.id,
      number: number,
      position: position ?? this.position,
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
      organizationId: organizationId,
      organizationName: organizationName,
      agencyId: agencyId,
      agencyName: agencyName,
      serviceId: serviceId,
      serviceName: serviceName,
      pendingSync: pendingSync ?? this.pendingSync,
      status: status ?? this.status,
      issuedAt: issuedAt,
      qrToken: qrToken ?? this.qrToken,
      counterLabel: counterLabel ?? this.counterLabel,
      totalInQueue: totalInQueue ?? this.totalInQueue,
      recoveryExpiresAt: clearRecoveryExpiresAt
          ? null
          : (recoveryExpiresAt ?? this.recoveryExpiresAt),
      missedCount: missedCount ?? this.missedCount,
      queueDegraded: queueDegraded ?? this.queueDegraded,
    );
  }

  // Égalité par valeur : le ticket sert d'état Riverpod, et deux réponses
  // identiques du serveur ne doivent pas provoquer de reconstruction.
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
        other.status == status &&
        other.issuedAt == issuedAt &&
        other.qrToken == qrToken &&
        other.counterLabel == counterLabel &&
        other.totalInQueue == totalInQueue &&
        other.recoveryExpiresAt == recoveryExpiresAt &&
        other.missedCount == missedCount &&
        other.queueDegraded == queueDegraded;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
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
    status,
    issuedAt,
    qrToken,
    counterLabel,
    totalInQueue,
    recoveryExpiresAt,
    missedCount,
    queueDegraded,
  ]);
}
