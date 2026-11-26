import 'package:tonde/core/network/api_client.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';

/// Accès aux retours utilisateurs (`/api/v1/feedback`).
///
/// Interface séparée de l'implémentation : l'écran d'assistance se teste avec
/// un faux service, sans monter de pile HTTP ni de session.
abstract interface class FeedbackService {
  /// Envoie un retour. Lève une [ApiException] portant un code métier quand le
  /// serveur refuse (quota horaire, doublon sur le même ticket).
  Future<FeedbackEntry> submit(FeedbackDraft draft);

  /// Historique « Mes retours », du plus récent au plus ancien.
  Future<List<FeedbackEntry>> mine({int page, int pageSize});

  /// Vrai si l'API répond. Utilisé par l'indicateur « État du service ».
  Future<bool> ping();
}

final class ApiFeedbackService implements FeedbackService {
  ApiFeedbackService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<FeedbackEntry> submit(FeedbackDraft draft) async {
    final response = await _client.post('/feedback', body: draft.toJson());
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Réponse de /feedback inattendue');
    }
    return FeedbackEntry.fromJson(data);
  }

  @override
  Future<List<FeedbackEntry>> mine({int page = 1, int pageSize = 20}) async {
    final response = await _client.get(
      '/feedback/mine',
      query: {'page': page, 'page_size': pageSize},
    );
    final data = response['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) {
      return const <FeedbackEntry>[];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(FeedbackEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<bool> ping() async {
    try {
      // `/health` ne touche ni la base ni Redis : c'est une sonde de réveil,
      // pas un diagnostic. C'est exactement ce qu'on veut ici — savoir si
      // l'application peut joindre son serveur, sans prétendre mesurer sa santé.
      await _client.get('/health', authenticated: false);
      return true;
    } on Object {
      return false;
    }
  }
}
