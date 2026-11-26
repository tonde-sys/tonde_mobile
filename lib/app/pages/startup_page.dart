import 'package:flutter/material.dart';
import 'package:tonde/app/pages/splash_page.dart';

/// Écran d'attente pendant la résolution de la session.
///
/// Il n'apparaît que dans un seul cas : le démarrage a dépassé son délai
/// d'attente (`TondeBootstrap.sessionTimeout`) et la session n'est toujours
/// pas connue — réseau lent, serveur qui tarde. L'application s'ouvre alors
/// ici plutôt que sur l'écran de connexion, qui serait un mensonge : on ne
/// sait pas encore si l'utilisateur est connecté.
///
/// La mise en page est celle de l'écran de marque ([SplashBrand]) : mêmes
/// teintes, même logo, même signature, à la même place. Seule la file
/// d'attente cède la place à un indicateur — le logo ne bouge donc pas d'un
/// pixel au passage de l'un à l'autre.
class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashBrand(
      // La zone du pied reçoit une surface serrée de 200 × 76 : l'indicateur
      // s'y centre pour rester un détail, pas un aplat.
      footer: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(SplashPage.foreground),
          ),
        ),
      ),
    );
  }
}
