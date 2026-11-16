import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Sphère holographique dessinée en caractères ASCII.
///
/// Reproduction du composant web `AnimatedSphere` du hero TONDE : la surface
/// d'une sphère est échantillonnée sur une grille phi/theta, projetée en
/// orthographique, triée par profondeur (painter's algorithm) puis dessinée
/// caractère par caractère. La couleur est interpolée du violet (avant) vers
/// le cyan (arrière) et l'opacité dépend de la profondeur Z.
///
/// Aucune image, aucun SVG, aucune bibliothèque 3D : le rendu tient
/// entièrement dans un [CustomPainter].
class AnimatedSphereWidget extends StatefulWidget {
  const AnimatedSphereWidget({super.key});

  /// Autorise l'animation en continu.
  ///
  /// Une animation perpétuelle empêche `pumpAndSettle` de retomber au repos :
  /// les tests de widgets la désactivent via `test/flutter_test_config.dart`
  /// et obtiennent alors une image fixe, identique au premier rendu.
  static bool animationsEnabled = true;

  @override
  State<AnimatedSphereWidget> createState() => _AnimatedSphereWidgetState();
}

class _AnimatedSphereWidgetState extends State<AnimatedSphereWidget>
    with SingleTickerProviderStateMixin {
  /// Vitesse de la spec web : +0.02 par image à 60 fps, soit 1.2 par seconde.
  ///
  /// Le pas est calculé à partir du temps réel de la [Ticker] plutôt que du
  /// nombre d'images : sur un écran 120 Hz la sphère tourne à la même vitesse.
  static const double _unitsPerSecond = 1.2;

  /// Pas maximal accepté entre deux images (50 ms). Un retour au premier plan
  /// produit un écart important qu'il ne faut pas traduire en saut visuel.
  static const double _maxStepSeconds = 0.05;

  late final Ticker _ticker;
  final _SphereModel _model = _SphereModel();
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration _lastElapsed = Duration.zero;
  late final bool _animated = AnimatedSphereWidget.animationsEnabled;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (_animated) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final delta = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    _time.value += math.min(delta, _maxStepSeconds) * _unitsPerSecond;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animated) {
      return CustomPaint(painter: _SpherePainter(time: 0, model: _model));
    }

    // Seul le CustomPaint est reconstruit à chaque image : l'AnimatedBuilder
    // isole le hero du rythme de l'animation.
    return AnimatedBuilder(
      animation: _time,
      builder: (context, child) => CustomPaint(
        painter: _SpherePainter(time: _time.value, model: _model),
      ),
    );
  }
}

/// Géométrie, tampons et glyphes réutilisés d'une image à l'autre.
///
/// Tous les tampons sont alloués une seule fois : à 60 fps, allouer une liste
/// de points par image créerait une pression inutile sur le ramasse-miettes
/// des appareils Android d'entrée de gamme.
class _SphereModel {
  _SphereModel() {
    for (double phi = 0; phi < 2 * math.pi; phi += _step) {
      for (double theta = 0; theta < math.pi; theta += _step) {
        _phi.add(phi);
        _sinTheta.add(math.sin(theta));
        _cosTheta.add(math.cos(theta));
      }
    }

    final count = _phi.length;
    _screenX = Float64List(count);
    _screenY = Float64List(count);
    _depthZ = Float64List(count);
    _order = List<int>.generate(count, (index) => index);
    _buildGlyphs();
  }

  /// Pas de la grille sphérique (spec web : 0.15).
  static const double _step = 0.15;

  /// Caractères de la spec, du plus lointain au plus proche.
  ///
  /// Le brief annonce « 19 caractères » mais n'en liste que 18 : on dessine
  /// ceux qui sont listés et l'index est borné à la longueur réelle.
  static const List<String> _chars = [
    '░',
    '▒',
    '▓',
    '█',
    '▀',
    '▄',
    '▌',
    '▐',
    '│',
    '─',
    '┤',
    '├',
    '┴',
    '┬',
    '╭',
    '╮',
    '╰',
    '╯',
  ];

  /// Nombre de paliers de profondeur pour la couleur et l'opacité.
  ///
  /// Les couleurs sont quantifiées par palier afin de réutiliser des
  /// [TextPainter] déjà calculés : la mise en page d'un texte par point et par
  /// image coûterait bien plus cher que le dessin lui-même.
  static const int _depthBuckets = 32;

  static const double _fontSize = 12;

  final List<double> _phi = <double>[];
  final List<double> _sinTheta = <double>[];
  final List<double> _cosTheta = <double>[];

  late final Float64List _screenX;
  late final Float64List _screenY;
  late final Float64List _depthZ;
  late final List<int> _order;

  late final List<List<TextPainter>> _glyphs;

  late final int Function(int, int) _byDepth = _compareDepth;

  void _buildGlyphs() {
    _glyphs = List<List<TextPainter>>.generate(_chars.length, (charIndex) {
      return List<TextPainter>.generate(_depthBuckets, (bucket) {
        final depth = (bucket + 0.5) / _depthBuckets;
        return _layoutGlyph(_chars[charIndex], _colorForDepth(depth));
      });
    });
  }

  TextPainter _layoutGlyph(String char, Color color) {
    return TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontSize: _fontSize,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['RobotoMono', 'Courier'],
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Violet `rgb(108, 71, 255)` en avant, cyan `rgb(0, 212, 255)` en arrière.
  static Color _colorForDepth(double depth) {
    final r = (108 * (1 - depth)).round();
    final g = (71 * (1 - depth) + 212 * depth).round();
    final b = (255 * (1 - depth) + 255 * depth).round();
    final alpha = (0.24 + depth * 0.32).clamp(0.0, 0.82);
    return Color.fromARGB((alpha * 255).round(), r, g, b);
  }

  void paint(Canvas canvas, Size size, double time) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.52;

    final cosY = math.cos(time * 0.3);
    final sinY = math.sin(time * 0.3);
    final cosX = math.cos(time * 0.2);
    final sinX = math.sin(time * 0.2);
    final spin = time * 0.5;

    // 1. Sphère paramétrique, rotations Y puis X, projection orthographique.
    for (var i = 0; i < _phi.length; i++) {
      final sinTheta = _sinTheta[i];
      final angle = _phi[i] + spin;
      final x = sinTheta * math.cos(angle);
      final y = sinTheta * math.sin(angle);
      final z = _cosTheta[i];

      final rotatedX = x * cosY - z * sinY;
      final rotatedZ = x * sinY + z * cosY;
      final rotatedY = y * cosX - rotatedZ * sinX;
      final finalZ = y * sinX + rotatedZ * cosX;

      _screenX[i] = centerX + rotatedX * radius;
      _screenY[i] = centerY + rotatedY * radius;
      _depthZ[i] = finalZ;
    }

    // 2. Painter's algorithm : les points lointains d'abord.
    _order.sort(_byDepth);

    // 3. Dessin des caractères, du fond vers l'avant.
    for (final i in _order) {
      final depth = (_depthZ[i] + 1.0) / 2.0;
      final bucket = math.min(
        (depth * _depthBuckets).floor(),
        _depthBuckets - 1,
      );
      final charIndex = math.min((depth * 18).floor(), _chars.length - 1);
      final glyph = _glyphs[charIndex][bucket];
      glyph.paint(
        canvas,
        Offset(_screenX[i] - glyph.width / 2, _screenY[i] - glyph.height / 2),
      );
    }
  }

  int _compareDepth(int a, int b) => _depthZ[a].compareTo(_depthZ[b]);

  void dispose() {
    for (final column in _glyphs) {
      for (final glyph in column) {
        glyph.dispose();
      }
    }
  }
}

class _SpherePainter extends CustomPainter {
  _SpherePainter({required this.time, required this.model});

  final double time;
  final _SphereModel model;

  @override
  void paint(Canvas canvas, Size size) => model.paint(canvas, size, time);

  @override
  bool shouldRepaint(_SpherePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.model != model;
}
