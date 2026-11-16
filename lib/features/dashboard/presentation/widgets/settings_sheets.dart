import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/config/app_config.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Choix de la langue de l'application.
///
/// Les libellés sont des endonymes (« Français », « Kirundi », « English ») :
/// on ne traduit jamais le nom d'une langue dans une autre langue, sinon
/// l'utilisateur qui ne lit pas la langue courante ne retrouve pas la sienne.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _LanguageSheet(),
  );
}

/// Choix du thème clair / sombre / système.
Future<void> showThemeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _ThemeSheet(),
  );
}

/// Fenêtre « À propos » : version, description et licences open source.
void showAboutApp(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  showAboutDialog(
    context: context,
    applicationName: l10n.appTitle,
    applicationVersion: l10n.appVersion(kAppVersion),
    applicationLegalese: l10n.tagline,
    children: [const SizedBox(height: 12), Text(l10n.aboutBody)],
  );
}

const Map<String, String> _languageNames = <String, String>{
  'fr': 'Français',
  'rn': 'Kirundi',
  'en': 'English',
};

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(localeProvider)?.languageCode;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTitle(text: l10n.moreLanguage),
          // Retour à la langue du téléphone : sans cette entrée, un choix
          // explicite serait définitif et l'utilisateur ne pourrait plus
          // suivre le réglage de son appareil.
          _ChoiceTile(
            label: l10n.languageSystem,
            selected: selected == null,
            onTap: () {
              ref.read(localeProvider.notifier).select(null);
              Navigator.of(context).pop();
            },
          ),
          for (final entry in supportedAppLocales.entries)
            _ChoiceTile(
              label: _languageNames[entry.key] ?? entry.key,
              selected: selected == entry.key,
              onTap: () {
                ref.read(localeProvider.notifier).select(entry.value);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(themeModeProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTitle(text: l10n.moreAppearance),
          _ChoiceTile(
            label: l10n.themeSystem,
            selected: selected == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).select(ThemeMode.system);
              Navigator.of(context).pop();
            },
          ),
          _ChoiceTile(
            label: l10n.themeLight,
            selected: selected == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).select(ThemeMode.light);
              Navigator.of(context).pop();
            },
          ),
          _ChoiceTile(
            label: l10n.themeDark,
            selected: selected == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).select(ThemeMode.dark);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(label),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
