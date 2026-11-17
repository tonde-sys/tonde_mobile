import 'package:tonde/core/offline/local_cache.dart';
import 'package:tonde/features/auth/data/user_codec.dart';
import 'package:tonde/features/auth/domain/auth_service.dart';
import 'package:tonde/features/auth/domain/user.dart';

/// Service fictif de démonstration : les comptes vivent en mémoire.
///
/// Actif **uniquement** quand aucune base URL n'est fournie à la compilation
/// (`TONDE_API_BASE_URL` vide) : dès qu'elle est renseignée, c'est
/// `ApiAuthService` qui prend le relais, sans qu'aucun écran ne change.
///
/// La session est restaurée depuis le cache local quand un [LocalCache] est
/// fourni : sans cela, une application relancée sans réseau retomberait sur
/// l'écran de connexion et le ticket stocké deviendrait inaccessible.
///
/// Depuis l'alignement sur le backend, l'identifiant de connexion est l'e-mail —
/// comme côté serveur. Le compte de démonstration utilise donc l'adresse
/// réelle de Vizane plutôt qu'un « nom d'utilisateur » qui n'existe nulle part
/// en base.
final class MockAuthService implements AuthService {
  MockAuthService({
    this.latency = const Duration(milliseconds: 500),
    LocalCache? cache,
  }) : _cache = cache;

  static const String sessionKey = 'session.user';

  /// Compte de démonstration : e-mail → mot de passe.
  static const String demoEmail = 'kananijospin63@gmail.com';
  static const String demoPassword = '12345';

  /// Délai artificiel pour rendre l'authentification perceptible en démo.
  final Duration latency;

  final LocalCache? _cache;

  /// Comptes de démonstration fournis par Vizane.
  final Map<String, String> _passwords = {demoEmail: demoPassword};

  /// Profils de démonstration : e-mail (normalisé) → User complet.
  final Map<String, User> _profiles = {
    demoEmail: const User(
      id: 'demo-jospin',
      name: 'Jospin Kanani',
      email: demoEmail,
      phone: '+257 79490806',
      role: 'Client',
      organization: 'TONDE - Bujumbura',
      createdAt: '2026-01-15',
    ),
  };

  User? _current;

  Future<void> _wait() => Future<void>.delayed(latency);

  String _normalize(String email) => email.trim().toLowerCase();

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
    required String email,
    required String password,
  }) async {
    await _wait();
    final key = _normalize(email);
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
    required String email,
    required String password,
  }) async {
    await _wait();
    final key = _normalize(email);
    if (_passwords.containsKey(key)) {
      throw const EmailAlreadyTakenException();
    }
    _passwords[key] = password;
    final now = DateTime.now().toIso8601String().split('T').first;
    final user = User(
      id: 'demo-${_profiles.length + 1}',
      name: name.trim(),
      email: key,
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
    final key = updated.email;
    if (key != null) {
      _profiles[key] = updated;
    }
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
