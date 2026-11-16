import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/dashboard/presentation/pages/assistance_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/home_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/more_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/notifications_tab.dart';
import 'package:tonde/features/dashboard/presentation/pages/tickets_tab.dart';
import 'package:tonde/features/dashboard/presentation/widgets/offline_banner.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Coquille du tableau de bord : navigation basse à cinq onglets.
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

    return Scaffold(
      body: IndexedStack(
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
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placé sous le contenu : discret, et hors de la zone du bandeau
          // système haut des différents onglets.
          const OfflineBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.tabHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.confirmation_number_outlined),
                selectedIcon: const Icon(Icons.confirmation_number),
                label: l10n.tabTickets,
              ),
              NavigationDestination(
                // Le badge ne compte que ce qui a réellement été reçu : une
                // pastille permanente finirait par ne plus rien signaler.
                icon: _NotificationIcon(count: unread, selected: false),
                selectedIcon: _NotificationIcon(count: unread, selected: true),
                label: l10n.tabNotifications,
              ),
              NavigationDestination(
                icon: const Icon(Icons.headset_mic_outlined),
                selectedIcon: const Icon(Icons.headset_mic),
                label: l10n.tabAssistance,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu),
                label: l10n.tabMore,
              ),
            ],
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
