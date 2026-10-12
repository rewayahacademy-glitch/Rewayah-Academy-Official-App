// BRAND-ORN-1 : la signature de la marque, aux deux seuls ecrans qui la
// portent ici. (1) Elle est affirmee : une fois au demarrage, une fois au pied
// de l'accueil de l'eleve, petite et a l'opacite fixee. (2) Elle ne deborde
// nulle part : a 320 points de large et texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/widgets/ornement_marque.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

final DateTime _horloge = DateTime(2026, 9, 8, 17);

List<Override> _surcharges() => <Override>[
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

Future<void> _monterDemarrage(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(const EcranDemarrage(), echelleTexte: echelle),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _monterAccueil(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      AccueilElevePage(horloge: () => _horloge),
      surcharges: _surcharges(),
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
}

void _signatureUnique(WidgetTester tester) {
  expect(find.byType(OrnementMarque), findsOneWidget);
  final OrnementMarque o = tester.widget(find.byType(OrnementMarque));
  expect(o.taille, TailleOrnement.petit);
  expect(o.variante, VarianteOrnement.plein);
  expect(o.opacite, OrnementMarque.opaciteSignature);
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('(1) la signature est affirmee', () {
    testWidgets(
      'au demarrage : une signature, entre la marque et l indicateur',
      (WidgetTester tester) async {
        await _monterDemarrage(tester);
        _signatureUnique(tester);
        final Rect signature = tester.getRect(find.byType(OrnementMarque));
        final Rect indicateur = tester.getRect(
          find.byType(CircularProgressIndicator),
        );
        expect(signature.bottom, lessThanOrEqualTo(indicateur.top));
      },
    );

    testWidgets('a l accueil de l eleve : une signature, au pied du contenu', (
      WidgetTester tester,
    ) async {
      await _monterAccueil(tester);
      _signatureUnique(tester);
      // Au pied : sous tous les blocs de contenu, jamais entre deux.
      final Rect signature = tester.getRect(find.byType(OrnementMarque));
      final Iterable<Element> textes = find.byType(Text).evaluate();
      expect(textes, isNotEmpty);
      for (final Element texte in textes) {
        final Rect r = tester.getRect(
          find.byElementPredicate((Element e) => e == texte),
        );
        expect(r.bottom, lessThanOrEqualTo(signature.top + 0.5));
      }
      final Rect corps = tester.getRect(find.byType(AccueilElevePage));
      expect(signature.center.dx, closeTo(corps.center.dx, 1));
    });

    testWidgets('la signature ne porte ni texte ni semantique', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _monterAccueil(tester);
      expect(
        find.descendant(
          of: find.byType(OrnementMarque),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(tester.getSemantics(find.byType(OrnementMarque)).label, isEmpty);
      poignee.dispose();
    });
  });

  group('(2) a 320 points, texte x2 : aucun debordement', () {
    const Size etroit = Size(320, 568);

    testWidgets('demarrage', (WidgetTester tester) async {
      await _monterDemarrage(tester, taille: etroit, echelle: 2);
      expect(tester.takeException(), isNull);
      _signatureUnique(tester);
      final Rect signature = tester.getRect(find.byType(OrnementMarque));
      expect(signature.left, greaterThanOrEqualTo(0));
      expect(signature.right, lessThanOrEqualTo(etroit.width));
      expect(signature.bottom, lessThanOrEqualTo(etroit.height));
    });

    testWidgets('accueil de l eleve', (WidgetTester tester) async {
      await _monterAccueil(tester, taille: etroit, echelle: 2);
      expect(tester.takeException(), isNull);
      _signatureUnique(tester);
      final Rect signature = tester.getRect(find.byType(OrnementMarque));
      expect(signature.left, greaterThanOrEqualTo(0));
      expect(signature.right, lessThanOrEqualTo(etroit.width));
      // L'accueil defile : la signature, au pied, se trouve en faisant defiler.
      await tester.ensureVisible(find.byType(OrnementMarque));
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
