import 'package:tonde/l10n/generated/app_localizations.dart';

/// Validation locale d'une adresse e-mail, avant envoi.
///
/// Volontairement permissive : le serveur valide avec `EmailStr` (RFC 5322) et
/// reste seul juge. Le but ici est d'éviter un aller-retour réseau sur une
/// saisie manifestement incomplète (« dupont », « a@b »), pas de refuser une
/// adresse exotique mais valide — un refus local injustifié laisserait
/// l'utilisateur sans recours, alors qu'un refus serveur est explicite.
String? validateEmail(AppLocalizations l10n, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return l10n.fieldRequired;
  }
  if (text.contains(' ') || text.contains('\n')) {
    return l10n.emailInvalid;
  }
  final at = text.indexOf('@');
  // Un seul arobase, ni en tête ni en queue.
  if (at <= 0 || at != text.lastIndexOf('@') || at == text.length - 1) {
    return l10n.emailInvalid;
  }
  final domain = text.substring(at + 1);
  // Un domaine sans point (« a@localhost ») n'est pas joignable depuis
  // l'application, et le serveur le refuserait de toute façon.
  if (!domain.contains('.') ||
      domain.startsWith('.') ||
      domain.endsWith('.') ||
      domain.contains('..')) {
    return l10n.emailInvalid;
  }
  return null;
}
