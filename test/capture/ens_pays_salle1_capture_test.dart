// Captures de recette ENS-PAYS-SALLE-1 (decision Q-4 = b du 05/10) : l'en-tete
// de la classe en direct n'affiche plus le pays de l'enseignant (ni son
// drapeau), avec et sans photo, a 390 et 320 texte x2, clair et sombre.
// Saute sans CAPTURE_DIR. Nommage : enspayssalle1_<ecran>_<largeur>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';

import '../features/ens_pays1/support_ens_pays1.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 1, '390'),
  (Size(320, 700), 2, '320x2'),
];

void main() {
  group('Capture : ENS-PAYS-SALLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final EcranPays e in ecransClasseLive().where(
      (EcranPays e) => e.role == 'tuteur',
    )) {
      for (final (Size cadre, double echelle, String nom) in _cadres) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'enspayssalle1_${e.nom}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, cadre, 1);
            await tester.pumpWidget(hotePays(e, theme: mode, echelle: echelle));
            await stabiliser(tester);
            tester.takeException();
            expect(find.byType(PaysEnseignant), findsNothing);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
