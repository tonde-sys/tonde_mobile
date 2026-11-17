import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/features/auth/data/auth_service_provider.dart';
import 'package:tonde/features/auth/domain/user.dart';

/// Utilisateur connecté (null si personne n'est connecté).
final authControllerProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() {
    return ref.watch(authServiceProvider).currentUser();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .register(name: name, email: email, password: password),
    );
  }

  /// Met à jour les informations du profil de l'utilisateur connecté.
  ///
  /// Ne renvoie pas d'erreur si le statut courant est en chargement : la
  /// mise à jour est une opération explicite, pas un simple reflet d'état.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organization,
  }) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final updated = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .updateProfile(
            name: name,
            email: email,
            phone: phone,
            role: role,
            organization: organization,
          ),
    );
    if (updated.hasError) {
      state = AsyncError(
        updated.error!,
        updated.stackTrace ?? StackTrace.current,
      );
      return;
    }
    state = AsyncData(updated.value);
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }
}
