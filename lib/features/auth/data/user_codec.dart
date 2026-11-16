import 'package:tonde/features/auth/domain/user.dart';

/// Sérialisation du profil pour la restauration de session locale.

Map<String, Object?> userToJson(User user) {
  return <String, Object?>{
    'name': user.name,
    'username': user.username,
    'email': user.email,
    'phone': user.phone,
    'role': user.role,
    'organization': user.organization,
    'createdAt': user.createdAt,
  };
}

User? userFromJson(Object? document) {
  if (document is! Map) {
    return null;
  }
  final name = document['name'];
  final username = document['username'];
  if (name is! String || username is! String) {
    return null;
  }
  return User(
    name: name,
    username: username,
    email: _asString(document['email']),
    phone: _asString(document['phone']),
    role: _asString(document['role']),
    organization: _asString(document['organization']),
    createdAt: _asString(document['createdAt']),
  );
}

String? _asString(Object? value) => value is String ? value : null;
