import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/profile/domain/profile_photo_picker.dart';

/// Sélecteur de photo de profil.
///
/// La valeur par défaut est inerte : sans appareil (tests, aperçus), l'écran
/// reste utilisable et se contente de ne rien changer. `main()` la remplace
/// par le sélecteur natif.
final profilePhotoPickerProvider = Provider<ProfilePhotoPicker>(
  (ref) => const NoopProfilePhotoPicker(),
);

/// Chemin de la photo de profil du compte connecté, ou `null` si le client
/// garde l'illustration par défaut.
final profilePhotoProvider =
    AsyncNotifierProvider<ProfilePhotoNotifier, String?>(
      ProfilePhotoNotifier.new,
    );

class ProfilePhotoNotifier extends AsyncNotifier<String?> {
  /// La photo appartient au compte : deux personnes qui se succèdent sur le
  /// même téléphone ne doivent pas hériter de l'avatar de la précédente.
  ///
  /// La clé est l'identifiant serveur, et non l'e-mail : celui-ci peut changer
  /// (l'utilisateur en demande la modification), et la photo disparaîtrait avec
  /// lui.
  static String keyFor(String userId) => 'profile.photo.$userId';

  @override
  Future<String?> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return null;
    }
    final cached = await ref
        .watch(localCacheProvider)
        .read(keyFor(user.id));
    if (cached is! String) {
      return null;
    }
    // Un fichier effacé (nettoyage du téléphone, restauration) ne doit pas
    // laisser un avatar vide : on retombe sur l'illustration par défaut.
    return File(cached).existsSync() ? cached : null;
  }

  /// Ouvre le sélecteur puis enregistre la photo retenue.
  ///
  /// Renvoie `false` quand l'utilisateur annule : l'écran n'a alors rien à
  /// annoncer, une annulation n'étant pas un échec.
  Future<bool> pick(ProfilePhotoSource source) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      return false;
    }
    final picker = ref.read(profilePhotoPickerProvider);
    final previous = state.value;
    final path = await picker.pick(source);
    if (path == null) {
      return false;
    }
    if (!ref.mounted) {
      // L'écran a été quitté pendant la sélection : le fichier resterait
      // orphelin, on le retire plutôt que de le laisser sur le disque.
      await picker.delete(path);
      return false;
    }
    await ref.read(localCacheProvider).write(keyFor(user.id), path);
    state = AsyncData(path);
    if (previous != null && previous != path) {
      // L'ancienne image n'est plus référencée : la garder ne ferait
      // qu'accumuler des fichiers invisibles.
      await picker.delete(previous);
    }
    return true;
  }

  /// Revient à l'illustration par défaut.
  Future<void> clear() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      return;
    }
    final previous = state.value;
    await ref.read(localCacheProvider).write(keyFor(user.id), null);
    if (!ref.mounted) {
      return;
    }
    state = const AsyncData(null);
    if (previous != null) {
      await ref.read(profilePhotoPickerProvider).delete(previous);
    }
  }
}
