import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

void main() {
  testWidgets('le repere Demonstration coiffe le rendu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? child) =>
            RepereDemonstration(child: child),
        home: const Text('accueil'),
      ),
    );
    expect(find.text('accueil'), findsOneWidget);
    final Banner bandeau = tester.widget<Banner>(find.byType(Banner));
    expect(bandeau.message, libelleRepereDemonstration);
  });

  testWidgets('le repere est annonce au lecteur d ecran (P2-10)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? child) =>
            RepereDemonstration(child: child),
        home: const Text('accueil'),
      ),
    );
    expect(
      find.bySemanticsLabel('Mode $libelleRepereDemonstration'),
      findsOneWidget,
    );
    semantique.dispose();
  });
}
