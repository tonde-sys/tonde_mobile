import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';

import '../../helpers/fakes.dart';

const _user = User(name: 'Jospin Kanani', username: 'jospin kanani');

void main() {
  testWidgets('l\'en-tête de l\'accueil ne défile pas avec le contenu', (
    tester,
  ) async {
    // Fenêtre étroite : le contenu dépasse à coup sûr, donc la page défile
    // réellement et le test prouve quelque chose.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationRepositoryProvider.overrideWithValue(
            MockOrganizationRepository(latency: Duration.zero),
          ),
          authServiceProvider.overrideWithValue(
            FakeAuthService(current: _user),
          ),
          ticketServiceProvider.overrideWithValue(FakeTicketService()),
          queueTrackingServiceProvider.overrideWithValue(
            StaticQueueTrackingService(),
          ),
        ],
        child: const TondeApp(),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.descendant(
      of: find.byType(HomeTab),
      matching: find.text('TONDE'),
    );
    expect(title, findsOneWidget);

    // L'en-tête est en dehors de la liste : il ne peut pas être emporté par
    // le défilement, contrairement à un simple premier élément de liste.
    expect(
      find.ancestor(of: title, matching: find.byType(ListView)),
      findsNothing,
    );

    final headerBefore = tester.getTopLeft(title);
    // La page défilante est la liste verticale ; la rangée horizontale des
    // organisations vit à l'intérieur et ne doit pas être prise pour cible.
    final list = find.descendant(
      of: find.byType(HomeTab),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.vertical,
      ),
    );
    expect(list, findsOneWidget);

    await tester.drag(list, const Offset(0, -260));
    await tester.pumpAndSettle();

    // La page a bien défilé...
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));

    // ...et l'en-tête n'a pas bougé d'un pixel.
    expect(tester.getTopLeft(title), headerBefore);
    expect(title.hitTestable(), findsOneWidget);
  });
}
