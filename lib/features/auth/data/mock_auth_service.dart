import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/auth/data/user_codec.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';

/// Service fictif approuvé par Vizane (2026-11-09) pour la démo : les comptes
/// vivent en mémoire. À remplacer par le client backend réel dès que le
/// contrat d'authentification sera disponible (Phase 3).
///
/// Depuis le lot 15, la **session** est restaurée depuis le cache local quand
/// un [LocalCache] est fourni : sans cela, une application relancée sans réseau
/// retomberait sur l'écran de connexion et le ticket stocké deviendrait
/// inaccessible, ce qui vide de sens le mode hors ligne. Le service backend
/// réel suivra son propre mécanisme (refresh token dans le stockage sécurisé).
final class MockAuthService implements AuthService {
  MockAuthService({
    this.latency = const Duration(milliseconds: 500),
    LocalCache? cache,
  }) : _cache = cache;

  static const String sessionKey = 'session.user';

  /// Délai artificiel pour rendre l'authentification perceptible en démo.
  final Duration latency;

  final LocalCache? _cache;

  /// Comptes de démonstration fournis par Vizane.
  final Map<String, String> _passwords = {'jospin kanani': '12345'};

  /// Profils de démonstration : username → User complet.
  final Map<String, User> _profiles = {
    'jospin kanani': const User(
      name: 'Jospin Kanani',
      username: 'jospin kanani',
      email: 'kananijospin63@gmail.com',
      phone: '+257 79490806',
      role: 'Agent',
      organization: 'TONDE - Bujumbura',
      createdAt: '2026-01-15',
    ),
  };

  User? _current;

  Future<void> _wait() => Future<void>.delayed(latency);

  String _normalize(String username) => username.trim().toLowerCase();

  @override
  Future<User?> currentUser() async {
    await _wait();
    final current = _current;
    if (current != null) {
      return current;
    }
    final cache = _cache;
    if (cache == null) {
      return null;
    }
    final restored = userFromJson(await cache.read(sessionKey));
    _current = restored;
    return restored;
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    await _wait();
    final key = _normalize(username);
    if (_passwords[key] != password) {
      throw const InvalidCredentialsException();
    }
    final user = _profiles[key]!;
    await _setCurrent(user);
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String username,
    required String password,
  }) async {
    await _wait();
    final key = _normalize(username);
    if (_passwords.containsKey(key)) {
      throw const UsernameAlreadyTakenException();
    }
    _passwords[key] = password;
    final now = DateTime.now().toIso8601String().split('T').first;
    final user = User(
      name: name.trim(),
      username: key,
      email: '$key@tonde.app',
      createdAt: now,
    );
    _profiles[key] = user;
    await _setCurrent(user);
    return user;
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organization,
  }) async {
    await _wait();
    final current = _current;
    if (current == null) {
      throw const NotAuthenticatedException();
    }
    final updated = current.copyWith(
      name: name?.trim(),
      email: email?.trim(),
      phone: phone?.trim(),
      role: role?.trim(),
      organization: organization?.trim(),
    );
    _profiles[updated.username] = updated;
    await _setCurrent(updated);
    return updated;
  }

  @override
  Future<void> logout() async {
    await _wait();
    await _setCurrent(null);
  }

  /// Met à jour la session en mémoire et, si un cache est disponible, la
  /// version persistée qui permet de rouvrir l'application hors ligne.
  Future<void> _setCurrent(User? user) async {
    _current = user;
    final cache = _cache;
    if (cache == null) {
      return;
    }
    await cache.write(sessionKey, user == null ? null : userToJson(user));
  }
}
