// EN-7c : captures du cahier avec l'echelle de performance et les faiblesses
// (N1 du directeur, 27/09) : la feuille d'un eleve preremplie, puis un niveau
// et une faiblesse choisis.
// Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode mode) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  group('Capture : EN-7c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 2600)),
      ('1440', const Size(1440, 1400)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${l}_${mode.name}';
        testWidgets('en7c_echelle_$suffixe', (WidgetTester tester) async {
          await _monter(tester, taille, mode);
          await _toucher(tester, find.text('Nour'));
          await capturer(tester, 'en7c_eleve_prerempli_$suffixe');
          await _toucher(tester, _cle('cahier-performance-acquis'));
          await _toucher(tester, _cle('cahier-faiblesse-waqf'));
          await capturer(tester, 'en7c_eleve_choisi_$suffixe');
          await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));
          await capturer(tester, 'en7c_cahier_$suffixe');
        });
      }
    }

    // EN-7c-200 (K-61) : la feuille de Nour a 200 % de texte, sur 390 et 320
    // de large, a la hauteur d'un telephone : le haut a l'ouverture, puis le
    // bas, defile jusqu'au bouton « Enregistrer pour cet eleve ».
    for (final double largeur in <double>[390, 320]) {
      final String l = '${largeur.toInt()}';
      testWidgets('en7c_feuille_texte200_$l', (WidgetTester tester) async {
        fixerVueCapture(tester, Size(largeur, 844), 1);
        await tester.pumpWidget(
          hoteCapture(
            const CoquilleEnseignantDemo(
              ecran: EcranDemoEnseignant.cahier,
              etat: EtatDemoEnseignant.nominal,
            ),
            surcharges: <Override>[
              depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            ],
            echelleTexte: 2,
          ),
        );
        await stabiliser(tester);
        await capturer(tester, 'en7c_cahier_texte200_$l');
        await _toucher(tester, find.text('Nour'));
        await capturer(tester, 'en7c_feuille_texte200_${l}_haut');
        await tester.ensureVisible(_cle('cahier-emplacement-faiblesses'));
        await stabiliser(tester);
        await capturer(tester, 'en7c_feuille_texte200_${l}_faiblesses');
        await tester.ensureVisible(
          find.text(t.enseignant.cahier.pointPhonetique),
        );
        await stabiliser(tester);
        await capturer(tester, 'en7c_feuille_texte200_${l}_presence');
        final Finder enregistrer = find.text(
          t.enseignant.cahier.ajusterValider,
        );
        await tester.ensureVisible(enregistrer);
        await stabiliser(tester);
        await capturer(tester, 'en7c_feuille_texte200_${l}_bas');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
