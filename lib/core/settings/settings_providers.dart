import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonde/core/offline/local_cache_provider.dart';

/// Préférences d'affichage : thème et langue.
///
/// Ce sont des préférences d'appareil, pas de compte : elles sont donc
/// enregistrées dans le cache local et non côté serveur. Elles doivent
/// s'appliquer dès le premier écran, sans réseau.

const String _themeKey = 'settings.theme';
const String _localeKey = 'settings.locale';
const String _notificationsKey = 'settings.notifications';
const String _callSoundKey = 'settings.call_sound';

/// Langues proposées à l'utilisateur, dans l'ordre d'affichage.
const Map<String, Locale> supportedAppLocales = <String, Locale>{
  'fr': Locale('fr'),
  'rn': Locale('rn'),
  'en': Locale('en'),
};

/// Thème choisi par l'utilisateur (`system` par défaut).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // La lecture disque est asynchrone : on part du thème système, puis on
    // applique la préférence enregistrée dès qu'elle est disponible.
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final cache = ref.read(localCacheProvider);
    final raw = await cache.read(_themeKey);
    if (!ref.mounted || raw is! String) {
      return;
    }
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) {
        state = mode;
        return;
      }
    }
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(localCacheProvider).write(_themeKey, mode.name);
  }
}

/// Langue choisie par l'utilisateur ; null = langue du système.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    final raw = await ref.read(localCacheProvider).read(_localeKey);
    if (!ref.mounted || raw is! String) {
      return;
    }
    final locale = supportedAppLocales[raw];
    if (locale != null) {
      state = locale;
    }
  }

  Future<void> select(Locale? locale) async {
    state = locale;
    await ref.read(localCacheProvider).write(_localeKey, locale?.languageCode);
  }
}

/// Notifications de file d'attente activées par l'usager.
///
/// Réglage d'appareil, pas de compte : il vit dans le cache local comme le
/// thème et la langue, et s'applique dès le premier écran. Il ne remplace pas
/// l'autorisation système : couper ici n'empêche pas de la redonner.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_restore());
    // Par défaut actif : l'intérêt de TONDE est justement d'être prévenu.
    return true;
  }

  Future<void> _restore() async {
    final raw = await ref.read(localCacheProvider).read(_notificationsKey);
    if (!ref.mounted || raw is! bool) {
      return;
    }
    state = raw;
  }

  Future<void> select(bool enabled) async {
    state = enabled;
    await ref.read(localCacheProvider).write(_notificationsKey, enabled);
  }
}

/// Alerte sonore à l'appel du ticket.
///
/// Distinct de [notificationsEnabledProvider] : un client peut vouloir la
/// bannière et l'historique sans une sonnerie qui insiste trois fois. Le
/// réglage ne coupe que le son et la vibration de l'alerte — la notification,
/// elle, reste affichée.
final callSoundEnabledProvider =
    NotifierProvider<CallSoundEnabledNotifier, bool>(
      CallSoundEnabledNotifier.new,
    );

class CallSoundEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_restore());
    return true;
  }

  Future<void> _restore() async {
    final raw = await ref.read(localCacheProvider).read(_callSoundKey);
    if (!ref.mounted || raw is! bool) {
      return;
    }
    state = raw;
  }

  Future<void> select(bool enabled) async {
    state = enabled;
    await ref.read(localCacheProvider).write(_callSoundKey, enabled);
  }
}
