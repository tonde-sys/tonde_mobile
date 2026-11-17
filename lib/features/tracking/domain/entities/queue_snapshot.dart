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
  absent,

  /// Le service est terminé ou le ticket annulé.
  ///
  /// Distinct de [inService] : le guichet a fini, le client n'est plus attendu.
  /// Sans cet état, un ticket clôturé retombait sur [waiting] — l'écran
  /// affichait « En attente » pour un service déjà rendu, et la surveillance de
  /// fin de prise en charge ne se déclenchait jamais, laissant le client bloqué
  /// sur un ticket qui ne comptait plus.
  done;

  /// Convertit la valeur brute du flux en statut connu.
  ///
  /// Le contrat est désormais figé (statuts en minuscules du backend), mais les
  /// graphies historiques restent tolérées ; toute valeur inconnue retombe sur
  /// [QueueStatus.waiting] plutôt que de faire échouer l'affichage.
  static QueueStatus fromWire(Object? raw) {
    return switch (raw?.toString().toLowerCase()) {
      'called' || 'calling' || 'now_calling' => QueueStatus.called,
      'serving' || 'in_service' || 'in_progress' => QueueStatus.inService,
      'absent' || 'no_show' || 'missed' => QueueStatus.absent,
      'done' || 'completed' || 'cancelled' || 'canceled' || 'expired' =>
        QueueStatus.done,
      // TRANSFERRED et INCOMPLETE sont encore ACTIFS côté serveur : le client
      // sera rappelé, il reste donc « en attente » pour lui.
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
  /// [previous] porte l'état déjà affiché. Il n'est pas décoratif : les messages
  /// `queue_update` poussés en direct ne transportent PAS le statut (seul le
  /// snapshot de connexion le fait). Sans lui, chaque mise à jour de position
  /// ramènerait un ticket « appelé » à « en attente », et le client verrait son
  /// écran régresser à chaque mouvement de file.
  factory QueueSnapshot.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
    QueueSnapshot? previous,
  }) {
    final rawPosition = _asInt(
      json['position'] ?? json['rank'] ?? json['place'],
    );
    final called = json['current_called_number'] ?? json['called_number'];
    final counter = json['counter_name'] ?? json['counter'] ?? json['desk'];
    final qr = json['qr_payload'] ?? json['qr'];
    final hasStatus = json['status'] != null;
    return QueueSnapshot(
      ticketNumber: (json['ticket_number'] ?? json['number'] ?? '').toString(),
      // La position 0 est une information, pas une absence : le backend la
      // renvoie pour un ticket appelé ou servi, et pour une file Redis
      // indisponible. La forcer à 1 annoncerait « vous êtes le prochain » à un
      // client déjà au guichet.
      position: rawPosition == null || rawPosition < 0 ? 1 : rawPosition,
      estimatedMinutes:
          _asInt(
            json['estimated_wait_minutes'] ??
                json['estimated_minutes'] ??
                json['eta_minutes'],
          ) ??
          previous?.estimatedMinutes ??
          0,
      status: hasStatus
          ? QueueStatus.fromWire(json['status'])
          : (previous?.status ?? QueueStatus.waiting),
      updatedAt: now ?? DateTime.now(),
      calledNumber: called?.toString() ?? previous?.calledNumber,
      counterLabel: counter?.toString() ?? previous?.counterLabel,
      qrPayload: qr?.toString() ?? previous?.qrPayload,
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
      status == QueueStatus.inService ||
      status == QueueStatus.absent ||
      status == QueueStatus.done;

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
