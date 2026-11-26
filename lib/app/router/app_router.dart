import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/pages/foundation_page.dart';
import 'package:tonde/app/pages/not_found_page.dart';
import 'package:tonde/app/pages/startup_page.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/assistance/domain/feedback_entry.dart';
import 'package:tonde/features/assistance/presentation/pages/faq_page.dart';
import 'package:tonde/features/assistance/presentation/pages/feedback_form_page.dart';
import 'package:tonde/features/assistance/presentation/pages/my_feedback_page.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/auth/presentation/pages/login_page.dart';
import 'package:tonde/features/auth/presentation/pages/register_page.dart';
import 'package:tonde/features/dashboard/presentation/pages/dashboard_shell.dart';
import 'package:tonde/features/dashboard/presentation/pages/edit_profile_page.dart';
import 'package:tonde/features/dashboard/presentation/pages/profile_page.dart';
import 'package:tonde/features/organizations/presentation/pages/agency_services_page.dart';
import 'package:tonde/features/organizations/presentation/pages/organization_detail_page.dart';
import 'package:tonde/features/organizations/presentation/pages/organizations_page.dart';
import 'package:tonde/features/tickets/presentation/pages/ticket_page.dart';
import 'package:tonde/features/tracking/presentation/pages/queue_tracking_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // La session est déjà résolue quand ce provider est lu : `TondeBootstrap`
  // attend sa réponse avant de construire l'application. L'emplacement initial
  // est donc le bon dès la première image, et un utilisateur connecté ne voit
  // jamais l'écran de connexion.
  //
  // Si la résolution a dépassé le délai autorisé, on démarre sur l'écran
  // d'attente — jamais sur la connexion, qui serait un mensonge visuel.
  final resolved = ref.read(authControllerProvider);
  final initialLocation = resolved.isLoading
      ? AppRoutes.startup
      : (resolved.value != null ? AppRoutes.home : AppRoutes.login);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.startup,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DashboardShell(),
      ),
      GoRoute(
        path: AppRoutes.organizations,
        builder: (context, state) => const OrganizationsPage(),
      ),
      GoRoute(
        path: AppRoutes.organizationDetail,
        builder: (context, state) =>
            OrganizationDetailPage(organizationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.agencyServices,
        builder: (context, state) => AgencyServicesPage(
          organizationId: state.pathParameters['organizationId']!,
          agencyId: state.pathParameters['agencyId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.agencyTicket,
        builder: (context, state) => TicketPage(
          organizationId: state.pathParameters['organizationId']!,
          agencyId: state.pathParameters['agencyId']!,
          serviceId: state.pathParameters['serviceId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.foundation,
        builder: (context, state) => const FoundationPage(),
      ),
      GoRoute(
        path: AppRoutes.queueTracking,
        builder: (context, state) => const QueueTrackingPage(),
      ),
      GoRoute(
        path: AppRoutes.feedbackNew,
        builder: (context, state) => FeedbackFormPage(
          // Sans catégorie dans l'URL, on part sur un avis : c'est l'entrée la
          // plus courante, et le sélecteur reste modifiable sur l'écran.
          category: switch (state.uri.queryParameters['categorie']) {
            'bug' => FeedbackCategory.bug,
            'suggestion' => FeedbackCategory.suggestion,
            _ => FeedbackCategory.review,
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.myFeedback,
        builder: (context, state) => const MyFeedbackPage(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (context, state) => const FaqPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfilePage(),
      ),
    ],
    // Porte d'authentification.
    //
    // Règle : tant que l'état de session est INCONNU (`AsyncLoading`), on ne
    // décide rien. Rediriger pendant le chargement était la cause du
    // clignotement « connexion puis tableau de bord » : au démarrage à froid,
    // `.value` vaut null alors que la session est simplement en train d'être
    // relue, et l'application concluait à tort à une déconnexion.
    //
    // Cette neutralité sert aussi les actions en cours : annuler un ticket ou
    // mettre à jour un profil passe l'état en chargement, et l'utilisateur ne
    // doit pas être déplacé pour autant.
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) {
        return null;
      }

      final location = state.matchedLocation;
      final onAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;
      final onStartup = location == AppRoutes.startup;
      final isAuthenticated = auth.value != null;

      // L'attente est terminée : on quitte l'écran de démarrage.
      if (onStartup) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }
      if (!isAuthenticated && !onAuthPage) {
        return AppRoutes.login;
      }
      if (isAuthenticated && onAuthPage) {
        return AppRoutes.home;
      }
      return null;
    },
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  // Rafraîchit le routeur dès que la session devient *connue*, et à chaque
  // bascule connexion ↔ déconnexion.
  //
  // Le premier cas est indispensable : si le démarrage a dépassé son délai
  // d'attente, l'application s'est ouverte sur `/demarrage` alors que la
  // session était encore en cours de lecture. Sans ce rafraîchissement, une
  // résolution vers « personne » laisserait l'utilisateur sur l'écran
  // d'attente indéfiniment — le statut ne « bascule » pas, il se révèle.
  //
  // Une simple mise à jour de profil, elle, ne rafraîchit rien : cela
  // annulerait le `context.pop()` qui suit l'édition.
  ref.listen<AsyncValue<User?>>(authControllerProvider, (previous, next) {
    final wasResolved = previous != null && !previous.isLoading;
    final isResolved = !next.isLoading;
    final wasAuthenticated = previous?.value != null;
    final isAuthenticated = next.value != null;
    if ((isResolved && !wasResolved) || wasAuthenticated != isAuthenticated) {
      router.refresh();
    }
  });

  ref.onDispose(router.dispose);
  return router;
});
