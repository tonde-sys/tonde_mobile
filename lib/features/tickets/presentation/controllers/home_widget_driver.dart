import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/platform/home_widget_bridge.dart';
import 'package:tonde/core/settings/settings_providers.dart';
import 'package:tonde/features/tickets/presentation/controllers/ticket_controller.dart';
import 'package:tonde/features/tickets/presentation/home_widget_state.dart';
import 'package:tonde/features/tracking/domain/entities/queue_snapshot.dart';
import 'package:tonde/features/tracking/presentation/controllers/queue_tracking_controller.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Passerelle vers le widget d'écran d'accueil de la plateforme courante.
///
/// Seul Android en a un : iOS demanderait une extension WidgetKit, écrite en
/// Swift et livrée dans une cible séparée, ce qui sort du périmètre de ce lot.
/// La passerelle inerte rend cet écart invisible au reste du code.
final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return const NoopHomeWidgetBridge();
  }
  return const MethodChannelHomeWidgetBridge();
});

/// Ce que le widget doit afficher, ou `null` quand on ne sait pas encore.
///
/// `null` n'est pas « aucun ticket » : c'est « ne touche à rien ». Au démarrage,
/// le ticket n'est pas encore lu ; publier un état vide ferait clignoter
/// « Aucun ticket » sur l'écran d'accueil avant de réafficher le vrai numéro.
final homeWidgetStateProvider = Provider<HomeWidgetState?>((ref) {
  final ticketAsync = ref.watch(activeTicketProvider);
  if (!ticketAsync.hasValue) {
    return null;
  }

  final ticket = ticketAsync.value;
  QueueSnapshot? snapshot;
  // Le flux temps réel n'a de sens que pour un ticket que le serveur connaît,
  // encore ouvert. Un ticket pris hors ligne n'a pas d'identifiant, et un
  // ticket clos ne rouvrira jamais.
  if (ticket != null &&
      !ticket.pendingSync &&
      !ticket.isClosed &&
      ticket.id != null) {
    snapshot = ref
        .watch(queueTrackingProvider(QueueTrackingKey(ticket)))
        .value
        ?.snapshot;
  }

  return homeWidgetStateFor(
    l10n: lookupAppLocalizations(_resolveLocale(ref.watch(localeProvider))),
    ticket: ticket,
    snapshot: snapshot,
  );
});

/// Vrai si le lanceur sait épingler le widget depuis l'application.
///
/// Interrogé par l'onglet « Plus » pour n'afficher l'entrée que là où elle
/// mène quelque part : un bouton qui explique ensuite qu'il ne peut rien faire
/// est pire que pas de bouton.
final homeWidgetPinSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(homeWidgetBridgeProvider).isPinSupported(),
  retry: (_, _) => null,
);

/// Maintient le widget d'écran d'accueil à jour.
///
/// Observé une seule fois, au sommet de l'application : le widget doit suivre
/// le ticket même si l'utilisateur est sur l'onglet Profil, et même si l'écran
/// de suivi n'est pas ouvert.
final homeWidgetDriverProvider = Provider<void>((ref) {
  final bridge = ref.watch(homeWidgetBridgeProvider);

  HomeWidgetState? published;
  // Une plateforme sans widget répond « canal inconnu » à chaque appel. Inutile
  // de réessayer : c'est définitif pour la session.
  var unavailable = false;

  Future<void> publish(HomeWidgetState? state) async {
    if (unavailable || state == null || state == published) {
      return;
    }
    try {
      await bridge.update(state);
      published = state;
    } on MissingPluginException {
      unavailable = true;
    } on PlatformException catch (error) {
      // Le widget est un confort : un échec ne doit jamais remonter jusqu'à
      // l'écran ni interrompre la navigation.
      debugPrint('widget: mise à jour impossible (${error.code})');
    }
  }

  ref.listen(homeWidgetStateProvider, (previous, next) {
    unawaited(publish(next));
  }, fireImmediately: true);
});

/// Langue des textes du widget.
///
/// La même règle que `MaterialApp` : la préférence de l'utilisateur d'abord,
/// la langue de l'appareil ensuite, le français à défaut. Le widget vit hors de
/// l'arbre Flutter et n'a donc pas accès au `Localizations` résolu par le
/// routeur ; il faut le refaire ici, avec la même issue.
Locale _resolveLocale(Locale? chosen) {
  for (final candidate in <Locale?>[chosen, PlatformDispatcher.instance.locale]) {
    if (candidate == null) {
      continue;
    }
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == candidate.languageCode) {
        return supported;
      }
    }
  }
  return const Locale('fr');
}
