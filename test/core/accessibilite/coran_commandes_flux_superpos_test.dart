// SUPERPOS-1, reprise du relecteur : les commandes du lecteur du Coran en
// Mode Accessibilite (`CommandesMasquables`, MA-CMD-1) etaient posees
// par-dessus le bas du Mushaf. Au toucher, elles se ferment au bout de
// quelques secondes (MA-CMD-1 garde) ; mais avec un lecteur d'ecran ou au
// clavier, elles restent TOUJOURS visibles, et recouvraient donc en
// permanence le bas du texte. Decide par delegation le 05/10 : dans ces cas,
// elles passent sous le Mushaf, dans le flux. Contre-epreuve faite : sur
// l'ancien code, le bas du contenu passe sous les commandes.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';

const Key _principale = ValueKey<String>('coran-ma-principale');

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  Future<void> poser(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> ouvrirLecteur(WidgetTester tester, Size vue) async {
    tester.view.physicalSize = vue;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: EcranAccessibiliteDemo(
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
                    personnelle: PositionLecture(
                      page: reference.pages.first.numero,
                      sourate: 1,
                      verset: 1,
                      zoom: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await poser(tester);
    await tester.tap(find.byKey(_principale));
    await poser(tester);
  }

  Rect contenu(WidgetTester tester) {
    final Finder page = find.byType(VuePageMushaf);
    return tester.getRect(
      page.evaluate().isNotEmpty ? page : find.byType(VueVersetAgrandi),
    );
  }

  Rect commandes(WidgetTester tester) =>
      tester.getRect(find.byKey(CommandesMasquables.commandesKey));

  for (final Size vue in <Size>[const Size(320, 640), const Size(390, 844)]) {
    testWidgets('${vue.width.toInt()} x2, lecteur d\'ecran : les commandes '
        'sous le Mushaf, jamais par-dessus', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await ouvrirLecteur(tester, vue);
      expect(tester.takeException(), isNull);
      final Rect c = contenu(tester);
      final Rect k = commandes(tester);
      expect(
        c.bottom,
        lessThanOrEqualTo(k.top + 0.5),
        reason: 'contenu $c, commandes $k',
      );
      // Toujours visibles : rien ne les ferme.
      await tester.pump(CommandesMasquables.delaiParDefaut);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(CommandesMasquables.commandesKey), findsOneWidget);
      expect(contenu(tester).bottom, lessThanOrEqualTo(k.top + 0.5));
    });
  }

  testWidgets('390 x2, clavier : les commandes sous le Mushaf', (
    WidgetTester tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await ouvrirLecteur(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    final Rect c = contenu(tester);
    final Rect k = commandes(tester);
    expect(
      c.bottom,
      lessThanOrEqualTo(k.top + 0.5),
      reason: 'contenu $c, commandes $k',
    );
  });

  testWidgets('390 x2, au toucher : MA-CMD-1 garde, les commandes passent '
      'par-dessus puis se ferment', (WidgetTester tester) async {
    await ouvrirLecteur(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    // Le contenu garde tout le lecteur ; les commandes, posees dessus, se
    // ferment au bout du delai.
    expect(contenu(tester).bottom, greaterThan(commandes(tester).top));
    double opacite() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(CommandesMasquables.commandesKey),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(opacite(), 1);
    await tester.pump(CommandesMasquables.delaiParDefaut);
    await tester.pump(const Duration(seconds: 1));
    expect(opacite(), 0);
  });
}
