import 'package:flutter/material.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Libellé et icône d'une catégorie d'organisation.
///
/// L'extension vit dans `presentation` et non dans le domaine : le domaine
/// n'a pas à connaître `material` ni les traductions.
extension OrganizationTypeStyle on OrganizationType {
  String label(AppLocalizations l10n) {
    return switch (this) {
      OrganizationType.bank => l10n.organizationTypeBank,
      OrganizationType.health => l10n.organizationTypeHealth,
      OrganizationType.other => l10n.organizationTypeOther,
    };
  }

  IconData get icon {
    return switch (this) {
      OrganizationType.bank => Icons.account_balance_outlined,
      OrganizationType.health => Icons.local_hospital_outlined,
      OrganizationType.other => Icons.storefront_outlined,
    };
  }
}
