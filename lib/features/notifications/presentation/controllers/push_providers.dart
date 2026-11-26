import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/app/router/app_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/notifications/data/push_registrar.dart';
import 'package:tonde/features/notifications/data/push_service.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';

/// Branche les notifications push sur la session et sur la navigation.
///
/// Observé une seule fois, au sommet de l'application : un jeton doit être
/// enregistré même si l'utilisateur reste sur l'onglet Profil, et un appui sur
/// une notification doit ouvrir le suivi depuis n'importe quel écran.
final pushDriverProvider = Provider<void>((ref) {
  final registrar = ref.watch(pushRegistrarProvider);
  final service = ref.watch(pushServiceProvider);

  // Le jeton est enregistré dès qu'une session apparaît — connexion, ou
  // session restaurée au démarrage. La déconnexion, elle, est traitée dans
  // AuthNotifier.logout() : il faut y couper le jeton *avant* de fermer la
  // session, sinon l'appel d'enregistrement serait refusé.
  ref.listen(authControllerProvider, (previous, next) {
    final wasSignedIn = previous?.value != null;
    final isSignedIn = next.value != null;
    if (isSignedIn && !wasSignedIn) {
      unawaited(registrar.register());
    }
  }, fireImmediately: true);

  final taps = service.taps.listen((tap) => unawaited(_open(ref, tap)));
  ref.onDispose(taps.cancel);

  // Application lancée par un appui : ce message n'est pas dans le flux, il
  // faut aller le chercher une fois.
  unawaited(_openInitial(ref, service));
});

Future<void> _openInitial(Ref ref, PushService service) async {
  final tap = await service.initialTap();
  if (tap != null) {
    await _open(ref, tap);
  }
}

/// Ouvre le suivi du ticket désigné par [tap].
///
/// Le ticket du payload doit être celui du compte connecté. Un message peut
/// arriver en retard, ou désigner un ticket pris depuis un autre appareil :
/// ouvrir le suivi d'un ticket qui n'est pas le sien afficherait un écran vide
/// ou, pire, le ticket de quelqu'un d'autre.
Future<void> _open(Ref ref, PushTap tap) async {
  final router = ref.read(appRouterProvider);

  final current = ref.read(activeTicketProvider).value;
  if (current != null && current.id == tap.ticketId) {
    router.go(AppRoutes.queueTracking);
    return;
  }

  // Le ticket a pu être pris depuis un autre appareil, ou le cache est en
  // retard sur le serveur : on redemande avant de décider.
  ref.invalidate(activeTicketProvider);
  final refreshed = await ref.read(activeTicketProvider.future);
  if (refreshed != null && refreshed.id == tap.ticketId) {
    router.go(AppRoutes.queueTracking);
  } else {
    router.go(AppRoutes.home);
  }
}
