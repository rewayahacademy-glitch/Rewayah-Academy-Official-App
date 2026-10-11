// MUSHAF-MODES (decision de l'orchestrateur du 11/10/2026) : « Lecture
// agrandie » et « Focus » avec la mise en page de Medine suivent la page du
// Mushaf. (a) credits hors de l'ecran, (b) meme navigation, (c) zone de
// lecture pleine hauteur sans ligne tronquee, (d) focus hors classe : la page
// ouverte, sans phrase d'aide, (e) UthmanicHafs, (f) plus de note de zoom
// borne, « Agrandir » se grise.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_madina_15.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/tc_mushaf/fleches_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

const List<ModeRenduCoran> _modes = <ModeRenduCoran>[
  ModeRenduCoran.versetAgrandi,
  ModeRenduCoran.focus,
];

int _page(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
        .read(lectureCoranProvider)
        .page;

Future<void> _monter(
  WidgetTester tester, {
  required ModeRenduCoran mode,
  required Size taille,
  int page = 293,
  double zoom = 1,
  ThemeMode theme = ThemeMode.light,
}) => monterPageMadina15(
  tester,
  page: page,
  taille: taille,
  mode: mode,
  zoom: zoom,
  theme: theme,
  ecranComplet: true,
);

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  setUp(masquerRubanDebug);

  for (final ModeRenduCoran mode in _modes) {
    group(mode.name, () {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('telephone', _telephone),
        ('bureau', _bureau),
      ]) {
        testWidgets('(a) $nom : aucun credit a l ecran', (
          WidgetTester tester,
        ) async {
          await _monter(tester, mode: mode, taille: taille);
          expect(find.byKey(MushafPage.attributionKey), findsNothing);
          expect(find.textContaining('Tanzil'), findsNothing);
          expect(find.textContaining('quran.ws'), findsNothing);
          expect(find.textContaining('KFGQPC'), findsNothing);
        });

        testWidgets('(b) $nom : ni barre ni compteur', (
          WidgetTester tester,
        ) async {
          await _monter(tester, mode: mode, taille: taille);
          expect(
            find.byKey(const ValueKey<String>('nav-precedent-suivant')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('nav-position')),
            findsNothing,
          );
          expect(find.textContaining('293 / 604'), findsNothing);
          expect(find.byKey(MushafPage.menuKey), findsOneWidget);
          expect(
            find.byType(FlechePageMushaf),
            taille == _bureau ? findsNWidgets(2) : findsNothing,
          );
        });

        testWidgets('(c) $nom : lecture pleine hauteur, le dernier verset se '
            'lit en entier', (WidgetTester tester) async {
          await _monter(tester, mode: mode, taille: taille);
          final Finder defilement = find.descendant(
            of: find.byType(ColonneVersetsReflow),
            matching: find.byType(SingleChildScrollView),
          );
          final Rect zone = tester.getRect(defilement);
          // La zone va jusqu'au bas de l'ecran : ni commandes, ni credits en
          // dessous.
          expect(zone.bottom, greaterThanOrEqualTo(taille.height - 1));
          await tester.dragUntilVisible(
            find.byType(BlocVerset).last,
            defilement,
            const Offset(0, -200),
          );
          await stabiliser(tester);
          final Rect dernier = tester.getRect(find.byType(BlocVerset).last);
          expect(dernier.bottom, lessThanOrEqualTo(zone.bottom + 0.5));
          expect(dernier.top, greaterThanOrEqualTo(zone.top - 0.5));
        });
      }

      testWidgets('(b) telephone : le glisser tourne les pages, sens Mushaf', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _telephone);
        await tester.drag(find.byType(PageView), const Offset(300, 0));
        await stabiliser(tester);
        expect(_page(tester), 294);
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await stabiliser(tester);
        expect(_page(tester), 293);
      });

      testWidgets('(b) bureau : fleches symetriques, centrees, et touches', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        final List<Rect> fleches = tester
            .widgetList<FlechePageMushaf>(find.byType(FlechePageMushaf))
            .map((FlechePageMushaf f) => tester.getRect(find.byWidget(f).first))
            .toList();
        expect(fleches, hasLength(2));
        expect(fleches.first.center.dy, closeTo(fleches.last.center.dy, 0.01));
        expect(
          fleches.first.left,
          closeTo(_bureau.width - fleches.last.right, 0.01),
        );
        final Rect zone = tester.getRect(find.byType(PageAvecFlechesMushaf));
        expect(fleches.first.center.dy, closeTo(zone.center.dy, 0.01));
        // Aucun chevauchement avec le texte.
        final Rect texte = tester.getRect(find.byType(ColonneVersetsReflow));
        expect(texte.left, greaterThanOrEqualTo(fleches.first.right));
        expect(texte.right, lessThanOrEqualTo(fleches.last.left));
        await tester.tap(find.byType(FlechePageMushaf).first);
        await stabiliser(tester);
        expect(_page(tester), 294);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await stabiliser(tester);
        expect(_page(tester), 293);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await stabiliser(tester);
        expect(_page(tester), 294);
      });

      testWidgets('(e) le texte est en UthmanicHafs, repli propre', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        final Finder texte = find.descendant(
          of: find.byType(BlocVerset).first,
          matching: find.byType(RichText),
        );
        final TextStyle? style = tester
            .widgetList<RichText>(texte)
            .where(
              (RichText r) =>
                  RegExp('[\u0600-\u06FF]').hasMatch(r.text.toPlainText()),
            )
            .map((RichText r) => r.text.style)
            .first;
        expect(style!.fontFamily, FamilleMushaf15L.nom);
        expect(style.fontFamily, AppFontFamily.arabeMushaf);
        expect(style.fontFamilyFallback, contains(AppFontFamily.arabeDocument));
      });

      testWidgets(
        '(f) aucune note de zoom borne, Agrandir se grise au maximum',
        (WidgetTester tester) async {
          await _monter(tester, mode: mode, taille: _bureau, zoom: 4);
          expect(find.textContaining(t.tc.coran.zoom.bride), findsNothing);
          final Finder agrandir = find.widgetWithText(
            ActionPrincipale,
            t.eleve.coran.agrandir,
          );
          final Finder reduire = find.widgetWithText(
            ActionPrincipale,
            t.eleve.coran.reduire,
          );
          expect(tester.widget<ActionPrincipale>(agrandir).onPress, isNull);
          expect(tester.widget<ActionPrincipale>(reduire).onPress, isNotNull);
          // Et le texte ne deborde pas : la borne d'integrite du mot demeure.
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('(f) Agrandir reste actif tant que la colonne le tient', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        final Finder agrandir = find.widgetWithText(
          ActionPrincipale,
          t.eleve.coran.agrandir,
        );
        expect(tester.widget<ActionPrincipale>(agrandir).onPress, isNotNull);
        double zoom() =>
            ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
                .read(lectureCoranProvider)
                .zoomLocal;
        for (int i = 0; i < 40; i++) {
          final VoidCallback? action = tester
              .widget<ActionPrincipale>(agrandir)
              .onPress;
          if (action == null) break;
          action();
          await tester.pump();
        }
        expect(tester.widget<ActionPrincipale>(agrandir).onPress, isNull);
        expect(zoom(), lessThanOrEqualTo(PositionLecture.zoomMax + 1e-9));
      });
    });
  }

  testWidgets('(d) focus hors classe : la page ouverte, sans phrase d aide', (
    WidgetTester tester,
  ) async {
    await _monter(tester, mode: ModeRenduCoran.focus, taille: _bureau);
    expect(find.textContaining(t.tc.coran.focus.aucunePlage), findsNothing);
    expect(find.byType(BlocVerset), findsWidgets);
    // Les versets de la page ouverte, tous : 293 porte 105 a 111 de la sourate 17.
    expect(find.textContaining('17:105'), findsOneWidget);
  });
}
