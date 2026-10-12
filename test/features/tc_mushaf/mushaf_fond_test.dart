// CORAN-320-FOND-1 (reserves de CORAN-320-1b) : l'habillage du Mushaf a 320 px
// et en texte agrandi, sans toucher au texte ni au rendu des versets.
//
// (1) la part des versets ne saute plus d'un seuil a l'autre : balayage du
//     texte de 1,0 a 2,0 par pas de 0,05 ;
// (2) au moins la moitie de la hauteur aux versets a 320 x 568, des le texte
//     de base ;
// (3) la mesure du focus est celle de la place reelle des versets ;
// (4) le reglage de taille se atteint directement, dans l'en-tete ;
// (5) `BarrePrecedentSuivant` resserree ne deborde pas a 320 x2, en RTL.

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
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_focus_classe.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, stabiliser;
import '../../support/aucun_mot_coupe.dart';
import '../../support/hote_theme.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart';

/// La part minimale de la hauteur de l'ecran donnee aux versets : la moitie.
const double _partMinimale = 0.5;

/// Le plus grand ecart de part entre deux pas de 0,05 du texte (decide par
/// delegation, CORAN-320-FOND-1) : la part ne chute jamais brutalement. Avant,
/// la rupture a 130 % faisait passer la part de 1 % a 54 %.
const double _ecartMaximalParPas = 0.04;

Type _zone(ModeRenduCoran mode) => switch (mode) {
  ModeRenduCoran.mushaf => VuePageMushaf,
  ModeRenduCoran.versetAgrandi => VueVersetAgrandi,
  ModeRenduCoran.focus => VueFocusClasse,
};

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  /// Monte la route reelle (mise en page sans lignes : l'habillage a titre,
  /// pagination et attribution) et passe dans [mode].
  Future<List<String>> monter(
    WidgetTester tester, {
    required ModeRenduCoran mode,
    required Size taille,
    required double echelle,
    TextDirection sens = TextDirection.ltr,
  }) async {
    final List<String> erreurs = <String>[];
    final void Function(FlutterErrorDetails)? avant = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) =>
        erreurs.add(d.exceptionAsString().split('\n').first);
    try {
      await monterAccueilAdulteReel(
        tester,
        taille: taille,
        echelle: echelle,
        direction: sens,
        surcharges: <Override>[
          ...surchargesAccueilAdulte(accueil: Valeur(accueilDemo())),
          portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
          portLayoutMushafProvider.overrideWithValue(
            const LayoutLignesIndisponible(),
          ),
          portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
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
      ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
          .read(lectureCoranProvider.notifier)
          .changerMode(mode);
      await stabiliser(tester);
    } finally {
      FlutterError.onError = avant;
    }
    return erreurs;
  }

  double part(WidgetTester tester, ModeRenduCoran mode, Size taille) =>
      tester.getSize(find.byType(_zone(mode))).height / taille.height;

  group('(1)(2) la part des versets est continue et tient la moitie', () {
    for (final ModeRenduCoran mode in ModeRenduCoran.values) {
      for (final Size taille in <Size>[
        const Size(320, 568),
        const Size(390, 844),
      ]) {
        testWidgets('${mode.name} ${taille.width.toInt()}x'
            '${taille.height.toInt()} : balayage du texte de 1,0 a 2,0', (
          WidgetTester tester,
        ) async {
          final List<double> parts = <double>[];
          for (int i = 0; i <= 20; i++) {
            final double echelle = 1 + i * 0.05;
            final List<String> erreurs = await monter(
              tester,
              mode: mode,
              taille: taille,
              echelle: echelle,
            );
            expect(erreurs, isEmpty, reason: 'x${echelle.toStringAsFixed(2)}');
            parts.add(part(tester, mode, taille));
          }
          debugPrint(
            'PART ${mode.name} ${taille.width.toInt()}: '
            '${parts.map((double p) => (p * 100).round()).join(' ')}',
          );
          for (int i = 1; i < parts.length; i++) {
            expect(
              (parts[i] - parts[i - 1]).abs(),
              lessThanOrEqualTo(_ecartMaximalParPas),
              reason:
                  'saut entre x${(1 + (i - 1) * 0.05).toStringAsFixed(2)} '
                  'et x${(1 + i * 0.05).toStringAsFixed(2)}',
            );
          }
          if (taille.width == 320) {
            for (final double p in parts) {
              expect(p, greaterThanOrEqualTo(_partMinimale));
            }
          }
        });
      }
    }
  });

  group('(3) focus : la mesure est celle de la place reelle des versets', () {
    for (final Size taille in <Size>[
      const Size(320, 568),
      const Size(390, 844),
    ]) {
      testWidgets('${taille.width.toInt()}x${taille.height.toInt()} x2 : '
          'aucune bande de message, la zone du focus est celle des versets', (
        WidgetTester tester,
      ) async {
        final List<String> erreurs = await monter(
          tester,
          mode: ModeRenduCoran.focus,
          taille: taille,
          echelle: 2,
        );
        expect(erreurs, isEmpty);
        // Plus de phrase d'aide : la zone du focus est la colonne des versets.
        expect(find.textContaining(t.tc.coran.focus.aucunePlage), findsNothing);
        final double zone = tester.getSize(find.byType(VueFocusClasse)).height;
        final double versets = tester
            .getSize(
              find.descendant(
                of: find.byType(VueFocusClasse),
                matching: find.byType(ColonneVersetsReflow),
              ),
            )
            .height;
        expect(versets, closeTo(zone, 0.5));
        expect(zone / taille.height, greaterThanOrEqualTo(_partMinimale));
      });
    }
  });

  group('(4) le reglage de taille est atteignable directement', () {
    for (final ModeRenduCoran mode in <ModeRenduCoran>[
      ModeRenduCoran.versetAgrandi,
      ModeRenduCoran.focus,
    ]) {
      for (final (String nom, Size taille, double echelle) cas
          in <(String, Size, double)>[
            ('320x568 x1', const Size(320, 568), 1),
            ('320x568 x2', const Size(320, 568), 2),
            ('390x844 x2', const Size(390, 844), 2),
          ]) {
        testWidgets('${mode.name} ${cas.$1} : deux boutons dans l en-tete, '
            'sans ouvrir « Mode de lecture »', (WidgetTester tester) async {
          final List<String> erreurs = await monter(
            tester,
            mode: mode,
            taille: cas.$2,
            echelle: cas.$3,
          );
          expect(erreurs, isEmpty);
          final Finder entete = find.byKey(MushafPage.enteteKey);
          expect(
            find.descendant(
              of: entete,
              matching: find.byKey(MushafPage.reduireKey),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: entete,
              matching: find.byKey(MushafPage.agrandirKey),
            ),
            findsOneWidget,
          );
          // Cibles tactiles de 48.
          expect(
            tester.getSize(find.byKey(MushafPage.agrandirKey)).shortestSide,
            greaterThanOrEqualTo(48),
          );
          double zoom() =>
              ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
                  .read(lectureCoranProvider)
                  .zoomLocal;
          final double avant = zoom();
          await tester.tap(find.byKey(MushafPage.agrandirKey));
          await tester.pump();
          expect(zoom(), closeTo(avant + 0.2, 1e-9));
          await tester.tap(find.byKey(MushafPage.reduireKey));
          await tester.pump();
          expect(zoom(), closeTo(avant, 1e-9));
          // Garde des mots coupes : aucun mot ne se coupe au milieu.
          verifierEcranSansMotCoupe(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('en page du mushaf, aucun reglage de taille', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        mode: ModeRenduCoran.mushaf,
        taille: const Size(320, 568),
        echelle: 2,
      );
      expect(find.byKey(MushafPage.reduireKey), findsNothing);
      expect(find.byKey(MushafPage.agrandirKey), findsNothing);
    });
  });

  group('(5) BarrePrecedentSuivant resserree ne deborde pas a 320 x2', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('etendue: false, ${sens.name}', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteTheme(
            Directionality(
              textDirection: sens,
              child: Align(
                child: BarrePrecedentSuivant(
                  etendue: false,
                  position: 'Page 604 sur 604',
                  positionSemantique: 'Page 604 sur 604',
                  libellePrecedent: 'Page précédente',
                  libelleSuivant: 'Page suivante',
                  onPrecedent: () {},
                  onSuivant: () {},
                ),
              ),
            ),
            echelleTexte: 2,
            defilant: false,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(BarrePrecedentSuivant)).width,
          lessThanOrEqualTo(320),
        );
      });
    }
  });
}
