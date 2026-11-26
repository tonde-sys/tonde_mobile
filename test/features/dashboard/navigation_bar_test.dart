import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/dashboard/presentation/widgets/tonde_navigation_bar.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';
import 'package:tonde/features/tracking/data/queue_tracking_service_provider.dart';

import '../../helpers/fakes.dart';

const _user = User(
  id: 'u-jospin',
  name: 'Jospin Kanani',
  email: 'jospin@example.com',
);

/// Monte l'application sur une largeur d'écran donnée, en français.
///
/// Le français est la langue la plus exigeante pour cette barre :
/// « Notifications » et « Assistance » y sont les libellés les plus longs.
Future<void> _pumpAppAt(WidgetTester tester, Size size) async {
  tester.platformDispatcher.localesTestValue = const [Locale('fr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(
          const MockOrganizationRepository(latency: Duration.zero),
        ),
        authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
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

void main() {
  // 320 dp est la largeur la plus étroite encore courante (téléphones
  // d'entrée de gamme sous Android). C'est là que les libellés de la barre se
  // coupaient au milieu d'un mot.
  const narrow = Size(320, 640);

  testWidgets('les cinq libellés tiennent sur une seule ligne en 320 dp', (
    tester,
  ) async {
    await _pumpAppAt(tester, narrow);

    const labels = [
      'Accueil',
      'Tickets',
      'Notifications',
      'Assistance',
      'Plus',
    ];

    final barWidth = tester.getSize(find.byType(TondeNavigationBar)).width;
    final slot = barWidth / labels.length;

    for (final label in labels) {
      final finder = find.descendant(
        of: find.byType(TondeNavigationBar),
        matching: find.text(label),
      );
      expect(finder, findsOneWidget, reason: '« $label » doit être affiché');

      final textSize = tester.getSize(finder);
      // Une ligne de labelMedium mesure une quinzaine de pixels ; deux lignes
      // doubleraient cette hauteur. C'est le repli qu'on interdit ici.
      expect(
        textSize.height,
        lessThan(24),
        reason: '« $label » ne doit pas être renvoyé à la ligne',
      );

      // Le libellé est réduit pour tenir dans son onglet — jamais tronqué par
      // une ellipse, jamais débordant sur le voisin.
      final scaled = tester.getSize(
        find.ancestor(of: finder, matching: find.byType(FittedBox)).first,
      );
      expect(
        scaled.width,
        lessThanOrEqualTo(slot),
        reason: '« $label » doit tenir dans son onglet',
      );
    }
  });

  testWidgets('un onglet reste sélectionnable en 320 dp', (tester) async {
    await _pumpAppAt(tester, narrow);

    await tester.tap(
      find.descendant(
        of: find.byType(TondeNavigationBar),
        matching: find.text('Notifications'),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<TondeNavigationBar>(
      find.byType(TondeNavigationBar),
    );
    expect(bar.selectedIndex, 2);
  });
}
