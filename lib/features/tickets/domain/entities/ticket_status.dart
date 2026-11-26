/// Statut d'un ticket, tel que le serveur en fait foi.
///
/// Le mobile ne décide jamais d'une transition : il lit `status` et l'affiche.
/// La machine à états vit dans le backend (`TicketStatus`, `app/models/
/// ticket.py`) et seules deux autorités la font avancer — le guichet
/// (appeler, servir, déclarer absent, terminer) et le client (annuler,
/// demander à revenir en file).
///
/// Ce type remplace le booléen `served` qui ne distinguait que « terminé » de
/// « tout le reste » : impossible d'y voir un ticket appelé, en cours de
/// service, absent avec une fenêtre de reprise, transféré ou incomplet.
enum TicketStatus {
  /// En attente dans la file.
  waiting,

  /// Appelé par le guichetier, pas encore présenté.
  called,

  /// En cours de prise en charge au guichet.
  serving,

  /// Client non présent après le délai de présentation.
  absent,

  /// Transféré vers un autre guichet ou service : le ticket est actif et sera
  /// rappelé, mais il n'occupe plus la file d'origine.
  transferred,

  /// Service interrompu sans être finalisé : l'agent peut remettre en file.
  incomplete,

  /// Service rendu.
  done,

  /// Annulé par le client, ou fenêtre de reprise dépassée.
  cancelled;

  /// Valeur du contrat HTTP et WebSocket.
  ///
  /// Identique au nom du membre : le backend sérialise `TicketStatus` en
  /// minuscules (`waiting`, `called`…). Une divergence ici ne se verrait pas
  /// en test — elle rendrait simplement tout ticket « en attente ».
  String get wire => name;

  /// Vrai quand le ticket ne bloque plus la prise d'un nouveau.
  ///
  /// Seuls [done] et [cancelled] libèrent le client. [absent] n'en fait pas
  /// partie, et c'est volontaire : le serveur garde le ticket actif pendant la
  /// fenêtre de reprise, donc un client absent qui revient ne doit pas s'être
  /// vu attribuer un second rang entre-temps.
  bool get isClosed => this == done || this == cancelled;

  /// Vrai quand le client est attendu (ou déjà pris en charge) au guichet.
  bool get isAtCounter => this == called || this == serving;

  /// Vrai quand le ticket attend encore son tour dans une file.
  bool get isQueued =>
      this == waiting || this == transferred || this == incomplete;

  /// Vrai quand le client peut demander à revenir en file après une absence.
  bool get canResume => this == absent;

  /// Convertit la valeur brute du contrat.
  ///
  /// Les graphies historiques restent tolérées : un cache écrit par une
  /// version antérieure, ou un serveur plus ancien, ne doit pas faire
  /// disparaître un ticket de l'écran.
  static TicketStatus fromWire(Object? raw) {
    final value = raw?.toString().toLowerCase().trim();
    return switch (value) {
      'waiting' || 'queued' => waiting,
      'called' || 'calling' || 'now_calling' => called,
      'serving' || 'in_service' || 'in_progress' => serving,
      'absent' || 'no_show' || 'missed' => absent,
      'transferred' => transferred,
      'incomplete' => incomplete,
      'done' || 'completed' => done,
      // `expired` n'est pas un statut du backend : une fenêtre de reprise
      // dépassée se termine en `cancelled`. Le traduire ainsi garde un cache
      // ancien cohérent au lieu de le faire retomber en « en attente ».
      'cancelled' || 'canceled' || 'expired' => cancelled,
      // Valeur inconnue : on la traite comme « en attente ». Bloquer le client
      // à tort se répare (il annule) ; le libérer à tort créerait un doublon
      // de ticket, que le serveur refuserait ensuite.
      _ => waiting,
    };
  }
}
