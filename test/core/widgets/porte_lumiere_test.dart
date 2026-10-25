import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/porte_lumiere.dart';

import '../../theme/support/contraste.dart';

/// La porte et la lumiere : le logo est celui de `BrandLogo`, la scene tient
/// dans 320 px de large, clair et sombre, et reste decorative.
void main() {
  Widget hote(AppPalette palette, Widget enfant, {TextDirection? sens}) =>
      MaterialApp(
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[palette]),
        home: Directionality(
          textDirection: sens ?? TextDirection.ltr,
          child: Scaffold(body: Center(child: enfant)),
        ),
      );

  for (final (String nom, AppPalette palette) in <(String, AppPalette)>[
    ('clair', AppPalette.claire()),
    ('sombre', AppPalette.sombre()),
  ]) {
    testWidgets('rendu $nom, 320 px, sans debordement ni semantique', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(hote(palette, const PorteLumiere()));
      expect(tester.takeException(), isNull);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(
        tester.getSize(find.byType(PorteLumiere)).width,
        lessThanOrEqualTo(320),
      );
    });
  }

  testWidgets('page de l application inchangee : symbole violet, meme taille', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(AppPalette.claire(), const PorteLumiere()));
    final BrandLogo logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
    expect(logo.fond, FondLogo.page);
    expect(logo.variante, VarianteLogo.symbole);
    expect(
      tester.getSize(find.byType(PorteLumiere)),
      const Size(PorteLumiere.largeur, PorteLumiere.hauteur),
    );
  });

  group('scene du site sur la surface de marque', () {
    for (final double largeur in <double>[288, 320, 576]) {
      testWidgets('$largeur px : symbole blanc a sa place du viewBox', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(largeur, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          hote(
            AppPalette.claire(),
            const PorteLumiere.surMarque(
              largeurMax: PorteLumiere.largeurViewBox,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final BrandLogo logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
        // Fond violet = logo blanc (README du logo).
        expect(logo.fond, FondLogo.violet);
        expect(BrandLogo.couleur(logo.fond), const Color(0xFFFFFFFF));

        final double e = largeur / PorteLumiere.largeurViewBox;
        final Rect scene = tester.getRect(find.byType(PorteLumiere));
        expect(scene.size.width, moreOrLessEquals(largeur));
        expect(
          scene.size.height,
          moreOrLessEquals(PorteLumiere.hauteurViewBox * e),
        );
        // `translate(127 58) scale(.54)` : le dessin du symbole, hors zone de
        // protection, commence a (127, 58) et finit au seuil (y = 439,8).
        final Rect boite = tester.getRect(find.byType(BrandLogo));
        final double zone = 707 * 0.54 * e * BrandLogo.zoneProtection;
        expect(boite.left + zone - scene.left, moreOrLessEquals(127 * e));
        expect(boite.top + zone - scene.top, moreOrLessEquals(58 * e));
        expect(
          boite.bottom - zone - scene.top,
          moreOrLessEquals((58 + 707 * 0.54) * e),
        );
      });
    }

    testWidgets('bornee par sa largeur maximale, decorative', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        hote(AppPalette.claire(), const PorteLumiere.surMarque()),
      );
      expect(
        tester.getSize(find.byType(PorteLumiere)).width,
        PorteLumiere.largeurScene,
      );
      expect(
        find.descendant(
          of: find.byType(PorteLumiere),
          matching: find.bySemanticsLabel(RegExp('.')),
        ),
        findsNothing,
      );
      semantique.dispose();
    });

    testWidgets('jamais retournee en arabe', (WidgetTester tester) async {
      await tester.pumpWidget(
        hote(
          AppPalette.claire(),
          const PorteLumiere.surMarque(),
          sens: TextDirection.rtl,
        ),
      );
      final Rect scene = tester.getRect(find.byType(PorteLumiere));
      final Rect boite = tester.getRect(find.byType(BrandLogo));
      final double e = scene.width / PorteLumiere.largeurViewBox;
      final double zone = 707 * 0.54 * e * BrandLogo.zoneProtection;
      expect(boite.left + zone - scene.left, moreOrLessEquals(127 * e));
    });

    test('teintes de la scene : symbole blanc lisible sur la marque', () {
      // Element graphique porteur de sens : 3:1 au moins (WCAG 1.4.11).
      expect(
        contraste(
          AppCouleursPorte.blanc.asBorderSide().color,
          AppPalette.claire().surfaceMarque.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
