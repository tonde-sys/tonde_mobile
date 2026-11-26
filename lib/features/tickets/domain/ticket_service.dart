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

  /// Enregistre l'état courant de [ticket] dans la mémoire locale.
  ///
  /// Appelé à chaque changement de statut venu du flux temps réel : un client
  /// qui ferme l'application après avoir été appelé, absent ou servi doit
  /// retrouver cet état au prochain démarrage, même sans réseau.
  ///
  /// Le serveur reste la source de vérité : l'implémentation distante n'envoie
  /// donc rien, elle laisse le prochain rafraîchissement corriger le cache.
  Future<void> saveStatus(Ticket ticket);

  /// Annule le ticket actif du client.
  ///
  /// Le ticket est libéré côté serveur : la place revient immédiatement à la
  /// file. Un appel hors ligne doit tout de même vider le cache local, sans
  /// quoi l'utilisateur resterait bloqué sur un ticket qu'il a annulé.
  Future<void> cancelTicket();

  /// Demande le retour en file d'un ticket absent (`ABSENT → WAITING`).
  ///
  /// Le client ne récupère pas son ancien rang : le serveur le replace en fin
  /// de sa tranche de priorité, avec une nouvelle séquence. C'est la contre-
  /// partie de son absence, et la raison pour laquelle le ticket renvoyé doit
  /// être relu — sa position a changé.
  ///
  /// Le serveur peut refuser : fenêtre de reprise écoulée, plafond d'absences
  /// atteint. Ces refus remontent en erreur API avec un code métier, pour que
  /// l'écran explique la situation au lieu d'afficher un échec générique.
  Future<Ticket> resumeTicket(Ticket ticket);

  /// Dernier ticket qui était actif et ne l'est plus.
  ///
  /// Sert uniquement à expliquer la disparition du ticket. `GET /tickets/active`
  /// répond `null` dans deux cas très différents — « vous n'avez jamais pris de
  /// ticket » et « votre ticket vient d'être clôturé » — et sans cette mémoire
  /// l'accueil afficherait la carte vide à un client qui attendait son tour.
  ///
  /// Retourne null quand aucun ticket n'a disparu, y compris après une
  /// annulation volontaire : le client sait alors pourquoi il n'a plus rien.
  Future<Ticket?> lastClosedTicket();
}

/// Levée quand un ticket est déjà actif (invariant un ticket par utilisateur).
final class TicketAlreadyActiveException implements Exception {
  const TicketAlreadyActiveException(this.existingTicket);

  final Ticket existingTicket;
}
