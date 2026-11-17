import 'package:tonde/features/auth/domain/user.dart';

/// Sérialisation du profil pour la restauration de session locale.

Map<String, Object?> userToJson(User user) {
  return <String, Object?>{
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'phone': user.phone,
    'role': user.role,
    'organization': user.organization,
    'createdAt': user.createdAt,
  };
}

/// Relit un profil depuis le cache. Retourne null si le document est
/// incomplet : une session illisible renvoie à l'écran de connexion plutôt que
/// de planter au démarrage.
///
/// Une session écrite par une version antérieure ne porte pas d'`id` (elle
/// avait un `username`) : elle est donc considérée comme illisible, et c'est le
/// comportement voulu — cet ancien identifiant ne correspond à aucun compte
/// serveur, et le ticket qui y était rattaché non plus.
User? userFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final id = document['id'];
  final name = document['name'];
  if (id is! String || id.isEmpty || name is! String) {
    return null;
  }
  return User(
    id: id,
    name: name,
    email: _asString(document['email']),
    phone: _asString(document['phone']),
    role: _asString(document['role']),
    organization: _asString(document['organization']),
    createdAt: _asString(document['createdAt']),
  );
}

String? _asString(Object? value) => value is String ? value : null;
