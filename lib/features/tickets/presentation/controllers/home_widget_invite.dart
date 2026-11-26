import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';

/// Réponse du client à la proposition d'épingler le widget d'accueil.
enum HomeWidgetInvite { undecided, accepted, dismissed }

const String _inviteKey = 'home_widget.invite';

/// Proposition d'épingler le widget, posée une seule fois.
///
/// Le choix est mémorisé sur l'appareil : reproposer à chaque ticket ferait
/// d'une aide une publicité. « Plus tard » vaut refus — le client sait où
/// retrouver l'entrée (onglet Plus), et relancer quelqu'un qui a déjà dit non
/// ne le convaincra pas.
final homeWidgetInviteProvider =
    NotifierProvider<HomeWidgetInviteNotifier, HomeWidgetInvite>(
      HomeWidgetInviteNotifier.new,
    );

class HomeWidgetInviteNotifier extends Notifier<HomeWidgetInvite> {
  @override
  HomeWidgetInvite build() {
    // La lecture disque est asynchrone : on part de « pas encore décidé »,
    // puis on applique le choix enregistré dès qu'il est disponible. Le
    // contraire ferait apparaître la carte une fraction de seconde chez ceux
    // qui l'ont déjà refusée.
    unawaited(_restore());
    return HomeWidgetInvite.undecided;
  }

  Future<void> _restore() async {
    final raw = await ref.read(localCacheProvider).read(_inviteKey);
    if (!ref.mounted || raw is! String) {
      return;
    }
    for (final decision in HomeWidgetInvite.values) {
      if (decision.name == raw) {
        state = decision;
        return;
      }
    }
  }

  Future<void> accept() => _decide(HomeWidgetInvite.accepted);

  Future<void> dismiss() => _decide(HomeWidgetInvite.dismissed);

  Future<void> _decide(HomeWidgetInvite decision) async {
    state = decision;
    await ref.read(localCacheProvider).write(_inviteKey, decision.name);
  }
}
