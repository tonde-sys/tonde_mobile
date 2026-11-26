import 'package:flutter/material.dart';

/// Centre le contenu et lui impose une largeur maximale.
///
/// Sur un téléphone, il ne fait rien : la largeur disponible est déjà inférieure
/// au plafond. Sur une tablette ou un écran de bureau, il évite qu'une ligne de
/// texte traverse 1 200 dp — au-delà d'environ 70 caractères, l'œil perd le
/// début de la ligne suivante.
///
/// [maxWidth] vaut 560 dp par défaut : la largeur d'une colonne de lecture
/// confortable, et celle qui garde les formulaires (prise de ticket, avis)
/// alignés avec les cartes de l'accueil.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
