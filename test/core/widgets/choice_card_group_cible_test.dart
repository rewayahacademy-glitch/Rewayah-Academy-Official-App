// E1 (demande du directeur du 17/10/2026) : toute la carte de choix est la
// cible et se lit comme telle. Un appui au centre ou dans la marge de la
// carte retient l'option ; le repere de selection est en tete, cote `start` ;
// au survol, le curseur est une main, le fond et le titre changent ; la
// carte fait au moins une cible tactile ; le lecteur d'ecran lit un bouton
// radio coche.
//
// Contre-epreuve : sur l'ancien code (6b510106), ce fichier ne compile pas
// (`CaseChoix` absent) ; le repere y est en bout de ligne (cote `end`) et le
// survol ne change ni le fond ni le titre.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_metriques.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

import '../../support/hote_theme.dart';

const Key _moi = Key('opt-moi');
const Key _famille = Key('opt-famille');

List<OptionChoix> _options() => const <OptionChoix>[
  OptionChoix(
    valeur: 'moi',
    libelle: 'Moi uniquement',
    description: 'Je suis les cours avec mon propre profil.',
    icone: AppIcons.profil,
    cle: _moi,
  ),
  OptionChoix(
    valeur: 'famille',
    libelle: 'Moi et ma famille',
    description: 'Vous inscrivez vos enfants ou vos proches.',
    icone: AppIcons.foyer,
    cle: _famille,
  ),
];

Future<List<ReponseChoix>> _monter(
  WidgetTester tester, {
  required Size taille,
  bool coteACote = false,
  bool multiple = false,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<ReponseChoix> recues = <ReponseChoix>[];
  await tester.pumpWidget(
    hoteTheme(
      Directionality(
        textDirection: sens,
        child: ChoiceCardGroup(
          options: _options(),
          autoriserSaisieLibre: false,
          coteACote: coteACote,
          selectionMultiple: multiple,
          onChange: recues.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return recues;
}

/// Les points d'appui d'une carte : le centre et quatre points dans sa marge
/// interieure, a 6 px du bord, hors de tout texte et de tout repere.
List<(String, Offset)> _points(Rect carte) => <(String, Offset)>[
  ('centre', carte.center),
  ('marge start', carte.centerLeft + const Offset(6, 0)),
  ('marge end', carte.centerRight - const Offset(6, 0)),
  ('marge haute', carte.topCenter + const Offset(0, 6)),
  ('marge basse', carte.bottomCenter - const Offset(0, 6)),
];

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    final String l = '${taille.width.toInt()}';
    for (final bool coteACote in <bool>[false, true]) {
      final String d = coteACote ? 'cote a cote' : 'liste';
      testWidgets('$d $l : appui au centre et dans la marge retient l option', (
        WidgetTester tester,
      ) async {
        final List<ReponseChoix> recues = await _monter(
          tester,
          taille: taille,
          coteACote: coteACote,
        );
        for (final (String ou, Offset point) in _points(
          tester.getRect(find.byKey(_famille)),
        )) {
          // Revenir a l'autre carte, pour que chaque appui change la reponse.
          await tester.tap(find.byKey(_moi));
          await tester.pumpAndSettle();
          expect(recues.last.valeurs, <String>{'moi'});
          await tester.tapAt(point);
          await tester.pumpAndSettle();
          expect(recues.last.valeurs, <String>{'famille'}, reason: ou);
          final RadioChoix radio = tester.widget<RadioChoix>(
            find.descendant(
              of: find.byKey(_famille),
              matching: find.byType(RadioChoix),
            ),
          );
          expect(radio.retenue, isTrue, reason: ou);
        }
      });

      for (final TextDirection sens in TextDirection.values) {
        testWidgets('$d $l ${sens.name} : repere en tete cote start', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            taille: taille,
            coteACote: coteACote,
            sens: sens,
          );
          final Rect carte = tester.getRect(find.byKey(_moi));
          final Rect repere = tester.getRect(
            find.descendant(
              of: find.byKey(_moi),
              matching: find.byType(RadioChoix),
            ),
          );
          final Rect titre = tester.getRect(find.text('Moi uniquement'));
          if (sens == TextDirection.ltr) {
            expect(repere.left - carte.left, lessThanOrEqualTo(24));
          } else {
            expect(carte.right - repere.right, lessThanOrEqualTo(24));
          }
          if (coteACote) {
            // Le repere a sa rangee, au-dessus du titre centre.
            expect(repere.bottom, lessThanOrEqualTo(titre.top));
          } else if (sens == TextDirection.ltr) {
            expect(repere.right, lessThan(titre.left));
          } else {
            expect(repere.left, greaterThan(titre.right));
          }
          expect(repere.top - carte.top, lessThanOrEqualTo(carte.height / 2));
        });
      }
    }
  }

  testWidgets('selection multiple : case en tete, appui dans la marge coche', (
    WidgetTester tester,
  ) async {
    final List<ReponseChoix> recues = await _monter(
      tester,
      taille: const Size(1440, 900),
      multiple: true,
    );
    expect(find.byType(CaseChoix), findsNWidgets(2));
    expect(find.byType(RadioChoix), findsNothing);
    final Rect carte = tester.getRect(find.byKey(_famille));
    final Rect repere = tester.getRect(
      find.descendant(
        of: find.byKey(_famille),
        matching: find.byType(CaseChoix),
      ),
    );
    expect(repere.center.dx, lessThan(carte.center.dx));
    await tester.tapAt(carte.centerRight - const Offset(6, 0));
    await tester.pumpAndSettle();
    expect(recues.last.valeurs, <String>{'famille'});
    expect(find.byIcon(AppIcons.succes.actif), findsOneWidget);
    await tester.tapAt(carte.topCenter + const Offset(0, 6));
    await tester.pumpAndSettle();
    expect(recues.last.valeurs, isEmpty);
  });

  testWidgets('survol : curseur main, fond et titre changent', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 900));
    final AppPalette palette = AppPalette.of(
      tester.element(find.byType(ChoiceCardGroup)),
    );
    Color? fond() {
      final AnimatedContainer boite = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(_famille),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (boite.decoration! as BoxDecoration).color;
    }

    Color? titre() => tester
        .widget<RichText>(
          find
              .descendant(
                of: find.text('Moi et ma famille'),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .style
        ?.color;

    final Color? fondRepos = fond();
    final Color? titreRepos = titre();
    // Sur ordinateur et sur le Web a la souris, le mode de surbrillance
    // est le mode classique ; le test tourne sous Android (tactile).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final TestGesture souris = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await souris.addPointer(location: Offset.zero);
    addTearDown(souris.removePointer);
    // Dans la marge de la carte, loin du texte.
    await souris.moveTo(
      tester.getRect(find.byKey(_famille)).centerRight - const Offset(6, 0),
    );
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
    expect(fond(), isNot(fondRepos));
    expect(titre(), isNot(titreRepos));
    expect(titre(), palette.inkAccent.debugValue);
  });

  testWidgets('cible : au moins la cible tactile, lue comme radio coche', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, taille: const Size(390, 844));
    final double cible = AppMetriques.of(
      tester.element(find.byType(ChoiceCardGroup)),
    ).cibleTactile;
    expect(cible, greaterThanOrEqualTo(48));
    for (final Key cle in <Key>[_moi, _famille]) {
      final Size carte = tester.getSize(find.byKey(cle));
      expect(carte.height, greaterThanOrEqualTo(cible));
      expect(carte.width, greaterThanOrEqualTo(cible));
    }
    await tester.tap(find.byKey(_moi));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Moi uniquement')),
      isSemantics(
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    semantique.dispose();
  });
}
