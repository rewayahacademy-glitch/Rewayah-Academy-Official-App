// Captures R3 de PROFILS P3 (points 1 et 2) : la Bibliotheque en tete de
// « Mes classes » de l'enseignant (demonstration, donnees synthetiques).
// 390 et 1440, clair, sombre, arabe, texte x2.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/profils-p3 \
//   flutter test test/capture/profils_p3_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';
import 'package:rewayah_academy/features/suivi_eleve/entree_bibliotheque.dart';

import '../support/demo/demo_enseignant_page.dart';
import '../support/demo/enseignant_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : PROFILS P3, Mes classes', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    final List<(String, double, ThemeMode, AppLocale, double)>
    cas = <(String, double, ThemeMode, AppLocale, double)>[
      for (final double l in const <double>[
        390,
        1440,
      ]) ...<(String, double, ThemeMode, AppLocale, double)>[
        ('mes-classes-${l.toInt()}-clair', l, ThemeMode.light, AppLocale.fr, 1),
        ('mes-classes-${l.toInt()}-sombre', l, ThemeMode.dark, AppLocale.fr, 1),
        ('mes-classes-${l.toInt()}-arabe', l, ThemeMode.light, AppLocale.ar, 1),
        (
          'mes-classes-${l.toInt()}-texte-x2',
          l,
          ThemeMode.light,
          AppLocale.fr,
          2,
        ),
      ],
    ];

    for (final (
          String nom,
          double l,
          ThemeMode mode,
          AppLocale langue,
          double e,
        )
        in cas) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, Size(l, l < 600 ? 844 : 900), 1);
        await tester.pumpWidget(
          hoteCapture(
            const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes),
            surcharges: <Override>[
              depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            ],
            themeMode: mode,
            echelleTexte: e,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(EntreeBibliothequeMaClasse.ligneKey), findsOneWidget);
        await capturerVue(tester, nom);
      });
    }
  });

  // Le Compte de l'enseignant sur PageCompte (points 3 et 4), en vue haute
  // pour montrer la page entiere jusqu'a la version.
  group(
    'Capture : PROFILS P3, Compte de l enseignant',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);

      for (final double l in const <double>[390, 1440]) {
        for (final (String v, ThemeMode mode, AppLocale langue, double e)
            in <(String, ThemeMode, AppLocale, double)>[
              ('clair', ThemeMode.light, AppLocale.fr, 1),
              ('sombre', ThemeMode.dark, AppLocale.fr, 1),
              ('arabe', ThemeMode.light, AppLocale.ar, 1),
              ('texte-x2', ThemeMode.light, AppLocale.fr, 2),
            ]) {
          final String nom = 'compte-enseignant-${l.toInt()}-$v';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
            final double h = switch ((l < 600, e > 1)) {
              (true, true) => 4200,
              (true, false) => 2300,
              (false, true) => 3400,
              (false, false) => 1900,
            };
            fixerVueCapture(tester, Size(l, h), 1);
            await tester.pumpWidget(
              hoteCapture(
                const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.profil),
                surcharges: <Override>[
                  depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
                ],
                themeMode: mode,
                echelleTexte: e,
              ),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            expect(find.byType(PageCompte), findsOneWidget);
            await capturerVue(tester, nom);
          });
        }
      }
    },
  );
}
