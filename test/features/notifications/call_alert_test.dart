import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/features/notifications/data/call_alert_controller.dart';

/// Son factice : compte les lectures et permet de les retenir.
final class _FakeSound implements CallSound {
  int plays = 0;
  int stops = 0;
  bool disposed = false;
  bool fail = false;

  @override
  Future<void> playOnce() async {
    if (fail) {
      throw StateError('fichier illisible');
    }
    plays++;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

/// Son qui ne rend pas la main tant qu'on ne l'y autorise pas : c'est ce qui
/// permet de tester l'arrêt au milieu d'une lecture.
final class _GatedSound implements CallSound {
  int plays = 0;
  final List<Completer<void>> gates = <Completer<void>>[];

  @override
  Future<void> playOnce() {
    plays++;
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

CallAlertController _controller({
  required CallSound sound,
  List<int>? vibrations,
  bool enabled = true,
  bool silent = false,
  DateTime Function()? clock,
  int maxRepeats = 3,
}) {
  return CallAlertController(
    sound: sound,
    vibrate: () async => vibrations?.add(1),
    isEnabled: () => enabled,
    isSilent: () async => silent,
    clock: clock,
    maxRepeats: maxRepeats,
    repeatGap: Duration.zero,
  );
}

void main() {
  group('Sonnerie d’appel', () {
    test('insiste trois fois puis s’arrête', () async {
      final sound = _FakeSound();
      final controller = _controller(sound: sound);

      await controller.ring(ticketNumber: 'A-014');

      expect(sound.plays, 3);
      expect(controller.isRinging, isFalse);
    });

    test('ne sonne pas deux fois pour le même appel', () async {
      final sound = _FakeSound();
      final controller = _controller(sound: sound);

      await controller.ring(ticketNumber: 'A-014');
      await controller.ring(ticketNumber: 'A-014');

      // Le flux temps réel et le push racontent le même événement : une seule
      // sonnerie doit en sortir.
      expect(sound.plays, 3);
    });

    test('un autre ticket sonne à nouveau', () async {
      final sound = _FakeSound();
      final controller = _controller(sound: sound);

      await controller.ring(ticketNumber: 'A-014');
      await controller.ring(ticketNumber: 'A-015');

      expect(sound.plays, 6);
    });

    test('la fenêtre de dédoublonnage expire', () async {
      final sound = _FakeSound();
      var now = DateTime(2026, 11, 26, 10);
      final controller = _controller(sound: sound, clock: () => now);

      await controller.ring(ticketNumber: 'A-014');
      now = now.add(const Duration(seconds: 31));
      await controller.ring(ticketNumber: 'A-014');

      expect(sound.plays, 6);
    });

    test('stop coupe la sonnerie en cours', () async {
      final sound = _GatedSound();
      final controller = _controller(sound: sound);

      final ringing = controller.ring(ticketNumber: 'A-014');
      while (sound.gates.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.isRinging, isTrue);

      await controller.stop();
      sound.gates.first.complete();
      await ringing;

      // Une seule lecture a eu lieu : les deux suivantes sont annulées.
      expect(sound.plays, 1);
      expect(controller.isRinging, isFalse);
    });

    test('en silencieux, la vibration seule prévient', () async {
      final sound = _FakeSound();
      final vibrations = <int>[];
      final controller = _controller(
        sound: sound,
        vibrations: vibrations,
        silent: true,
      );

      await controller.ring(ticketNumber: 'A-014');

      expect(sound.plays, 0);
      expect(vibrations, hasLength(1));
    });

    test('un fichier illisible ne fait pas tomber l’alerte', () async {
      final sound = _FakeSound()..fail = true;
      final vibrations = <int>[];
      final controller = _controller(sound: sound, vibrations: vibrations);

      await controller.ring(ticketNumber: 'A-014');

      // La vibration est le filet : elle part avant la lecture.
      expect(vibrations, hasLength(1));
      expect(sound.plays, 0);
      expect(controller.isRinging, isFalse);
    });

    test('désactivée, elle ne fait rien du tout', () async {
      final sound = _FakeSound();
      final vibrations = <int>[];
      final controller = _controller(
        sound: sound,
        vibrations: vibrations,
        enabled: false,
      );

      await controller.ring(ticketNumber: 'A-014');

      expect(sound.plays, 0);
      expect(vibrations, isEmpty);
    });

    test('dispose libère le moteur audio', () async {
      final sound = _FakeSound();
      final controller = _controller(sound: sound);

      await controller.dispose();

      expect(sound.disposed, isTrue);
    });
  });
}
