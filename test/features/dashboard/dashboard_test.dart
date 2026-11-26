import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/notifications_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/tickets_tab.dart';
import 'package:tonde/features/dashboard/presentation/widgets/tonde_navigation_bar.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tickets/domain/entities/ticket.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/screen.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

const _ticket = Ticket(
  number: 'T-9999',
  position: 3,
  estimatedMinutes: 6,
  organizationId: 'org-4',
  organizationName: 'Clinique Espoir',
  agencyId: 'ag-4',
  agencyName: 'Agence Rohero',
);

List<Override> _overrides({Ticket? ticket}) => [
  organizationRepositoryProvider.overrideWithValue(
    MockOrganizationRepository(latency: Duration.zero),
  ),
  authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
  ticketServiceProvider.overrideWithValue(FakeTicketService(ticket: ticket)),
  // Flux figé : la file n'avance pas pendant le test, et aucun minuteur de
  // simulation ne survit à la fin de l'arbre.
  queueTrackingServiceProvider.overrideWithValue(StaticQueueTrackingService()),
];

// L'IndexedStack garde les onglets masqués dans l'arbre (Visibility.maintain,
// opacité 0), donc les textes des onglets non sélectionnés restent trouvables :
// on restreint les recherches à l'onglet visé.
Finder _inHome(Finder matching) =>
    find.descendant(of: find.byType(HomeTab), matching: matching);
Finder _inTickets(Finder matching) =>
    find.descendant(of: find.byType(TicketsTab), matching: matching);
Finder _inNotifications(Finder matching) =>
    find.descendant(of: find.byType(NotificationsTab), matching: matching);
Finder _navDestination(String label) => find.descendant(
  of: find.byType(TondeNavigationBar),
  matching: find.text(label),
);

void main() {
  // Surface de téléphone : la taille par défaut de flutter_test (800×600)
  // fait basculer la coquille sur un rail latéral, et ces tests naviguent
  // dans la barre basse.
  setUp(usePhoneSurfaceForEachTest);

  testWidgets('affiche le ticket actif et les organisations sur l\'accueil', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(ticket: _ticket),
        child: const TondeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Avec un ticket actif, la bannière ne vante plus la prise de ticket :
    // elle situe le client dans la file et propose d'en suivre la position.
    expect(find.text("You're in the queue"), findsOneWidget);
    expect(_inHome(find.text('Waiting')), findsOneWidget);
    expect(_inHome(find.text('T-9999')), findsOneWidget);
    expect(_inHome(find.text('People ahead of you')), findsOneWidget);
    expect(_inHome(find.text('6 min')), findsOneWidget);
    expect(_inHome(find.text('See my position')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('My organizations'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // La section est construite à l'affichage (ListView paresseuse) : on
    // laisse sa requête se terminer avant de vérifier son contenu.
    await tester.pumpAndSettle();
    expect(find.text('My organizations'), findsOneWidget);
    expect(find.text('Banque Horizon'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Need help?'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Need help?'), findsOneWidget);
  });

  testWidgets('affiche un état vide sans ticket actif', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    expect(_inHome(find.text('No active ticket')), findsOneWidget);
    // Un seul bouton : celui de la bannière. La carte d'état vide explique la
    // situation sans répéter l'action juste en dessous.
    expect(_inHome(find.text('Take a ticket')), findsOneWidget);
  });

  testWidgets('les onglets Tickets et Notifications sont navigables', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(ticket: _ticket),
        child: const TondeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_navDestination('Tickets'));
    await tester.pumpAndSettle();

    expect(_inTickets(find.text('T-9999')), findsOneWidget);
    expect(_inTickets(find.text('Position in the queue: 3')), findsOneWidget);

    await tester.tap(_navDestination('Notifications'));
    await tester.pumpAndSettle();

    // L'onglet liste les alertes réellement émises pour le ticket courant.
    expect(
      _inNotifications(find.text('Your ticket T-9999 is confirmed')),
      findsOneWidget,
    );
    expect(
      _inNotifications(find.text('Your turn is coming up!')),
      findsOneWidget,
    );
  });

  testWidgets('la déconnexion ramène à la page de connexion', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const TondeApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(_navDestination('More'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Email address'), findsOneWidget);
  });

  testWidgets('annuler le ticket depuis l\'accueil demande confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // La file est déjà figée par `_overrides` : la carte ne bascule pas
        // « en cours » pendant que le test déroule le dialogue.
        overrides: _overrides(ticket: _ticket),
        child: const TondeApp(),
      ),
    );
    await tester.pumpAndSettle();

    final cancel = _inHome(find.text('Cancel ticket'));
    await tester.ensureVisible(cancel);
    await tester.pumpAndSettle();
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    // Aucune annulation ne part sans confirmation explicite.
    expect(find.text('Do you want to cancel the ticket?'), findsOneWidget);
    expect(
      find.text(
        'Ticket T-9999 will be removed from the queue '
        'and your place will be lost.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep my ticket'));
    await tester.pumpAndSettle();
    expect(_inHome(find.text('T-9999')), findsOneWidget);

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();

    expect(_inHome(find.text('No active ticket')), findsOneWidget);
    expect(find.text('Ticket cancelled'), findsOneWidget);
  });
}
