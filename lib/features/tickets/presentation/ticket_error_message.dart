import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Message affichable pour un échec de reprise de ticket.
///
/// Le serveur répond en français, avec un code métier stable. On traduit donc
/// le **code**, jamais le message : un utilisateur anglophone ou kirundi doit
/// comprendre pourquoi sa reprise est refusée, et ce qu'il peut faire ensuite.
///
/// Les deux refus métier ne disent pas la même chose au client :
///   - fenêtre écoulée : il a raté son créneau, un nouveau ticket est la seule
///     issue ;
///   - plafond d'absences atteint : c'est cumulatif, et le serveur ne
///     reviendra pas dessus.
/// Les confondre en « échec » le laisserait réessayer indéfiniment.
String resumeErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'RECOVERY_WINDOW_EXPIRED' => l10n.resumeWindowExpired,
      'MAX_MISSED_COUNT_REACHED' => l10n.resumeMaxMissed,
      _ => l10n.resumeFailed,
    };
  }
  if (error is NetworkException ||
      error is RequestTimeoutException ||
      error is SecureConnectionException) {
    return l10n.networkError;
  }
  return l10n.resumeFailed;
}
