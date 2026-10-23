import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/selecteur_theme.dart';

import '../support/hote_theme.dart';

PreferenceTheme _theme(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SelecteurTheme)))
        .read(preferencesLocalesProvider)
        .theme;

Finder ligne(String detail) => find.textContaining(detail, findRichText: true);

void main() {
  testWidgets(
    'phrase de contexte et ligne des trois options toujours visibles',
    (WidgetTester tester) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(hoteTheme(const SelecteurTheme()));

      expect(find.text(t.compte.themeContexte), findsOneWidget);
      for (final String detail in <String>[
        t.compte.themeClairDetail,
        t.compte.themeSystemeDetail,
        t.compte.themeSombreDetail,
      ]) {
        expect(ligne(detail), findsOneWidget, reason: detail);
      }

      // Les trois lignes restent affichees apres un changement de choix.
      await tester.tap(find.text(t.compte.themeSombre));
      await tester.pump();
      for (final String detail in <String>[
        t.compte.themeClairDetail,
        t.compte.themeSystemeDetail,
        t.compte.themeSombreDetail,
      ]) {
        expect(ligne(detail), findsOneWidget, reason: detail);
      }
    },
  );

  testWidgets('trois segments cote a cote : clair, systeme, sombre', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(const SelecteurTheme()));

    final Finder controle = find.byType(ControleSegmente<PreferenceTheme>);
    expect(controle, findsOneWidget);
    final ControleSegmente<PreferenceTheme> w = tester.widget(controle);
    expect(w.rectangle, isTrue);
    expect(
      w.segments.map((Segment<PreferenceTheme> s) => s.valeur),
      <PreferenceTheme>[
        PreferenceTheme.clair,
        PreferenceTheme.systeme,
        PreferenceTheme.sombre,
      ],
    );
    // Un seul rectangle, une seule rangee : meme centre vertical, de gauche a
    // droite en LTR.
    final Rect clair = tester.getRect(find.text(t.compte.themeClair));
    final Rect systeme = tester.getRect(find.text(t.compte.themeSysteme));
    final Rect sombre = tester.getRect(find.text(t.compte.themeSombre));
    expect(clair.center.dx, lessThan(systeme.center.dx));
    expect(systeme.center.dx, lessThan(sombre.center.dx));
    expect((clair.center.dy - sombre.center.dy).abs(), lessThan(1));
    expect((clair.center.dy - systeme.center.dy).abs(), lessThan(1));
    // Aucune carte ni ligne radio.
    expect(find.byType(Radio<PreferenceTheme>), findsNothing);
  });

  testWidgets('en arabe (RTL) l ordre se miroite : sombre a gauche', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(
      hoteTheme(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: SelecteurTheme(),
        ),
      ),
    );
    final double clair = tester.getCenter(find.text(t.compte.themeClair)).dx;
    final double sombre = tester.getCenter(find.text(t.compte.themeSombre)).dx;
    expect(clair, greaterThan(sombre));
  });

  testWidgets('un seul segment selectionne, la preference change au tap', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(const SelecteurTheme()));

    int selectionnes() => tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((Semantics s) => s.properties.selected ?? false)
        .length;

    expect(_theme(tester), PreferenceTheme.systeme);
    expect(selectionnes(), 1);
    expect(ligne(t.compte.themeSystemeDetail), findsOneWidget);

    await tester.tap(find.text(t.compte.themeSombre));
    await tester.pump();
    expect(_theme(tester), PreferenceTheme.sombre);
    expect(selectionnes(), 1);

    await tester.tap(find.text(t.compte.themeClair));
    await tester.pump();
    expect(_theme(tester), PreferenceTheme.clair);
    expect(selectionnes(), 1);

    // Presser le segment deja choisi ne change rien.
    await tester.tap(find.text(t.compte.themeClair));
    await tester.pump();
    expect(_theme(tester), PreferenceTheme.clair);
    semantique.dispose();
  });

  for (final Size vue in <Size>[const Size(320, 700), vueBureau]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets(
          'geometrie ${vue.width.toInt()} px, texte x${echelle.toInt()}, '
          '$luminosite : aucun debordement',
          (WidgetTester tester) async {
            fixerVue(tester, vue);
            await tester.pumpWidget(
              hoteTheme(
                const SelecteurTheme(),
                luminosite: luminosite,
                echelleTexte: echelle,
              ),
            );
            expect(tester.takeException(), isNull);

            final Rect piste = tester.getRect(
              find.byType(ControleSegmente<PreferenceTheme>),
            );
            expect(piste.left, greaterThanOrEqualTo(0));
            expect(piste.right, lessThanOrEqualTo(vue.width));
            for (final String libelle in <String>[
              t.compte.themeClair,
              t.compte.themeSysteme,
              t.compte.themeSombre,
            ]) {
              final Rect r = tester.getRect(find.text(libelle));
              expect(r.left, greaterThanOrEqualTo(piste.left), reason: libelle);
              expect(r.right, lessThanOrEqualTo(piste.right), reason: libelle);
            }
            // Trois segments de meme largeur, sans chevauchement.
            final Rect a = tester.getRect(find.text(t.compte.themeClair));
            final Rect b = tester.getRect(find.text(t.compte.themeSysteme));
            final Rect c = tester.getRect(find.text(t.compte.themeSombre));
            expect(a.right, lessThanOrEqualTo(b.left));
            expect(b.right, lessThanOrEqualTo(c.left));
            expect(
              tester
                  .getSize(find.byType(ControleSegmente<PreferenceTheme>))
                  .height,
              greaterThanOrEqualTo(48),
            );
          },
        );
      }
    }
  }
}
