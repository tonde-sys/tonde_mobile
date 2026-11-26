import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';

/// Ticket actif de l'utilisateur (null si aucun).
final activeTicketProvider = AsyncNotifierProvider<TicketNotifier, Ticket?>(
  TicketNotifier.new,
);

/// Ticket qui vient de cesser d'être actif, pour expliquer sa disparition.
///
/// `GET /tickets/active` ne distingue pas « aucun ticket » de « votre ticket
/// vient d'être clôturé » : dans les deux cas il répond `null`. Sans cette
/// relecture, un client dont le ticket expire pendant qu'il attend retombe sur
/// la carte « aucun ticket actif », comme s'il n'avait jamais rien pris — et
/// croit à une perte de son ticket.
///
/// La valeur est lue dans le cache local, donc elle survit à un redémarrage
/// de l'application. Elle est effacée dès qu'un ticket redevient actif ou que
/// le client annule lui-même le sien.
final lastClosedTicketProvider = FutureProvider<Ticket?>((ref) async {
  final active = ref.watch(activeTicketProvider);
  // Tant qu'un ticket est actif, il n'y a rien à expliquer.
  if (active.value != null) {
    return null;
  }
  // Premier chargement : on ne sait pas encore, et afficher l'avis maintenant
  // le ferait clignoter à chaque ouverture de l'application.
  if (active.isLoading && !active.hasValue) {
    return null;
  }
  return ref.watch(ticketServiceProvider).lastClosedTicket();
});

/// Règle métier : **un seul ticket en attente à la fois**.
///
/// Un ticket clos (`done`, `cancelled`) ne compte plus : le client peut en
/// reprendre un immédiatement. Un ticket absent, lui, reste actif le temps de
/// sa fenêtre de reprise — c'est ce qui permet au client de revenir en file
/// sans perdre son rang.
class TicketNotifier extends AsyncNotifier<Ticket?> {
  @override
  Future<Ticket?> build() async {
    // Dès que le réseau revient, on rejoue la prise de ticket mise en attente
    // hors ligne. L'écoute vit et se coupe avec le provider.
    ref.listen(isOnlineProvider, (previous, next) {
      if (next && previous != true) {
        unawaited(syncPending());
      }
    });

    final service = ref.watch(ticketServiceProvider);
    final ticket = await service.activeTicket();

    // Une action laissée en attente lors d'une session hors ligne doit aussi
    // être rejouée au démarrage si le réseau est déjà revenu : sans cela, elle
    // resterait bloquée jusqu'à la prochaine coupure.
    if (ticket != null &&
        ticket.pendingSync &&
        service is CachedTicketService &&
        ref.read(isOnlineProvider)) {
      final synced = await service.syncPending();
      if (synced != null) {
        _watchStatus(synced);
        return synced;
      }
    }
    _watchStatus(ticket);
    return ticket;
  }

  /// Suit l'état du ticket dans la file et l'enregistre.
  ///
  /// Le statut n'est pas décoratif : c'est lui qui décide du bouton de la
  /// carte d'accueil (voir sa position, reprendre, reprendre un ticket) et de
  /// ce que le client peut encore faire. Il doit donc être persisté, sinon un
  /// client absent qui ferme l'application rouvre sur un ticket « en attente »
  /// et attend un rappel qui n'arrivera plus.
  void _watchStatus(Ticket? ticket) {
    // Un ticket pris hors ligne n'a pas d'identifiant serveur : il n'existe
    // qu'en local, donc aucun flux temps réel ne peut le décrire.
    //
    // Un ticket clos ne rouvre jamais : `done` et `cancelled` sont terminaux
    // dans la machine à états du serveur. Écouter sa file n'aurait donc aucun
    // sens, et un flux résiduel pourrait le faire repasser « en attente ».
    if (ticket == null ||
        ticket.pendingSync ||
        ticket.isClosed ||
        ticket.id == null) {
      return;
    }
    ref.listen(queueTrackingProvider(QueueTrackingKey(ticket)), (
      previous,
      next,
    ) {
      final snapshot = next.value?.snapshot;
      if (snapshot == null) {
        return;
      }
      final status = _statusOf(snapshot.status);
      // L'écoute d'un ancien ticket peut survivre à un changement de ticket :
      // on ne met à jour que celui qui est réellement courant.
      final current = state.value;
      if (current == null ||
          current.number != ticket.number ||
          current.isClosed ||
          current.status == status) {
        return;
      }
      unawaited(_applyStatus(status));
    });
  }

  /// Traduit un statut du flux vers le statut persistant.
  ///
  /// [QueueStatus.done] couvre à la fois « service rendu » et « annulé » : le
  /// flux ne distingue pas les deux, et le prochain `GET /tickets/active`
  /// tranchera. Les deux ferment le ticket, ce qui est le seul effet attendu.
  TicketStatus _statusOf(QueueStatus status) => switch (status) {
    QueueStatus.waiting => TicketStatus.waiting,
    QueueStatus.called => TicketStatus.called,
    QueueStatus.inService => TicketStatus.serving,
    QueueStatus.absent => TicketStatus.absent,
    QueueStatus.done => TicketStatus.done,
  };

  Future<void> takeTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    final current = state.value;
    // Un ticket encore actif bloque la prise ; un ticket clos non.
    if (current != null && !current.isClosed) {
      return;
    }
    state = const AsyncLoading();
    try {
      final created = await ref
          .read(ticketServiceProvider)
          .createTicket(
            organization: organization,
            agency: agency,
            service: service,
          );
      state = AsyncData(created);
      _watchStatus(created);
    } on TicketAlreadyActiveException catch (error) {
      // Le serveur détient encore un ticket : ce n'est pas une panne, c'est
      // l'invariant métier. On affiche ce ticket au lieu d'un écran d'erreur
      // réseau, sinon le client croit à une coupure et ne comprend pas.
      state = AsyncData(error.existingTicket);
      _watchStatus(error.existingTicket);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Enregistre le nouvel état du ticket courant.
  ///
  /// L'état est publié immédiatement : l'écran ne doit pas attendre une écriture
  /// disque pour réagir à un appel. La persistance, elle, est un confort — un
  /// échec ne bloque jamais le client, et le prochain rafraîchissement serveur
  /// fera foi.
  Future<void> _applyStatus(TicketStatus status) async {
    final current = state.value;
    if (current == null || current.status == status) {
      return;
    }
    final updated = current.copyWith(status: status);
    state = AsyncData(updated);
    try {
      await ref.read(ticketServiceProvider).saveStatus(updated);
    } on Object {
      // Voir plus haut : l'état en mémoire suffit pour la session en cours.
    }
  }

  /// Demande le retour en file du ticket absent courant.
  ///
  /// L'erreur éventuelle remonte volontairement : l'écran doit distinguer une
  /// fenêtre de reprise écoulée d'un plafond d'absences atteint, et un message
  /// générique priverait le client de la seule information utile — ce qu'il
  /// lui reste à faire.
  Future<void> resumeTicket() async {
    final current = state.value;
    if (current == null || !current.canResume) {
      return;
    }
    final resumed = await ref.read(ticketServiceProvider).resumeTicket(current);
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(resumed);
  }

  /// Annule le ticket actif : la place est rendue à la file et l'accueil
  /// repasse à l'état « aucun ticket ».
  Future<void> cancelTicket() async {
    if (state.value == null) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard<Ticket?>(() async {
      await ref.read(ticketServiceProvider).cancelTicket();
      return null;
    });
  }

  /// Rejoue l'action mise en attente hors ligne, sans jamais lever d'erreur.
  Future<void> syncPending() async {
    final service = ref.read(ticketServiceProvider);
    if (service is! CachedTicketService) {
      return;
    }
    final synced = await service.syncPending();
    if (synced != null && ref.mounted) {
      state = AsyncData(synced);
    }
  }
}
