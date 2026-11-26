import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/layout/app_breakpoints.dart';
import 'package:tonde/core/layout/responsive_center.dart';
import 'package:tonde/core/layout/text_scale.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/pages/dashboard_shell.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';

import '../helpers/fakes.dart';

const _user = User(id: 'u-1', name: 'Test', email: 'test@example.com');

void main() {
  group('Classes de largeur', () {
    test('les seuils correspondent aux bornes annoncées', () {
      // 359 dp est le cas qui cassait la navigation : il doit rester compact.
      expect(AppBreakpoints.ofWidth(320), AppWidthClass.compact);
      expect(AppBreakpoints.ofWidth(359), AppWidthClass.compact);
      expect(AppBreakpoints.ofWidth(360), AppWidthClass.standard);
      expect(AppBreakpoints.ofWidth(599), AppWidthClass.standard);
      expect(AppBreakpoints.ofWidth(600), AppWidthClass.medium);
      expect(AppBreakpoints.ofWidth(899), AppWidthClass.medium);
      expect(AppBreakpoints.ofWidth(900), AppWidthClass.expanded);
      expect(AppBreakpoints.ofWidth(1600), AppWidthClass.expanded);
    });

    test('le rail apparaît à partir de 600 dp', () {
      expect(AppWidthClass.compact.usesRail, isFalse);
      expect(AppWidthClass.standard.usesRail, isFalse);
      expect(AppWidthClass.medium.usesRail, isTrue);
      expect(AppWidthClass.expanded.usesRail, isTrue);
    });

    test('les grilles gagnent une colonne par palier', () {
      expect(AppWidthClass.compact.gridColumns, 1);
      expect(AppWidthClass.standard.gridColumns, 1);
      expect(AppWidthClass.medium.gridColumns, 2);
      expect(AppWidthClass.expanded.gridColumns, 3);
    });
  });

  group('ResponsiveCenter', () {
    testWidgets('ne change rien sur un écran étroit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(child: SizedBox(height: 10, width: 400)),
          ),
        ),
      );

      // 400 dp de contenu sur un écran de test à 800 dp : le plafond de 560
      // n'est pas atteint, la largeur demandée est respectée.
      expect(tester.getSize(find.byType(SizedBox)).width, 400);
    });

    testWidgets('plafonne la largeur sur un grand écran', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(child: SizedBox(height: 10, width: 1200)),
          ),
        ),
      );

      // 1 200 dp demandés, 560 accordés : une ligne de texte plus large que
      // cela fatigue l'œil et désaligne les formulaires.
      expect(tester.getSize(find.byType(SizedBox)).width, 560);
    });
  });

  group('Plafond du facteur de police', () {
    testWidgets('ramène un réglage système à 2,0 sous 1,3', (tester) async {
      late TextScaler observed;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) {
              return clampTextScale(
                context,
                Builder(
                  builder: (inner) {
                    observed = MediaQuery.textScalerOf(inner);
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(observed.scale(10), closeTo(13, 0.01));
    });

    testWidgets('laisse passer un réglage raisonnable', (tester) async {
      late TextScaler observed;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.1)),
          child: Builder(
            builder: (context) {
              return clampTextScale(
                context,
                Builder(
                  builder: (inner) {
                    observed = MediaQuery.textScalerOf(inner);
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(observed.scale(10), closeTo(11, 0.01));
    });
  });

  group('Coquille du tableau de bord', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
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
    }

    testWidgets('une barre basse sur téléphone', (tester) async {
      await pumpAt(tester, const Size(360, 800));

      expect(find.byType(DashboardShell), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      // Le libellé le plus long doit rester entier, même à 360 dp.
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('un rail latéral sur grand écran', (tester) async {
      await pumpAt(tester, const Size(1024, 768));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });
  });
}
