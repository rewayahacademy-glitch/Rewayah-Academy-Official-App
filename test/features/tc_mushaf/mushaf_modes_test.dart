// MUSHAF-MODES (decisions de l'orchestrateur du 11/10/2026) : « Lecture
// agrandie » et « Focus » avec la mise en page de Medine suivent la page du
// Mushaf. (a) credits hors de l'ecran, (b) meme navigation, (c) zone de
// lecture pleine hauteur, (d) focus hors classe : la page ouverte, (e) le texte
// KFGQPC va avec UthmanicHafs et seulement avec elle, (f) plus de note de zoom
// borne, (g) interligne fixe et proportionnelle, (h) versets en texte continu,
// rosace en ligne, (i) focus : surlignage de la plage, (j) garde de
// l'interligne mesuree.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/rosace_verset.dart';
import 'package:rewayah_academy/features/tc_mushaf/fleches_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/texte_continu_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart';
import '../../support/mushaf_15l.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

const List<ModeRenduCoran> _modes = <ModeRenduCoran>[
  ModeRenduCoran.versetAgrandi,
  ModeRenduCoran.focus,
];

final RegExp _signesKfgqpc = RegExp('[\\u06D6-\\u06DC\\u06DE\\u06E9]');

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
  bool policeMushaf = true,
  ContentRange? plageFocus,
  ThemeMode theme = ThemeMode.light,
}) => monterPageMadina15(
  tester,
  page: page,
  taille: taille,
  mode: mode,
  zoom: zoom,
  theme: theme,
  tanzilSimple: true,
  policeMushaf: policeMushaf,
  plageFocus: plageFocus,
  ecranComplet: true,
);

/// Le paragraphe du texte continu.
Finder _texte() => find.descendant(
  of: find.byType(ColonneContinueMushaf),
  matching: find.byWidgetPredicate(
    (Widget w) => w is RichText && w.text.toPlainText().contains('￼'),
  ),
);

double _corps(WidgetTester tester) =>
    tester.widget<RichText>(_texte()).text.style!.fontSize!;

/// Les boites des lettres (hors rosaces en ligne et espaces).
List<TextBox> _lettres(RenderParagraph rendu) {
  final String texte = rendu.text.toPlainText();
  return <TextBox>[
    for (int i = 0; i < texte.length; i++)
      if (texte[i] != '￼' && texte[i].trim().isNotEmpty)
        ...rendu.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        ),
  ];
}

/// Les pas verticaux entre lignes successives du paragraphe, en points : une
/// valeur de haut par ligne, puisque la strut impose la meme hauteur partout.
List<double> _pas(WidgetTester tester) {
  final RenderParagraph rendu = tester.renderObject<RenderParagraph>(_texte());
  final Set<double> hauts = <double>{
    for (final TextBox b in _lettres(rendu)) (b.top * 2).round() / 2,
  };
  final List<double> tries = hauts.toList()..sort();
  return <double>[
    for (int i = 1; i < tries.length; i++) tries[i] - tries[i - 1],
  ];
}

/// Les textes portant un fond de surlignage.
List<String> _surlignes(WidgetTester tester) {
  final RichText r = tester.widget<RichText>(_texte());
  final List<String> out = <String>[];
  r.text.visitChildren((InlineSpan s) {
    if (s is TextSpan && s.style?.backgroundColor != null && s.text != null) {
      out.add(s.text!);
    }
    return true;
  });
  return out;
}

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

        testWidgets(
          '(c) $nom : lecture pleine hauteur, la fin se lit en entier',
          (WidgetTester tester) async {
            await _monter(tester, mode: mode, taille: taille);
            final Finder defilement = find.descendant(
              of: find.byType(ColonneContinueMushaf),
              matching: find.byType(SingleChildScrollView),
            );
            final Rect zone = tester.getRect(defilement);
            // La zone va jusqu'au bas de l'ecran : ni commandes, ni credits en
            // dessous.
            expect(zone.bottom, greaterThanOrEqualTo(taille.height - 32));
            final ScrollableState etat = tester.state<ScrollableState>(
              find
                  .descendant(of: defilement, matching: find.byType(Scrollable))
                  .first,
            );
            etat.position.jumpTo(etat.position.maxScrollExtent);
            await stabiliser(tester);
            final Rect texte = tester.getRect(_texte());
            expect(texte.bottom, lessThanOrEqualTo(zone.bottom + 0.5));
            expect(texte.top, lessThan(zone.bottom));
          },
        );
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
        final Rect texte = tester.getRect(find.byType(ColonneContinueMushaf));
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

      testWidgets('(e) avec la police : texte KFGQPC en UthmanicHafs', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        final RichText r = tester.widget<RichText>(_texte());
        final TextStyle style = r.text.style!;
        expect(style.fontFamily, AppFontFamily.arabeMushaf);
        expect(style.fontFamilyFallback, contains(AppFontFamily.arabeDocument));
        // Le texte est celui des lignes de l'edition : il porte les signes
        // propres a l'ecriture uthmanie que le corpus Tanzil simple n'a pas.
        expect(_signesKfgqpc.hasMatch(r.text.toPlainText()), isTrue);
      });

      testWidgets('(e) sans la police : texte Tanzil simple, jamais KFGQPC', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau, policeMushaf: false);
        final RichText r = tester.widget<RichText>(_texte());
        final TextStyle style = r.text.style!;
        expect(style.fontFamily, isNot(AppFontFamily.arabeMushaf));
        expect(style.fontFamily, AppFontFamily.arabeDocument);
        expect(
          _signesKfgqpc.hasMatch(r.text.toPlainText()),
          isFalse,
          reason: 'le texte KFGQPC ne se rend jamais sans UthmanicHafs',
        );
      });

      for (final bool police in <bool>[true, false]) {
        testWidgets('(e) garde : tout paragraphe a signes KFGQPC est en '
            'UthmanicHafs (police=$police)', (WidgetTester tester) async {
          await _monter(
            tester,
            mode: mode,
            taille: _bureau,
            policeMushaf: police,
          );
          for (final RichText r in tester.widgetList<RichText>(
            find.byType(RichText),
          )) {
            if (_signesKfgqpc.hasMatch(r.text.toPlainText())) {
              expect(
                r.text.style?.fontFamily,
                AppFontFamily.arabeMushaf,
                reason: 'texte KFGQPC rendu sans UthmanicHafs',
              );
            }
          }
        });
      }

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
        for (int i = 0; i < 40; i++) {
          final VoidCallback? action = tester
              .widget<ActionPrincipale>(agrandir)
              .onPress;
          if (action == null) break;
          action();
          await tester.pump();
        }
        expect(tester.widget<ActionPrincipale>(agrandir).onPress, isNull);
        expect(
          ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
              .read(lectureCoranProvider)
              .zoomLocal,
          lessThanOrEqualTo(PositionLecture.zoomMax + 1e-9),
        );
      });

      testWidgets('(h) versets en texte continu, rosace en ligne', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle poignee = tester.ensureSemantics();
        await _monter(tester, mode: mode, taille: _bureau);
        // Un seul flux : plus de bloc par verset, plus de reference au-dessus.
        expect(find.byType(BlocVerset), findsNothing);
        // La reference n'est plus devant chaque verset : elle n'est que dans
        // l'en-tete (la page 293 passe de la sourate 17 a la 18).
        expect(find.textContaining('17:105 à 18:'), findsOneWidget);
        expect(find.byType(RosaceVerset), findsWidgets);
        final Rect texte = tester.getRect(_texte());
        for (final Element e in find.byType(RosaceVerset).evaluate()) {
          final Rect r = tester.getRect(
            find.byElementPredicate((Element x) => x == e),
          );
          expect(r.top, greaterThanOrEqualTo(texte.top - 1));
          expect(r.bottom, lessThanOrEqualTo(texte.bottom + 1));
        }
        // La reference sourate:verset est l'etiquette semantique de la rosace.
        expect(find.bySemanticsLabel(RegExp('17:105')), findsWidgets);
        poignee.dispose();
      });

      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', _telephone),
        ('1440', _bureau),
      ]) {
        testWidgets('(h) $nom : aucune rosace seule sur sa ligne', (
          WidgetTester tester,
        ) async {
          await _monter(tester, mode: mode, taille: taille, zoom: 4);
          final RenderParagraph rendu = tester.renderObject<RenderParagraph>(
            _texte(),
          );
          final String texte = rendu.text.toPlainText();
          final List<TextBox> lettres = _lettres(rendu);
          for (int i = 0; i < texte.length; i++) {
            if (texte[i] != '￼') continue;
            for (final TextBox rosace in rendu.getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            )) {
              final double milieu = (rosace.top + rosace.bottom) / 2;
              expect(
                lettres.any(
                  (TextBox l) => l.top <= milieu && milieu <= l.bottom,
                ),
                isTrue,
                reason: 'rosace $i seule sur sa ligne',
              );
            }
          }
        });
      }

      testWidgets('(h) alignement a droite, jamais justifie', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        final RichText r = tester.widget<RichText>(_texte());
        expect(r.textAlign, isNot(TextAlign.justify));
      });

      for (final (String nom, Size taille, double zoom)
          in <(String, Size, double)>[
            ('390 a 100 %', _telephone, 1),
            ('390 au maximum', _telephone, 4),
            ('1440 a 100 %', _bureau, 1),
            ('1440 au maximum', _bureau, 4),
          ]) {
        testWidgets(
          '(g)(j) interligne mesuree, $nom : pas fixe et proportionnel',
          (WidgetTester tester) async {
            await _monter(tester, mode: mode, taille: taille, zoom: zoom);
            final List<double> pas = _pas(tester);
            expect(pas, isNotEmpty);
            final double attendu = _corps(tester) * ratioInterligneModes;
            expect(ratioInterligneModes, inInclusiveRange(1.9, 2.1));
            for (final double p in pas) {
              // Le meme ecart d'une ligne a l'autre, a plus ou moins 5 %.
              expect(
                p,
                closeTo(attendu, attendu * 0.05),
                reason: '$p vs $attendu',
              );
            }
          },
        );
      }

      testWidgets('(i) hors classe : page entiere, aucun surlignage', (
        WidgetTester tester,
      ) async {
        await _monter(tester, mode: mode, taille: _bureau);
        expect(find.textContaining(t.tc.coran.focus.aucunePlage), findsNothing);
        expect(_surlignes(tester), isEmpty);
      });
    });
  }

  testWidgets(
    '(i) focus en classe : la plage designee est surlignee, la page reste '
    'entiere',
    (WidgetTester tester) async {
      final ContentRange plage = ContentRange(
        resourceId: 'hafs',
        debut: const ContentPosition.ayah(
          resourceId: 'hafs',
          sourate: 17,
          ayah: 106,
        ),
        fin: const ContentPosition.ayah(
          resourceId: 'hafs',
          sourate: 17,
          ayah: 107,
        ),
      );
      await _monter(
        tester,
        mode: ModeRenduCoran.focus,
        taille: _bureau,
        plageFocus: plage,
      );
      expect(_surlignes(tester), isNotEmpty);
      expect(find.byType(RosaceVerset).evaluate().length, greaterThan(2));
      final String tout = tester.widget<RichText>(_texte()).text.toPlainText();
      expect(tout.length, greaterThan(_surlignes(tester).join().length));
    },
  );
}
