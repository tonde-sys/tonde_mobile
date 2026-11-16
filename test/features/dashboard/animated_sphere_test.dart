import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/dashboard/presentation/widgets/animated_sphere.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: const Color(0xFF1E293B),
    child: SizedBox(width: 240, height: 240, child: child),
  ),
);

void main() {
  // `test/flutter_test_config.dart` désactive l'animation pour l'ensemble de
  // la suite : on restaure ce réglage après chaque test.
  tearDown(() => AnimatedSphereWidget.animationsEnabled = false);

  testWidgets('dessine une image fixe quand l\'animation est désactivée', (
    tester,
  ) async {
    AnimatedSphereWidget.animationsEnabled = false;
    await tester.pumpWidget(_host(const AnimatedSphereWidget()));

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('planifie une image par frame quand l\'animation est activée', (
    tester,
  ) async {
    AnimatedSphereWidget.animationsEnabled = true;
    await tester.pumpWidget(_host(const AnimatedSphereWidget()));

    expect(tester.binding.hasScheduledFrame, isTrue);

    // Démonte le widget pour arrêter le Ticker avant la fin du test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('se démonte sans laisser de Ticker actif', (tester) async {
    AnimatedSphereWidget.animationsEnabled = true;
    await tester.pumpWidget(_host(const AnimatedSphereWidget()));
    await tester.pumpWidget(const SizedBox.shrink());
    // Consomme l'image déjà planifiée par le Ticker avant son démontage.
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
