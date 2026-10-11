// MUSHAF-15L : le rendu de la page du Mushaf de Medine. Chaque ligne justifiee
// sur la largeur du cadre, cadre de sourate et basmala centres, rosaces,
// surlignage, 320 px a texte x2, semantique par verset (texte Tanzil), palette
// seule, et le credit du jeu de donnees a cote de l'attribution Tanzil.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/layout_madina_15.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart'
    show VersetCorpus;
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/rosace_verset.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart'
    show FauxNavigationCoran;

Finder _ligne(int numero) => find.byKey(cleLigneMadina15(numero));

Rect _rect(WidgetTester t, Finder f) =>
    t.getRect(find.descendant(of: f, matching: find.byType(Row)).first);

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });

  group('lignes', () {
    for (final (int page, int n) in <(int, int)>[(544, 15), (1, 8), (2, 8)]) {
      testWidgets('page $page : $n lignes', (WidgetTester tester) async {
        await monterPageMadina15(
          tester,
          page: page,
          taille: const Size(390, 844),
        );
        for (int i = 1; i <= n; i++) {
          expect(_ligne(i), findsOneWidget, reason: 'page $page ligne $i');
        }
        expect(_ligne(n + 1), findsNothing);
      });
    }

    testWidgets('chaque ligne justifiee occupe toute la largeur du texte', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 293, taille: const Size(390, 844));
      // Page 293 : fin d'Al-Isra puis debut d'Al-Kahf. Les lignes de texte
      // ordinaires ont toutes la meme largeur, au pixel pres.
      final LayoutPage p = LayoutMadina15().depuis(293)!;
      final List<double> largeurs = <double>[
        for (final SectionLigne l in p.lignes)
          if (l.type == TypeLigneMushaf.texte && !l.termineLaSourate)
            _rect(tester, _ligne(l.numero)).width,
      ];
      expect(largeurs.length, greaterThan(8));
      final double reference = largeurs.reduce(
        (double a, double b) => a > b ? a : b,
      );
      for (final double w in largeurs) {
        expect(w, closeTo(reference, 0.6));
      }
      // Et le corps est le meme : meme hauteur de ligne imprimee.
      final List<double> hauteurs = <double>[
        for (final SectionLigne l in p.lignes)
          if (l.type == TypeLigneMushaf.texte && !l.termineLaSourate)
            _rect(tester, _ligne(l.numero)).height,
      ];
      for (final double h in hauteurs) {
        expect(h, closeTo(hauteurs.first, 0.6));
      }
    });

    testWidgets('cadre de sourate et basmala centres sur la page', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 2, taille: const Size(390, 844));
      final Rect cadre = tester.getRect(_ligne(1));
      final Rect basmala = tester.getRect(
        find.descendant(of: _ligne(2), matching: find.byType(Text)).first,
      );
      final Rect texte = _rect(tester, _ligne(3));
      expect(basmala.center.dx, closeTo(cadre.center.dx, 1.5));
      expect(
        tester
            .getRect(
              find
                  .descendant(
                    of: _ligne(1),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .center
            .dx,
        closeTo(cadre.center.dx, 1.5),
      );
      // La basmala est plus etroite que le cadre : elle est centree, pas etiree.
      expect(basmala.width, lessThan(texte.width));
    });

    testWidgets('une rosace a chaque fin de verset', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 1, taille: const Size(390, 844));
      // Al-Fatiha : sept versets, sept rosaces, plus le numero de page.
      expect(find.byType(RosaceVerset), findsNWidgets(8));
    });
  });

  group('surlignage et palette', () {
    testWidgets('un verset surligne prend le lavis de la palette', (
      WidgetTester tester,
    ) async {
      final LayoutMadina15 source = LayoutMadina15();
      final PageMushafVM vue = PageMushafVM.depuis(
        pageDemandee: 1,
        page: await CorpusDepuisLayout(source).page(1),
        chargementEnCours: false,
        sourates: null,
        fidelite: DisponibiliteLayout.fidele,
        layout: source.depuis(1),
      );
      Future<int> compter(Set<String> surlignes) async {
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: SingleChildScrollView(
                child: PageMadina15(
                  vue: vue,
                  largeur: 358,
                  versetsSurlignes: surlignes,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(PageMadina15)),
        );
        return tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where(
              (DecoratedBox d) =>
                  d.decoration is BoxDecoration &&
                  (d.decoration as BoxDecoration).color ==
                      palette.washAccent.background &&
                  (d.decoration as BoxDecoration).border == null,
            )
            .length;
      }

      final int sans = await compter(const <String>{});
      final int avec = await compter(const <String>{'1:2'});
      // Le verset 1:2 porte quatre mots : quatre mots surlignes, aucun autre.
      expect(avec - sans, 4);
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('${theme.name} : le fond est la surface de l\'application', (
        WidgetTester tester,
      ) async {
        await monterPageMadina15(
          tester,
          page: 50,
          taille: const Size(390, 844),
          theme: theme,
        );
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(PageMadina15)),
        );
        // Ni parchemin ni brun : la surface de l'application, et son encre.
        final ColoredBox fond = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(PageMadina15),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(fond.color, palette.surfaceCanvas.background);
        expect(fond.color, isNot(palette.surfaceQuran.background));
        final RenderParagraph mot = tester.renderObject<RenderParagraph>(
          find.descendant(of: _ligne(5), matching: find.byType(RichText)).first,
        );
        expect(mot.text.style?.color, palette.surfaceCanvas.onBackground);
      });
    }
  });

  group('formats et accessibilite', () {
    testWidgets('320 px, texte x2 : rien ne deborde, le corps ne grossit pas', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 544, taille: const Size(320, 640));
      final double h1 = _rect(tester, _ligne(5)).height;
      await monterPageMadina15(
        tester,
        page: 544,
        taille: const Size(320, 640),
        echelleTexte: 2,
      );
      expect(tester.takeException(), isNull);
      // La page est un dessin : l'echelle de texte du systeme ne change pas
      // la taille des lignes imprimees.
      expect(_rect(tester, _ligne(5)).height, closeTo(h1, 0.6));
      expect(_rect(tester, _ligne(5)).width, lessThanOrEqualTo(320));
    });

    testWidgets('1440 : double page, rien ne deborde', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 543,
        taille: const Size(1440, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(PageMadina15), findsNWidgets(2));
    });

    testWidgets('la semantique est un noeud par verset, le texte de Tanzil', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await monterPageMadina15(tester, page: 1, taille: const Size(390, 844));
      final List<String> versets = <String>[
        for (final VersetCorpus v in (await CorpusDepuisLayout(
          LayoutMadina15(),
        ).page(1))!.versets)
          v.texte,
      ];
      expect(versets, hasLength(7));
      for (final String texte in versets) {
        expect(find.bySemanticsLabel(texte), findsOneWidget, reason: texte);
      }
      // Le texte dessine n'est pas lu en plus : aucun noeud ne repete un mot
      // de la page en dehors des versets.
      expect(find.bySemanticsLabel(RegExp('^ال')), findsNothing);
      poignee.dispose();
    });
  });

  group('source de layout et credit', () {
    test(
      'sans drapeau, la source est « indisponible » ; avec, c\'est Medine',
      () async {
        expect(Env.mushaf15LActif, isFalse);
        final ProviderContainer c = ProviderContainer();
        addTearDown(c.dispose);
        expect(
          c.read(portLayoutMushafProvider),
          isA<LayoutLignesIndisponible>(),
        );
      },
    );

    testWidgets('le credit CC-BY apparait avec la mise en page de l\'edition', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          const MushafPage(),
          surcharges: <Override>[
            ...surchargesMadina15(page: 2),
            portNavigationCoranProvider.overrideWithValue(
              FauxNavigationCoran(),
            ),
          ],
        ),
      );
      await stabiliser(tester);
      expect(find.textContaining('quran.ws (CC BY 4.0)'), findsOneWidget);
      expect(find.textContaining('Tanzil'), findsWidgets);
    });
  });
}
