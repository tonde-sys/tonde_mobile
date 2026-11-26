import 'package:intl/intl.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/presentation/ticket_status_display.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Compose l'état du widget d'écran d'accueil à partir du ticket et du flux.
///
/// Fonction pure : aucune dépendance à Riverpod, à l'horloge système ni au
/// canal natif, donc testable ligne à ligne. Toute la décision « quoi montrer »
/// est ici ; le code Kotlin ne fait que peindre.
///
/// [snapshot] est la dernière photo du flux temps réel. Il prime sur le ticket
/// parce qu'il est plus récent : le ticket n'est réécrit qu'aux changements de
/// statut, alors que la position et l'attente bougent à chaque tour de file.
HomeWidgetState homeWidgetStateFor({
  required AppLocalizations l10n,
  required Ticket? ticket,
  QueueSnapshot? snapshot,
  DateTime? now,
}) {
  if (ticket == null || ticket.isClosed) {
    return HomeWidgetState.empty(
      title: l10n.widgetEmptyTitle,
      body: l10n.widgetEmptyBody,
    );
  }

  final updated = l10n.widgetUpdated(
    DateFormat.Hm().format(now ?? DateTime.now()),
  );

  // Un ticket pris hors ligne n'a pas de rang serveur : afficher « Position 1 »
  // ferait croire à une place réservée alors que rien n'est encore enregistré.
  if (ticket.pendingSync) {
    return HomeWidgetState(
      hasTicket: true,
      number: ticket.number,
      agency: ticket.agencyName,
      status: l10n.ticketPendingSync,
      updated: updated,
    );
  }

  final status = snapshot?.status ?? queueStatusOf(ticket.status);
  final counter = ticket.counterLabel;
  final statusLabel = queueStatusLabelOf(l10n, status);

  return HomeWidgetState(
    hasTicket: true,
    number: ticket.number,
    agency: ticket.agencyName,
    // Au guichet, savoir *lequel* est la seule information qui manque au
    // client : il a le numéro sous les yeux, pas la porte où se présenter.
    status:
        counter != null &&
            counter.isNotEmpty &&
            (status == QueueStatus.called || status == QueueStatus.inService)
        ? '$statusLabel · $counter'
        : statusLabel,
    position: _positionText(l10n, ticket, snapshot, status),
    eta: _etaText(l10n, ticket, snapshot, status),
    updated: updated,
  );
}

/// Position dans la file, ou chaîne vide quand elle n'a pas de sens.
///
/// Trois cas se ressemblent et ne doivent pas être confondus : la file est
/// dégradée (position 0, inconnue), le client est déjà appelé (sa position
/// n'existe plus), et il attend réellement. Seul le dernier s'affiche.
String _positionText(
  AppLocalizations l10n,
  Ticket ticket,
  QueueSnapshot? snapshot,
  QueueStatus status,
) {
  if (status != QueueStatus.waiting || ticket.queueDegraded) {
    return '';
  }
  final position = snapshot?.position ?? ticket.position;
  if (position <= 0) {
    return '';
  }
  return l10n.widgetPosition(position);
}

/// Attente estimée, ou chaîne vide si elle n'est pas fiable.
///
/// Une estimation nulle n'est jamais « 0 min » : le backend renvoie `null`
/// quand il ne sait pas, et un zéro affiché ferait croire que le tour est
/// arrivé. Le widget masque donc la ligne, comme l'écran affiche « Estimation
/// en cours ».
///
/// Quand un guichet de la file est en pause, c'est **la pause** qui occupe la
/// place de l'attente : c'est la réponse à la seule question que le client se
/// pose devant un compteur qui n'avance pas, et une durée estimée à côté d'un
/// guichet fermé se lirait comme un retard.
String _etaText(
  AppLocalizations l10n,
  Ticket ticket,
  QueueSnapshot? snapshot,
  QueueStatus status,
) {
  if (status != QueueStatus.waiting) {
    return '';
  }
  final paused = snapshot?.pausedCounters ?? const <CounterPauseInfo>[];
  if (paused.isNotEmpty) {
    final until = paused.first.pausedUntil;
    return until == null
        ? l10n.widgetCounterPaused
        : l10n.widgetCounterPausedUntil(
            DateFormat.Hm().format(until.toLocal()),
          );
  }
  final minutes = snapshot?.estimatedMinutes ?? ticket.estimatedMinutes;
  if (minutes == null || minutes <= 0) {
    return '';
  }
  return l10n.widgetEta(minutes);
}
