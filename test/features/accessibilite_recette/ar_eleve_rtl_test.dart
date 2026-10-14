// AR-ELEVE-1 : les ecrans de l'eleve en arabe, de droite a gauche.
//
// L'accueil, Ma classe et l'entree en salle de la demonstration (Mariam,
// mineure ; Idriss, adulte) se montent en arabe sans debordement ni
// exception, au telephone (390, et 320 a texte x2) comme au bureau ; le sens
// est RTL et les libelles sont ceux de l'arabe. Avec CAPTURE_DIR, les memes
// ecrans sont captures :
//   CAPTURE_DIR=docs/current/captures/AR-ELEVE-1 flutter test \
//     test/features/accessibilite_recette/ar_eleve_rtl_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../capture/outil_capture.dart';

final Map<String, Widget> _ecrans = <String, Widget>{
  'accueil_mariam': const EcranAccessibiliteDemo(
    eleve: EleveDemoAccessibilite.mariam,
    destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
  ),
  'classe_idriss': const EcranAccessibiliteDemo(
    eleve: EleveDemoAccessibilite.idriss,
  ),
  'salle_mariam': const EcranAccessibiliteDemo(
    eleve: EleveDemoAccessibilite.mariam,
    moment: MomentDemoAccessibilite.fenetre,
    etapeInitiale: EtapeDemoAccessibilite.salle,
  ),
};

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

void main() {
  setUpAll(() async {
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _ecrans.forEach((String nom, Widget ecran) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      final String fichier = 'ar_eleve_${nom}_$cas';
      testWidgets(fichier, (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            ecran,
            themeMode: mode,
            echelleTexte: texte,
            interfaceMode: InterfaceMode.enfant,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byWidget(ecran))),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, fichier)}');
        }
      });
    }
  });

  testWidgets('Ma classe en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    final String titreFr = t.accessibilite.maClasse.titre;
    await LocaleSettings.setLocale(AppLocale.ar);
    fixerVueCapture(tester, const Size(390, 844), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        _ecrans['classe_idriss']!,
        interfaceMode: InterfaceMode.enfant,
      ),
    );
    await stabiliser(tester);
    expect(find.text(t.accessibilite.maClasse.titre), findsWidgets);
    expect(find.text(titreFr), findsNothing);
  });
}
