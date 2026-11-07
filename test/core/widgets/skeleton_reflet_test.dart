// FLUIDITE-1 (DECISION-FLUIDITE-2026-11-07 §2) : le reflet lent du Skeleton.
// - Un reflet traverse les blocs, en translation seule, dans le sens de
//   lecture.
// - Aucune fausse donnee : aucun texte.
// - Sous mouvement reduit : aucun reflet, aucune boucle.
// - Le delai de 180 ms avant toute image est garde.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';

import '../../support/hote_theme.dart';

Widget _hote({
  required bool reduit,
  bool differe = false,
  TextDirection sens = TextDirection.ltr,
}) => hoteTheme(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
      child: Directionality(
        textDirection: sens,
        child: SizedBox(width: 320, child: Skeleton.texte(differe: differe)),
      ),
    ),
  ),
);

/// Les translations horizontales des reflets (une par bloc).
List<double> _reflets(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(Transform),
      ),
    )
    .map((Transform t) => t.transform.getTranslation().x)
    .toList();

void main() {
  group('FLUIDITE-1 : le reflet lent du squelette', () {
    testWidgets('un reflet par bloc, qui avance, ensemble', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      final List<double> avant = _reflets(tester);
      // Skeleton.texte : trois blocs, trois reflets.
      expect(avant, hasLength(3));
      await tester.pump(const Duration(milliseconds: 400));
      final List<double> apres = _reflets(tester);
      for (int i = 0; i < 3; i++) {
        expect(apres[i], greaterThan(avant[i]));
      }
      expect(tester.binding.hasScheduledFrame, isTrue);
      // Aucune fausse donnee.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('en arabe, le reflet traverse dans le sens de lecture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, sens: TextDirection.rtl));
      await tester.pump(const Duration(milliseconds: 100));
      final double avant = _reflets(tester).first;
      await tester.pump(const Duration(milliseconds: 400));
      expect(_reflets(tester).first, lessThan(avant));
    });

    testWidgets('les blocs gardent leur taille pendant le reflet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pump();
      final Size fixe = tester.getSize(find.byType(Skeleton));
      await tester.pumpWidget(_hote(reduit: false));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(find.byType(Skeleton)), fixe);
      }
    });

    testWidgets('deux squelettes montes a 300 ms d ecart passent ensemble', (
      WidgetTester tester,
    ) async {
      Widget hote({required bool deux}) => hoteTheme(
        Column(
          children: <Widget>[
            const SizedBox(
              width: 320,
              child: Skeleton(hauteur: 16, differe: false),
            ),
            if (deux)
              const SizedBox(
                width: 320,
                child: Skeleton(hauteur: 16, differe: false),
              ),
          ],
        ),
      );
      await tester.pumpWidget(hote(deux: false));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(hote(deux: true));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 170));
        final List<double> x = _reflets(tester);
        expect(x, hasLength(2));
        expect(x.last, closeTo(x.first, 0.5), reason: 'meme phase');
      }
    });

    testWidgets('mouvement reduit : aucun reflet, aucune boucle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pumpAndSettle();
      expect(_reflets(tester), isEmpty);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('le delai de 180 ms est garde : rien avant, puis le reflet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, differe: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_reflets(tester), isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_reflets(tester), hasLength(3));
    });
  });
}
