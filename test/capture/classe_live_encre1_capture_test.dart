// Captures de recette CLASSE-LIVE-ENCRE-1 : l'ecran d'attente « seul dans la
// salle » de la classe en direct, a 390, 1440 et 320 texte x2, clair et sombre.
// Saute sans CAPTURE_DIR. Nommage : classelive_encre1_<largeur>_<mode>.png.

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
  group('Capture : CLASSE-LIVE-ENCRE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size cadre, double echelle, String nom) in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'classelive_encre1_${nom}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          fixerVueCapture(tester, cadre, 1);
          await tester.pumpWidget(
            hotePays(classeLiveTuteur(), theme: mode, echelle: echelle),
          );
          await stabiliser(tester);
          tester.takeException();
          debugPrint('PNG ${await capturer(tester, fichier)}');
        });
      }
    }
  });
}
