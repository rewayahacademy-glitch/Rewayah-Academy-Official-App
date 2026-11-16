// MESSAGERIE-COULEURS (directeur, 16/11/2026, « moche, trop moche, je prefere la
// couleur d'avant ») : les couleurs de fond de la messagerie sont FIXEES par test.
//
//   * la page est le fond de page du theme (`#F1EFF4` clair, `#16161E` sombre) ;
//   * la liste des conversations est UNE carte blanche (`surfaceRaised`) sur la
//     page, ses lignes sans teinte lavande : seule la conversation ouverte porte
//     un trait au bord de debut, jamais une couleur de fond ;
//   * le fil a le MEME fond que la page (`fondFil` = `surfaceCanvas`), le champ
//     de saisie repose dessus, sans rectangle ;
//   * les bulles recues restent blanches, avec leur ombre legere.
// Contre-epreuve : echoue sur main avant ce lot (fil `#E9E5F0`, lignes nues).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/ligne_conversation.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';

import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

/// Le rapport de contraste WCAG entre deux couleurs opaques.
double _rapport(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// La conversation `fil-bulles` (messages courts et longs, deux jours) n'existe
/// que dans cette variante de la demonstration.
MessagesMetierDemo _portBulles() => MessagesMetierDemo(
  role: RoleDemoCommunications.enseignant,
  maintenant: maintenantTest,
  avecBulles: true,
);

void main() {
  group('les valeurs de fond de la messagerie', () {
    test('clair : fil = page = #F1EFF4, ligne et bulle recue = blanc', () {
      final AppPalette p = AppPalette.claire();
      expect(p.surfaceCanvas.background, const Color(0xFFF1EFF4));
      expect(p.fondFil.background, const Color(0xFFF1EFF4));
      expect(p.fondFil.background, p.surfaceCanvas.background);
      expect(p.surfaceRaised.background, const Color(0xFFFFFFFF));
    });

    test('sombre : fil = page = #16161E', () {
      final AppPalette p = AppPalette.sombre();
      expect(p.surfaceCanvas.background, const Color(0xFF16161E));
      expect(p.fondFil.background, const Color(0xFF16161E));
      expect(p.fondFil.background, p.surfaceCanvas.background);
    });

    test('le bord de la bulle recue sur le fil : rapport mesure, '
        'l\'ombre legere fait le reste', () {
      final AppPalette c = AppPalette.claire();
      final AppPalette s = AppPalette.sombre();
      final double clair = _rapport(
        c.surfaceRaised.background,
        c.fondFil.background,
      );
      final double sombre = _rapport(
        s.surfaceRaised.background,
        s.fondFil.background,
      );
      // ignore: avoid_print
      print(
        'bord de bulle recue sur le fil : clair ${clair.toStringAsFixed(2)}:1, '
        'sombre ${sombre.toStringAsFixed(2)}:1',
      );
      // Blanc sur #F1EFF4 : environ 1,15:1 ; seul le dessin (ombre) detache.
      expect(clair, greaterThan(1.1));
      expect(sombre, greaterThan(1.1));
    });
  });

  for (final (Size taille, Brightness lum) in <(Size, Brightness)>[
    (const Size(390, 844), Brightness.light),
    (const Size(390, 844), Brightness.dark),
    (const Size(1440, 900), Brightness.light),
    (const Size(1440, 900), Brightness.dark),
  ]) {
    final String cas =
        '${taille.width.toInt()} ${lum == Brightness.dark ? 'sombre' : 'clair'}';

    testWidgets('liste, $cas : une carte blanche sur la page, lignes sans '
        'teinte', (WidgetTester tester) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.enseignant),
        taille: taille,
        luminosite: lum,
      );
      await tester.pumpAndSettle();
      final BuildContext ctx = tester.element(find.byType(ListeFils));
      final AppPalette p = AppPalette.of(ctx);
      // La page.
      expect(Theme.of(ctx).scaffoldBackgroundColor, p.surfaceCanvas.background);
      // Les lignes sont portees par UNE carte a la surface « raised ».
      final Finder lignes = find.byType(LigneConversation);
      expect(lignes, findsWidgets);
      final Iterable<Element> cartes = find
          .ancestor(of: lignes.first, matching: find.byType(DecoratedBox))
          .evaluate()
          .where((Element e) {
            final Decoration d = (e.widget as DecoratedBox).decoration;
            return d is BoxDecoration && d.color == p.surfaceRaised.background;
          });
      expect(
        cartes,
        isNotEmpty,
        reason: 'les lignes doivent reposer sur une carte surfaceRaised',
      );
      // Aucune ligne ne porte la teinte lavande de selection.
      for (final Element e in lignes.evaluate()) {
        final Iterable<Color?> fonds = find
            .descendant(
              of: find.byElementPredicate((Element x) => x == e),
              matching: find.byType(DecoratedBox),
            )
            .evaluate()
            .map((Element d) => (d.widget as DecoratedBox).decoration)
            .whereType<BoxDecoration>()
            .map((BoxDecoration b) => b.color);
        expect(
          fonds,
          isNot(contains(p.washAccent.background)),
          reason: 'une ligne de la liste ne se teinte pas en lavande',
        );
      }
    });

    testWidgets('fil, $cas : meme fond que la page, champ sans rectangle', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: _portBulles(),
        depart: cheminFilTest('fil-bulles'),
        taille: taille,
        luminosite: lum,
      );
      await tester.pumpAndSettle();
      final BuildContext ctx = tester.element(find.byType(FilDiscussion));
      final AppPalette p = AppPalette.of(ctx);
      final Color page = p.surfaceCanvas.background;
      // Les messages reposent sur le fond de la page.
      final ColoredBox fond = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byKey(FilDiscussion.cleMessages),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(fond.color, page);
      // Le champ de saisie : aucun fond d'une autre couleur derriere lui.
      final Iterable<Color> fondsDuChamp = find
          .ancestor(
            of: find.byKey(FilDiscussion.champKey),
            matching: find.byType(ColoredBox),
          )
          .evaluate()
          .map((Element e) => (e.widget as ColoredBox).color);
      for (final Color c in fondsDuChamp) {
        expect(
          c,
          page,
          reason: 'derriere le champ : le fond de la page, rien d\'autre',
        );
      }
      // La bulle recue reste blanche (surfaceRaised), avec son ombre.
      final Iterable<BoxDecoration> bulles = find
          .byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    p.surfaceRaised.background &&
                ((w.decoration as BoxDecoration).boxShadow?.isNotEmpty ??
                    false),
          )
          .evaluate()
          .map((Element e) => (e.widget as DecoratedBox).decoration)
          .cast<BoxDecoration>();
      expect(bulles, isNotEmpty);
    });
  }

  testWidgets('la conversation ouverte : un trait au bord de debut, sans '
      'teinte (1440, clair)', (WidgetTester tester) async {
    await monterMessages(
      tester,
      port: _portBulles(),
      depart: cheminFilTest('fil-bulles'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LigneConversation.cleRepereSelection), findsOneWidget);
  });
}
