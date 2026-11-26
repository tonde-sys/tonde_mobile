import 'package:flutter/material.dart';
import 'package:tonde/core/errors/error_view.dart';
import 'package:tonde/core/errors/user_message.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Message d'erreur d'un écran de chargement, avec bouton de nouvelle tentative.
///
/// Enveloppe mince autour de [ErrorView] : elle existe pour que les écrans qui
/// n'ont qu'un « recharger » à proposer n'aient pas à connaître le catalogue
/// de messages. Le texte, l'icône et la référence d'incident viennent de
/// l'erreur réelle — plus aucun écran n'affiche « impossible de charger » pour
/// un simple quota atteint.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = userMessageFor(AppLocalizations.of(context), error);

    // Les actions de navigation (voir ma position, choisir un service, prendre
    // un ticket) n'ont pas de destination ici : les proposer mènerait nulle
    // part. Tout le reste se rejoue depuis cet écran.
    final navigatesAway = switch (message.action) {
      ErrorAction.seePosition ||
      ErrorAction.chooseService ||
      ErrorAction.takeNewTicket => true,
      ErrorAction.none || ErrorAction.retry || ErrorAction.wait => false,
    };

    return ErrorView(error: error, onAction: navigatesAway ? null : onRetry);
  }
}
