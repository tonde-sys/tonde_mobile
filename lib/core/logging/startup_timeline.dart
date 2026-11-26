import 'package:flutter/foundation.dart';

/// Chronologie du démarrage, en millisecondes depuis l'entrée dans `main`.
///
/// Un seul relevé par lancement, sur une seule ligne : c'est ce qu'on demande
/// au téléphone quand quelqu'un dit « l'application met du temps à s'ouvrir ».
/// Sans chiffre, on ne corrige que des intuitions — et on ajoute des délais
/// là où il faudrait en retirer.
///
/// Ce que ce relevé **ne mesure pas** : le temps passé par Android et par le
/// moteur Flutter avant l'appel de `main` (écran natif, chargement de la VM,
/// première compilation). Pour le total vu par l'utilisateur :
///
///     adb shell am start -W -n app.tonde/.MainActivity
///
/// La ligne produite ici et le `TotalTime` d'`am start` se complètent : le
/// premier dit ce que l'application fait de son temps, le second ce que le
/// système lui en laisse.
abstract final class StartupTimeline {
  static final Stopwatch _watch = Stopwatch()..start();
  static final Map<String, int> _marks = <String, int>{};
  static bool _reported = false;

  /// Enregistre un jalon, une seule fois.
  ///
  /// Le premier appel vaut 0 ms par convention : c'est l'entrée dans `main`,
  /// pas le lancement de l'application.
  static void mark(String label) {
    _marks.putIfAbsent(label, () => _watch.elapsedMilliseconds);
  }

  /// Écrit la ligne, une seule fois par lancement.
  ///
  /// `debugPrint` plutôt qu'`AppLogger` : en build release, `developer.log`
  /// n'atteint pas logcat — et c'est justement la release qu'on mesure, sur
  /// les téléphones de l'équipe.
  static void reportOnce() {
    if (_reported) {
      return;
    }
    _reported = true;
    final details = _marks.entries
        .map((entry) => '${entry.key}=${entry.value}ms')
        .join(' ');
    debugPrint('TONDE_STARTUP $details');
  }

  /// Remet le relevé à zéro. Réservé aux tests : un lancement réel n'a lieu
  /// qu'une fois par processus.
  @visibleForTesting
  static void reset() {
    _watch
      ..reset()
      ..start();
    _marks.clear();
    _reported = false;
  }
}
