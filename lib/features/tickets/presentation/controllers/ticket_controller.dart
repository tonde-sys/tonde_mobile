import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/data/cached_ticket_service.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';

/// Ticket actif de l'utilisateur (null si aucun).
final activeTicketProvider = AsyncNotifierProvider<TicketNotifier, Ticket?>(
  TicketNotifier.new,
);

/// Règle métier : **un seul ticket en attente à la fois**.
///
/// Un ticket déjà servi (client pris en charge, ou absent) ne compte plus :
/// le client peut en reprendre un immédiatement. Le ticket servi reste
/// consultable, avec son QR, jusqu'à ce qu'il soit remplacé ou annulé.
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
        _watchServing(synced);
        return synced;
      }
    }
    _watchServing(ticket);
    return ticket;
  }

  /// Surveille la fin de prise en charge du ticket pour le libérer.
  ///
  /// Sans cela, un client servi resterait bloqué sur un ticket « actif » et ne
  /// pourrait jamais en reprendre un autre sans annuler.
  void _watchServing(Ticket? ticket) {
    // Un ticket pris hors ligne n'a pas d'identifiant serveur : il n'existe
    // qu'en local, donc aucun flux temps réel ne peut le décrire.
    if (ticket == null || ticket.pendingSync || ticket.served || ticket.id == null) {
      return;
    }
    ref.listen(queueTrackingProvider(ticket), (previous, next) {
      final snapshot = next.value?.snapshot;
      if (snapshot == null || !snapshot.isTerminal) {
        return;
      }
      // L'écoute d'un ancien ticket peut survivre à un changement de ticket :
      // on ne libère que celui qui est réellement courant.
      final current = state.value;
      if (current == null || current.number != ticket.number) {
        return;
      }
      unawaited(markServed());
    });
  }

  Future<void> takeTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    final current = state.value;
    // Un ticket encore en attente bloque la prise ; un ticket servi non.
    if (current != null && !current.served) {
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
      _watchServing(created);
    } on TicketAlreadyActiveException catch (error) {
      // Le serveur détient encore un ticket : ce n'est pas une panne, c'est
      // l'invariant métier. On affiche ce ticket au lieu d'un écran d'erreur
      // réseau, sinon le client croit à une coupure et ne comprend pas.
      state = AsyncData(error.existingTicket);
      _watchServing(error.existingTicket);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Marque le ticket courant comme servi : il ne bloque plus la file.
  Future<void> markServed() async {
    final current = state.value;
    if (current == null || current.served) {
      return;
    }
    final served = current.copyWith(served: true);
    state = AsyncData(served);
    try {
      await ref.read(ticketServiceProvider).markServed(served);
    } on Object {
      // La persistance est un confort : l'état en mémoire suffit pour la
      // session en cours, et le prochain rafraîchissement serveur fera foi.
    }
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
