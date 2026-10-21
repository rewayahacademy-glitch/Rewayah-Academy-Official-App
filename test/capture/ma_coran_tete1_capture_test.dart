// Captures de recette MA-CORAN-TETE-1 : l'en-tete du lecteur du Coran en Mode
// Accessibilite (« Al-Faatiha . Page 1 sur 604 ») sur une ligne, en entier,
// a texte x2 (390 et 320), clair et sombre ; plus 390 et 1440 a texte x1.
// Corpus de reference des tests, rendu du Coran intouche.
//
// Saute sans CAPTURE_DIR. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

void main() {
  group('Capture MA-CORAN-TETE-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final bool grande in <bool>[false, true]) {
        for (final (String nom, Size taille, double echelle) cas
            in <(String, Size, double)>[
              ('390x2', const Size(390, 844), 2),
              ('320x2', const Size(320, 640), 2),
              ('390', const Size(390, 844), 1),
              ('1440', const Size(1440, 900), 1),
            ]) {
          final String fichier =
              'ma_coran_tete1_${cas.$1}_${theme.name}'
              '${grande ? '_grand_texte' : ''}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, cas.$2, 1);
            await tester.pumpWidget(
              hoteCapture(
                EcranAccessibiliteDemo(
                  eleve: EleveDemoAccessibilite.mariam,
                  destinationInitiale: EcranAccessibiliteDemo.indexCoran,
                  surchargesCoran: <Override>[
                    portCorpusCoranProvider.overrideWithValue(
                      FauxCorpusCoran(reference),
                    ),
                    portLayoutMushafProvider.overrideWithValue(
                      const LayoutLignesIndisponible(),
                    ),
                    portNavigationCoranProvider.overrideWithValue(
                      FauxNavigationCoran(
                        personnelle: const PositionLecture(
                          page: 1,
                          sourate: 1,
                          verset: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                themeMode: theme,
                echelleTexte: cas.$3,
                interfaceMode: InterfaceMode.enfant,
              ),
            );
            await stabiliser(tester);
            ProviderScope.containerOf(
              tester.element(find.byType(EcranAccessibiliteDemo)),
            ).read(preferencesLocalesProvider.notifier).lectureGrande(grande);
            await tester.pump();
            await tester.tap(
              find.byKey(const ValueKey<String>('coran-ma-principale')),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
