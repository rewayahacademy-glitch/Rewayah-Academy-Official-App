// ETATS-BTN-1 (revue de la relecture, 02/10/2026) : la bascule Agrandir /
// Reduire se lit par les trois signaux cumules (disque plein ou contour seul,
// icone, mot d'etat) PARTOUT : dans le dock de la seance et dans la barre du
// support (ZoomLocal), comme micro et camera.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

const Key _disqueCle = ValueKey<String>('disque-appel');
const Key _dockCle = ValueKey<String>('bouton-agrandir');
const Key _barreCle = ValueKey<String>('bouton-agrandir-barre');

BoxDecoration _decoration(WidgetTester tester, Key cle) {
  final Finder boite = find.descendant(
    of: find.descendant(of: find.byKey(cle), matching: find.byKey(_disqueCle)),
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(boite.first).decoration as BoxDecoration;
}

IconData _icone(WidgetTester tester, Key cle) => tester
    .widget<Icon>(
      find.descendant(of: find.byKey(cle), matching: find.byType(Icon)),
    )
    .icon!;

Widget _dock({required bool agrandi}) => DockSeance(
  vue: DonneesSeanceDemo.vue(RoleSeance.guidee, EtatDemoSalle.visite),
  actions: ActionsSeance(onAgrandir: () {}),
  agrandi: agrandi,
);

Widget _barre({required bool agrandi}) => Center(
  child: ZoomLocal(zoom: 1, onAgrandir: () {}, agrandi: agrandi),
);

void main() {
  final Map<String, (Widget Function({required bool agrandi}), Key)> sites =
      <String, (Widget Function({required bool agrandi}), Key)>{
        'barre du support': (_barre, _barreCle),
      };
  sites.forEach((
    String nom,
    (Widget Function({required bool agrandi}), Key) s,
  ) {
    final Widget Function({required bool agrandi}) monter = s.$1;
    final Key cle = s.$2;
    for (final ThemeMode luminosite in const <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('$nom, ${luminosite.name} : trois signaux, un par un', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await tester.pumpWidget(
          hoteCapture(monter(agrandi: false), themeMode: luminosite),
        );
        await tester.pump();
        final AppPalette palette = AppPalette.of(
          tester.element(find.byKey(cle)),
        );
        // Inactif (le support n'occupe pas l'ecran) : contour seul, icone
        // agrandir, mot « Agrandir ».
        final BoxDecoration repos = _decoration(tester, cle);
        expect(repos.color, isNull, reason: 'contour seul');
        expect(repos.border, isNotNull);
        expect(_icone(tester, cle), AppIcons.agrandir.repos);
        expect(
          find.descendant(
            of: find.byKey(cle),
            matching: find.text(t.salle.seance.agrandir),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(
          hoteCapture(monter(agrandi: true), themeMode: luminosite),
        );
        await tester.pump();
        // Actif : disque plein de contraste, icone reduire, mot « Reduire ».
        final BoxDecoration plein = _decoration(tester, cle);
        expect(plein.color, palette.surfaceInverse.background);
        expect(plein.border, isNull);
        expect(_icone(tester, cle), AppIcons.reduire.repos);
        expect(
          find.descendant(
            of: find.byKey(cle),
            matching: find.text(t.salle.seance.reduire),
          ),
          findsOneWidget,
        );
        expect(plein.color, isNot(repos.color));
        expect(plein.border, isNot(repos.border));
      });
    }
  });

  // TB-2 (VIS-01) : Agrandir a quitte la barre de l'appel ; seule sa sortie
  // « Reduire » y reste tant que le focus local est actif, avec les trois
  // signaux de la bascule active.
  for (final ThemeMode luminosite in const <ThemeMode>[
    ThemeMode.light,
    ThemeMode.dark,
  ]) {
    testWidgets('dock de la seance, ${luminosite.name} : Reduire seulement '
        'quand le support occupe l\'ecran', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(_dock(agrandi: false), themeMode: luminosite),
      );
      await tester.pump();
      expect(find.byKey(_dockCle), findsNothing);
      await tester.pumpWidget(
        hoteCapture(_dock(agrandi: true), themeMode: luminosite),
      );
      await tester.pump();
      final AppPalette palette = AppPalette.of(
        tester.element(find.byKey(_dockCle)),
      );
      final BoxDecoration plein = _decoration(tester, _dockCle);
      expect(plein.color, palette.surfaceInverse.background);
      expect(plein.border, isNull);
      expect(_icone(tester, _dockCle), AppIcons.reduire.repos);
      expect(
        find.descendant(
          of: find.byKey(_dockCle),
          matching: find.text(t.salle.seance.reduire),
        ),
        findsOneWidget,
      );
    });
  }
}
