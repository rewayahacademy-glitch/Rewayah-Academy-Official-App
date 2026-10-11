// BOUTON-ICONE-1 : captures du lecteur du Coran en Mode Accessibilite
// (`LecteurCoranAccessibilite`, corpus de reference des tests, aucun
// serveur), avant et apres le remplacement de `_BoutonIcone` recompose par
// le composant partage `BoutonIcone` (formes `disque` et `nue`, cible du
// mode). Le rendu doit etre identique, pixel a pixel.
// - prefixe `avant_` : lance sur le code d'avant (0d0eaa25) avec
//   CAPTURE_PREFIXE=avant ; prefixe `apres_` (defaut) sur le code d'apres.
// - interface standard (cible 48) et guidee (cible 72), a 390 x 844 texte x1
//   et 320 x 568 texte x2, clair ; plus 390 sombre RTL dans chaque mode.
// Saute sans CAPTURE_DIR (voir LISEZ-MOI.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/features/accueil_eleve/coran_accessibilite.dart';

import '../teaching_core/c/faux/faux_corpus_coran.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

/// `avant` ou `apres` : le prefixe des fichiers.
final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

typedef _Format = (InterfaceMode, Size, double, ThemeMode, TextDirection);

void main() {
  group('Capture : BOUTON-ICONE-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    const Size petit = Size(320, 568);
    const Size moyen = Size(390, 844);
    final Map<String, _Format> formats = <String, _Format>{
      for (final (String nom, InterfaceMode mode) m
          in <(String, InterfaceMode)>[
            ('standard', InterfaceMode.standard),
            ('guidee', InterfaceMode.enfant),
          ]) ...<String, _Format>{
        '${m.$1}_390x844_x1_clair': (
          m.$2,
          moyen,
          1,
          ThemeMode.light,
          TextDirection.ltr,
        ),
        '${m.$1}_320x568_x2_clair': (
          m.$2,
          petit,
          2,
          ThemeMode.light,
          TextDirection.ltr,
        ),
        '${m.$1}_390x844_x1_sombre_rtl': (
          m.$2,
          moyen,
          1,
          ThemeMode.dark,
          TextDirection.rtl,
        ),
      },
    };

    for (final MapEntry<String, _Format> f in formats.entries) {
      final (
        InterfaceMode mode,
        Size taille,
        double echelle,
        ThemeMode theme,
        TextDirection sens,
      ) = f.value;

      testWidgets(f.key, (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 2);
        // Une page du milieu : les deux fleches sont rendues.
        final int page = reference.pages[reference.pages.length ~/ 2].numero;
        await tester.pumpWidget(
          hoteCapture(
            Directionality(
              textDirection: sens,
              child: Scaffold(
                body: SafeArea(
                  child: LecteurCoranAccessibilite(onRetour: () {}),
                ),
              ),
            ),
            surcharges: <Override>[
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
            themeMode: theme,
            echelleTexte: echelle,
            interfaceMode: mode,
          ),
        );
        await stabiliser(tester);
        ProviderScope.containerOf(
            tester.element(find.byType(LecteurCoranAccessibilite)),
          ).read(lectureCoranProvider.notifier)
          ..changerMode(ModeRenduCoran.versetAgrandi)
          ..allerA(page, origine: OrigineNavigation.personnelle);
        await stabiliser(tester);
        expect(find.byTooltip(t.eleve.coran.pageSuivante), findsOneWidget);
        expect(find.byTooltip(t.eleve.coran.pagePrecedente), findsOneWidget);
        expect(find.byTooltip(t.commun.retour), findsOneWidget);
        // La capture compare un rendu : un debordement eventuel est le
        // constat, il ne doit pas l'empecher.
        tester.takeException();
        // Laisse passer le delai d'enregistrement de la position.
        await tester.pump(const Duration(seconds: 4));
        await capturer(tester, '${_prefixe}_coran_ma_${f.key}');
      });
    }
  });
}
