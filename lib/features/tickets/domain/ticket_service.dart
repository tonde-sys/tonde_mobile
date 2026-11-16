import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';

/// Accès au ticket actif et à la prise de ticket.
///
/// Dans l'application réelle, l'invariant « un seul ticket actif par
/// utilisateur » est imposé par le backend ; le mobile présente l'état
/// retourné. Le mock reproduit ce comportement en mémoire pour la démo.
abstract interface class TicketService {
  /// Retourne le ticket actif de l'utilisateur, ou null s'il n'y en a pas.
  Future<Ticket?> activeTicket();

  /// Crée un ticket pour [service] auprès de [agency] et [organization].
  ///
  /// Le service est obligatoire : c'est lui qui détermine la file, donc la
  /// position et le temps d'attente du client.
  ///
  /// Lève [TicketAlreadyActiveException] si un ticket est déjà actif.
  Future<Ticket> createTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  });

  /// Marque [ticket] comme servi (client pris en charge ou absent).
  ///
  /// Le ticket reste consultable — le client peut encore montrer son QR — mais
  /// il ne bloque plus la prise d'un nouveau ticket.
  Future<void> markServed(Ticket ticket);

  /// Annule le ticket actif du client.
  ///
  /// Le ticket est libéré côté serveur : la place revient immédiatement à la
  /// file. Un appel hors ligne doit tout de même vider le cache local, sans
  /// quoi l'utilisateur resterait bloqué sur un ticket qu'il a annulé.
  Future<void> cancelTicket();
}

/// Levée quand un ticket est déjà actif (invariant un ticket par utilisateur).
final class TicketAlreadyActiveException implements Exception {
  const TicketAlreadyActiveException(this.existingTicket);

  final Ticket existingTicket;
}
