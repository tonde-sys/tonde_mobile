import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/app/app.dart';
import 'package:tonde/core/errors/app_exception.dart';
import 'package:tonde/core/errors/error_view.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une coupure réseau s’explique et se rejoue', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      ErrorView(
        error: const NetworkException(),
        onAction: () => retried++,
      ),
    );

    expect(
      find.text('Serveur injoignable. Vérifiez votre connexion.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('sans gestionnaire, aucun bouton n’est proposé', (tester) async {
    // Un bouton sans destination serait pire que pas de bouton.
    await _pump(tester, const ErrorView(error: NetworkException()));

    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('le détail technique reste replié', (tester) async {
    await _pump(
      tester,
      const ErrorView(
        error: ApiException(statusCode: 429, code: 'RATE_LIMITED'),
      ),
    );

    expect(find.text('Détails techniques'), findsOneWidget);
    // Replié : le code métier n'est pas visible tant qu'on ne déplie pas.
    expect(find.text('RATE_LIMITED'), findsNothing);

    await tester.tap(find.text('Détails techniques'));
    await tester.pumpAndSettle();

    expect(find.textContaining('RATE_LIMITED'), findsOneWidget);
    expect(find.textContaining('HTTP 429'), findsOneWidget);
  });

  testWidgets('la référence d’incident est affichée pour le support', (
    tester,
  ) async {
    await _pump(
      tester,
      const ErrorView(error: ApiException(statusCode: 500)),
    );

    await tester.tap(find.text('Détails techniques'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Référence :'), findsOneWidget);
  });

  testWidgets('un refus métier n’affiche pas de message générique', (
    tester,
  ) async {
    await _pump(
      tester,
      const ErrorView(
        error: ApiException(statusCode: 409, code: 'TICKET_ALREADY_ACTIVE'),
      ),
    );

    // Avant ce lot, tous ces cas affichaient « impossible de charger ».
    expect(find.text('Vous avez déjà un ticket en cours.'), findsOneWidget);
    expect(find.textContaining('impossible de charger'), findsNothing);
  });
}
