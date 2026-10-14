import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/ornement_marque.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

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
    await tester.pumpWidget(hoteTheme(const OrnementMarque.signature()));
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

  group('signature', () {
    testWidgets('petite, a l opacite fixee, plein', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteTheme(const OrnementMarque.signature()));
      final OrnementMarque o = tester.widget(find.byType(OrnementMarque));
      expect(o.taille, TailleOrnement.petit);
      expect(o.variante, VarianteOrnement.plein);
      expect(o.opacite, OrnementMarque.opaciteSignature);
      expect(OrnementMarque.opaciteSignature, lessThanOrEqualTo(0.5));
      expect(OrnementMarque.opaciteSignature, greaterThan(0));
    });

    testWidgets('jamais retourne : ni rotation, ni miroir, en LTR et en RTL', (
      WidgetTester tester,
    ) async {
      for (final TextDirection sens in TextDirection.values) {
        await tester.pumpWidget(
          hoteTheme(
            Directionality(
              textDirection: sens,
              child: const OrnementMarque.signature(),
            ),
          ),
        );
        final CustomPaint peint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(OrnementMarque),
            matching: find.byType(CustomPaint),
          ),
        );
        final _Espion c = _Espion();
        peint.painter!.paint(c, peint.size);
        expect(c.interdits, isEmpty, reason: sens.name);
        expect(c.echelles, isNotEmpty);
        for (final double e in c.echelles) {
          expect(e, greaterThan(0), reason: 'echelle negative = miroir');
        }
      }
    });
  });

  testWidgets('la confirmation porte la signature, l erreur non', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        const EcranResultat(
          icone: AppIcons.accueil,
          titre: 'Fait',
          ton: TonEtat.succes,
        ),
      ),
    );
    expect(find.byType(OrnementMarque), findsOneWidget);
    await tester.pumpWidget(
      hoteTheme(
        const EcranResultat(
          icone: AppIcons.accueil,
          titre: 'Echec',
          ton: TonEtat.alerte,
        ),
      ),
    );
    expect(find.byType(OrnementMarque), findsNothing);
  });

  testWidgets('jamais sur un ecran de travail : l etat vide n en porte pas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(const EmptyState(message: 'Rien pour le moment')),
    );
    expect(find.byType(OrnementMarque), findsNothing);
  });
}

/// Un canevas qui refuse tout ce qui retournerait le dessin.
class _Espion extends Fake implements Canvas {
  final List<String> interdits = <String>[];
  final List<double> echelles = <double>[];

  @override
  void save() {}

  @override
  void restore() {}

  @override
  void translate(double dx, double dy) {}

  @override
  void scale(double sx, [double? sy]) {
    echelles
      ..add(sx)
      ..add(sy ?? sx);
  }

  @override
  void rotate(double radians) => interdits.add('rotate');

  @override
  void skew(double sx, double sy) => interdits.add('skew');

  @override
  void transform(Float64List matrix4) => interdits.add('transform');

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void drawPath(Path path, Paint paint) {}
}
