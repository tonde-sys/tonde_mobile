import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/presentation/auth_error_message.dart';
import 'package:tonde/features/auth/presentation/email_validation.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('validateEmail', () {
    test('accepte une adresse ordinaire', () {
      expect(validateEmail(l10n, 'jospin@example.com'), isNull);
      expect(validateEmail(l10n, '  jean.test+tonde@mail.co.bi  '), isNull);
    });

    test('exige un champ rempli', () {
      expect(validateEmail(l10n, null), l10n.fieldRequired);
      expect(validateEmail(l10n, '   '), l10n.fieldRequired);
    });

    test('refuse une saisie manifestement incomplète', () {
      // Ces formes n'atteignent jamais le serveur : un aller-retour réseau pour
      // apprendre que « dupont » n'est pas une adresse serait du temps perdu.
      for (final invalid in <String>[
        'dupont',
        'jospin@',
        '@example.com',
        'jospin@example',
        'jospin@@example.com',
        'jospin@.com',
        'jospin@example.',
        'jospin@exa..mple.com',
        'jospin @example.com',
      ]) {
        expect(
          validateEmail(l10n, invalid),
          l10n.emailInvalid,
          reason: 'devrait refuser « $invalid »',
        );
      }
    });
  });

  group('authErrorMessage', () {
    test('distingue les refus du serveur', () {
      expect(
        authErrorMessage(l10n, const InvalidCredentialsException()),
        l10n.invalidCredentials,
      );
      // Un compte désactivé n'est pas un mauvais mot de passe : réessayer ne
      // servirait à rien.
      expect(
        authErrorMessage(l10n, const AccountDisabledException()),
        l10n.accountDisabled,
      );
      expect(
        authErrorMessage(l10n, const AccountLockedException()),
        l10n.accountLocked,
      );
      expect(
        authErrorMessage(l10n, const EmailAlreadyTakenException()),
        l10n.emailTaken,
      );
    });

    test('un serveur injoignable n\'est pas un mauvais mot de passe', () {
      expect(
        authErrorMessage(l10n, const NetworkException()),
        l10n.networkError,
      );
      expect(
        authErrorMessage(l10n, const RequestTimeoutException()),
        l10n.networkError,
      );
    });

    test('une validation serveur garde son message précis', () {
      const error = ApiException(
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        serverMessage: 'Le mot de passe doit contenir au moins 8 caractères',
      );

      // Traduire ce message le viderait de sa contrainte : l'écran doit dire
      // ce qui ne va pas, pas « une erreur est survenue ».
      expect(
        authErrorMessage(l10n, error),
        'Le mot de passe doit contenir au moins 8 caractères',
      );
    });

    test('une erreur inconnue ne laisse pas l\'écran muet', () {
      expect(authErrorMessage(l10n, null), '');
      expect(authErrorMessage(l10n, StateError('x')), l10n.authErrorGeneric);
    });
  });
}
