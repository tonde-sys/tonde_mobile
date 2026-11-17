import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/ticket_service.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/domain/queue_tracking_service.dart';

/// Service d'authentification de test : session en mémoire, sans latence.
class FakeAuthService implements AuthService {
  FakeAuthService({User? current, this.rejectLogin = false})
    : _current = current;

  /// Quand vrai, [login] refuse toujours les identifiants.
  final bool rejectLogin;
  User? _current;

  @override
  Future<User?> currentUser() async => _current;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    if (rejectLogin) {
      throw const InvalidCredentialsException();
    }
    final user = User(id: 'u-${email.hashCode}', name: email, email: email);
    _current = user;
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = User(id: 'u-${email.hashCode}', name: name, email: email);
    _current = user;
    return user;
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organization,
  }) async {
    final current = _current;
    if (current == null) {
      throw const NotAuthenticatedException();
    }
    final updated = current.copyWith(
      name: name,
      email: email,
      phone: phone,
      role: role,
      organization: organization,
    );
    _current = updated;
    return updated;
  }

  @override
  Future<void> logout() async {
    _current = null;
  }
}

/// Service de ticket de test : retourne le ticket fourni, sans latence.
class FakeTicketService implements TicketService {
  FakeTicketService({this.ticket});

  Ticket? ticket;

  @override
  Future<Ticket?> activeTicket() async => ticket;

  @override
  Future<Ticket> createTicket({
    required Organization organization,
    required Agency agency,
    required AgencyService service,
  }) async {
    final created = Ticket(
      number: 'T-9999',
      position: service.waitingCount + 1,
      estimatedMinutes: service.waitingCount,
      organizationId: organization.id,
      organizationName: organization.name,
      agencyId: agency.id,
      agencyName: agency.name,
      serviceId: service.id,
      serviceName: service.name,
    );
    ticket = created;
    return created;
  }

  @override
  Future<void> markServed(Ticket ticket) async {
    this.ticket = ticket;
  }

  @override
  Future<void> cancelTicket() async {
    ticket = null;
  }
}

/// Flux de suivi figé : émet un seul instantané, puis se termine.
///
/// Utile pour les tests d'écran : aucun minuteur ne reste en attente après la
/// destruction de l'arbre, et la file ne bouge pas sous les assertions.
class StaticQueueTrackingService implements QueueTrackingService {
  StaticQueueTrackingService({this.snapshot});

  /// Instantané imposé ; sinon il est dérivé du ticket testé.
  final QueueSnapshot? snapshot;

  @override
  Stream<QueueUpdate> watch(Ticket ticket) async* {
    yield QueueUpdate(
      snapshot:
          snapshot ??
          QueueSnapshot(
            ticketNumber: ticket.number,
            position: ticket.position,
            estimatedMinutes: ticket.estimatedMinutes,
            status: QueueStatus.waiting,
            updatedAt: DateTime(2026, 11, 15, 11, 34),
            calledNumber: 'T-1041',
            counterLabel: 'Guichet 2',
          ),
      source: QueueFeedSource.live,
    );
  }
}
