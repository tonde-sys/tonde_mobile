import 'package:flutter/widgets.dart';

/// Classes de largeur de l'application.
///
/// Quatre classes, pas cinq : au-delà de 900 dp, la mise en page ne change plus,
/// elle s'élargit. Ajouter une classe « extra-large » aurait multiplié les cas
/// à tester pour un gain visuel nul sur une application de file d'attente.
enum AppWidthClass {
  /// Téléphones étroits (320–359 dp). C'est le cas qui cassait la barre de
  /// navigation : « Notifications » coupé au milieu du mot.
  compact,

  /// Téléphones courants (360–599 dp).
  standard,

  /// Petites tablettes et téléphones en paysage (600–899 dp).
  medium,

  /// Tablettes et bureau (≥ 900 dp).
  expanded;

  /// Vrai quand la barre de navigation doit passer sur le côté.
  ///
  /// Le seuil est celui de Material : en dessous de 600 dp, une barre latérale
  /// mangerait trop de largeur utile.
  bool get usesRail => this == AppWidthClass.medium || this == AppWidthClass.expanded;

  /// Nombre de colonnes pour une grille de fiches.
  int get gridColumns => switch (this) {
    AppWidthClass.compact || AppWidthClass.standard => 1,
    AppWidthClass.medium => 2,
    AppWidthClass.expanded => 3,
  };
}

/// Seuils de largeur, en dp logiques.
///
/// Regroupés ici plutôt que dispersés en `MediaQuery.of(context).size.width > …` :
/// un seuil écrit à deux endroits finit toujours par diverger, et la moitié de
/// l'écran change de disposition avant l'autre.
abstract final class AppBreakpoints {
  static const double compact = 360;
  static const double medium = 600;
  static const double expanded = 900;

  static AppWidthClass ofWidth(double width) {
    if (width < compact) return AppWidthClass.compact;
    if (width < medium) return AppWidthClass.standard;
    if (width < expanded) return AppWidthClass.medium;
    return AppWidthClass.expanded;
  }

  /// Classe de largeur courante.
  ///
  /// `MediaQuery.sizeOf` et non `MediaQuery.of` : seule la taille est écoutée,
  /// donc un changement de clavier ou de barre système ne reconstruit pas
  /// l'arbre entier.
  static AppWidthClass of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);
}
