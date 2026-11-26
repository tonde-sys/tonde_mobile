import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sonnerie d'appel au guichet.
///
/// Trois responsabilités, et rien d'autre :
///
/// 1. **Faire insister** — trois lectures au maximum, pas un bip unique qu'on
///    n'entend pas dans une salle d'attente.
/// 2. **S'arrêter net** — dès que le client interagit (il ouvre le suivi) ou
///    que le ticket avance, la sonnerie se tait. Une alerte qu'on ne peut pas
///    faire taire est une agression.
/// 3. **Ne jamais sonner deux fois pour le même appel** — le flux temps réel et
///    le push peuvent raconter le même événement ; la fenêtre de dédoublonnage
///    est la seule chose qui empêche la double sonnerie.
///
/// Le mode silencieux du téléphone est respecté : dans ce cas, seule la
/// vibration prévient. C'est un choix produit — un téléphone mis en silencieux
/// l'a été volontairement.

/// Abstrait la lecture audio pour que la règle se teste sans téléphone.
abstract interface class CallSound {
  /// Joue le son une fois et rend la main à la fin de la lecture.
  Future<void> playOnce();

  Future<void> stop();

  Future<void> dispose();
}

/// Lecture réelle depuis `assets/sounds/ticket_called.mp3`.
final class AssetCallSound implements CallSound {
  AssetCallSound({AudioPlayer? player}) : _player = player;

  /// `audioplayers` préfixe lui-même par `assets/` : le chemin est donc relatif
  /// au dossier déclaré dans `pubspec.yaml`.
  static const String assetPath = 'sounds/ticket_called.mp3';

  AudioPlayer? _player;

  /// Créé à la première lecture, pas à la construction : les tests et les
  /// aperçus n'ouvrent jamais de canal audio pour rien.
  AudioPlayer get _ensurePlayer {
    final existing = _player;
    if (existing != null) {
      return existing;
    }
    final player = AudioPlayer();
    unawaited(player.setReleaseMode(ReleaseMode.stop));
    _player = player;
    return player;
  }

  @override
  Future<void> playOnce() async {
    final player = _ensurePlayer;
    await player.stop();
    await player.play(AssetSource(assetPath));
    // Sans borne, un fichier illisible laisserait la sonnerie suspendue pour
    // toujours. Le délai est plus long que le son (2,6 s) pour ne pas couper
    // une lecture normale.
    await player.onPlayerComplete.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}

/// Mode sonore du téléphone, lu côté Android.
///
/// Flutter n'expose pas le mode sonnerie : sans ce pont, l'application sonnerait
/// dans un téléphone mis en silencieux, ce qui est le meilleur moyen de faire
/// désinstaller une application.
abstract final class DeviceAudioMode {
  static const MethodChannel _channel = MethodChannel('app.tonde/audio_mode');

  /// Vrai si le téléphone est en silencieux (pas en vibreur).
  ///
  /// En cas de doute — canal absent, plateforme non Android — on répond faux :
  /// mieux vaut sonner une fois de trop que rater un appel au guichet.
  static Future<bool> isSilent() async {
    try {
      final mode = await _channel.invokeMethod<String>('ringerMode');
      return mode == 'silent';
    } on Object {
      return false;
    }
  }
}

final class CallAlertController {
  CallAlertController({
    CallSound? sound,
    Future<void> Function()? vibrate,
    bool Function()? isEnabled,
    Future<bool> Function()? isSilent,
    DateTime Function()? clock,
    this.maxRepeats = 3,
    this.repeatGap = const Duration(milliseconds: 700),
    this.dedupeWindow = const Duration(seconds: 30),
  }) : _sound = sound ?? AssetCallSound(),
       _vibrate = vibrate ?? _defaultVibrate,
       _isEnabled = isEnabled ?? (() => true),
       _isSilent = isSilent ?? DeviceAudioMode.isSilent,
       _clock = clock ?? DateTime.now;

  final CallSound _sound;
  final Future<void> Function() _vibrate;
  final bool Function() _isEnabled;
  final Future<bool> Function() _isSilent;
  final DateTime Function() _clock;

  /// Trois lectures : assez pour être entendu, assez court pour ne pas hurler.
  final int maxRepeats;

  final Duration repeatGap;

  /// Deux appels du même ticket dans cette fenêtre sont le même événement.
  final Duration dedupeWindow;

  String? _lastTicket;
  DateTime? _lastRingAt;
  bool _active = false;

  /// Incrémenté à chaque arrêt : une boucle en cours sait qu'elle est périmée.
  int _generation = 0;

  bool get isRinging => _active;

  /// Déclenche la sonnerie pour [ticketNumber].
  ///
  /// Ne lève jamais : une alerte sonore ne doit pas faire tomber l'écran qui
  /// l'a demandée.
  Future<void> ring({required String ticketNumber}) async {
    if (ticketNumber.isEmpty || !_isEnabled() || _active) {
      return;
    }

    final now = _clock();
    final last = _lastRingAt;
    if (_lastTicket == ticketNumber &&
        last != null &&
        now.difference(last) < dedupeWindow) {
      return;
    }

    _lastTicket = ticketNumber;
    _lastRingAt = now;
    _active = true;
    final generation = ++_generation;

    // La vibration part tout de suite : elle ne dépend pas du fichier audio et
    // reste le seul canal si le son est coupé ou illisible.
    unawaited(_vibrate());

    final silent = await _isSilent();
    if (silent || generation != _generation) {
      // En silencieux, la vibration a fait son travail : on ne force pas le son.
      if (generation == _generation) {
        _active = false;
      }
      return;
    }

    for (var played = 0; played < maxRepeats; played++) {
      if (generation != _generation) {
        return;
      }
      try {
        await _sound.playOnce();
      } on Object {
        // Fichier absent ou codec refusé : la vibration a déjà prévenu.
        break;
      }
      if (played < maxRepeats - 1) {
        await Future<void>.delayed(repeatGap);
      }
    }

    if (generation == _generation) {
      _active = false;
    }
  }

  /// Coupe la sonnerie immédiatement (interaction du client, ticket avancé).
  Future<void> stop() async {
    _generation++;
    _active = false;
    // Le ticket est oublié : si le guichet le rappelle vraiment, ce doit être
    // une nouvelle alerte, pas un silence hérité d'un arrêt précédent.
    _lastTicket = null;
    try {
      await _sound.stop();
    } on Object {
      // Rien à faire : le son est déjà arrêté ou le moteur audio est absent.
    }
  }

  Future<void> dispose() async {
    _generation++;
    _active = false;
    await _sound.dispose();
  }
}

/// Trois impulsions espacées : le motif se distingue d'une notification banale
/// même à travers une poche.
Future<void> _defaultVibrate() async {
  for (var pulse = 0; pulse < 3; pulse++) {
    await HapticFeedback.heavyImpact();
    if (pulse < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
  }
}
