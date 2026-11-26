import 'package:flutter/material.dart';

/// Un onglet de la barre de navigation.
class TondeNavigationDestination {
  const TondeNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;

  /// Libellé affiché sous l'icône. Il est réduit pour tenir dans la largeur
  /// disponible, jamais coupé ni renvoyé à la ligne.
  final String label;
}

/// Barre de navigation basse de TONDE.
///
/// Remplace `NavigationBar` de Material pour une seule raison : ses libellés
/// sont des `String` rendus dans la largeur d'un cinquième d'écran, sans
/// réduction possible. Sur un téléphone de 320 dp, « Notifications » et
/// « Assistance » n'y tenaient pas et se coupaient au milieu d'un mot.
///
/// Ici chaque libellé est réduit d'un bloc (`FittedBox`) pour tenir sur une
/// seule ligne : le mot reste entier à toutes les largeurs, et la taille du
/// texte s'adapte au lieu de casser. L'apparence Material 3 est conservée —
/// pastille du parent sélectionné, icône pleine, encrage au toucher — ainsi
/// que la sémantique attendue par les lecteurs d'écran.
class TondeNavigationBar extends StatelessWidget {
  const TondeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  }) : assert(destinations.length > 0, 'au moins un onglet est nécessaire');

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<TondeNavigationDestination> destinations;

  /// Hauteur de la barre, hors zone système. Assez haute pour la pastille et
  /// le libellé, assez basse pour laisser respirer le contenu.
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      // Même teinte que la barre Material : le changement est invisible à
      // l'œil, seul le comportement des libellés diffère.
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _Destination(
                    destination: destinations[index],
                    selected: index == selectedIndex,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final TondeNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // L'encrage déborde de la pastille : c'est le comportement Material
        // attendu quand on touche un onglet.
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconTheme(
                data: IconThemeData(color: foreground, size: 22),
                child: selected ? destination.selectedIcon : destination.icon,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              // Deux pixels de retrait de chaque côté : sur un écran de 320 dp
              // cela suffit à éviter que deux libellés voisins se touchent.
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    // L'interlettrage par défaut coûte six pixels sur
                    // « Notifications » : autant les rendre à la lisibilité.
                    letterSpacing: 0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
