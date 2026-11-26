import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/config/app_config_provider.dart';
import 'package:tonde/core/config/tonde_support.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/controllers/feedback_providers.dart';
import 'package:tonde/features/assistance/presentation/pages/faq_page.dart';
import 'package:tonde/features/assistance/presentation/pages/feedback_form_page.dart';
import 'package:tonde/features/assistance/presentation/pages/my_feedback_page.dart';
import 'package:tonde/features/dashboard/presentation/pages/assistance_tab.dart';
import 'package:tonde/features/organizations/data/repositories/organization_repository_provider.dart';
import 'package:tonde/features/organizations/domain/entities/agency.dart';
import 'package:tonde/features/organizations/domain/entities/agency_service.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/domain/repositories/organization_repository.dart';
import 'package:tonde/features/tickets/data/ticket_service_provider.dart';

import '../../helpers/fakes.dart';

/// Configuration sans aucun canal de contact : c'est l'état réel tant que
/// `TONDE_SUPPORT_*` n'est pas fourni à la compilation.
final _configSansContact = AppConfig.parse(
  environmentName: 'dev',
  apiBaseUrlRaw: '',
  enableHttpLogging: false,
);

/// Aucune institution rattachée : le cas d'un client qui découvre TONDE.
final class _EmptyOrganizationRepository implements OrganizationRepository {
  @override
  Future<List<Organization>> fetchOrganizations() async =>
      const <Organization>[];

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async =>
      const <Agency>[];

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async => const <AgencyService>[];
}

/// Une institution qui a publié toutes ses coordonnées.
final class _SingleOrganizationRepository implements OrganizationRepository {
  @override
  Future<List<Organization>> fetchOrganizations() async =>
      const <Organization>[
        Organization(
          id: 'org-1',
          name: 'Banque Horizon',
          type: OrganizationType.bank,
          supportPhone: '25722257890',
          supportWhatsapp: '25779123456',
          supportEmail: 'support@horizon.bi',
          supportHours: 'Lun–Ven 8h–16h',
        ),
      ];

  @override
  Future<List<Agency>> fetchAgencies(String organizationId) async =>
      const <Agency>[];

  @override
  Future<List<AgencyService>> fetchServices({
    required String organizationId,
    required String agencyId,
  }) async => const <AgencyService>[];
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required FakeFeedbackService feedback,
  AppConfig? config,
  OrganizationRepository? organizations,
}) async {
  final container = ProviderContainer(
    overrides: [
      feedbackServiceProvider.overrideWithValue(feedback),
      ticketServiceProvider.overrideWithValue(FakeTicketService()),
      appConfigProvider.overrideWithValue(config ?? _configSansContact),
      if (organizations != null)
        organizationRepositoryProvider.overrideWithValue(organizations),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fait défiler jusqu'à [finder].
///
/// Les sections du bas de l'assistance vivent dans un `ListView` : elles ne
/// sont construites qu'en entrant dans la fenêtre, donc introuvables tant
/// qu'on n'a pas défilé. Les chercher sans défiler ferait passer un écran
/// correct pour un écran vide.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Onglet Assistance', () {
    testWidgets('le centre d’aide propose les trois portes', (tester) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(),
      );

      expect(find.text("Centre d'aide"), findsOneWidget);
      expect(find.text('Comment pouvons-nous vous aider ?'), findsOneWidget);
      expect(find.text('Contacter mon institution'), findsOneWidget);
      expect(find.text('Contacter TONDE'), findsOneWidget);
      expect(find.text('Questions fréquentes'), findsOneWidget);
    });

    testWidgets('la fiche TONDE ne montre pas le numéro et propose les canaux', (
      tester,
    ) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(),
      );

      await tester.tap(find.text('Contacter TONDE'));
      await tester.pumpAndSettle();

      // Demande produit : le numéro n'apparaît jamais, seule l'icône appelle.
      expect(find.textContaining(TondeSupport.phone), findsNothing);
      expect(find.text('Appeler'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text(TondeSupport.email), findsOneWidget);
      expect(find.text('Disponible 24 h/24, 7 j/7'), findsOneWidget);
    });

    testWidgets('la fiche de l’institution affiche ses coordonnées', (
      tester,
    ) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(),
        organizations: _SingleOrganizationRepository(),
      );

      await tester.tap(find.text('Contacter mon institution'));
      await tester.pumpAndSettle();

      expect(find.text('Banque Horizon'), findsOneWidget);
      expect(find.text('Lun–Ven 8h–16h'), findsOneWidget);
      expect(find.text('+25722257890'), findsOneWidget);
      expect(find.text('support@horizon.bi'), findsOneWidget);
    });

    testWidgets('sans institution, la fiche le dit au lieu de rester vide', (
      tester,
    ) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(),
        organizations: _EmptyOrganizationRepository(),
      );

      await tester.tap(find.text('Contacter mon institution'));
      await tester.pumpAndSettle();

      expect(
        find.text('Aucune institution liée à votre compte.'),
        findsOneWidget,
      );
      expect(find.text('Parcourir les institutions'), findsOneWidget);
    });

    testWidgets('la FAQ garde ses six réponses', (tester) async {
      await _pump(
        tester,
        const FaqPage(),
        feedback: FakeFeedbackService(),
      );

      expect(find.text('Comment prendre un ticket ?'), findsOneWidget);
      expect(find.text('Mon ticket a expiré'), findsOneWidget);
      expect(find.text('Puis-je prendre deux tickets ?'), findsOneWidget);
    });

    testWidgets('l’état du service et la version sont affichés', (tester) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(reachable: true),
      );

      await _scrollTo(tester, find.text('État du service'));
      expect(find.text('État du service'), findsOneWidget);
      expect(find.text('Service joignable'), findsOneWidget);
      expect(find.text('Version $kAppVersion'), findsOneWidget);
    });

    testWidgets('un serveur muet est annoncé comme injoignable', (tester) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(reachable: false),
      );

      await _scrollTo(tester, find.text('Service injoignable'));
      expect(find.text('Service injoignable'), findsOneWidget);
    });

    testWidgets('la pastille de l’historique ne compte que les retours reçus', (
      tester,
    ) async {
      await _pump(
        tester,
        const AssistanceTab(),
        feedback: FakeFeedbackService(
          entries: [
            FeedbackEntry(
              id: 'fb-1',
              category: FeedbackCategory.review,
              message: 'Le guichet trois etait ferme ce matin',
              status: FeedbackStatus.received,
              createdAt: DateTime(2026, 11, 24, 10),
            ),
          ],
        ),
      );

      await _scrollTo(tester, find.text('Signaler un problème'));
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);
    });
  });

  group('Formulaire de retour', () {
    testWidgets('le bouton reste fermé sous 20 caractères', (tester) async {
      final feedback = FakeFeedbackService();
      await _pump(
        tester,
        const FeedbackFormPage(category: FeedbackCategory.review),
        feedback: feedback,
      );

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), 'trop court');
      await tester.pump();

      // Le serveur refuserait : autant le dire avant l'aller-retour.
      expect(find.text('Encore 10 caractères.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('un message valide part avec sa catégorie et sa note', (
      tester,
    ) async {
      final feedback = FakeFeedbackService();
      await _pump(
        tester,
        const FeedbackFormPage(category: FeedbackCategory.bug),
        feedback: feedback,
      );

      await tester.enterText(
        find.byType(TextField),
        'Le bouton de prise de ticket ne repond pas du tout',
      );
      await tester.pump();
      // 3e étoile : la note est facultative, mais elle doit être transmise.
      await tester.tap(find.byTooltip('3'));
      await tester.pump();

      // L'introduction a allongé le formulaire : le bouton peut être sous la
      // ligne de flottaison sur la surface de test (800×600).
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(feedback.submitted, hasLength(1));
      expect(feedback.submitted.single.category, FeedbackCategory.bug);
      expect(feedback.submitted.single.rating, 3);
      expect(
        feedback.submitted.single.message,
        'Le bouton de prise de ticket ne repond pas du tout',
      );
    });

    testWidgets('un quota atteint est expliqué à l’utilisateur', (
      tester,
    ) async {
      final feedback = FakeFeedbackService(
        failure: const ApiException(
          statusCode: 429,
          code: 'FEEDBACK_RATE_LIMITED',
        ),
      );
      await _pump(
        tester,
        const FeedbackFormPage(category: FeedbackCategory.review),
        feedback: feedback,
      );

      await tester.enterText(
        find.byType(TextField),
        'Le guichet trois etait ferme ce matin',
      );
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Vous avez envoyé plusieurs retours récemment. Réessayez dans une heure.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Mes retours', () {
    testWidgets('un historique vide invite à en envoyer un', (tester) async {
      await _pump(
        tester,
        const MyFeedbackPage(),
        feedback: FakeFeedbackService(),
      );

      expect(find.text('Aucun retour envoyé'), findsOneWidget);
    });

    testWidgets('chaque retour affiche son état de traitement', (tester) async {
      await _pump(
        tester,
        const MyFeedbackPage(),
        feedback: FakeFeedbackService(
          entries: [
            FeedbackEntry(
              id: 'fb-2',
              category: FeedbackCategory.bug,
              message: 'Le bouton de prise de ticket ne repond pas du tout',
              status: FeedbackStatus.resolved,
              createdAt: DateTime(2026, 11, 24, 10),
            ),
            FeedbackEntry(
              id: 'fb-1',
              category: FeedbackCategory.review,
              message: 'Le guichet trois etait ferme ce matin',
              status: FeedbackStatus.received,
              createdAt: DateTime(2026, 11, 23, 9),
              rating: 2,
            ),
          ],
        ),
      );

      expect(find.text('Traité'), findsOneWidget);
      expect(find.text('Reçu'), findsOneWidget);
      expect(find.text('Problème'), findsOneWidget);
    });
  });
}
