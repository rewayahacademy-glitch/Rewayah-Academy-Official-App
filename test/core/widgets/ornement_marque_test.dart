import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/ornement_marque.dart';

import '../../support/hote_theme.dart';

/// L'ornement de la marque (BRAND-ORN-1) : tailles de l'echelle, couleur par
/// fond, decoratif, et sans effet sur la hauteur des ecrans qui le portent.
double _luminance(Color c) => c.computeLuminance();

double _contraste(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  group('tailles', () {
    test('chaque taille est une valeur de l echelle d espacement', () {
      const List<double> echelle = <double>[
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];
      for (final TailleOrnement t in TailleOrnement.values) {
        expect(echelle, contains(t.hauteur), reason: t.name);
        expect(t.hauteur, lessThanOrEqualTo(AppSpacing.xxxl));
      }
    });

    for (final VarianteOrnement v in VarianteOrnement.values) {
      testWidgets('proportions verrouillees (${v.name})', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTheme(OrnementMarque(taille: TailleOrnement.grand, variante: v)),
        );
        final Size taille = tester.getSize(find.byType(CustomPaint).last);
        expect(taille.height, TailleOrnement.grand.hauteur);
        expect(
          taille.width / taille.height,
          closeTo(v.dessin.proportion, 1e-6),
        );
      });
    }
  });

  group('couleur', () {
    test('violet de marque sur le fond de page', () {
      expect(
        BrandLogo.couleur(FondLogo.page),
        AppPalette.claire().surfacePrimary.background,
      );
    });

    test('blanc sur une bande violette, encre a l impression', () {
      final AppPalette marque = AppPalette.claire();
      expect(
        BrandLogo.couleur(FondLogo.violet),
        marque.surfacePrimary.onBackground,
      );
      expect(
        BrandLogo.couleur(FondLogo.impression),
        marque.surfaceRaised.onBackground,
      );
    });

    test('le violet de marque tient 3:1 sur les deux fonds de page', () {
      final Color violet = BrandLogo.couleur(FondLogo.page);
      for (final AppPalette p in <AppPalette>[
        AppPalette.claire(),
        AppPalette.sombre(),
      ]) {
        expect(
          _contraste(violet, p.surfaceCanvas.background),
          greaterThanOrEqualTo(3),
        );
      }
    });
  });

  testWidgets('decoratif : aucune semantique, aucun texte', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    await tester.pumpWidget(
      hoteTheme(
        const Column(
          children: <Widget>[OrnementMarque(), SeparateurOrnement()],
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(OrnementMarque),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.byType(OrnementMarque).first).label,
      isEmpty,
    );
    poignee.dispose();
  });

  testWidgets('le separateur prend la hauteur de sa taille', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteTheme(const SeparateurOrnement()));
    expect(
      tester.getSize(find.byType(SeparateurOrnement)).height,
      TailleOrnement.moyen.hauteur,
    );
  });

  testWidgets('en arabe : meme dessin, meme taille', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteTheme(const OrnementMarque()));
    final Size ltr = tester.getSize(find.byType(OrnementMarque));
    await tester.pumpWidget(
      hoteTheme(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: OrnementMarque(),
        ),
      ),
    );
    expect(tester.getSize(find.byType(OrnementMarque)), ltr);
  });

  group('etat vide', () {
    Future<double> hauteur(
      WidgetTester tester, {
      AppColorPair? encre,
      double echelle = 1,
    }) async {
      await tester.pumpWidget(
        hoteTheme(
          EmptyState(message: 'Rien pour le moment', encre: encre),
          echelleTexte: echelle,
        ),
      );
      return tester.getSize(find.byType(EmptyState)).height;
    }

    testWidgets('porte l ornement, absent sur une surface inverse', (
      WidgetTester tester,
    ) async {
      await hauteur(tester);
      expect(find.byType(OrnementMarque), findsOneWidget);
      await hauteur(tester, encre: AppPalette.claire().surfaceInverse);
      expect(find.byType(OrnementMarque), findsNothing);
    });

    testWidgets('la hauteur de l etat vide ne change pas', (
      WidgetTester tester,
    ) async {
      final double avec = await hauteur(tester);
      final double sans = await hauteur(
        tester,
        encre: AppPalette.claire().surfaceCanvas,
      );
      expect(avec, sans);
    });
  });
}
