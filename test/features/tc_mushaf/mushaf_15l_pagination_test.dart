// MUSHAF-15L (retours du directeur du 11/10/2026) : on tourne les pages sans
// barre ni « 544 / 604 ». Telephone : glisser (la page suivante arrive de la
// gauche, comme dans un livre arabe), menu dans l'en-tete, actions
// d'accessibilite. Tablette et bureau : une fleche de chaque cote de la page,
// touches gauche et droite. Les credits quittent l'ecran : feuille « A propos
// de cette edition » ouverte depuis le menu.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/features/tc_mushaf/a_propos_edition.dart';
import 'package:rewayah_academy/features/tc_mushaf/fleches_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/navigation_coran_feuille.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';

const Size _telephone = Size(390, 844);
const Size _tablette = Size(800, 1000);
const Size _bureau = Size(1440, 900);

int _page(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
        .read(lectureCoranProvider)
        .page;

Future<void> _glisser(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(PageMadina15).first, Offset(dx, 0));
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  setUp(masquerRubanDebug);

  group('telephone : le glisser tourne les pages', () {
    testWidgets(
      'ni barre, ni position, ni credit : le menu est dans l en-tete',
      (WidgetTester tester) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: _telephone,
          ecranComplet: true,
        );
        expect(
          find.byKey(const ValueKey<String>('nav-precedent-suivant')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('nav-position')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('nav-precedent')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey<String>('nav-suivant')), findsNothing);
        expect(find.byKey(MushafPage.attributionKey), findsNothing);
        expect(find.textContaining('Tanzil'), findsNothing);
        expect(find.textContaining('quran.ws'), findsNothing);
        expect(find.byType(FlechePageMushaf), findsNothing);
        expect(find.byKey(MushafPage.menuKey), findsOneWidget);
      },
    );

    testWidgets(
      'glisser vers la droite : la page suivante vient de la gauche',
      (WidgetTester tester) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: _telephone,
          ecranComplet: true,
        );
        await _glisser(tester, 300);
        expect(_page(tester), 545);
        await _glisser(tester, 300);
        expect(_page(tester), 546);
      },
    );

    testWidgets('glisser vers la gauche : la page precedente', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 544,
        taille: _telephone,
        ecranComplet: true,
      );
      await _glisser(tester, -300);
      expect(_page(tester), 543);
    });

    testWidgets('meme sens quand l interface est en arabe', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      await monterPageMadina15(
        tester,
        page: 544,
        taille: _telephone,
        ecranComplet: true,
      );
      await _glisser(tester, 300);
      expect(_page(tester), 545);
      await _glisser(tester, -300);
      expect(_page(tester), 544);
    });

    testWidgets('actions d accessibilite : page suivante et precedente', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await monterPageMadina15(
        tester,
        page: 544,
        taille: _telephone,
        ecranComplet: true,
      );
      final Semantics corps = tester.widget<Semantics>(
        find.ancestor(
          of: find.byType(PageView),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Semantics &&
                w.properties.customSemanticsActions != null &&
                w.properties.customSemanticsActions!.isNotEmpty,
          ),
        ),
      );
      final Map<CustomSemanticsAction, VoidCallback> actions =
          corps.properties.customSemanticsActions!;
      expect(
        actions.keys.map((CustomSemanticsAction a) => a.label),
        containsAll(<String>[
          t.eleve.coran.pageSuivante,
          t.eleve.coran.pagePrecedente,
        ]),
      );
      actions.entries
          .firstWhere(
            (MapEntry<CustomSemanticsAction, VoidCallback> e) =>
                e.key.label == t.eleve.coran.pageSuivante,
          )
          .value();
      await stabiliser(tester);
      expect(_page(tester), 545);
      poignee.dispose();
    });

    testWidgets('texte agrandi : toujours ni barre ni position', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 544,
        taille: _telephone,
        echelleTexte: 1.5,
        ecranComplet: true,
      );
      expect(
        find.byKey(const ValueKey<String>('nav-precedent-suivant')),
        findsNothing,
      );
      expect(find.byKey(MushafPage.menuKey), findsOneWidget);
    });
  });

  group('tablette et bureau : une fleche de chaque cote', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('tablette', _tablette),
      ('bureau', _bureau),
    ]) {
      testWidgets('$nom : fleches symetriques, centrees, hors du texte', (
        WidgetTester tester,
      ) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: taille,
          ecranComplet: true,
        );
        expect(
          find.byKey(const ValueKey<String>('nav-position')),
          findsNothing,
        );
        expect(find.byKey(MushafPage.attributionKey), findsNothing);
        final List<Rect> fleches = tester
            .widgetList<FlechePageMushaf>(find.byType(FlechePageMushaf))
            .map((FlechePageMushaf f) => tester.getRect(find.byWidget(f).first))
            .toList();
        expect(fleches, hasLength(2));
        final Rect gauche = fleches.first;
        final Rect droite = fleches.last;
        expect(gauche.left, lessThan(droite.left));
        expect(gauche.center.dy, closeTo(droite.center.dy, 0.01));
        expect(gauche.left, closeTo(taille.width - droite.right, 0.01));
        final Rect zone = tester.getRect(find.byType(PageAvecFlechesMushaf));
        expect(gauche.center.dy, closeTo(zone.center.dy, 0.01));
        for (final Element e in find.byType(PageMadina15).evaluate()) {
          final Rect page = tester.getRect(
            find.byElementPredicate((Element x) => x == e),
          );
          expect(page.left, greaterThanOrEqualTo(gauche.right));
          expect(page.right, lessThanOrEqualTo(droite.left));
        }
      });
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('sens des glyphes (${sens.name}) : la fleche de gauche '
          'pointe a gauche, celle de droite a droite', (
        WidgetTester tester,
      ) async {
        if (sens == TextDirection.rtl) {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        }
        await monterPageMadina15(
          tester,
          page: 51,
          taille: _tablette,
          ecranComplet: true,
        );
        // Le glyphe des jetons pointe a droite : une echelle horizontale
        // negative le retourne vers la gauche.
        double echelleX(Finder fleche) => tester
            .widgetList<Transform>(
              find.descendant(of: fleche, matching: find.byType(Transform)),
            )
            .map((Transform t) => t.transform.entry(0, 0))
            .reduce((double a, double b) => a < b ? a : b);
        final Finder fleches = find.byType(FlechePageMushaf);
        expect(fleches, findsNWidgets(2));
        final Finder gauche = fleches.first;
        final Finder droite = fleches.last;
        expect(
          tester.getCenter(gauche).dx,
          lessThan(tester.getCenter(droite).dx),
        );
        expect(
          echelleX(gauche),
          lessThan(0),
          reason: 'gauche : vers la gauche',
        );
        expect(
          echelleX(droite),
          greaterThan(0),
          reason: 'droite : vers la droite',
        );
      });
    }

    testWidgets('la fleche de gauche tourne vers la page suivante', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 51,
        taille: _tablette,
        ecranComplet: true,
      );
      final Finder fleches = find.byType(FlechePageMushaf);
      await tester.tap(fleches.first);
      await stabiliser(tester);
      expect(_page(tester), 52);
      await tester.tap(fleches.last);
      await stabiliser(tester);
      expect(_page(tester), 51);
    });

    testWidgets('bureau : une ouverture compte deux pages', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 543,
        taille: _bureau,
        ecranComplet: true,
      );
      await tester.tap(find.byType(FlechePageMushaf).first);
      await stabiliser(tester);
      expect(_page(tester), 545);
      await tester.tap(find.byType(FlechePageMushaf).last);
      await stabiliser(tester);
      expect(_page(tester), 543);
    });

    testWidgets('touches gauche (suivante) et droite (precedente)', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 51,
        taille: _tablette,
        ecranComplet: true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await stabiliser(tester);
      expect(_page(tester), 52);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await stabiliser(tester);
      expect(_page(tester), 51);
    });

    testWidgets('aux bornes, la fleche n est pas rendue', (
      WidgetTester tester,
    ) async {
      await monterPageMadina15(
        tester,
        page: 1,
        taille: _tablette,
        ecranComplet: true,
      );
      // La premiere page : la fleche « precedente » (droite) disparait, sa
      // place reste ; on ne la trouve plus par son libelle.
      expect(find.bySemanticsLabel(t.eleve.coran.pagePrecedente), findsNothing);
      expect(find.bySemanticsLabel(t.eleve.coran.pageSuivante), findsOneWidget);
    });
  });

  group('credits : feuille « A propos de cette edition »', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('telephone', _telephone),
      ('bureau', _bureau),
    ]) {
      testWidgets('$nom : le menu mene aux credits complets', (
        WidgetTester tester,
      ) async {
        await monterPageMadina15(
          tester,
          page: 544,
          taille: taille,
          ecranComplet: true,
        );
        if (nom == 'telephone') {
          await tester.tap(find.byKey(MushafPage.menuKey));
        } else {
          await tester.tap(find.text(t.tc.coran.navigation.ouvrir));
        }
        await stabiliser(tester);
        await tester.tap(find.byKey(FeuilleNavigationCoran.aProposKey));
        await stabiliser(tester);
        expect(find.byKey(FeuilleAProposEdition.contenuKey), findsOneWidget);
        expect(find.text(t.eleve.coran.edition), findsOneWidget);
        expect(find.textContaining(t.eleve.coran.sourceLien), findsWidgets);
        expect(
          find.text(t.tc.coran.mushaf.page15.creditMiseEnPage),
          findsOneWidget,
        );
        expect(find.textContaining('CC BY 4.0'), findsWidgets);
        expect(find.textContaining('KFGQPC'), findsWidgets);
        expect(find.textContaining('MIT'), findsOneWidget);
      });
    }
  });
}
