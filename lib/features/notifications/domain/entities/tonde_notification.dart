/// Étapes de la vie d'un ticket qui méritent une notification.
///
/// La liste suit le document produit : les quatre premières étapes sont le
/// socle du MVP, les suivantes sont déjà modélisées parce que le flux temps
/// réel les expose (absence, reprise, fin de service).
enum TondeNotificationKind {
  /// Le ticket vient d'être créé et enregistré.
  ticketConfirmed,

  /// Il reste une dizaine de personnes devant le client.
  queueProgress,

  /// Le tour du client approche (environ trois personnes).
  turnApproaching,

  /// Le numéro est appelé au guichet.
  called,

  /// Rappel : le numéro est toujours appelé, le client ne s'est pas présenté.
  presentationReminder,

  /// L'agent a déclaré le client absent.
  absent,

  /// Le ticket a été réactivé après une absence.
  resumed,

  /// La prise en charge est terminée.
  served,
}

/// Notification destinée à l'usager, prête à être affichée.
///
/// L'objet est volontairement indépendant du système d'affichage : le même
/// message alimente la bannière du téléphone et l'historique dans
/// l'application, ce qui garantit qu'ils ne divergent jamais.
final class TondeNotification {
  const TondeNotification({
    required this.kind,
    required this.title,
    required this.body,
    required this.ticketNumber,
    required this.sentAt,
    this.urgent = false,
    this.read = false,
  });

  final TondeNotificationKind kind;
  final String title;
  final String body;

  /// Ticket concerné : sert à ne jamais mélanger deux files dans l'historique.
  final String ticketNumber;

  final DateTime sentAt;

  /// Vrai pour l'appel au guichet et le rappel : ces messages doivent
  /// interrompre l'utilisateur, les autres peuvent attendre.
  final bool urgent;

  /// Vrai une fois que l'usager a ouvert la notification dans l'application.
  ///
  /// Une alerte non lue se distingue visuellement et compte dans la pastille ;
  /// une alerte lue reste consultable mais ne réclame plus l'attention.
  final bool read;

  TondeNotification copyWith({bool? read}) {
    return TondeNotification(
      kind: kind,
      title: title,
      body: body,
      ticketNumber: ticketNumber,
      sentAt: sentAt,
      urgent: urgent,
      read: read ?? this.read,
    );
  }

  /// Clé d'unicité : une même étape ne se répète pas pour un même ticket.
  String get dedupKey => '${kind.name}:$ticketNumber';
}
