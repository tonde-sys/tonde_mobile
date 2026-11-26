import 'package:flutter/widgets.dart';

/// Facteur de police maximal appliqué par l'application.
///
/// Le système autorise jusqu'à 2,0 (voire plus avec les réglages
/// d'accessibilité). À cette taille, les rangées de la carte de ticket, les
/// libellés de la barre de navigation et les boutons débordent : le texte est
/// coupé, et l'information devient moins lisible qu'à taille normale — l'inverse
/// du but recherché.
///
/// 1,3 couvre les besoins courants (presbytie légère, écrans denses) sans
/// casser la mise en page. Au-delà, ce n'est plus un problème de facteur mais
/// de conception, et cela demanderait un mode « grand texte » dédié.
const double kMaxTextScaleFactor = 1.3;

/// Applique le plafond au facteur de police courant.
///
/// Passé par le `builder` de `MaterialApp` : un seul endroit, donc aucun écran
/// ne peut l'oublier — et aucun ne peut non plus le contourner par mégarde.
Widget clampTextScale(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(
      textScaler: media.textScaler.clamp(
        maxScaleFactor: kMaxTextScaleFactor,
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}
