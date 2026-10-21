// Captures de recette d'Aujourd'hui du Comptable (CPT-JOUR) : la VRAIE
// coquille de demonstration (`CoquilleComptableDemo`, `/demo/comptable
// ?ecran=aujourdhui`) sur la VRAIE page, donnees de `aujourdhui_demo.dart`.
// 390x844 @3 et 1440x900 @1, clair et sombre, montants masques ; une
// version pleine hauteur de chaque largeur ; montants affiches ; la file
// complete ; 320 px texte x2.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart';
import '../../../router/support_routeur.dart' hide stabiliser;
import '../../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  EcranDemoComptable ecran, {
  ThemeMode mode = ThemeMode.light,
  bool montantsAffiches = false,
  double texte = 1,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      CoquilleComptableDemo(ecran: ecran, montantsAffiches: montantsAffiches),
      surcharges: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.accountant)),
      ),
      themeMode: mode,
      echelleTexte: texte,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : Aujourd hui du Comptable (CPT-JOUR)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille, double densite, EdgeInsets zone) vue
          in <(String, Size, double, EdgeInsets)>[
            (
              '390x844@3',
              const Size(390, 844),
              3,
              const EdgeInsets.only(top: 47, bottom: 34),
            ),
            ('390x2000@2_plein', const Size(390, 2000), 2, EdgeInsets.zero),
            ('1440x900@1', const Size(1440, 900), 1, EdgeInsets.zero),
            ('1440x1800@1_plein', const Size(1440, 1800), 1, EdgeInsets.zero),
          ]) {
        testWidgets('${vue.$1}, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, vue.$2, vue.$3, zoneSure: vue.$4);
          await _monter(tester, EcranDemoComptable.aujourdhui, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'aujourdhui_${vue.$1}_${mode.name}')}',
          );
        });
      }
    }

    testWidgets('1440x1800, montants affiches, clair', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1800), 1);
      await _monter(
        tester,
        EcranDemoComptable.aujourdhui,
        montantsAffiches: true,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'aujourdhui_1440x1800@1_affiches_light')}',
      );
    });

    testWidgets('file complete, 390x2000, clair', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 2000), 2);
      await _monter(tester, EcranDemoComptable.attention);
      debugPrint(
        'PNG ${await capturer(tester, 'aujourdhui_attention_390x2000@2_light')}',
      );
    });

    for (final EcranDemoComptable ecran in <EcranDemoComptable>[
      EcranDemoComptable.aujourdhui,
      EcranDemoComptable.attention,
    ]) {
      testWidgets('320x2400 texte x2, ${ecran.name}, clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 2400), 2);
        await _monter(tester, ecran, texte: 2);
        debugPrint(
          'PNG ${await capturer(tester, 'aujourdhui_${ecran.name}_320x2400@2_texte2_light')}',
        );
      });
    }
  });
}
