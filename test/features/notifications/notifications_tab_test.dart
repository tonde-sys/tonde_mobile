import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/features/dashboard/presentation/pages/notifications_tab.dart';
import 'package:tonde/features/notifications/domain/entities/tonde_notification.dart';
import 'package:tonde/features/notifications/presentation/controllers/notification_providers.dart';

TondeNotification _notification({
  required TondeNotificationKind kind,
  required String title,
  required String body,
  required int minute,
}) {
  return TondeNotification(
    kind: kind,
    title: title,
    body: body,
    ticketNumber: 'B-145',
    sentAt: DateTime(2026, 11, 15, 10, minute),
  );
}

Future<ProviderContainer> _pumpTab(
  WidgetTester tester,
  List<TondeNotification> notifications,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final center = container.read(notificationCenterProvider.notifier);
  // Ordre d'arrivée réel : le centre empile la plus récente en tête.
  final chronological = [...notifications]
    ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  for (final notification in chronological) {
    center.add(notification);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const Scaffold(body: NotificationsTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('toucher une alerte la marque comme lue', (tester) async {
    final container = await _pumpTab(tester, [
      _notification(
        kind: TondeNotificationKind.called,
        title: 'C’est votre tour !',
        body: 'Le ticket B-145 est appelé au Guichet 4.',
        minute: 5,
      ),
    ]);

    expect(container.read(unreadNotificationsProvider), 1);

    await tester.tap(find.text('C’est votre tour !'));
    await tester.pumpAndSettle();

    expect(container.read(unreadNotificationsProvider), 0);
    expect(container.read(notificationCenterProvider).single.read, isTrue);
  });

  testWidgets('le bouton supprimer retire l’alerte de la liste', (
    tester,
  ) async {
    final container = await _pumpTab(tester, [
      _notification(
        kind: TondeNotificationKind.called,
        title: 'C’est votre tour !',
        body: 'Le ticket B-145 est appelé au Guichet 4.',
        minute: 5,
      ),
      _notification(
        kind: TondeNotificationKind.ticketConfirmed,
        title: 'Votre ticket B-145 est confirmé',
        body: 'Vous êtes inscrit dans la file Consultation.',
        minute: 0,
      ),
    ]);

    expect(find.byType(IconButton), findsNWidgets(2));

    // La première carte est la plus récente : c'est elle qu'on supprime.
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(container.read(notificationCenterProvider).length, 1);
    expect(find.text('C’est votre tour !'), findsNothing);
    expect(find.text('Votre ticket B-145 est confirmé'), findsOneWidget);
  });

  testWidgets('sans alerte, l’onglet explique ce qui va arriver', (
    tester,
  ) async {
    await _pumpTab(tester, const []);

    expect(find.text('Aucune notification pour le moment'), findsOneWidget);
  });
}
