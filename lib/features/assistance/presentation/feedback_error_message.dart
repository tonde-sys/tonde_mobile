import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Traduit un refus du serveur en une phrase utile pour l'utilisateur.
///
/// Le serveur répond avec un code métier (`FEEDBACK_RATE_LIMITED`,
/// `FEEDBACK_ALREADY_SENT`) précisément pour que l'application puisse dire
/// *pourquoi* l'envoi a échoué. Un message générique obligerait le client à
/// réessayer à l'aveugle, ou à appeler le support pour apprendre qu'il avait
/// simplement atteint son quota.
String feedbackErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'FEEDBACK_RATE_LIMITED' => l10n.feedbackRateLimited,
      'FEEDBACK_ALREADY_SENT' => l10n.feedbackAlreadySent,
      _ => l10n.feedbackFailed,
    };
  }
  if (error is NetworkException ||
      error is RequestTimeoutException ||
      error is SecureConnectionException) {
    return l10n.networkError;
  }
  return l10n.feedbackFailed;
}
