import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/core/config/tonde_support.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fiches de contact du centre d'aide.
///
/// Deux fiches, deux responsabilités : TONDE répond des problèmes de
/// l'application, l'institution répond de son service et de ses files. Les
/// mélanger dans une seule liste obligerait le client à deviner qui appeler —
/// exactement la question à laquelle un centre d'aide doit répondre.

/// Ouvre la fiche du support TONDE.
Future<void> showTondeContactSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _TondeContactSheet(),
  );
}

/// Ouvre la fiche de l'institution du client.
///
/// La liste des institutions est chargée **à l'ouverture**, pas au rendu de
/// l'onglet : un client qui vient lire la FAQ n'a pas à payer un appel réseau
/// pour des coordonnées qu'il ne demande pas.
Future<void> showInstitutionContactSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _InstitutionContactSheet(),
  );
}

Future<void> _open(BuildContext context, Uri uri) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.contactOpenFailed)));
  }
}

Uri _tel(String digits) => Uri(scheme: 'tel', path: '+$digits');

Uri _whatsApp(String digits) => Uri.parse('https://wa.me/$digits');

Uri _mail(String address) => Uri(scheme: 'mailto', path: address);

// ── TONDE ─────────────────────────────────────────────────────────────────────

class _TondeContactSheet extends StatelessWidget {
  const _TondeContactSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.support_agent_rounded,
                size: 32,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'TONDE',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.supportTondeSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Le numéro n'est jamais affiché : seule l'icône est proposée,
                // et le composeur du téléphone montre le numéro à l'appel.
                _RoundAction(
                  icon: Icons.call_rounded,
                  label: l10n.contactCall,
                  emphasized: true,
                  onTap: () => _open(context, _tel(TondeSupport.phone)),
                ),
                _RoundAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: l10n.contactWhatsApp,
                  onTap: () => _open(context, _whatsApp(TondeSupport.whatsapp)),
                ),
                _RoundAction(
                  icon: Icons.mail_outline_rounded,
                  label: l10n.contactEmail,
                  onTap: () => _open(context, _mail(TondeSupport.email)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.supportAlwaysOpen,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // L'adresse reste lisible : on peut la copier ou l'écrire depuis un
            // ordinateur, ce qu'un simple bouton ne permet pas.
            Text(
              TondeSupport.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.supportClose),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Institution ───────────────────────────────────────────────────────────────

class _InstitutionContactSheet extends ConsumerStatefulWidget {
  const _InstitutionContactSheet();

  @override
  ConsumerState<_InstitutionContactSheet> createState() =>
      _InstitutionContactSheetState();
}

class _InstitutionContactSheetState
    extends ConsumerState<_InstitutionContactSheet> {
  Organization? _selected;

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: organizations.when(
          loading: () => const _SheetLoading(),
          error: (_, _) => _SheetError(
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _NoInstitution();
            }
            final selected = _selected ?? (items.length == 1 ? items.first : null);
            if (selected == null) {
              return _InstitutionPicker(
                organizations: items,
                onSelected: (organization) =>
                    setState(() => _selected = organization),
              );
            }
            return _InstitutionDetails(
              organization: selected,
              // Une seule institution : pas de retour vers une liste d'un
              // élément, qui n'apprendrait rien au client.
              onBack: items.length > 1
                  ? () => setState(() => _selected = null)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _InstitutionDetails extends StatelessWidget {
  const _InstitutionDetails({required this.organization, this.onBack});

  final Organization organization;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.secondaryContainer,
              child: Icon(
                Icons.apartment_rounded,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (organization.supportHours.isNotEmpty)
                    Text(
                      organization.supportHours,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!organization.hasSupportContact)
          _NoChannel()
        else ...[
          if (organization.supportPhone.isNotEmpty)
            _ContactTile(
              icon: Icons.call_outlined,
              title: l10n.supportCallInstitution,
              subtitle: '+${organization.supportPhone}',
              onTap: () => _open(context, _tel(organization.supportPhone)),
            ),
          if (organization.supportWhatsapp.isNotEmpty)
            _ContactTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.contactWhatsApp,
              subtitle: '+${organization.supportWhatsapp}',
              onTap: () =>
                  _open(context, _whatsApp(organization.supportWhatsapp)),
            ),
          if (organization.supportEmail.isNotEmpty)
            _ContactTile(
              icon: Icons.mail_outline_rounded,
              title: l10n.contactEmail,
              subtitle: organization.supportEmail,
              onTap: () => _open(context, _mail(organization.supportEmail)),
            ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.supportClose),
        ),
      ],
    );
  }
}

class _InstitutionPicker extends StatelessWidget {
  const _InstitutionPicker({
    required this.organizations,
    required this.onSelected,
  });

  final List<Organization> organizations;
  final ValueChanged<Organization> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.supportChooseInstitution,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final organization in organizations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.apartment_rounded),
            title: Text(organization.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelected(organization),
          ),
      ],
    );
  }
}

class _NoInstitution extends StatelessWidget {
  const _NoInstitution();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // `maybeOf` et non `of` : la fiche se teste aussi hors routeur, et un
    // centre d'aide ne doit pas planter parce qu'il est monté seul.
    final router = GoRouter.maybeOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.apartment_outlined,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.supportInstitutionEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.supportInstitutionEmptyBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () {
            // Le routeur est capturé avant la fermeture : après `pop`, le
            // contexte de la fiche n'est plus monté.
            if (router != null) {
              router.pop();
              router.push(AppRoutes.organizations);
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.supportBrowseInstitutions),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.supportClose),
        ),
      ],
    );
  }
}

class _NoChannel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supportInstitutionNoChannel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.supportInstitutionNoChannelBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLoading extends StatelessWidget {
  const _SheetLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          size: 36,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.supportLoadFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.errOfflineDetail,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}

// ── Briques communes ──────────────────────────────────────────────────────────

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = emphasized ? scheme.primary : scheme.primaryContainer;
    final foreground = emphasized ? scheme.onPrimary : scheme.onPrimaryContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(icon, color: foreground, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: onTap,
    );
  }
}
