import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import 'faux/faux_corpus_coran.dart';
import 'goldens/corpus_reference.dart';
import 'support/hote_tc_c.dart';

/// Les gabarits mesures, pas devines.
const Size _telephone = Size(390, 844);
const Size _petitTelephone = Size(320, 640);
const Size _desktop = Size(1400, 900);

void main() {
  late CorpusReference reference;

  setUpAll(() => reference = CorpusReference.charger());

  Widget ecran({
    PortLayoutMushaf layout = const LayoutLignesIndisponible(),
  }) => hoteCoran(
    const MushafPage(),
    surcharges: <Override>[
      portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
      portLayoutMushafProvider.overrideWithValue(layout),
      portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
    ],
  );

  /// Laisse les `FutureProvider` se resoudre sans `pumpAndSettle`, que
  /// l'indicateur de chargement ferait tourner sans fin.
  Future<void> poser(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump();
    }
  }

  group('le rendu mushaf', () {
    testWidgets('le telephone montre une page a la fois', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      expect(find.byType(CadrePageMushaf), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un ecran large montre une ouverture de deux pages', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _desktop);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final Iterable<CadrePageMushaf> cadres = tester
          .widgetList<CadrePageMushaf>(find.byType(CadrePageMushaf));

      expect(cadres.length, 2);
      expect(cadres.first.vue.numero, 1);
      expect(cadres.first.vue.cote, CoteDePage.droite);
      expect(cadres.last.vue.numero, 2);
      expect(cadres.last.vue.cote, CoteDePage.gauche);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la composition approximee est ecrite a l ecran', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      expect(find.text(t.tc.coran.fidelite.approchee), findsOneWidget);
      expect(find.textContaining("l'édition"), findsWidgets);
    });

    testWidgets('avec de vraies lignes, la notice change de discours', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(
        ecran(
          layout: const FauxLayoutFidele(<int, List<SectionLigne>>{
            1: <SectionLigne>[
              SectionLigne(
                numero: 1,
                centree: true,
                segments: <SegmentVersetLigne>[
                  SegmentVersetLigne(
                    sourate: 1,
                    ayah: 1,
                    texte: 'texte 1:1',
                    debuteLAyah: true,
                    termineLAyah: true,
                  ),
                ],
              ),
            ],
          }),
        ),
      );
      await poser(tester);

      expect(find.text(t.tc.coran.fidelite.fidele), findsOneWidget);
      expect(find.text(t.tc.coran.fidelite.approchee), findsNothing);
      expect(find.byType(LigneComposee), findsOneWidget);
    });

    testWidgets('le mode mushaf ne propose pas le zoom, il renvoie', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      expect(
        find.text(t.tc.coran.zoom.renvoiLectureAgrandie),
        findsOneWidget,
      );
    });
  });

  group('le rendu verset agrandi', () {
    testWidgets('il ne deborde pas au zoom maximal sur un petit ecran', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _petitTelephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      conteneur
          .read(lectureCoranProvider.notifier)
          .changerMode(ModeRenduCoran.versetAgrandi);
      conteneur.read(lectureCoranProvider.notifier).definirZoom(4);
      await poser(tester);

      expect(find.byType(ColonneVersetsReflow), findsOneWidget);
      expect(find.byType(BlocVerset), findsWidgets);
      // Un debordement de rendu leve une `FlutterError` que le harnais capture.
      expect(tester.takeException(), isNull);
    });

    testWidgets('le zoom bride se dit, il ne se subit pas', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _petitTelephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      conteneur
          .read(lectureCoranProvider.notifier)
          .changerMode(ModeRenduCoran.versetAgrandi);
      conteneur.read(lectureCoranProvider.notifier).definirZoom(4);
      await poser(tester);

      expect(find.textContaining(t.tc.coran.zoom.bride), findsOneWidget);
    });

    testWidgets('il rend les versets de la page ouverte', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      conteneur
          .read(lectureCoranProvider.notifier)
          .changerMode(ModeRenduCoran.versetAgrandi);
      await poser(tester);

      // Page 1 du golden : Al-Faatiha, sept versets.
      expect(find.byType(BlocVerset), findsNWidgets(7));
    });
  });

  group('le rendu focus', () {
    testWidgets('sans plage designee, il le dit et centre la page', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      conteneur
          .read(lectureCoranProvider.notifier)
          .changerMode(ModeRenduCoran.focus);
      await poser(tester);

      expect(
        find.textContaining(t.tc.coran.focus.aucunePlage),
        findsOneWidget,
      );
      expect(find.byType(ColonneVersetsReflow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('le zoom local ne quitte pas l appareil', () {
    testWidgets('une page tournee par la classe ne remet pas le zoom a un', (
      WidgetTester tester,
    ) async {
      await poserFenetre(tester, _telephone);
      await tester.pumpWidget(ecran());
      await poser(tester);

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      conteneur.read(lectureCoranProvider.notifier).definirZoom(2.5);
      conteneur
          .read(lectureCoranProvider.notifier)
          .allerA(3, origine: OrigineNavigation.groupe);
      await poser(tester);

      expect(conteneur.read(lectureCoranProvider).zoomLocal, 2.5);
      expect(conteneur.read(lectureCoranProvider).page, 3);
    });
  });
}
