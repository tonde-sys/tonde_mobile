import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tonde/features/profile/domain/profile_photo_picker.dart';

/// Sélecteur natif : galerie via le sélecteur système d'Android, appareil photo
/// via l'intention caméra.
///
/// Aucune autorisation n'est demandée à l'utilisateur : le système ne remet à
/// l'application que l'image réellement choisie. C'est aussi la raison pour
/// laquelle le manifeste ne déclare pas `CAMERA` — le déclarer obligerait à
/// réclamer l'autorisation au premier usage.
final class LocalProfilePhotoPicker implements ProfilePhotoPicker {
  LocalProfilePhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Côté maximal de l'image enregistrée : un avatar s'affiche au plus sur
  /// quelques centaines de pixels, inutile de garder la photo d'origine.
  static const double _maxSide = 1024;

  @override
  Future<String?> pick(ProfilePhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == ProfilePhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: 88,
      // Un selfie se prend de face : c'est le portrait que l'on veut afficher.
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) {
      return null;
    }
    return _persist(File(picked.path));
  }

  /// Copie l'image hors du cache.
  ///
  /// Le sélecteur écrit dans un répertoire que le système peut vider à tout
  /// moment ; la photo de profil doit survivre à un redémarrage du téléphone.
  Future<String> _persist(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    // Un nom unique à chaque prise évite que Flutter réaffiche l'ancienne
    // image décodée, mise en cache sur le chemin précédent.
    final target = File(
      '${directory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final copied = await source.copy(target.path);
    return copied.path;
  }

  @override
  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (error) {
      // Un fichier déjà absent n'est pas une erreur pour l'appelant.
      debugPrint('Photo de profil introuvable : $error');
    }
  }
}
