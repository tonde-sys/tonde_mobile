import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Traduit le statut persistant du ticket vers le statut d'affichage.
///
/// Les deux énumérations ne couvrent pas la même chose : [QueueStatus] décrit
/// ce que le flux temps réel vient de dire, avec les quatre états que l'écran
/// sait peindre ; [TicketStatus] suit la machine à états complète du serveur,
/// y compris les états transitoires. Un ticket transféré ou incomplet reste,
/// pour le client, un ticket qui attend son rappel.
QueueStatus queueStatusOf(TicketStatus status) => switch (status) {
  TicketStatus.waiting ||
  TicketStatus.transferred ||
  TicketStatus.incomplete => QueueStatus.waiting,
  TicketStatus.called => QueueStatus.called,
  TicketStatus.serving => QueueStatus.inService,
  TicketStatus.absent => QueueStatus.absent,
  TicketStatus.done || TicketStatus.cancelled => QueueStatus.done,
};

/// Libellé traduit d'un statut de file.
///
/// Vit ici et non dans le badge : le widget d'écran d'accueil écrit le même
/// texte dans un `RemoteViews`, sans widget Flutter. Deux tables de
/// correspondance donneraient tôt ou tard deux formulations pour le même état.
String queueStatusLabelOf(AppLocalizations l10n, QueueStatus status) =>
    switch (status) {
      QueueStatus.waiting => l10n.trackingStatusWaiting,
      QueueStatus.called => l10n.trackingStatusCalled,
      QueueStatus.inService => l10n.trackingStatusInService,
      QueueStatus.absent => l10n.trackingStatusAbsent,
      QueueStatus.done => l10n.trackingStatusDone,
    };
