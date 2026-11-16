import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';

/// Nombre d'actions en attente de synchronisation, tel qu'affiché.
///
/// Dérivé du ticket actif plutôt que relu depuis le cache : l'indicateur et la
/// carte du ticket ne peuvent donc jamais se contredire. L'invariant produit
/// n'autorise qu'un seul ticket actif, la valeur est 0 ou 1.
final pendingSyncCountProvider = Provider<int>((ref) {
  final ticket = ref.watch(activeTicketProvider).value;
  return ticket != null && ticket.pendingSync ? 1 : 0;
});
