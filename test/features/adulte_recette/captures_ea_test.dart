// EA-1b : squelette des captures de la vague Eleves adultes, complete en
// EA-12 (recette) pour chaque ecran et les 25 cas du doc section 18. Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Modele :
// `captures_en_test.dart`. Sortie en un sous-dossier par ecran.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 1200)),
  ('768', Size(768, 1100)),
  ('1440', Size(1440, 1000)),
];

const List<ThemeMode> _themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(ecran, themeMode: mode));
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  // -------------------------------------------------------------------
  // Coquille de l'eleve adulte (EA-1b) : 4 destinations, plus Ma famille
  // (coquille du tuteur sur le Foyer) et les variantes de Mon espace.
  // -------------------------------------------------------------------
  group('Capture EA-1b : coquille', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EcranDemoAdulte ecran in EcranDemoAdulte.values) {
      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _themes) {
          testWidgets('coquille_${ecran.name}_${l}_${mode.name}', (
            WidgetTester tester,
          ) async {
            await _capturer(
              tester,
              'ea1b/ea1b_${ecran.name}_${l}_${mode.name}',
              CoquilleAdulteDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
    for (final (String nom, CoquilleAdulteDemo ecran)
        in <(String, CoquilleAdulteDemo)>[
          (
            'adulte_seul',
            const CoquilleAdulteDemo(
              ecran: EcranDemoAdulte.monEspace,
              etat: EtatDemoAdulte.adulteSeul,
            ),
          ),
          (
            'vue_conjointe',
            const CoquilleAdulteDemo(
              ecran: EcranDemoAdulte.monEspace,
              vue: VueDemoAdulte.secondAdulte,
            ),
          ),
          (
            'titulaire_femme',
            const CoquilleAdulteDemo(
              ecran: EcranDemoAdulte.monEspace,
              genre: GenreTitulaireDemo.femme,
            ),
          ),
        ]) {
      for (final ThemeMode mode in _themes) {
        testWidgets('mon_espace_${nom}_390_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'ea1b/ea1b_mon_espace_${nom}_390_${mode.name}',
            ecran,
            const Size(390, 1200),
            mode: mode,
          );
        });
      }
    }
  });
}
