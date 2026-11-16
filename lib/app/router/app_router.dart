import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/pages/foundation_page.dart';
import 'package:tonde/app/pages/not_found_page.dart';
import 'package:tonde/app/router/app_routes.dart';
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
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
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
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfilePage(),
      ),
    ],
    // Porte d'authentification : toute page privée renvoie vers la
    // connexion tant qu'aucun utilisateur n'est connecté.
    redirect: (context, state) {
      final isAuthenticated = ref.read(authControllerProvider).value != null;
      final location = state.matchedLocation;
      final isAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;
      if (!isAuthenticated && !isAuthPage) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthPage) {
        return AppRoutes.home;
      }
      return null;
    },
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  // Ne rafraîchit le routeur que lorsque l'état d'authentification change
  // réellement (connexion ↔ déconnexion), pas lors d'une simple mise à jour
  // du profil. Cela évite que context.pop() soit annulé après une édition.
  ref.listen<AsyncValue<User?>>(authControllerProvider, (previous, next) {
    final wasAuthenticated = previous?.value != null;
    final isAuthenticated = next.value != null;
    if (wasAuthenticated != isAuthenticated) {
      router.refresh();
    }
  });

  ref.onDispose(router.dispose);
  return router;
});
