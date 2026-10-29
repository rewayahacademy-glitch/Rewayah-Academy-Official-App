// CORAN-320-FOND-1 : captures avant / apres de l'habillage du Mushaf (route
// reelle `/eleve/coran`, mise en page sans lignes : en-tete, pagination,
// attribution) : 320 x1 et x2, 390 x2, 1440 x1, clair et sombre, et le RTL a
// 320 x2. Les memes captures sont prises sur l'etat d'avant (dossier `avant`)
// et sur celui d'apres (dossier `apres`).
//
// Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';

import '../features/accueil_adulte/support_accueil_adulte_route.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

void main() {
  late CorpusReference reference;
  group('Capture : CORAN-320-FOND-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });
    setUp(masquerRubanDebug);

    final List<(String, Size, double, ThemeMode, TextDirection)> cas =
        <(String, Size, double, ThemeMode, TextDirection)>[
          for (final ThemeMode theme in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) ...<(String, Size, double, ThemeMode, TextDirection)>[
            ('320_x1', const Size(320, 568), 1, theme, TextDirection.ltr),
            ('320_x2', const Size(320, 568), 2, theme, TextDirection.ltr),
            ('390_x2', const Size(390, 844), 2, theme, TextDirection.ltr),
            ('1440_x1', const Size(1440, 900), 1, theme, TextDirection.ltr),
          ],
          (
            '320_x2_rtl',
            const Size(320, 568),
            2,
            ThemeMode.light,
            TextDirection.rtl,
          ),
        ];

    for (final ModeRenduCoran mode in ModeRenduCoran.values) {
      for (final (
            String nom,
            Size taille,
            double echelle,
            ThemeMode theme,
            TextDirection sens,
          )
          in cas) {
        final String fichier =
            '${mode.name}_${nom}_${theme == ThemeMode.dark ? 'sombre' : 'clair'}';
        testWidgets(fichier, (WidgetTester tester) async {
          await monterAccueilAdulteReel(
            tester,
            taille: taille,
            echelle: echelle,
            direction: sens,
            theme: theme,
            surcharges: <Override>[
              ...surchargesAccueilAdulte(accueil: Valeur(accueilDemo())),
              portCorpusCoranProvider.overrideWithValue(
                FauxCorpusCoran(reference),
              ),
              portLayoutMushafProvider.overrideWithValue(
                const LayoutLignesIndisponible(),
              ),
              portNavigationCoranProvider.overrideWithValue(
                FauxNavigationCoran(),
              ),
            ],
            depart: Routes.eleve,
          );
          await tester.tap(
            find
                .descendant(
                  of: find.byType(NavShell),
                  matching: find.text(t.nav.eleve.apprendre),
                )
                .last,
          );
          await stabiliser(tester);
          ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
              .read(lectureCoranProvider.notifier)
              .changerMode(mode);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, fichier)}');
        });
      }
    }
  });
}
