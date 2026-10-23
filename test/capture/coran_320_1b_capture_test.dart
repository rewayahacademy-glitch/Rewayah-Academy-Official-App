// CORAN-320-1b : captures de la page Coran (route reelle `/eleve/coran`, la
// vraie `MushafPage` sur le corpus de reference des tests, aucun serveur),
// avant et apres les reserves de CORAN-320-1 : commandes de la lecture
// agrandie sur une rangee, etat vide du focus, seuil a 130 % exactement,
// juz dans l'en-tete compact, position « 1 / 604 » en arabe.
// - prefixe `avant_` : lance sur le code d'avant (tete 5a52ff30) avec
//   CAPTURE_PREFIXE=avant ; prefixe `apres_` (defaut) sur le code d'apres.
// - modes : lecture agrandie et focus a 320 x 568 (x2 clair, sombre, RTL ;
//   x1,3), 390 x 844 x2 (clair, sombre RTL), 1440 x 900 x1 (clair, sombre) ;
//   page du mushaf a 320 x 568 x1,3 et x2 RTL ; plus, apres, le panneau
//   « Mode de lecture » deplie en lecture agrandie a 320 x 568 x2.
// Saute sans CAPTURE_DIR (voir LISEZ-MOI.md).

import 'dart:io';

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

/// `avant` ou `apres` : le prefixe des fichiers.
final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

/// La cle du bouton d'options, ecrite en clair.
const Key _options = ValueKey<String>('mushaf-options');

typedef _Format = (
  ModeRenduCoran,
  Size,
  double,
  ThemeMode,
  TextDirection,
  bool,
);

void main() {
  group('Capture : CORAN-320-1b', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    const Size petit = Size(320, 568);
    const Size moyen = Size(390, 844);
    const Size large = Size(1440, 900);
    final Map<String, _Format> formats = <String, _Format>{
      for (final (String nom, ModeRenduCoran mode) m
          in <(String, ModeRenduCoran)>[
            ('verset', ModeRenduCoran.versetAgrandi),
            ('focus', ModeRenduCoran.focus),
          ]) ...<String, _Format>{
        '${m.$1}_320x568_x2_clair': (
          m.$2,
          petit,
          2,
          ThemeMode.light,
          TextDirection.ltr,
          false,
        ),
        '${m.$1}_320x568_x2_sombre': (
          m.$2,
          petit,
          2,
          ThemeMode.dark,
          TextDirection.ltr,
          false,
        ),
        '${m.$1}_320x568_x2_rtl': (
          m.$2,
          petit,
          2,
          ThemeMode.light,
          TextDirection.rtl,
          false,
        ),
        '${m.$1}_320x568_x1.3_clair': (
          m.$2,
          petit,
          1.3,
          ThemeMode.light,
          TextDirection.ltr,
          false,
        ),
        '${m.$1}_390x844_x2_clair': (
          m.$2,
          moyen,
          2,
          ThemeMode.light,
          TextDirection.ltr,
          false,
        ),
        '${m.$1}_390x844_x2_sombre_rtl': (
          m.$2,
          moyen,
          2,
          ThemeMode.dark,
          TextDirection.rtl,
          false,
        ),
        '${m.$1}_1440_clair': (
          m.$2,
          large,
          1,
          ThemeMode.light,
          TextDirection.ltr,
          false,
        ),
        '${m.$1}_1440_sombre': (
          m.$2,
          large,
          1,
          ThemeMode.dark,
          TextDirection.ltr,
          false,
        ),
      },
      'mushaf_320x568_x1.3_clair': (
        ModeRenduCoran.mushaf,
        petit,
        1.3,
        ThemeMode.light,
        TextDirection.ltr,
        false,
      ),
      'mushaf_320x568_x2_rtl': (
        ModeRenduCoran.mushaf,
        petit,
        2,
        ThemeMode.light,
        TextDirection.rtl,
        false,
      ),
      'verset_320x568_x2_options': (
        ModeRenduCoran.versetAgrandi,
        petit,
        2,
        ThemeMode.light,
        TextDirection.ltr,
        true,
      ),
    };

    for (final MapEntry<String, _Format> f in formats.entries) {
      final (
        ModeRenduCoran mode,
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
        ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
            .read(lectureCoranProvider.notifier)
            .changerMode(mode);
        await stabiliser(tester);
        if (options) {
          await tester.tap(find.byKey(_options));
          await stabiliser(tester);
        }
        // Les debordements du code d'avant sont le constat : ils ne doivent
        // pas empecher la capture.
        tester.takeException();
        await capturer(tester, '${_prefixe}_coran_${f.key}');
      });
    }
  });
}
