import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Surface de téléphone utilisée par les tests de navigation.
///
/// 390×844 dp : la taille d'un téléphone courant, au-dessus du seuil « compact »
/// de 360 dp mais bien en dessous des 600 dp qui font basculer la coquille sur
/// un rail latéral.
const Size kPhoneSurface = Size(390, 844);

/// Impose une surface de téléphone à tous les tests d'un fichier.
///
/// `flutter_test` rend par défaut sur 800×600 dp. Depuis L8, cette largeur
/// déclenche le rail latéral : les tests qui tapent dans la barre de navigation
/// basse ne trouvent plus rien, alors que l'application est correcte. Ces tests
/// décrivent le téléphone ; ils doivent donc s'exécuter à une largeur de
/// téléphone. Ceux qui décrivent la tablette fixent leur propre taille.
///
/// À appeler depuis un `setUp` :
/// ```dart
/// setUp(usePhoneSurfaceForEachTest);
/// ```
void usePhoneSurfaceForEachTest() {
  final views = TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .views;
  for (final view in views) {
    view.physicalSize = kPhoneSurface;
    view.devicePixelRatio = 1;
  }
}
