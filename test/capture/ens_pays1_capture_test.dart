// Captures de recette ENS-PAYS-1 : le pays de l'enseignant sur sa carte,
// pour chaque role (tuteur, eleve enfant, eleve adulte, Mode Accessibilite,
// controleur, administration), a 390, 1440 et 320 texte x2, clair et
// sombre. Vrais ecrans, donnees de demonstration ou faux services ; chaque
// vue est defilee jusqu'a la ligne du pays (`montrerPays`).
//
// Depuis ENS-DRAPEAU-1 (05/10/2026), le drapeau est une image embarquee,
// la meme sur toutes les plateformes : plus de police d'emoji a charger, plus
// de rendu « sans drapeau » a part. Les images sont decodees avant la prise
// de vue (`chargerDrapeaux`).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// enspays1_<role>_<ecran>_<largeur>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ens_pays1/support_ens_pays1.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 1, '390'),
  (Size(1440, 900), 1, '1440'),
  (Size(320, 700), 2, '320x2'),
];

void main() {
  group('Capture : ENS-PAYS-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final EcranPays e in ecransPays()) {
      for (final (Size cadre, double echelle, String nom) in _cadres) {
        // Les listes paresseuses de l'administration ne construisent aucune
        // ligne a 320 x2 sous 700 px de haut (meme surface que le test).
        final Size taille = echelle > 1 ? Size(320, e.hauteur320) : cadre;
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'enspays1_${e.nom}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(hotePays(e, theme: mode, echelle: echelle));
            await stabiliser(tester);
            if (e.toucher != null) {
              await tester.tap(find.text(e.toucher!).first);
              await stabiliser(tester);
            }
            // K-61 (verification croisee du 04/10) : la ligne du pays est
            // amenee dans la vue, au-dessus de la barre de navigation, avant
            // la prise de vue.
            await montrerPays(tester);
            await chargerDrapeaux(tester);
            tester.takeException();
            expect(
              rectangleVisibleDuPays(tester, taille),
              isNotNull,
              reason: '$fichier : ligne du pays hors de la vue',
            );
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
