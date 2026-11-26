import 'package:flutter/material.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';
import 'package:tonde/features/organizations/presentation/organization_type_style.dart';

/// Carte présentant une organisation dans la liste de découverte.
class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    super.key,
    required this.organization,
    required this.onTap,
  });

  final Organization organization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            organization.type.icon,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          organization.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          // Une raison sociale longue occupe sinon trois lignes en grille et
          // déborde de la hauteur réservée à la fiche.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          organization.type.label(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
