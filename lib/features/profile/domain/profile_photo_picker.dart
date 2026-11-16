/// Origine d'une nouvelle photo de profil.
enum ProfilePhotoSource {
  /// Photothèque du téléphone.
  gallery,

  /// Appareil photo du téléphone.
  camera,
}

/// Sélection d'une photo de profil sur l'appareil.
///
/// L'interface reste volontairement étroite : l'écran ne sait pas si l'image
/// vient de la galerie, de l'appareil photo ou d'un futur stockage distant, et
/// les tests n'ont donc besoin d'aucun plugin natif pour la vérifier.
abstract interface class ProfilePhotoPicker {
  /// Ouvre le sélecteur système et renvoie le chemin de l'image retenue.
  ///
  /// Renvoie `null` quand l'utilisateur annule : ce n'est pas une erreur, donc
  /// rien ne doit être signalé à l'écran.
  Future<String?> pick(ProfilePhotoSource source);

  /// Supprime une image précédemment renvoyée par [pick].
  Future<void> delete(String path);
}

/// Sélecteur inerte : utilisé par les tests et les aperçus.
///
/// Aucune photo n'est jamais renvoyée, mais l'écran qui l'utilise reste
/// entièrement navigable.
final class NoopProfilePhotoPicker implements ProfilePhotoPicker {
  const NoopProfilePhotoPicker();

  @override
  Future<String?> pick(ProfilePhotoSource source) async => null;

  @override
  Future<void> delete(String path) async {}
}
