// MUSHAF-15L : le cadre ornemental (propositions A, B, C), le fond de la page,
// la page pleine hauteur et les contrastes.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/ornement_traces.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/tc_mushaf/cadre_ornement.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';
import '../../theme/support/contraste.dart';

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  setUp(masquerRubanDebug);
  tearDown(() => StyleCadreMushaf.surcharge = null);

  group('l\'ornement vient des fichiers du directeur', () {
    String lire(String dossier, String nom) =>
        File('assets/brand/logo/$dossier/$nom').readAsStringSync();

    test('les traces generes sont ceux des SVG, mot pour mot', () {
      final String plein = lire('violet', 'ornement-plein.svg');
      expect(plein, contains('d="${ornementPlein.trace}"'));
      final String contour = lire('violet', 'ornement-contour.svg');
      expect(contour, contains('d="${ornementContour.trace}"'));
      expect(contour, contains('d="${ornementContour.masque}"'));
      expect(ornementPlein.masque, isNull);
      expect(
        ornementPlein.source,
        'assets/brand/logo/violet/ornement-plein.svg',
      );
    });

    test('le generateur est a jour', () {
      final ProcessResult r = Process.runSync('dart', <String>[
        'run',
        'tool/generer_ornement.dart',
        '--verifier',
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    });

    test('aucun logo, symbole ni signature dans le cadre', () {
      final String source = File('lib/features/tc_mushaf/cadre_ornement.dart')
          .readAsStringSync();
      expect(source, isNot(contains('logoHorizontal')));
      expect(source, isNot(contains('logoVertical')));
      expect(source, isNot(contains('logoSymbole')));
      expect(source, isNot(contains('BrandLogo')));
    });

    test('aucune couleur ecrite dans le rendu du Mushaf', () {
      for (final String f in <String>[
        'lib/features/tc_mushaf/cadre_ornement.dart',
        'lib/features/tc_mushaf/page_madina_15.dart',
      ]) {
        final String source = File(f).readAsStringSync();
        expect(source, isNot(contains('Color(0x')), reason: f);
        expect(source, isNot(contains('Colors.')), reason: f);
        expect(source, isNot(contains('LinearGradient')), reason: f);
        expect(source, isNot(contains('BoxShadow')), reason: f);
      }
    });
  });

  group('le drapeau choisit le cadre', () {
    test('A, B, C, sans egard a la casse ; A par defaut', () {
      expect(StyleCadreMushaf.depuisCode('A'), StyleCadreMushaf.a);
      expect(StyleCadreMushaf.depuisCode('b'), StyleCadreMushaf.b);
      expect(StyleCadreMushaf.depuisCode(' C '), StyleCadreMushaf.c);
      expect(StyleCadreMushaf.depuisCode(''), StyleCadreMushaf.a);
      expect(StyleCadreMushaf.depuisCode('Z'), StyleCadreMushaf.a);
      expect(StyleCadreMushaf.courant, StyleCadreMushaf.a);
    });

    test('le cadre ne prend pas plus de 4 % de la hauteur', () {
      for (final StyleCadreMushaf s in StyleCadreMushaf.values) {
        final GeometrieCadreMushaf g = GeometrieCadreMushaf(
          style: s,
          hauteurPage: 700,
        );
        expect(g.hauteurPrise / 700, lessThanOrEqualTo(0.04 + 1e-9));
      }
      expect(
        const GeometrieCadreMushaf(
          style: StyleCadreMushaf.c,
          hauteurPage: 700,
        ).lateral,
        0,
        reason: 'C n\'a pas de bords',
      );
    });
  });

  group('la page remplit la place, avec un cadre dans la marge', () {
    for (final StyleCadreMushaf style in StyleCadreMushaf.values) {
      for (final int page in <int>[1, 2, 50, 544, 604]) {
        testWidgets('${style.name.toUpperCase()} page $page 390x700', (
          WidgetTester tester,
        ) async {
          StyleCadreMushaf.surcharge = style;
          await monterPageMadina15(
            tester,
            page: page,
            taille: const Size(390, 700),
          );
          expect(tester.takeException(), isNull);
          final Rect cadre = tester.getRect(find.byType(CadreMushaf));
          // Le texte reste hors du cadre : de la premiere a la derniere ligne,
          // il est dans la page, a l'interieur des bandes.
          final Rect premiere = tester.getRect(find.byKey(cleLigneMadina15(1)));
          final Rect derniere = tester.getRect(
            find.byKey(cleLigneMadina15(page <= 2 ? 8 : 15)),
          );
          expect(premiere.top, greaterThan(cadre.top));
          expect(derniere.bottom, lessThan(cadre.bottom));
          expect(premiere.left, greaterThanOrEqualTo(cadre.left));
          expect(derniere.right, lessThanOrEqualTo(cadre.right));
          // Les bandes du haut et du bas : 4 % de la hauteur de la page.
          final double e =
              cadre.height * GeometrieCadreMushaf.epaisseurRelative;
          expect(premiere.top - cadre.top, greaterThanOrEqualTo(e));
          // La page occupe la hauteur : le cadre est la page.
          expect(cadre.height, greaterThan(700 * 0.9));
          expect(cadre.height, lessThanOrEqualTo(700));
          expect(cadre.width, lessThanOrEqualTo(390));
          // La largeur est prise aussi : sur telephone, le texte va presque
          // d'un bord a l'autre.
          expect(cadre.width, greaterThan(390 * 0.85));
        });
      }
    }

    testWidgets('le cadre est dans son RepaintBoundary, hors du texte', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 544, taille: const Size(390, 700));
      final Finder cadre = find.byType(CadreMushaf);
      expect(cadre, findsOneWidget);
      expect(
        find.descendant(of: cadre, matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
      expect(
        find.descendant(of: cadre, matching: find.byType(RichText)),
        findsNothing,
        reason: 'rien derriere le texte : le cadre ne porte aucun texte',
      );
      expect(
        find.descendant(of: cadre, matching: find.byKey(cleLigneMadina15(5))),
        findsNothing,
      );
    });

    testWidgets('rien qu\'un numero en pied : pas de notice de composition', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 544, taille: const Size(390, 700));
      expect(find.byType(NoticeComposition), findsNothing);
      expect(find.textContaining('Composition'), findsNothing);
      expect(find.textContaining('sur 604'), findsNothing);
    });

    testWidgets('grand ecran : la double page est gardee, sans carte', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 544,
        taille: const Size(1440, 900),
      );
      expect(find.byType(PageMadina15), findsNWidgets(2));
      expect(find.byType(Card), findsNothing);
      final Rect a = tester.getRect(find.byType(CadreMushaf).first);
      final Rect b = tester.getRect(find.byType(CadreMushaf).last);
      expect(a.height, closeTo(b.height, 0.5));
      expect(a.height, lessThanOrEqualTo(900));
    });
  });

  group('le fond et les contrastes (AA dans les deux themes)', () {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('${theme.name} : l\'ecran entier est sur la surface', (
        WidgetTester tester,
      ) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: const Size(390, 844),
          theme: theme,
          ecranComplet: true,
        );
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(PageMadina15)),
        );
        final Scaffold coque = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(MushafPage),
            matching: find.byType(Scaffold),
          ),
        );
        expect(coque.backgroundColor, palette.surfaceCanvas.background);
        expect(
          palette.surfaceCanvas.background,
          isNot(palette.surfaceQuran.background),
        );
        // Sur telephone, la page prend la place : celle de l'en-tete serre et
        // de la rangee de commandes est celle du texte agrandi.
        expect(find.byType(PageMadina15), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      test(
        '${theme.name} : texte, rosaces, signes de pause et cadre lisibles',
        () {
          final AppPalette p = theme == ThemeMode.dark
              ? AppPalette.sombre()
              : AppPalette.claire();
          final Color fond = p.surfaceCanvas.background;
          // Le texte.
          expect(
            contraste(p.surfaceCanvas.onBackground, fond),
            greaterThanOrEqualTo(seuilTexte),
          );
          // Signes de pause et numeros de verset : l'encre d'accent.
          expect(
            contraste(p.inkAccent.debugValue, fond),
            greaterThanOrEqualTo(seuilTexte),
          );
          // Le cadre : un element graphique, 3:1.
          expect(
            contraste(p.surfacePrimary.background, fond),
            greaterThanOrEqualTo(seuilComposant),
          );
        },
      );
    }

    testWidgets('un signe de pause prend l\'encre d\'accent, le mot l\'encre', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(tester, page: 50, taille: const Size(390, 700));
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(PageMadina15)),
      );
      final Color accent = palette.inkAccent.debugValue;
      int signes = 0;
      for (final RichText r in tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(PageMadina15),
          matching: find.byType(RichText),
        ),
      )) {
        r.text.visitChildren((InlineSpan s) {
          if (s is TextSpan && s.text != null && s.style?.color == accent) {
            // L'encre d'accent est celle des signes de lecture et des
            // chiffres des rosaces, de rien d'autre.
            final bool chiffres = s.text!.runes.every(
              (int r) => r >= 0x0660 && r <= 0x0669,
            );
            expect(
              chiffres || s.text!.runes.every(estSigneDeLecture),
              isTrue,
              reason: s.text,
            );
            if (!chiffres) signes++;
          }
          return true;
        });
      }
      expect(signes, greaterThan(0));
    });

    test('scinder un mot au signe de pause n\'en perd aucun caractere', () {
      const String mot = 'ٱلْغُرُوبِۖ';
      final List<InlineSpan> segments = signesEnAccent(
        mot,
        AppPalette.claire().inkAccent,
      );
      expect(segments.map((InlineSpan s) => (s as TextSpan).text).join(), mot);
      expect(
        signesEnAccent('كتاب', AppPalette.claire().inkAccent),
        hasLength(1),
      );
    });
  });
}
