/// Retour envoyé depuis l'application, tel que le serveur le renvoie.
///
/// Les deux énumérations portent le vocabulaire du serveur (`review`, `bug`,
/// `suggestion` / `received`, `read`, `resolved`). L'interface les traduit :
/// l'utilisateur lit « Votre avis a été lu », jamais `read`.
library;

/// Ce que l'utilisateur veut dire.
enum FeedbackCategory {
  /// Avis sur un passage au guichet. C'est la seule catégorie qui appelle
  /// naturellement une note.
  review,

  /// Quelque chose ne fonctionne pas.
  bug,

  /// Idée d'amélioration.
  suggestion;

  String get wire => name;

  /// Libellé traduit, fourni par l'appelant pour ne pas lier le domaine à l'i18n.
  static FeedbackCategory fromWire(Object? raw) {
    return switch (raw) {
      'review' => FeedbackCategory.review,
      'bug' => FeedbackCategory.bug,
      'suggestion' => FeedbackCategory.suggestion,
      // Une catégorie inconnue ne doit pas faire planter l'historique : un
      // serveur plus récent peut en introduire une, et l'ancien client doit
      // continuer d'afficher le message.
      _ => FeedbackCategory.suggestion,
    };
  }
}

/// Où en est le traitement, du point de vue du support.
enum FeedbackStatus {
  received,
  read,
  resolved;

  String get wire => name;

  /// Vrai tant que le support n'a pas ouvert le retour.
  bool get isPending => this == FeedbackStatus.received;

  static FeedbackStatus fromWire(Object? raw) {
    return switch (raw) {
      'received' => FeedbackStatus.received,
      'read' => FeedbackStatus.read,
      'resolved' => FeedbackStatus.resolved,
      _ => FeedbackStatus.received,
    };
  }
}

/// Un retour, côté client.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.rating,
    this.orgId,
    this.ticketId,
    this.appVersion,
    this.readAt,
  });

  final String id;
  final FeedbackCategory category;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;
  final int? rating;
  final String? orgId;
  final String? ticketId;
  final String? appVersion;
  final DateTime? readAt;

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id'] as String,
      category: FeedbackCategory.fromWire(json['category']),
      message: json['message'] as String? ?? '',
      status: FeedbackStatus.fromWire(json['status']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      rating: (json['rating'] as num?)?.toInt(),
      orgId: json['org_id'] as String?,
      ticketId: json['ticket_id'] as String?,
      appVersion: json['app_version'] as String?,
      readAt: DateTime.tryParse(json['read_at'] as String? ?? '')?.toLocal(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeedbackEntry &&
      other.id == id &&
      other.status == status &&
      other.category == category &&
      other.message == message;

  @override
  int get hashCode => Object.hash(id, status, category, message);
}

/// Ce que l'application envoie au serveur.
///
/// Les champs techniques sont renseignés par l'application, jamais saisis :
/// c'est la première question que le support pose, et celle à laquelle
/// personne ne sait répondre de mémoire.
class FeedbackDraft {
  const FeedbackDraft({
    required this.category,
    required this.message,
    this.rating,
    this.orgId,
    this.ticketId,
    this.appVersion,
    this.platform,
    this.deviceModel,
    this.locale,
  });

  final FeedbackCategory category;
  final String message;
  final int? rating;
  final String? orgId;
  final String? ticketId;
  final String? appVersion;
  final String? platform;
  final String? deviceModel;
  final String? locale;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'category': category.wire,
    'message': message,
    if (rating != null) 'rating': rating,
    if (orgId != null) 'org_id': orgId,
    if (ticketId != null) 'ticket_id': ticketId,
    if (appVersion != null) 'app_version': appVersion,
    if (platform != null) 'platform': platform,
    if (deviceModel != null) 'device_model': deviceModel,
    if (locale != null) 'locale': locale,
  };
}
