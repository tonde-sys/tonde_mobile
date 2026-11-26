import 'package:flutter/material.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Demande confirmation avant d'annuler un ticket.
///
/// L'annulation est définitive et rend la place immédiatement : elle ne se
/// répare pas. Le dialogue est donc identique partout où l'action existe
/// (détail du ticket, suivi, assistance) — trois formulations différentes pour
/// la même conséquence feraient douter de ce qui va se passer.
///
/// Retourne `true` seulement si l'utilisateur a confirmé explicitement.
Future<bool> confirmCancelTicket(
  BuildContext context, {
  required String number,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.detailsCancelTitle(number)),
      content: Text(l10n.detailsCancelBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.detailsCancelKeep),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(l10n.detailsCancelConfirm),
        ),
      ],
    ),
  );
  return confirmed == true;
}
