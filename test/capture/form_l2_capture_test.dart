// Captures de recette de FORM-L2 : le choix de l'eleve ou de l'enseignant
// dans une liste, sur les vraies feuilles des ecrans Classes et Evaluations.
// 390x844 et 1440x900, clair et sombre ; 320 a texte x2, clair et sombre
// (K-61). Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';

import '../features/support_form_l2.dart';
import 'outil_capture.dart';

enum _Feuille { creation, ajout, evaluation }

Future<void> _ouvrir(
  WidgetTester tester,
  _Feuille feuille, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final List<Override> surcharges = surchargesFormL2(
    comptes: FauxComptesFormL2(comptesFormL2),
  );
  await tester.pumpWidget(
    hoteCapture(
      feuille == _Feuille.evaluation
          ? const EvaluationsPage()
          : const GroupesPage(),
      surcharges: surcharges,
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
  switch (feuille) {
    case _Feuille.creation:
      await tester.tap(find.text(t.admin.groupes.creer).first);
    case _Feuille.ajout:
      await tester.tap(find.byType(MenuActions).first);
      await stabiliser(tester);
      await tester.tap(find.text(t.admin.groupes.actionAjouter).last);
    case _Feuille.evaluation:
      await tester.tap(find.text(t.admin.evaluations.planifier).first);
  }
  await stabiliser(tester);
  // Un choix fait : l'etat retenu se voit sur la carte.
  final Finder carte = find.byKey(
    ValueKey<String>(
      feuille == _Feuille.creation ? 'personne-t-yacine' : 'personne-e-ines',
    ),
  );
  await tester.ensureVisible(carte);
  await stabiliser(tester);
  await tester.tap(carte);
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : FORM-L2', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final _Feuille feuille in <_Feuille>[
        _Feuille.creation,
        _Feuille.evaluation,
      ]) {
        testWidgets('390x844 @3, ${feuille.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: zone);
          await _ouvrir(tester, feuille, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l2_${feuille.name}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('320x1400 @2 texte x2, ${feuille.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 1400), 2);
          await _ouvrir(tester, feuille, mode: mode, echelle: 2);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l2_${feuille.name}_320x1400@2_x2_${mode.name}')}',
          );
        });
      }

      for (final _Feuille feuille in _Feuille.values) {
        testWidgets('1440x900 @1, ${feuille.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _ouvrir(tester, feuille, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l2_${feuille.name}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }
  });
}
