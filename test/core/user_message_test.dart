import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/errors/api_error_mapper.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/errors/user_message.dart';
import 'package:tonde/l10n/generated/app_localizations_fr.dart';

/// Traductions françaises réelles : une clé oubliée dans l'ARB doit faire
/// échouer la compilation, pas produire un écran vide.
final AppLocalizationsFr _l10n = AppLocalizationsFr();

UserMessage _message(String? code, {int status = 400, int? retryAfter}) {
  return userMessageFor(
    _l10n,
    ApiException(
      statusCode: status,
      code: code,
      retryAfterSeconds: retryAfter,
    ),
  );
}

void main() {
  group('Catalogue de messages', () {
    test('un ticket déjà actif renvoie vers le suivi', () {
      final message = _message('TICKET_ALREADY_ACTIVE');

      expect(message.message, _l10n.errTicketActive);
      expect(message.action, ErrorAction.seePosition);
      // Le libellé existe déjà ailleurs dans l'application : on le réutilise
      // plutôt que d'inventer un second vocabulaire pour la même action.
      expect(actionLabelFor(_l10n, message.action), _l10n.seePosition);
    });

    test('une agence fermée ne propose aucune action', () {
      final message = _message('BRANCH_CLOSED');

      expect(message.message, _l10n.errBranchClosed);
      // Aucun écran d'horaires n'existe : un bouton « voir les horaires »
      // mènerait nulle part, donc il n'y a pas de bouton.
      expect(message.hasAction, isFalse);
      expect(actionLabelFor(_l10n, message.action), isNull);
    });

    test('un service indisponible renvoie au choix du service', () {
      expect(_message('SERVICE_INACTIVE').action, ErrorAction.chooseService);
    });

    test('la limite du jour est expliquée', () {
      final message = _message('DAILY_LIMIT_REACHED');
      expect(message.message, _l10n.errDailyLimit);
      expect(message.detail, _l10n.errDailyLimitDetail);
    });

    test('un délai imposé par le serveur est repris dans la phrase', () {
      final message = _message('RATE_LIMIT_EXCEEDED', status: 429, retryAfter: 45);

      expect(message.message, contains('45'));
      expect(message.retryAfter, const Duration(seconds: 45));
      expect(message.action, ErrorAction.wait);
    });

    test('sans délai connu, le message reste général', () {
      final message = _message('RATE_LIMITED', status: 429);

      expect(message.message, _l10n.errRateLimited);
      expect(message.retryAfter, isNull);
    });

    test('un délai de grâce non écoulé demande d’attendre', () {
      expect(_message('GRACE_PERIOD_NOT_ELAPSED').action, ErrorAction.wait);
    });

    test('une fenêtre de reprise dépassée propose un nouveau ticket', () {
      final message = _message('RECOVERY_WINDOW_EXPIRED');
      expect(message.action, ErrorAction.takeNewTicket);
      expect(message.message, _l10n.resumeWindowExpired);
    });

    test('une panne serveur se rejoue', () {
      final message = _message(null, status: 503);
      expect(message.message, _l10n.errServer);
      expect(message.action, ErrorAction.retry);
    });

    test('un refus inconnu en 4xx ne promet pas de solution', () {
      final message = _message('UN_CODE_QUI_NEXISTE_PAS', status: 400);
      expect(message.message, _l10n.errUnexpected);
      expect(message.hasAction, isFalse);
    });

    test('une coupure réseau est reconnue et rejouable', () {
      final message = userMessageFor(_l10n, const NetworkException());

      expect(message.message, _l10n.networkError);
      expect(message.action, ErrorAction.retry);
    });

    test('aucun message ne laisse filtrer de terme technique', () {
      // Le critère du lot : rien de brut à l'écran, dans aucune des branches.
      final samples = <Object>[
        const NetworkException(),
        const RequestTimeoutException(),
        const ApiException(statusCode: 500),
        const ApiException(statusCode: 400, code: 'TICKET_NOT_FOUND'),
        const ApiException(statusCode: 429, code: 'RATE_LIMITED'),
        const UnexpectedException(),
      ];

      for (final error in samples) {
        final message = userMessageFor(_l10n, error);
        final text = '${message.message} ${message.detail ?? ''}'.toLowerCase();
        expect(text, isNot(contains('exception')));
        expect(text, isNot(contains('http')));
        expect(text, isNot(contains('dio')));
        expect(text, isNot(contains('null')));
      }
    });
  });

  group('Référence d’incident', () {
    test('tient en huit caractères alphanumériques', () {
      final id = incidentIdFor(const ApiException(statusCode: 500));

      expect(id.length, lessThanOrEqualTo(8));
      expect(id, matches(RegExp(r'^[0-9A-Z]{7,8}$')));
    });

    test('deux erreurs différentes ne partagent pas la même référence', () {
      // Sinon le support ne pourrait pas distinguer deux signalements.
      final first = incidentIdFor(const ApiException(statusCode: 500));
      final second = incidentIdFor(const ApiException(statusCode: 404));
      expect(first, isNot(second));
    });
  });

  group('Lecture de retry_after', () {
    Response<dynamic> response({
      Object? data,
      Map<String, List<String>>? headers,
    }) {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: '/tickets'),
        statusCode: 429,
        data: data,
        headers: headers == null ? null : Headers.fromMap(headers),
      );
    }

    test('lit le champ du corps', () {
      expect(
        errorRetryAfterOf(
          response(
            data: {
              'detail': {'code': 'RATE_LIMITED', 'retry_after': 30},
            },
          ),
        ),
        30,
      );
    });

    test('lit la variante utilisée pour les SMS', () {
      expect(
        errorRetryAfterOf(
          response(
            data: {
              'detail': {'code': 'SMS_RATE_LIMIT', 'retry_after_seconds': 60},
            },
          ),
        ),
        60,
      );
    });

    test('retombe sur l’en-tête quand le corps est muet', () {
      expect(
        errorRetryAfterOf(
          response(headers: {'retry-after': ['90']}),
        ),
        90,
      );
    });

    test('ignore une valeur absurde', () {
      expect(
        errorRetryAfterOf(
          response(
            data: {
              'detail': {'retry_after': -5},
            },
          ),
        ),
        isNull,
      );
    });
  });
}
