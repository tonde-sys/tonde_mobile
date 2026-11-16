import 'dart:async';

import 'package:tonde/features/dashboard/presentation/widgets/animated_sphere.dart';
import 'package:tonde/features/tracking/presentation/widgets/queue_status_badge.dart';

/// Configuration appliquée à tous les tests du paquet.
///
/// Deux animations tournent en continu dans l'application : la sphère du hero
/// et le badge « Appelé ». Tant qu'elles animent, `pumpAndSettle` ne retombe
/// jamais au repos et tous les tests qui traversent ces écrans échouent en
/// timeout. On les fige ici ; le rendu obtenu reste l'image du premier instant.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AnimatedSphereWidget.animationsEnabled = false;
  QueueStatusBadge.animationsEnabled = false;
  await testMain();
}
