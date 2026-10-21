import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';

import '../../support/hote_theme.dart';
import '../../support/logo.dart';

/// Le logo Rewayah Academy (LOGO-APP) : couleur d'apres le fond, proportions
/// verrouillees, tailles minimales, semantique.
RenduLogo _peintre(WidgetTester tester) =>
    tester.renderObject<RenduLogo>(find.byType(LogoPeint));

/// La taille du dessin rendu, hors zone de protection.
Size _tailleDessin(WidgetTester tester) {
  final RenduLogo rendu = _peintre(tester);
  final double h = rendu.hauteurDessin;
  return Size(h * BrandLogo.dessin(rendu.varianteRendue).proportion, h);
}

double _luminance(Color c) => c.computeLuminance();

double _contraste(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  group('couleur', () {
    for (final Brightness luminosite in Brightness.values) {
      testWidgets('violet de marque sur le fond de page (${luminosite.name})', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTheme(
            const BrandLogo(variante: VarianteLogo.horizontal, hauteur: 32),
            luminosite: luminosite,
          ),
        );
        final Color violet = AppPalette.claire().surfacePrimary.background;
        expect(_peintre(tester).couleur, violet);
        expect(violet, const Color(0xFF8652E6));
        // Element graphique : 3:1 au moins sur le fond de page du theme.
        final AppPalette palette = luminosite == Brightness.light
            ? AppPalette.claire()
            : AppPalette.sombre();
        expect(
          _contraste(violet, palette.surfaceCanvas.background),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contraste(violet, palette.surfaceRaised.background),
          greaterThanOrEqualTo(3),
        );
      });
    }

    testWidgets('blanc sur une bande violette, encre pour l impression', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTheme(
          const BrandLogo(
            variante: VarianteLogo.symbole,
            hauteur: 32,
            fond: FondLogo.violet,
          ),
        ),
      );
      expect(_peintre(tester).couleur, const Color(0xFFFFFFFF));
      expect(
        _contraste(
          _peintre(tester).couleur,
          AppPalette.claire().surfacePrimary.background,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        BrandLogo.couleur(FondLogo.impression),
        AppPalette.claire().surfaceRaised.onBackground,
      );
    });
  });

  group('proportions et tailles minimales', () {
    for (final VarianteLogo v in VarianteLogo.values) {
      testWidgets('${v.name} garde la proportion de son viewBox', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTheme(Center(child: BrandLogo(variante: v, hauteur: 96))),
        );
        final Size taille = _tailleDessin(tester);
        expect(taille.height, 96);
        expect(
          taille.width / taille.height,
          closeTo(BrandLogo.dessin(v).proportion, 1e-9),
        );
        // Zone de protection : 25 % de la hauteur de chaque cote.
        expect(
          tester.getSize(find.byType(BrandLogo)),
          Size(taille.width + 48, taille.height + 48),
        );
      });
    }

    testWidgets('trop etroit pour l horizontal : le logo reduit puis passe '
        'au symbole', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteTheme(
          const Center(
            child: SizedBox(
              width: 200,
              child: BrandLogo(variante: VarianteLogo.horizontal, hauteur: 64),
            ),
          ),
        ),
      );
      // 200 / (3,578 + 0,5) = 49 : il reduit, homogene.
      Size taille = _tailleDessin(tester);
      expect(
        taille.width / taille.height,
        closeTo(logoProportion(VarianteLogo.horizontal), 1e-9),
      );
      expect(taille.width + taille.height * 0.5, lessThanOrEqualTo(200.001));
      expect(logoRendu(VarianteLogo.horizontal), findsOneWidget);

      await tester.pumpWidget(
        hoteTheme(
          const Center(
            child: SizedBox(
              width: 100,
              child: BrandLogo(variante: VarianteLogo.horizontal, hauteur: 64),
            ),
          ),
        ),
      );
      expect(logoRendu(VarianteLogo.symbole), findsOneWidget);
      taille = _tailleDessin(tester);
      expect(taille.height, greaterThanOrEqualTo(BrandLogo.minimumSymbole));
    });

    test('regles de repli', () {
      expect(
        BrandLogo.varianteRendue(VarianteLogo.horizontal, 20).$1,
        VarianteLogo.symbole,
      );
      expect(
        BrandLogo.varianteRendue(VarianteLogo.horizontal, 20).$2,
        BrandLogo.minimumSymbole,
      );
      expect(BrandLogo.varianteRendue(VarianteLogo.vertical, 40), (
        VarianteLogo.horizontal,
        40.0,
      ));
      expect(BrandLogo.varianteRendue(VarianteLogo.vertical, 96), (
        VarianteLogo.vertical,
        96.0,
      ));
      expect(
        BrandLogo.varianteRendue(VarianteLogo.symbole, 10).$2,
        BrandLogo.minimumSymbole,
      );
    });
  });

  group('semantique', () {
    testWidgets(
      'le logo d en-tete est un lien lu « Rewayah Academy, accueil »',
      (WidgetTester tester) async {
        final SemanticsHandle poignee = tester.ensureSemantics();
        int accueils = 0;
        await tester.pumpWidget(
          hoteTheme(
            BrandLogo(
              variante: VarianteLogo.horizontal,
              hauteur: 32,
              onAccueil: () => accueils++,
            ),
          ),
        );
        final Finder lien = find.bySemanticsLabel(t.nav.logoAccueil);
        expect(lien, findsOneWidget);
        expect(
          tester.getSemantics(lien),
          matchesSemantics(
            label: t.nav.logoAccueil,
            isLink: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        await tester.tap(find.byType(BrandLogo));
        expect(accueils, 1);
        // Cible tactile : jamais sous 48.
        expect(
          tester.getSize(find.byType(BrandLogo)).height,
          greaterThanOrEqualTo(48),
        );
        poignee.dispose();
      },
    );

    testWidgets('decoratif sans lien ni libelle, image nommee avec libelle', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              BrandLogo(variante: VarianteLogo.symbole, hauteur: 32),
              BrandLogo(
                variante: VarianteLogo.vertical,
                hauteur: 96,
                libelle: 'Rewayah Academy',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel(t.nav.logoAccueil), findsNothing);
      final Finder image = find.bySemanticsLabel('Rewayah Academy');
      expect(image, findsOneWidget);
      expect(
        tester.getSemantics(image),
        matchesSemantics(label: 'Rewayah Academy', isImage: true),
      );
      // Le symbole decoratif n'apporte aucun noeud : seul le vertical nomme
      // est lu.
      expect(
        find.descendant(
          of: find.byType(BrandLogo).first,
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      poignee.dispose();
    });
  });

  testWidgets('jamais retourne en arabe', (WidgetTester tester) async {
    await tester.pumpWidget(
      hoteTheme(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: BrandLogo(variante: VarianteLogo.horizontal, hauteur: 32),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(BrandLogo),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });
}

double logoProportion(VarianteLogo v) => BrandLogo.dessin(v).proportion;
