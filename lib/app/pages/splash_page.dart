import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Écran de démarrage de TONDE.
///
/// Le nom est écrit au-dessus du logo, et sous celui-ci une petite file
/// d'attente s'écoule vers la droite : des silhouettes en lignes qui avancent
/// vers le guichet. Tout est dessiné à la main (aucune image, aucune
/// animation externe), donc l'écran s'affiche instantanément, même hors ligne.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Teintes fixes de l'écran de marque.
  ///
  /// L'écran de démarrage natif d'Android ne connaît pas le thème choisi dans
  /// l'application : il suit celui du téléphone. En figeant ces trois teintes
  /// ici, la marque reste identique dans tous les cas et le passage du fond
  /// natif à Flutter ne se voit pas, ni en clair ni en sombre.
  static const Color background = Color(0xFF1E293B);
  static const Color foreground = Color(0xFFB9CDFF);
  static const Color muted = Color(0xFF8FA3BF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TONDE',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 116,
                  height: 116,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 76,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => CustomPaint(
                    painter: _QueuePainter(
                      progress: _controller.value,
                      track: muted,
                      accent: foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context).tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// File d'attente en lignes : cinq silhouettes glissent vers le guichet.
///
/// La silhouette la plus proche du guichet passe en couleur d'accent, comme
/// le client qui vient d'être appelé. Les silhouettes s'estompent en entrant
/// et en sortant du cadre, ce qui rend la boucle invisible.
class _QueuePainter extends CustomPainter {
  const _QueuePainter({
    required this.progress,
    required this.track,
    required this.accent,
  });

  final double progress;
  final Color track;
  final Color accent;

  static const int _count = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 8;
    final slot = size.width / _count;
    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final headPaint = Paint()..style = PaintingStyle.fill;

    // Ligne de sol, en pointillés : la « file » elle-même.
    final dashPaint = Paint()
      ..color = track.withValues(alpha: 0.25)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, baseline + 4),
        Offset(math.min(x + 4, size.width), baseline + 4),
        dashPaint,
      );
    }

    // Guichet, à droite : un trait vertical un peu plus haut.
    final counterPaint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width - 1, baseline - 26),
      Offset(size.width - 1, baseline),
      counterPaint,
    );

    // Positions courantes, pour repérer la silhouette la plus avancée.
    final xs = <double>[
      for (var index = 0; index < _count; index++)
        (index * slot + progress * slot) % size.width,
    ];
    final leader = xs.indexOf(xs.reduce(math.max));

    for (var index = 0; index < _count; index++) {
      final x = xs[index];
      // Fondu aux deux bords : la boucle reste invisible.
      final edge = math.min(x, size.width - x);
      final opacity = (edge / 18).clamp(0.0, 1.0);
      if (opacity == 0) {
        continue;
      }
      final isLeader = index == leader;
      final color = isLeader ? accent : track;
      final alpha = isLeader ? opacity : opacity * 0.45;
      // Petite respiration verticale, décalée d'une silhouette à l'autre.
      final bob =
          math.sin((progress * 2 * math.pi) + index * 0.9) * 2.2;
      final height = (isLeader ? 24.0 : 18.0) + bob;

      bodyPaint.color = color.withValues(alpha: alpha);
      headPaint.color = color.withValues(alpha: alpha);

      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 4.5, baseline - height, 9, height),
        const Radius.circular(4.5),
      );
      canvas.drawRRect(bodyRect, bodyPaint);
      canvas.drawCircle(Offset(x, baseline - height - 7), 4.2, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QueuePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.accent != accent;
}
