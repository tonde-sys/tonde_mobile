import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/app/router/app_routes.dart';
import 'package:tonde/core/layout/app_breakpoints.dart';
import 'package:tonde/features/organizations/domain/entities/organization.dart';
import 'package:tonde/features/organizations/presentation/controllers/organizations_controller.dart';
import 'package:tonde/features/organizations/presentation/widgets/async_error_view.dart';
import 'package:tonde/features/organizations/presentation/widgets/organization_card.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Écran de découverte : organisations dont l'adhésion est confirmée.
class OrganizationsPage extends ConsumerStatefulWidget {
  const OrganizationsPage({super.key});

  @override
  ConsumerState<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends ConsumerState<OrganizationsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final organizationsAsync = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (organizations) {
          final normalizedQuery = _query.trim().toLowerCase();
          final filtered = organizations
              .where(
                (organization) =>
                    organization.name.toLowerCase().contains(normalizedQuery),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(organizationsProvider.future),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.organizationsSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          message: organizations.isEmpty
                              ? l10n.organizationsEmpty
                              : l10n.organizationsNoResults,
                        )
                      : _OrganizationList(
                          organizations: filtered,
                          onOpen: (organization) => context.push(
                            AppRoutes.organizationDetailPath(organization.id),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Liste des organisations, en une à trois colonnes selon la largeur.
///
/// Sur téléphone, une seule colonne : c'est la disposition qui laisse le plus
/// de place au nom de l'organisation. À partir de 600 dp, deux puis trois
/// colonnes — une liste pleine largeur sur tablette laisse sinon des fiches de
/// 900 dp de large pour deux mots.
class _OrganizationList extends StatelessWidget {
  const _OrganizationList({required this.organizations, required this.onOpen});

  final List<Organization> organizations;
  final void Function(Organization) onOpen;

  /// Hauteur d'une fiche : un `ListTile` avec sous-titre (72 dp), ses marges
  /// (12 dp) et la place laissée à un facteur de police monté à 1,3.
  static const double _cardExtent = 96;

  @override
  Widget build(BuildContext context) {
    final columns = AppBreakpoints.of(context).gridColumns;

    if (columns == 1) {
      // Sur téléphone on garde la liste : elle gère le défilement sans
      // contraindre la hauteur, donc un nom sur deux lignes ne déborde pas.
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: organizations.length,
        itemBuilder: (context, index) {
          final organization = organizations[index];
          return OrganizationCard(
            organization: organization,
            onTap: () => onOpen(organization),
          );
        },
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: _cardExtent,
      ),
      itemCount: organizations.length,
      itemBuilder: (context, index) {
        final organization = organizations[index];
        return OrganizationCard(
          organization: organization,
          onTap: () => onOpen(organization),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
