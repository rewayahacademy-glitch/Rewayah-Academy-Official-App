// CORAN-320-1 : captures de la page Coran (route reelle `/eleve/coran`, la
// vraie `MushafPage` sur le corpus de reference des tests, aucun serveur),
// avant et apres le resserrement de l'en-tete, des mentions et de la
// pagination a texte agrandi.
// - prefixe `avant_` : lance sur le code d'avant (tete 6e2c91c4) avec
//   CAPTURE_PREFIXE=avant ; prefixe `apres_` (defaut) sur le code d'apres.
// - formats : 320 x 568 et 390 x 844 a texte x2 (clair, sombre, RTL),
//   1440 x 900 a texte x1 (clair et sombre) ; plus, apres, le choix du rendu
//   deplie a 320 x 568 x2.
// Saute sans CAPTURE_DIR (voir LISEZ-MOI.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';

import '../features/accueil_adulte/support_accueil_adulte_route.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

/// `avant` ou `apres` : le prefixe des fichiers.
final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

/// La cle du bouton d'options, ecrite en clair pour que le script compile
/// aussi sur le code d'avant (ou elle n'existe pas).
const Key _options = ValueKey<String>('mushaf-options');

void main() {
  group('Capture : CORAN-320-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    // nom : (taille logique, echelle du texte, theme, sens, options depliees)
    final Map<String, (Size, double, ThemeMode, TextDirection, bool)> formats =
        <String, (Size, double, ThemeMode, TextDirection, bool)>{
          '320x568_x2_clair': (
            const Size(320, 568),
            2,
            ThemeMode.light,
            TextDirection.ltr,
            false,
          ),
          '320x568_x2_sombre': (
            const Size(320, 568),
            2,
            ThemeMode.dark,
            TextDirection.ltr,
            false,
          ),
          '320x568_x2_rtl': (
            const Size(320, 568),
            2,
            ThemeMode.light,
            TextDirection.rtl,
            false,
          ),
          '390x844_x2_clair': (
            const Size(390, 844),
            2,
            ThemeMode.light,
            TextDirection.ltr,
            false,
          ),
          '390x844_x2_sombre_rtl': (
            const Size(390, 844),
            2,
            ThemeMode.dark,
            TextDirection.rtl,
            false,
          ),
          '1440_clair': (
            const Size(1440, 900),
            1,
            ThemeMode.light,
            TextDirection.ltr,
            false,
          ),
          '1440_sombre': (
            const Size(1440, 900),
            1,
            ThemeMode.dark,
            TextDirection.ltr,
            false,
          ),
          '320x568_x2_options': (
            const Size(320, 568),
            2,
            ThemeMode.light,
            TextDirection.ltr,
            true,
          ),
        };

    for (final MapEntry<String, (Size, double, ThemeMode, TextDirection, bool)>
        f
        in formats.entries) {
      final (
        Size taille,
        double echelle,
        ThemeMode theme,
        TextDirection sens,
        bool options,
      ) = f.value;

      testWidgets(f.key, (WidgetTester tester) async {
        await monterAccueilAdulteReel(
          tester,
          taille: taille,
          echelle: echelle,
          theme: theme,
          direction: sens,
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
                matching: find.text(t.nav.eleve.coran),
              )
              .last,
        );
        await stabiliser(tester);
        expect(find.byType(MushafPage), findsOneWidget);
        if (options) {
          if (find.byKey(_options).evaluate().isEmpty) {
            return; // Code d'avant : pas de bouton d'options.
          }
          await tester.tap(find.byKey(_options));
          await stabiliser(tester);
        }
        // Le debordement du code d'avant (320 x 568 x2) est le constat : il
        // ne doit pas empecher la capture.
        tester.takeException();
        await capturer(tester, '${_prefixe}_coran_${f.key}');
      });
    }
  });
}
