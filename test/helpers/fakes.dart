import 'package:tonde/features/assistance/data/feedback_service.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tickets/domain/entities/ticket_status.dart';
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
  FakeTicketService({this.ticket, this.lastClosed});

  Ticket? ticket;

  /// Ticket qui vient de disparaître, si le scénario testé en a un.
  Ticket? lastClosed;

  /// Nombre de reprises demandées, pour vérifier qu'un appui déclenche bien
  /// l'appel — et qu'il ne part pas deux fois.
  int resumeCalls = 0;

  @override
  Future<Ticket?> activeTicket() async => ticket;

  @override
  Future<Ticket?> lastClosedTicket() async => lastClosed;

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
  Future<void> saveStatus(Ticket ticket) async {
    this.ticket = ticket;
  }

  @override
  Future<void> cancelTicket() async {
    ticket = null;
  }

  @override
  Future<Ticket> resumeTicket(Ticket ticket) async {
    resumeCalls++;
    final resumed = ticket.copyWith(
      status: TicketStatus.waiting,
      clearRecoveryExpiresAt: true,
    );
    this.ticket = resumed;
    return resumed;
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

/// Service de retours de test : garde en mémoire ce qui a été envoyé.
///
/// [failure] permet de rejouer un refus du serveur sans pile HTTP : c'est le
/// seul moyen de vérifier que le formulaire affiche bien « quota atteint »
/// plutôt qu'un message d'échec générique.
class FakeFeedbackService implements FeedbackService {
  FakeFeedbackService({
    List<FeedbackEntry> entries = const <FeedbackEntry>[],
    this.failure,
    this.reachable = true,
  }) : _entries = List<FeedbackEntry>.of(entries);

  List<FeedbackEntry> _entries;

  /// Erreur levée par [submit] ; nulle quand l'envoi doit réussir.
  final Object? failure;

  final bool reachable;

  /// Tout ce que le formulaire a transmis, pour vérifier le contenu exact.
  final List<FeedbackDraft> submitted = <FeedbackDraft>[];

  @override
  Future<FeedbackEntry> submit(FeedbackDraft draft) async {
    submitted.add(draft);
    final error = failure;
    if (error != null) {
      throw error;
    }
    final entry = FeedbackEntry(
      id: 'fb-${submitted.length}',
      category: draft.category,
      message: draft.message,
      status: FeedbackStatus.received,
      createdAt: DateTime(2026, 11, 24, 10),
      rating: draft.rating,
      appVersion: draft.appVersion,
    );
    _entries = <FeedbackEntry>[entry, ..._entries];
    return entry;
  }

  @override
  Future<List<FeedbackEntry>> mine({int page = 1, int pageSize = 20}) async {
    return List<FeedbackEntry>.unmodifiable(_entries);
  }

  @override
  Future<bool> ping() async => reachable;
}
