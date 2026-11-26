import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/organizations/data/repositories/mock_organization_repository.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';

import '../../helpers/fakes.dart';

const _user = User(id: 'u-test', name: 'Test', email: 'test@example.com');

class _FailingOrganizationRepository implements OrganizationRepository {
  @override
  Future<List<Organization>> fetchOrganizations() async {
    throw const NetworkException();
  }

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async {
    throw const NetworkException();
  }

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async {
    throw const NetworkException();
  }
}

Future<void> _pumpAndOpenOrganizations(
  WidgetTester tester, {
  required OrganizationRepository repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      organizationRepositoryProvider.overrideWithValue(repository),
      authServiceProvider.overrideWithValue(FakeAuthService(current: _user)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TondeApp()),
  );
  await tester.pumpAndSettle();

  container.read(appRouterProvider).go('/organizations');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la recherche filtre les organisations', (tester) async {
    await _pumpAndOpenOrganizations(
      tester,
      repository: MockOrganizationRepository(latency: Duration.zero),
    );

    expect(find.text('Banque Horizon'), findsOneWidget);
    expect(find.text('Clinique Espoir'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'horizon');
    await tester.pumpAndSettle();

    expect(find.text('Banque Horizon'), findsOneWidget);
    expect(find.text('Clinique Espoir'), findsNothing);
  });

  testWidgets('toucher une organisation ouvre le détail avec ses agences', (
    tester,
  ) async {
    await _pumpAndOpenOrganizations(
      tester,
      repository: MockOrganizationRepository(latency: Duration.zero),
    );

    await tester.tap(find.text('Banque Horizon'));
    await tester.pumpAndSettle();

    expect(find.text('Agencies'), findsOneWidget);
    expect(find.text('Agence Bujumbura Centre'), findsOneWidget);
    expect(find.text("Boulevard de l'Uprona, Bujumbura"), findsOneWidget);
  });

  testWidgets('une erreur réseau affiche un bouton de nouvelle tentative', (
    tester,
  ) async {
    await _pumpAndOpenOrganizations(
      tester,
      repository: _FailingOrganizationRepository(),
    );

    // Depuis L7, une coupure réseau n'affiche plus le message générique
    // « impossible de charger » : elle dit ce qui se passe réellement.
    expect(
      find.text('Server unreachable. Check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
