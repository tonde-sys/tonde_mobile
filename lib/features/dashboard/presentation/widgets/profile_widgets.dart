import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/auth/domain/user.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Widget d'en-tête du profil : grand avatar, nom et identifiant de connexion.
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, this.user});

  /// Utilisateur à afficher ; si null, l'utilisateur connecté est utilisé.
  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolved = user ?? ref.watch(authControllerProvider).value;

    return Column(
      children: [
        ProfileAvatar(radius: 48, editable: true),
        const SizedBox(height: 12),
        Text(
          resolved?.name ?? l10n.profileTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        // Pas de ligne d'identifiant ici : le backend n'a pas de nom
        // d'utilisateur, et l'e-mail est déjà listé dans la carte
        // d'informations juste en dessous. L'afficher deux fois sur le même
        // écran n'ajoute rien et donne l'impression d'un doublon de données.

        const SizedBox(height: 6),
        // Sans cette ligne, la pastille appareil photo se lit comme un
        // ornement : le geste attendu doit être écrit.
        Text(
          l10n.profilePhotoHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Carte listant les informations du compte.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notAvailable = l10n.profileNotAvailable;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (user.email != null)
            ProfileInfoTile(
              icon: Icons.email_outlined,
              label: l10n.profileEmail,
              value: user.email!,
            ),
          if (user.phone != null)
            ProfileInfoTile(
              icon: Icons.phone_outlined,
              label: l10n.profilePhone,
              value: user.phone!,
            ),
          if (user.role != null)
            ProfileInfoTile(
              icon: Icons.badge_outlined,
              label: l10n.profileRole,
              value: user.role!,
            ),
          if (user.organization != null)
            ProfileInfoTile(
              icon: Icons.business_outlined,
              label: l10n.profileOrganization,
              value: user.organization!,
            ),
          if (user.createdAt != null)
            ProfileInfoTile(
              icon: Icons.calendar_today_outlined,
              label: l10n.profileMemberSince,
              value: formatProfileDate(user.createdAt!),
            ),
          if (user.email == null &&
              user.phone == null &&
              user.role == null &&
              user.organization == null &&
              user.createdAt == null)
            ProfileInfoTile(
              icon: Icons.info_outline,
              label: l10n.profileAccountInfo,
              value: notAvailable,
            ),
        ],
      ),
    );
  }
}

/// Une ligne d'information avec icône, libellé et valeur.
class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Titre de section du profil.
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Formate une date ISO (yyyy-MM-dd) en format lisible jj/mm/aaaa.
String formatProfileDate(String iso) {
  try {
    final parts = iso.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
  } catch (_) {
    // Date illisible : on renvoie la valeur brute.
  }
  return iso;
}
