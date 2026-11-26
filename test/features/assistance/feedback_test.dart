import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/controllers/feedback_providers.dart';
import 'package:tonde/features/assistance/presentation/feedback_error_message.dart';
import 'package:tonde/l10n/generated/app_localizations_fr.dart';

/// Traductions françaises réelles : tester sur des chaînes inventées
/// laisserait passer une clé oubliée dans l'ARB.
final AppLocalizationsFr _l10n = AppLocalizationsFr();

Map<String, dynamic> _json({Object? category, Object? status}) => {
  'id': 'fb-1',
  'category': category ?? 'review',
  'message': 'Le guichet trois etait ferme ce matin',
  'status': status ?? 'received',
  'rating': 4,
  'created_at': '2026-11-24T08:30:00Z',
};

void main() {
  group('FeedbackEntry', () {
    test('lit la catégorie et le statut envoyés par le serveur', () {
      final entry = FeedbackEntry.fromJson(_json());

      expect(entry.category, FeedbackCategory.review);
      expect(entry.status, FeedbackStatus.received);
      expect(entry.rating, 4);
      // L'heure arrive en UTC et doit être convertie : un client de Bujumbura
      // qui voit « 08:30 » pour un envoi de 10:30 croit à un bug.
      expect(entry.createdAt.isUtc, isFalse);
    });

    test('une catégorie inconnue ne casse pas l’historique', () {
      // Un serveur plus récent peut introduire une catégorie : l'ancien client
      // doit continuer d'afficher le message plutôt que de vider la liste.
      final entry = FeedbackEntry.fromJson(_json(category: 'praise'));

      expect(entry.category, FeedbackCategory.suggestion);
      expect(entry.message, isNotEmpty);
    });

    test('un statut inconnu retombe sur « reçu »', () {
      final entry = FeedbackEntry.fromJson(_json(status: 'archived'));
      expect(entry.status, FeedbackStatus.received);
    });
  });

  group('FeedbackDraft', () {
    test('n’envoie pas les champs facultatifs vides', () {
      const draft = FeedbackDraft(
        category: FeedbackCategory.bug,
        message: 'Le bouton ne repond pas du tout',
      );

      final json = draft.toJson();
      expect(json['category'], 'bug');
      expect(json.containsKey('rating'), isFalse);
      expect(json.containsKey('ticket_id'), isFalse);
    });

    test('buildDraft renseigne la version et la plateforme', () {
      final draft = buildDraft(
        category: FeedbackCategory.review,
        message: 'Le guichet trois etait ferme ce matin',
        rating: 2,
        orgId: 'org-1',
        ticketId: 't-9',
        locale: 'fr',
      );

      expect(draft.appVersion, isNotEmpty);
      expect(draft.platform, isNotNull);
      expect(draft.locale, 'fr');
      expect(draft.toJson()['ticket_id'], 't-9');
      expect(draft.toJson()['org_id'], 'org-1');
    });
  });

  group('feedbackErrorMessage', () {
    test('le quota atteint est expliqué, pas résumé en échec', () {
      final message = feedbackErrorMessage(
        _l10n,
        const ApiException(statusCode: 429, code: 'FEEDBACK_RATE_LIMITED'),
      );
      expect(message, _l10n.feedbackRateLimited);
    });

    test('un doublon sur le même ticket est expliqué', () {
      final message = feedbackErrorMessage(
        _l10n,
        const ApiException(statusCode: 409, code: 'FEEDBACK_ALREADY_SENT'),
      );
      expect(message, _l10n.feedbackAlreadySent);
    });

    test('une panne réseau est distinguée d’un refus du serveur', () {
      final message = feedbackErrorMessage(_l10n, const NetworkException());
      expect(message, _l10n.networkError);
    });

    test('un code inconnu retombe sur le message générique', () {
      final message = feedbackErrorMessage(
        _l10n,
        const ApiException(statusCode: 500, code: 'WHATEVER'),
      );
      expect(message, _l10n.feedbackFailed);
    });
  });
}
