// Captures de recette de la Tresorerie (CPT-TRES-1, CPT-TRES-2) : la VRAIE
// coquille de demonstration (`/demo/comptable?ecran=tresorerie` et
// `?ecran=alimenter`, `CoquilleComptableDemo`), 390x844 @3 et 1440x900 @1,
// clair et sombre, montants masques et affiches ; 320 avec le texte a 200 % ;
// la page entiere en hauteur ; la Reserve sous deux politiques (mois,
// 1 000 000 USD).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_page.dart';
import 'package:rewayah_academy/features/demo/comptable/tresorerie_demo.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart';
import 'faux_tresorerie.dart';

const EdgeInsets _zoneTelephone = EdgeInsets.only(top: 47, bottom: 34);

Future<void> _demo(
  WidgetTester tester,
  EcranDemoComptable ecran, {
  ThemeMode mode = ThemeMode.light,
  bool affiches = false,
  double echelle = 1,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      CoquilleComptableDemo(ecran: ecran, montantsAffiches: affiches),
      // Les memes surcharges a la racine : les lectures de la page (providers
      // non surcharges) se resolvent dans la portee racine, pas dans celle,
      // imbriquee, de la coquille (sinon « en preparation »).
      surcharges: surchargesCoquilleComptableDemo(montantsAffiches: affiches),
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : Tresorerie (CPT-TRES)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final bool affiches in <bool>[false, true]) {
        final String etat = affiches ? 'affiches' : 'masques';
        testWidgets('390x844 @3, tresorerie, ${mode.name}, $etat', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: _zoneTelephone,
          );
          await _demo(
            tester,
            EcranDemoComptable.tresorerie,
            mode: mode,
            affiches: affiches,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'cpt_tres_tresorerie_390x844@3_${mode.name}_$etat')}',
          );
        });

        testWidgets('1440x900 @1, tresorerie, ${mode.name}, $etat', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _demo(
            tester,
            EcranDemoComptable.tresorerie,
            mode: mode,
            affiches: affiches,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'cpt_tres_tresorerie_1440x900@1_${mode.name}_$etat')}',
          );
        });
      }

      testWidgets('390x844 @3, alimenter (feuille), ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          const Size(390, 844),
          3,
          zoneSure: _zoneTelephone,
        );
        await _demo(tester, EcranDemoComptable.alimenter, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'cpt_tres_alimenter_390x844@3_${mode.name}_masques')}',
        );
      });

      testWidgets('1440x900 @1, alimenter (dialogue), ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _demo(
          tester,
          EcranDemoComptable.alimenter,
          mode: mode,
          affiches: true,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'cpt_tres_alimenter_1440x900@1_${mode.name}_affiches')}',
        );
      });
    }

    testWidgets('320 texte 200 %, tresorerie, page entiere', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 7600), 1);
      await _demo(tester, EcranDemoComptable.tresorerie, echelle: 2);
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'cpt_tres_tresorerie_320x2_page_entiere')}',
      );
    });

    testWidgets('320 texte 200 %, alimenter', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, 900), 2);
      await _demo(tester, EcranDemoComptable.alimenter, echelle: 2);
      expect(tester.takeException(), isNull);
      debugPrint('PNG ${await capturer(tester, 'cpt_tres_alimenter_320x2')}');
    });

    testWidgets('390 page entiere, clair, montants affiches', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 3900), 2);
      await _demo(tester, EcranDemoComptable.tresorerie, affiches: true);
      debugPrint(
        'PNG ${await capturer(tester, 'cpt_tres_tresorerie_390_page_entiere_affiches')}',
      );
    });

    testWidgets('1440 page entiere, sombre, montants affiches', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 1900), 1);
      await _demo(
        tester,
        EcranDemoComptable.tresorerie,
        mode: ThemeMode.dark,
        affiches: true,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'cpt_tres_tresorerie_1440_page_entiere_sombre_affiches')}',
      );
    });

    // La Reserve sous deux politiques (la demonstration Direction, propriete
    // de CPT-DIR, est encore neutre) : la page seule, ports de test.
    for (final (String nom, FaussePolitique politique) cas
        in <(String, FaussePolitique)>[
          (
            'mois',
            FaussePolitique(
              politique: politiqueMois(3),
              indic: indicateursMois(3),
            ),
          ),
          (
            'fixe_1000000',
            FaussePolitique(
              politique: politiqueFixe(cible: usd(1000000), auto: usd(1000000)),
              indic: indicateursFixes(objectif: usd(1000000)),
            ),
          ),
        ]) {
      testWidgets('1440 page seule, Reserve ${cas.$1}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 1700), 1);
        await tester.pumpWidget(
          hoteCapture(
            const TresoreriePage(),
            surcharges: surchargesTresorerie(
              tresorerie: const TresorerieDemo(),
              politique: cas.$2,
              montantsAffiches: true,
            ),
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'cpt_tres_reserve_${cas.$1}_1440_affiches')}',
        );
      });
    }
  });
}
