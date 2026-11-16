import 'package:flutter/material.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Présentation en trois écrans, affichée au tout premier lancement.
///
/// Les illustrations sont dessinées avec des widgets et un peu de peinture
/// vectorielle : aucune image à charger, donc un affichage instantané même
/// sans réseau. Aucune permission n'est demandée ici — la caméra ne sera
/// demandée qu'au moment du scan, les notifications après le premier ticket.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  /// Appelé par « Passer » et par « Commencer ».
  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final slides = <_SlideData>[
      _SlideData(
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
        illustration: const _PromiseIllustration(),
      ),
      _SlideData(
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
        illustration: const _TimingIllustration(),
      ),
      _SlideData(
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
        illustration: const _ScanIllustration(),
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _index < _pageCount - 1 ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: _index >= _pageCount - 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: widget.onFinished,
                        child: Text(l10n.onboardingSkip),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  for (final slide in slides) _Slide(data: slide),
                ],
              ),
            ),
            _Pagination(index: _index, count: _pageCount),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _index == _pageCount - 1
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: widget.onFinished,
                        child: Text(l10n.onboardingStart),
                      ),
                    )
                  : Row(
                      children: [
                        if (_index > 0)
                          TextButton(
                            onPressed: _back,
                            child: Text(l10n.onboardingBack),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _next,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(l10n.onboardingNext),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String title;
  final String body;
  final Widget illustration;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 280, child: Center(child: data.illustration)),
          const SizedBox(height: 12),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trois points, dont le point actif s'allonge en pilule.
class _Pagination extends StatelessWidget {
  const _Pagination({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Illustrations
// ---------------------------------------------------------------------------

/// Cadre de téléphone commun aux trois illustrations.
class _Phone extends StatelessWidget {
  const _Phone({required this.child, this.width = 124, this.height = 208});

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.55), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 26,
            height: 4,
            margin: const EdgeInsets.only(top: 2, bottom: 6),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Pastille circulaire d'accent (coche verte, cloche…).
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, this.size = 38});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
  }
}

/// Silhouette en ligne, comme dans l'animation de démarrage.
class _Person extends StatelessWidget {
  const _Person({required this.color, this.height = 22});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Container(
          width: 9,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.5),
          ),
        ),
      ],
    );
  }
}

/// Écran 1 : le ticket numérique, et la file qui n'est plus subie.
class _PromiseIllustration extends StatelessWidget {
  const _PromiseIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.28);
    const green = Color(0xFF1D9E75);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 216,
            height: 216,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Person(color: muted, height: 18),
                const SizedBox(width: 10),
                _Person(color: muted, height: 22),
                const SizedBox(width: 10),
                _Person(color: muted, height: 16),
              ],
            ),
          ),
          _Phone(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A-014',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 26,
            bottom: 44,
            child: _Badge(icon: Icons.check_rounded, color: green, size: 44),
          ),
        ],
      ),
    );
  }
}

/// Écran 2 : le compte à rebours avant l'appel.
class _TimingIllustration extends StatelessWidget {
  const _TimingIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const amber = Color(0xFFBA7517);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 216,
            height: 216,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          _Phone(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: CircularProgressIndicator(
                          value: 0.68,
                          strokeWidth: 6,
                          backgroundColor: scheme.onSurfaceVariant.withValues(
                            alpha: 0.18,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '3',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '≈ 8 min',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: i == 0 ? 0.55 : 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            right: 30,
            top: 44,
            child: _Badge(
              icon: Icons.notifications_active_outlined,
              color: amber,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran 3 : le ticket papier scanné devient un ticket mobile.
class _ScanIllustration extends StatelessWidget {
  const _ScanIllustration();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 216,
            height: 216,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: 18,
            top: 56,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                width: 86,
                height: 112,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'B-145',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          width: i == 2 ? 34 : 58,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.22,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 40,
            child: _Phone(
              width: 120,
              height: 196,
              child: const _ScanFrame(),
            ),
          ),
          Positioned(
            right: 6,
            top: 52,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: scheme.primary.withValues(alpha: 0.55),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cadre de visée avec une ligne de balayage qui descend en boucle.
class _ScanFrame extends StatefulWidget {
  const _ScanFrame();

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Motif fixe : lisible comme un QR, sans dépendre du hasard.
    final cells = [
      for (var i = 0; i < 25; i++) (i * 7 + 3) % 5 < 2,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var row = 0; row < 5; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var col = 0; col < 5; col++)
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cells[row * 5 + col]
                              ? scheme.onSurface.withValues(alpha: 0.75)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Align(
              alignment: Alignment(0, -1 + 2 * _controller.value),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0),
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Coins de visée.
          for (final alignment in [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(
                  painter: _CornerPainter(
                    alignment: alignment,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dessine un seul coin de visée, orienté selon [alignment].
class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    final left = alignment.x < 0;
    final top = alignment.y < 0;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    path.moveTo(x + (left ? 0 : -12), y);
    path.lineTo(x, y);
    path.lineTo(x, y + (top ? 12 : -12));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.alignment != alignment;
}
