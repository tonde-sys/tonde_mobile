import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/dashboard/presentation/widgets/profile_widgets.dart';
import 'package:tonde/features/dashboard/presentation/widgets/settings_sheets.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tonde/features/tickets/presentation/controllers/home_widget_driver.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Onglet Plus : accès au profil, préférences d'affichage et déconnexion.
///
/// Aucune donnée personnelle n'est affichée ici : la tuile de compte ne montre
/// que l'icône de l'utilisateur, et les informations (nom, e-mail,
/// téléphone, rôle, organisation) s'ouvrent au clic sur la page profil. C'est
/// aussi ce qui rend l'onglet présentable sur un téléphone partagé.
class MoreTab extends ConsumerWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Compte : icône seule, le détail vit sur la page profil ----
          _AccountTile(onTap: () => context.push(AppRoutes.profile)),
          const SizedBox(height: 24),

          // ---- Préférences d'affichage ----
          ProfileSectionTitle(text: l10n.moreSettings),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.moreNotifications),
                  subtitle: Text(l10n.moreNotificationsSubtitle),
                  value: ref.watch(notificationsEnabledProvider),
                  onChanged: (value) => ref
                      .read(notificationsEnabledProvider.notifier)
                      .select(value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: Text(l10n.moreCallSound),
                  subtitle: Text(l10n.moreCallSoundSubtitle),
                  value: ref.watch(callSoundEnabledProvider),
                  onChanged: (value) => ref
                      .read(callSoundEnabledProvider.notifier)
                      .select(value),
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.translate,
                  title: l10n.moreLanguage,
                  value: _localeName(context, l10n),
                  onTap: () => showLanguageSheet(context),
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.moreAppearance,
                  value: _themeName(ref.watch(themeModeProvider), l10n),
                  onTap: () => showThemeSheet(context),
                ),
                const Divider(height: 1),
                // L'entrée n'apparaît que là où elle mène quelque part : sur
                // iOS il n'y a pas de widget d'écran d'accueil Android, et
                // certains lanceurs refusent l'épinglage depuis une
                // application. Un bouton qui explique ensuite qu'il ne peut
                // rien faire est pire que pas de bouton.
                if (ref.watch(homeWidgetPinSupportedProvider).value ?? false) ...[
                  const _WidgetTile(),
                  const Divider(height: 1),
                ],
                _MenuTile(
                  icon: Icons.info_outline,
                  title: l10n.aboutTitle,
                  onTap: () => showAboutApp(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Déconnexion ----
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                l10n.logout,
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ),

          // ---- Version et mode de compilation ----
          //
          // « L'application met du temps à s'ouvrir » a deux causes très
          // différentes : un vrai problème de démarrage, ou un APK de debug
          // installé à la place de la release — un build debug n'est pas
          // compilé en AOT et démarre plusieurs fois plus lentement. Cette
          // ligne permet de trancher en trois secondes, sans adb ni fichier
          // à comparer.
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'TONDE $kAppVersion · ${kReleaseMode ? 'release' : 'debug'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Langue réellement appliquée : la préférence si elle existe, sinon celle
  /// résolue par le système pour cette locale.
  String _localeName(BuildContext context, AppLocalizations l10n) {
    const names = <String, String>{
      'fr': 'Français',
      'rn': 'Kirundi',
      'en': 'English',
    };
    final code = Localizations.localeOf(context).languageCode;
    return names[code] ?? code.toUpperCase();
  }

  String _themeName(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Le libellé reste accessible aux lecteurs d'écran alors que la tuile
    // n'affiche aucun texte.
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: l10n.profileTitle,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const ProfileAvatar(radius: 26),
                const Spacer(),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrée qui propose d'épingler le widget d'écran d'accueil.
///
/// Le lanceur ouvre sa propre boîte de dialogue : on ne peut ni savoir à
/// l'avance si l'utilisateur acceptera, ni repeindre le widget depuis ici. Le
/// message se contente donc de dire ce qui vient de se passer.
class _WidgetTile extends ConsumerWidget {
  const _WidgetTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _MenuTile(
      icon: Icons.widgets_outlined,
      title: l10n.moreHomeWidget,
      value: l10n.moreHomeWidgetSubtitle,
      onTap: () async {
        // Capturé avant l'attente : après, le contexte peut avoir été démonté.
        final messenger = ScaffoldMessenger.of(context);
        final requested = await ref
            .read(homeWidgetBridgeProvider)
            .requestPin();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              requested ? l10n.homeWidgetPinConfirm : l10n.homeWidgetPinUnsupported,
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;

  /// Valeur courante affichée sous le libellé (langue, thème).
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: value == null ? null : Text(value!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
