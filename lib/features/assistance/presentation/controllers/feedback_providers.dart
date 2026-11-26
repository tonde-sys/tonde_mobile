import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/network/dio_provider.dart';
import 'package:tonde/features/assistance/data/feedback_service.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';

/// Service des retours. Remplacé dans les tests par un faux.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return ApiFeedbackService(client: ref.watch(apiClientProvider));
});

/// Historique « Mes retours ».
///
/// Il se recharge après chaque envoi : le formulaire n'a pas à connaître
/// l'historique, et l'utilisateur retrouve son retour en ouvrant la liste.
///
/// `retry` est désactivé, comme pour la sonde de service : une relance
/// automatique sur un serveur muet laisserait un minuteur actif après la
/// fermeture de l'écran, et rejouerait la requête sans que personne ne l'ait
/// demandé. Le tirer-vers-le-bas de l'écran suffit à réessayer.
final myFeedbackProvider =
    AsyncNotifierProvider<MyFeedbackNotifier, List<FeedbackEntry>>(
      MyFeedbackNotifier.new,
      retry: (_, _) => null,
    );

class MyFeedbackNotifier extends AsyncNotifier<List<FeedbackEntry>> {
  @override
  Future<List<FeedbackEntry>> build() {
    return ref.watch(feedbackServiceProvider).mine();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(feedbackServiceProvider).mine(),
    );
  }

  /// Envoie un retour puis met l'historique à jour.
  ///
  /// Les erreurs remontent : c'est le formulaire qui décide quoi en dire, et il
  /// connaît le contexte (quota atteint, doublon sur ce ticket).
  Future<FeedbackEntry> submit(FeedbackDraft draft) async {
    final entry = await ref.read(feedbackServiceProvider).submit(draft);
    // On repart du serveur plutôt que d'insérer localement : l'ordre et le
    // statut viennent de lui, et un doublon inséré à la main finirait par
    // apparaître deux fois après le prochain rafraîchissement.
    state = await AsyncValue.guard(
      () => ref.read(feedbackServiceProvider).mine(),
    );
    return entry;
  }
}

/// Vrai si l'API répond à `/health`.
///
/// Volontairement sans rechargement automatique : c'est un diagnostic que
/// l'utilisateur consulte, pas un indicateur temps réel. Un `ping` toutes les
/// quelques secondes coûterait de la batterie pour une information qui ne
/// change presque jamais pendant une session.
///
/// `retry` est désactivé : la relance automatique de Riverpod laisserait un
/// minuteur en attente à chaque échec — y compris après la fermeture de
/// l'écran, ce qui fait échouer les tests et réveille l'application pour rien.
/// Un serveur injoignable le reste jusqu'à ce que l'utilisateur réessaie.
final serviceReachableProvider = FutureProvider<bool>((ref) {
  return ref.watch(feedbackServiceProvider).ping();
}, retry: (_, _) => null);

/// Renseigne les champs techniques du retour.
///
/// `kAppVersion` est maintenu à la main dans `app_config.dart` : la version
/// envoyée est donc celle du code compilé, pas celle d'un manifeste lu à
/// l'exécution. Un décalage entre les deux se voit en revue, pas en production.
FeedbackDraft buildDraft({
  required FeedbackCategory category,
  required String message,
  int? rating,
  String? orgId,
  String? ticketId,
  String? locale,
}) {
  return FeedbackDraft(
    category: category,
    message: message,
    rating: rating,
    orgId: orgId,
    ticketId: ticketId,
    appVersion: kAppVersion,
    platform: _platformName(),
    // Version du système plutôt que modèle commercial : c'est ce que le support
    // peut reproduire, et cela évite une dépendance native supplémentaire pour
    // un champ que personne ne lit au-delà de « Android 13 » ou « iOS 17 ».
    deviceModel: _deviceModel(),
    locale: locale,
  );
}

String _platformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'unknown';
}

String _deviceModel() {
  final raw = Platform.operatingSystemVersion.trim();
  // La colonne fait 80 caractères côté serveur ; tronquer ici évite un rejet
  // de validation pour une chaîne que personne ne lira en entier.
  return raw.length <= 80 ? raw : raw.substring(0, 80);
}
