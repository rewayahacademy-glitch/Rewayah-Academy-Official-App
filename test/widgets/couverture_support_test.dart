// Lot SUPPORTS-ETAGERE, reprise (directeur, 11/11/2026) : les couvertures de
// l'academie aux couleurs de la marque, la couverture standard du Coran en
// arabe, contrastes mesures.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/couverture_ressource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/couverture_support.dart';
import 'package:rewayah_academy/core/widgets/ornement_marque.dart';

import '../capture/outil_capture.dart';

double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const CouvertureRessource _lettres = CouvertureRessource(
  indexTeinte: 0,
  motif: MotifCouverture.lignes,
  monogramme: 'L',
  type: TypeRessource.texteStructure,
);

Future<void> _monter(
  WidgetTester tester,
  Widget couverture, {
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  double largeur = 120,
}) async {
  fixerVueCapture(tester, const Size(320, 640), 1);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(
          child: SizedBox(width: largeur, child: couverture),
        ),
      ),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('collection de l academie : les seuls violets de la marque, encre '
      'blanche lisible (4,5:1 au moins)', () {
    const List<int> marque = <int>[0xFF4E2983, 0xFF6538E4, 0xFF8652E6];
    expect(
      AppCouleursCouverture.academie
          .map((AppColorPair p) => p.background.toARGB32())
          .toList(),
      marque,
    );
    for (final AppColorPair p in AppCouleursCouverture.academie) {
      expect(_contraste(p.background, p.onBackground), greaterThan(4.5));
    }
  });

  test('couverture du Coran : titre dore a 4,5:1 au moins, filet a 3:1 '
      'au moins, aucun fond parchemin', () {
    const AppColorPair coran = AppCouleursCouverture.coran;
    expect(_contraste(coran.background, coran.onBackground), greaterThan(4.5));
    expect(
      _contraste(
        coran.background,
        AppCouleursCouverture.filetCoran.asBorderSide().color,
      ),
      greaterThan(3),
    );
    expect(
      coran.background,
      isNot(AppPalette.claire().surfaceQuran.background),
    );
  });

  testWidgets('le Coran ecrit « القرآن الكريم » en arabe meme en francais ; '
      'le lecteur d ecran lit le titre en francais ; aucune marque de l '
      'academie', (WidgetTester tester) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(
      tester,
      CouvertureSupport(
        titre: t.salle.supports.coran,
        couverture: CouvertureRessource.coran(t.salle.supports.coran),
      ),
    );
    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('مصحف المدينة'), findsOneWidget);
    expect(find.bySemanticsLabel(t.salle.supports.coran), findsOneWidget);
    expect(find.byType(OrnementMarque), findsNothing);
    semantique.dispose();
  });

  testWidgets('un livre de l academie : titre, repere, ornement de la '
      'marque, mention', (WidgetTester tester) async {
    await _monter(
      tester,
      CouvertureSupport(
        titre: t.salle.etagere.demo.lettres,
        couverture: _lettres,
        repere: t.salle.etagere.etape(numero: 1),
        mention: t.salle.etagere.aValider,
      ),
    );
    expect(find.text(t.salle.etagere.demo.lettres), findsOneWidget);
    expect(find.text(t.salle.etagere.etape(numero: 1)), findsOneWidget);
    expect(find.byType(OrnementMarque), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final ThemeMode theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('arabe, texte x2, 96 points de large, ${theme.name} : rien ne '
        'deborde', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        Row(
          children: <Widget>[
            Expanded(
              child: CouvertureSupport(
                titre: t.salle.supports.coran,
                couverture: CouvertureRessource.coran(t.salle.supports.coran),
              ),
            ),
            Expanded(
              child: CouvertureSupport(
                titre: t.salle.etagere.demo.voyelles,
                couverture: _lettres,
                repere: t.salle.etagere.etape(numero: 2),
                mention: t.salle.etagere.aValider,
              ),
            ),
          ],
        ),
        texte: 2,
        theme: theme,
        largeur: 200,
      );
      expect(find.text('القرآن الكريم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
