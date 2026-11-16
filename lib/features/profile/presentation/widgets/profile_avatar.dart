import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/profile/domain/profile_photo_picker.dart';
import 'package:tonde/features/profile/presentation/controllers/profile_photo_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Avatar du compte connecté.
///
/// Affiche la photo choisie par l'utilisateur, ou l'illustration fournie avec
/// l'application tant qu'il n'en a pas choisi.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    this.radius = 24,
    this.onTap,
    this.editable = false,
    this.showEditBadge = false,
  });

  /// Rayon de l'avatar.
  final double radius;

  /// Action au toucher ; ignorée si [editable] est vrai.
  final VoidCallback? onTap;

  /// Ouvre directement le choix de la photo (galerie ou appareil photo).
  final bool editable;

  /// Affiche la pastille appareil photo, pour signaler que la photo se change.
  final bool showEditBadge;

  /// Illustration utilisée à défaut de photo personnelle.
  static const String fallbackAsset = 'assets/images/profile.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final photo = ref.watch(profilePhotoProvider).value;
    final diameter = radius * 2;

    Widget picture = SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: ColoredBox(color: Colors.white, child: _picture(photo)),
      ),
    );

    if (editable || showEditBadge) {
      picture = Stack(
        clipBehavior: Clip.none,
        children: [
          picture,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                // Liseré de la couleur du fond : la pastille se détache de
                // l'image sans flotter au-dessus.
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: radius * 0.45,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      );
    }

    final handler = editable
        ? () => showProfilePhotoSheet(context, ref)
        : onTap;
    if (handler == null) {
      return picture;
    }

    return Semantics(
      button: true,
      label: editable ? l10n.profilePhotoHint : l10n.profileTitle,
      child: InkWell(
        onTap: handler,
        customBorder: const CircleBorder(),
        child: picture,
      ),
    );
  }

  Widget _picture(String? photo) {
    if (photo == null) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }
    return Image.file(
      File(photo),
      fit: BoxFit.cover,
      // Le fichier a pu être supprimé hors de l'application : mieux vaut
      // l'illustration par défaut qu'un carré d'erreur.
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(fallbackAsset, fit: BoxFit.cover),
    );
  }
}

/// Choix offert à l'utilisateur pour sa photo de profil.
enum _PhotoAction { camera, gallery, remove }

/// Ouvre le menu de la photo de profil et applique le choix.
Future<void> showProfilePhotoSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final notifier = ref.read(profilePhotoProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final hasPhoto = ref.read(profilePhotoProvider).value != null;

  final action = await showModalBottomSheet<_PhotoAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.profilePhotoTitle,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.profilePhotoCamera),
            onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.profilePhotoGallery),
            onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.gallery),
          ),
          // Proposé seulement s'il y a quelque chose à retirer.
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                l10n.profilePhotoRemove,
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == null) {
    return;
  }

  try {
    if (action == _PhotoAction.remove) {
      await notifier.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoRemoved)));
      return;
    }
    final changed = await notifier.pick(
      action == _PhotoAction.camera
          ? ProfilePhotoSource.camera
          : ProfilePhotoSource.gallery,
    );
    // Une annulation du sélecteur n'est pas un échec : aucun message.
    if (changed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoUpdated)));
    }
  } on Object catch (error) {
    debugPrint('Photo de profil : $error');
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.profilePhotoFailed),
        backgroundColor: colorScheme.error,
      ),
    );
  }
}
