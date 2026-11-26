import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/layout/app_breakpoints.dart';
import 'package:tonde/features/dashboard/presentation/pages/assistance_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/more_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/notifications_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/tickets_tab.dart';
import 'package:tonde/features/dashboard/presentation/widgets/offline_banner.dart';
import 'package:tonde/features/dashboard/presentation/widgets/tonde_navigation_bar.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Coquille du tableau de bord.
///
/// Barre basse sur téléphone, rail latéral dès 600 dp : sur une tablette ou un
/// téléphone en paysage, une barre basse à cinq onglets occupe une hauteur
/// utile pour rien, alors que la largeur, elle, est disponible.
class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationsProvider);
    final useRail = AppBreakpoints.of(context).usesRail;

    final destinations = <TondeNavigationDestination>[
      TondeNavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.tabHome,
      ),
      TondeNavigationDestination(
        icon: const Icon(Icons.confirmation_number_outlined),
        selectedIcon: const Icon(Icons.confirmation_number),
        label: l10n.tabTickets,
      ),
      TondeNavigationDestination(
        // Le badge ne compte que ce qui a réellement été reçu : une pastille
        // permanente finirait par ne plus rien signaler.
        icon: _NotificationIcon(count: unread, selected: false),
        selectedIcon: _NotificationIcon(count: unread, selected: true),
        label: l10n.tabNotifications,
      ),
      TondeNavigationDestination(
        icon: const Icon(Icons.headset_mic_outlined),
        selectedIcon: const Icon(Icons.headset_mic),
        label: l10n.tabAssistance,
      ),
      TondeNavigationDestination(
        icon: const Icon(Icons.menu),
        selectedIcon: const Icon(Icons.menu),
        label: l10n.tabMore,
      ),
    ];

    final content = IndexedStack(
      index: _index,
      children: [
        // L'IndexedStack garde tous les onglets vivants : on coupe le Ticker
        // de la sphère du hero dès que l'accueil n'est plus affiché.
        TickerMode(
          enabled: _index == 0,
          child: HomeTab(
            onNotifications: () => _select(2),
            onAssistance: () => _select(3),
          ),
        ),
        const TicketsTab(),
        const NotificationsTab(),
        const AssistanceTab(),
        const MoreTab(),
      ],
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: content),
                  // Placé sous le contenu : discret, et hors de la zone du
                  // bandeau système haut des différents onglets.
                  const OfflineBanner(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(),
          TondeNavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: destinations,
          ),
        ],
      ),
    );
  }
}

/// Icône de l'onglet Notifications, avec une pastille seulement s'il y a
/// quelque chose à lire.
class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.notifications : Icons.notifications_outlined,
    );
    if (count == 0) {
      return icon;
    }
    return Badge(label: Text('$count'), child: icon);
  }
}
