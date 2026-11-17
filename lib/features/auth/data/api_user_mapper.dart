import 'package:tonde/features/auth/domain/user.dart';

/// Mappage du profil renvoyé par le backend (`UserInToken`) vers le domaine.
///
/// Deux écarts assumés avec le passé du mobile :
///
///  * **Pas de `username`.** Le backend n'en a pas : l'identité est `id`, et
///    l'identifiant de connexion est l'e-mail (ou le téléphone pour l'OTP).
///  * **Pas d'`organization`.** Le serveur renvoie `org_id`, un UUID. Afficher
///    un UUID dans le profil serait pire que ne rien afficher : le champ reste
///    vide tant qu'une route ne donne pas le NOM de l'organisation. C'est une
///    limitation connue, pas un oubli silencieux.
User? userFromTokenPayload(Object? payload) {
  if (payload is! Map) {
    return null;
  }
  final id = payload['id'];
  if (id is! String || id.isEmpty) {
    return null;
  }
  final email = _asString(payload['email']);
  final phone = _asString(payload['phone']);
  final name = _asString(payload['name']);
  return User(
    id: id,
    // Un compte créé par OTP n'a pas de nom. Mieux vaut un libellé dérivé de
    // l'identifiant qu'une chaîne vide à l'écran.
    name: name?.trim().isNotEmpty == true
        ? name!.trim()
        : (email ?? phone ?? 'Client'),
    email: email,
    phone: phone,
    role: _roleLabel(payload['role']),
  );
}

/// `CLIENT` → `Client`, `SUPER_ADMIN` → `Super admin`.
String? _roleLabel(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  final words = raw.toLowerCase().split('_');
  final first = words.first;
  final rest = words.skip(1);
  return [
    '${first[0].toUpperCase()}${first.substring(1)}',
    ...rest,
  ].join(' ');
}

String? _asString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
