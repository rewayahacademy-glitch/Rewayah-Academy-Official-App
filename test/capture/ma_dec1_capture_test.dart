// Captures de recette MA-DEC-1 : decisions A3, A5 et A8 du 27/09 en Mode
// Accessibilite. Accueil (salutation « Assalamou alaykoum », A3 = c), Ma
// classe (sans la pastille des places, A5 = a), entree du Coran (libelles
// existants « Reprendre ta lecture » / « Reprendre votre lecture », A8 = a),
// pour Mariam (mineure) et Idriss (adulte, entree du Coran). Tailles : 390 et
// 1440 a texte x1, 390 et 320 a texte x2 ; clair et sombre.
//
// Saute sans CAPTURE_DIR. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

void main() {
  group('Capture MA-DEC-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    List<Override> corpus() => <Override>[
      portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
      portLayoutMushafProvider.overrideWithValue(
        const LayoutLignesIndisponible(),
      ),
      portNavigationCoranProvider.overrideWithValue(
        FauxNavigationCoran(
          personnelle: const PositionLecture(page: 6, sourate: 3, verset: 1),
        ),
      ),
    ];

    final List<(String, EleveDemoAccessibilite, int)> ecrans =
        <(String, EleveDemoAccessibilite, int)>[
          (
            'accueil_mariam',
            EleveDemoAccessibilite.mariam,
            EcranAccessibiliteDemo.indexAccueil,
          ),
          (
            'ma_classe_mariam',
            EleveDemoAccessibilite.mariam,
            EcranAccessibiliteDemo.indexMaClasse,
          ),
          (
            'coran_mariam',
            EleveDemoAccessibilite.mariam,
            EcranAccessibiliteDemo.indexCoran,
          ),
          (
            'coran_idriss',
            EleveDemoAccessibilite.idriss,
            EcranAccessibiliteDemo.indexCoran,
          ),
        ];

    for (final (String nom, EleveDemoAccessibilite eleve, int index)
        in ecrans) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String taille, Size vue, double echelle) cas
            in <(String, Size, double)>[
              ('390', const Size(390, 844), 1),
              ('1440', const Size(1440, 900), 1),
              ('390x2', const Size(390, 844), 2),
              ('320x2', const Size(320, 640), 2),
            ]) {
          final String fichier = 'ma_dec1_${nom}_${cas.$1}_${theme.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, 1);
            await tester.pumpWidget(
              hoteCapture(
                EcranAccessibiliteDemo(
                  eleve: eleve,
                  destinationInitiale: index,
                  surchargesCoran: corpus(),
                ),
                themeMode: theme,
                echelleTexte: cas.$3,
                interfaceMode: InterfaceMode.enfant,
              ),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
