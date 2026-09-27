// MA-1b : squelette des captures de la vague Mode Accessibilite, complete de
// MA-2 a MA-12 (recette) pour chaque ecran et ses cas (avant, pendant,
// apres ; mineur et adulte ; texte a 200 % ; animations reduites). Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Modele :
// `captures_en_test.dart`. Sortie en un sous-dossier par ecran.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../capture/outil_capture.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 1900)),
  ('768', Size(768, 1500)),
  ('1440', Size(1440, 1100)),
];

const List<ThemeMode> _themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// Monte [ecran] en Mode Accessibilite et ecrit son PNG ; [echelle] simule le
/// texte agrandi, [reduit] les animations reduites.
Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool reduit = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      reduit
          ? Builder(
              builder: (BuildContext context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: ecran,
              ),
            )
          : ecran,
      themeMode: mode,
      echelleTexte: echelle,
      interfaceMode: InterfaceMode.enfant,
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  // -------------------------------------------------------------------
  // Socle (MA-1b) : la liste de la demonstration et l'ecran de Mariam.
  // -------------------------------------------------------------------
  group('Capture MA-1b : socle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('liste_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma1b/ma1b_liste_${l}_${mode.name}',
            const DemoAccessibilitePage(),
            taille,
            mode: mode,
          );
        });
        testWidgets('mariam_avant_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'ma1b/ma1b_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('mariam_avant_390_light_texte200_reduit', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ma1b/ma1b_mariam_avant_390_light_texte200_reduit',
        const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
        const Size(390, 2600),
        echelle: 2,
        reduit: true,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-2 : la navigation a 4 destinations (barre, rail, barre laterale).
  // -------------------------------------------------------------------
  group('Capture MA-2 : navigation', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in const <(String, Size)>[
      ('390', Size(390, 844)),
      ('768', Size(768, 1024)),
      ('1440', Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in _themes) {
        testWidgets('nav_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma2/ma2_nav_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('nav_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma2/ma2_nav_mariam_avant_390_light_texte200',
        const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
        const Size(390, 844),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-3 : l'Accueil de l'eleve (Mariam avant, Idriss apres, 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-3 : Accueil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('accueil_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma3/ma3_accueil_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('accueil_idriss_apres_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma3/ma3_accueil_idriss_apres_390_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          moment: MomentDemoAccessibilite.apres,
          destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
        ),
        const Size(390, 1900),
      );
    });
    testWidgets('accueil_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma3/ma3_accueil_mariam_avant_390_light_texte200',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
        ),
        const Size(390, 3400),
        echelle: 2,
      );
    });
  });
}
