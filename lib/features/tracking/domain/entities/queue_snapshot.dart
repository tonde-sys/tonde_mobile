/// Statut d'un ticket dans la file d'attente, tel que rapporté par le backend.
///
/// Le mobile n'arbitre jamais ce statut : il affiche ce que le serveur envoie.
enum QueueStatus {
  /// Le ticket attend son tour.
  waiting,

  /// Le numéro vient d'être appelé au guichet.
  called,

  /// Le client est en cours de prise en charge.
  inService,

  /// Le client ne s'est pas présenté.
  absent;

  /// Convertit la valeur brute du flux en statut connu.
  ///
  /// Le contrat n'étant pas encore figé, plusieurs graphies sont tolérées ;
  /// toute valeur inconnue retombe sur [QueueStatus.waiting] plutôt que de
  /// faire échouer l'affichage.
  static QueueStatus fromWire(Object? raw) {
    return switch (raw) {
      'called' || 'calling' || 'now_calling' => QueueStatus.called,
      'in_service' || 'serving' || 'in_progress' => QueueStatus.inService,
      'absent' || 'no_show' || 'missed' => QueueStatus.absent,
      _ => QueueStatus.waiting,
    };
  }
}

/// Photo instantanée de la position du client dans la file.
///
/// Chaque message du flux WebSocket (ou chaque réponse du polling de secours)
/// produit un [QueueSnapshot] complet : le mobile remplace l'état précédent au
/// lieu de le recomposer, ce qui évite toute dérive entre deux sources.
final class QueueSnapshot {
  const QueueSnapshot({
    required this.ticketNumber,
    required this.position,
    required this.estimatedMinutes,
    required this.status,
    required this.updatedAt,
    this.calledNumber,
    this.counterLabel,
    this.qrPayload,
  });

  /// Lit un message du flux.
  ///
  /// Les clés sont tolérantes tant que le contrat backend n'est pas figé ;
  /// les champs absents prennent une valeur neutre plutôt que de lever.
  factory QueueSnapshot.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final position = _asInt(json['position'] ?? json['rank'] ?? json['place']);
    final called = json['called_number'] ?? json['current_number'];
    final counter = json['counter'] ?? json['counter_label'] ?? json['desk'];
    final qr = json['qr_payload'] ?? json['qr'];
    return QueueSnapshot(
      ticketNumber: (json['ticket_number'] ?? json['number'] ?? '').toString(),
      position: position == null || position < 1 ? 1 : position,
      estimatedMinutes:
          _asInt(json['estimated_minutes'] ?? json['eta_minutes']) ?? 0,
      status: QueueStatus.fromWire(json['status']),
      updatedAt: now ?? DateTime.now(),
      calledNumber: called?.toString(),
      counterLabel: counter?.toString(),
      qrPayload: qr?.toString(),
    );
  }

  final String ticketNumber;

  /// Rang du client dans la file, à partir de 1.
  final int position;

  /// Temps d'attente estimé, calculé par le serveur.
  final int estimatedMinutes;

  final QueueStatus status;

  final DateTime updatedAt;

  /// Numéro actuellement appelé au guichet, si le backend le fournit.
  final String? calledNumber;

  /// Libellé du guichet, par exemple « Guichet 3 ».
  final String? counterLabel;

  /// Charge utile du QR code, signée par le backend.
  final String? qrPayload;

  /// Nombre de personnes devant le client.
  int get peopleAhead => position > 1 ? position - 1 : 0;

  /// Vrai quand la file n'attend plus rien du client.
  bool get isTerminal =>
      status == QueueStatus.inService || status == QueueStatus.absent;

  QueueSnapshot copyWith({
    int? position,
    int? estimatedMinutes,
    QueueStatus? status,
    DateTime? updatedAt,
    String? calledNumber,
    String? counterLabel,
    String? qrPayload,
  }) {
    return QueueSnapshot(
      ticketNumber: ticketNumber,
      position: position ?? this.position,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      calledNumber: calledNumber ?? this.calledNumber,
      counterLabel: counterLabel ?? this.counterLabel,
      qrPayload: qrPayload ?? this.qrPayload,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
