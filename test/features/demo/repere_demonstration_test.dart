import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

void main() {
  testWidgets('le bandeau hors ligne garde son texte hors du ruban', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const String texte =
        'Pas de reseau. Tout reste consultable, l envoi '
        'attendra.';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
          home: const Scaffold(
            body: Column(
              children: <Widget>[OfflineBanner.message(message: texte)],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getRect(find.text(texte)).right,
      lessThanOrEqualTo(390 - empriseRepereDemonstration),
    );
  });

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
