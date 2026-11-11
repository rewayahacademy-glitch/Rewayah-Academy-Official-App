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
}
