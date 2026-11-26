import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Ce que l'écran propose de faire après une erreur.
///
/// L'action est une **intention**, pas un bouton : c'est l'appelant qui fournit
/// le comportement, parce que lui seul sait où revenir. Un catalogue qui
/// afficherait « Voir les horaires » sans écran d'horaires produirait un bouton
/// mort — c'est précisément ce qu'on veut éviter.
enum ErrorAction {
  /// Rien à proposer : le message suffit.
  none,

  /// Rejouer la même opération.
  retry,

  /// Aller voir le ticket en cours.
  seePosition,

  /// Revenir au choix du service.
  chooseService,

  /// Prendre un nouveau ticket.
  takeNewTicket,

  /// Attendre la fin d'un délai imposé par le serveur.
  wait,
}

/// Message destiné à l'utilisateur, avec l'action qui va avec.
class UserMessage {
  const UserMessage(
    this.message, {
    this.detail,
    this.action = ErrorAction.none,
    this.retryAfter,
  });

  /// Phrase principale, courte, à afficher en gras.
  final String message;

  /// Explication facultative : ce qui s'est passé, ce qui va se passer.
  final String? detail;

  final ErrorAction action;

  /// Délai imposé par le serveur, quand il en fournit un.
  final Duration? retryAfter;

  bool get hasAction => action != ErrorAction.none;
}

/// Traduit n'importe quelle erreur en message utilisable.
///
/// Le principe : **aucun message technique n'atteint l'écran**. Le code métier
/// du serveur choisit une phrase ; à défaut, on explique ce qui est sûr
/// (réseau, délai, panne serveur) sans jamais afficher `DioException` ni un
/// statut HTTP.
UserMessage userMessageFor(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    return _fromApiCode(l10n, error);
  }
  if (error is NetworkException ||
      error is RequestTimeoutException ||
      error is SecureConnectionException) {
    return UserMessage(
      l10n.networkError,
      detail: l10n.errOfflineDetail,
      action: ErrorAction.retry,
    );
  }
  if (error is RequestCancelledException) {
    return UserMessage(l10n.errUnexpected);
  }
  return UserMessage(l10n.errUnexpected, detail: l10n.errUnexpectedDetail);
}

UserMessage _fromApiCode(AppLocalizations l10n, ApiException error) {
  switch (error.code) {
    // ── Ticket ───────────────────────────────────────────────────────────────
    case 'TICKET_ALREADY_ACTIVE':
    case 'ACTIVE_TICKET_ALREADY_EXISTS':
      return UserMessage(
        l10n.errTicketActive,
        detail: l10n.errTicketActiveDetail,
        action: ErrorAction.seePosition,
      );
    case 'BRANCH_CLOSED':
    case 'COUNTER_CLOSED':
      return UserMessage(l10n.errBranchClosed, detail: l10n.errBranchClosedDetail);
    case 'SERVICE_INACTIVE':
      return UserMessage(
        l10n.serviceUnavailable,
        action: ErrorAction.chooseService,
      );
    case 'DAILY_LIMIT_REACHED':
      return UserMessage(
        l10n.errDailyLimit,
        detail: l10n.errDailyLimitDetail,
      );
    case 'GRACE_PERIOD_NOT_ELAPSED':
      return UserMessage(
        l10n.errGracePeriod,
        detail: l10n.errGracePeriodDetail,
        action: ErrorAction.wait,
      );
    case 'RECOVERY_WINDOW_EXPIRED':
      return UserMessage(
        l10n.resumeWindowExpired,
        action: ErrorAction.takeNewTicket,
      );
    case 'MAX_MISSED_COUNT_REACHED':
    case 'RECALL_LIMIT_REACHED':
      return UserMessage(
        l10n.resumeMaxMissed,
        action: ErrorAction.takeNewTicket,
      );
    case 'TICKET_NOT_FOUND':
      return UserMessage(l10n.errTicketGone, detail: l10n.errTicketGoneDetail);

    // ── Débit ────────────────────────────────────────────────────────────────
    case 'RATE_LIMITED':
    case 'RATE_LIMIT_EXCEEDED':
    case 'SMS_RATE_LIMIT':
      final seconds = error.retryAfterSeconds;
      return UserMessage(
        seconds == null
            ? l10n.errRateLimited
            : l10n.errRateLimitedSeconds(seconds),
        detail: seconds == null ? l10n.errRateLimitedDetail : null,
        action: ErrorAction.wait,
        retryAfter: seconds == null ? null : Duration(seconds: seconds),
      );

    // ── Compte ───────────────────────────────────────────────────────────────
    case 'ACCOUNT_DISABLED':
      return UserMessage(l10n.accountDisabled);
    case 'ACCOUNT_LOCKED':
      return UserMessage(l10n.accountLocked);
    case 'FORBIDDEN':
      return UserMessage(l10n.errForbidden);

    // ── Requête ──────────────────────────────────────────────────────────────
    case 'VALIDATION_ERROR':
    case 'INVALID_FORMAT':
      return UserMessage(l10n.errValidation);
    case 'TICKET_CREATION_IN_PROGRESS':
      return UserMessage(l10n.errInProgress, action: ErrorAction.retry);
    case 'SERVER_ERROR':
    case 'ERROR':
      return UserMessage(
        l10n.errServer,
        detail: l10n.errServerDetail,
        action: ErrorAction.retry,
      );
  }

  // Code inconnu : le serveur a refusé, mais on ne sait pas pourquoi. On le dit
  // sans inventer, et on laisse le statut dans les détails techniques.
  if (error.statusCode >= 500) {
    // Une panne serveur se rejoue : c'est le seul conseil honnête.
    return UserMessage(
      l10n.errServer,
      detail: l10n.errServerDetail,
      action: ErrorAction.retry,
    );
  }
  return UserMessage(l10n.errUnexpected, detail: l10n.errUnexpectedDetail);
}

/// Libellé du bouton d'action, ou null si l'action n'en a pas.
String? actionLabelFor(AppLocalizations l10n, ErrorAction action) {
  return switch (action) {
    ErrorAction.none => null,
    ErrorAction.retry => l10n.retry,
    ErrorAction.seePosition => l10n.seePosition,
    ErrorAction.chooseService => l10n.actionChooseService,
    ErrorAction.takeNewTicket => l10n.actionTakeNewTicket,
    ErrorAction.wait => l10n.actionWait,
  };
}

/// Référence courte affichée à l'écran et journalisée.
///
/// Huit caractères, dérivés de l'erreur : assez courts pour être lus au
/// téléphone, assez longs pour ne pas collisionner sur une journée de support.
/// Elle ne contient aucune donnée personnelle — seulement de quoi retrouver la
/// ligne de journal correspondante.
String incidentIdFor(Object error) {
  final hash = error.hashCode & 0x7FFFFFFF;
  return hash.toRadixString(36).toUpperCase().padLeft(7, '0');
}
