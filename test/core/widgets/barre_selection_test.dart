// La barre de selection promue du Comptable vers le core (ADM-20). Ce que le
// test prouve :
// - elle dit combien de lignes sont retenues et pourquoi l'action est la ou
//   n'est pas la, avec les textes de l'ecran (aucun libelle propre) ;
// - « Tout relacher » est discret, l'action de la selection est le seul bouton
//   plein ; sans action, il n'y en a aucun et rien n'est grise (K-56) ;
// - un complement (l'export du Comptable) se pose entre la phrase et les
//   boutons ;
// - 320 px, texte x2, clair et sombre : rien ne deborde.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';

import '../../support/garde_interface.dart';
import '../../support/hote_theme.dart';

Widget _barre({
  VoidCallback? onAction,
  VoidCallback? onRelacher,
  Widget? avant,
}) => BarreSelection(
  titre: '3 candidatures retenues',
  phrase: 'Choisissez l\'action à lancer.',
  libelleRelacher: 'Tout relâcher',
  onRelacher: onRelacher ?? () {},
  libelleAction: 'Agir sur la sélection',
  onAction: onAction,
  avantActions: avant,
);

int _pleins() => find
    .byWidgetPredicate(
      (Widget w) =>
          w is ActionPrincipale && w.niveau == NiveauAction.principale,
    )
    .evaluate()
    .length;

void main() {
  testWidgets('titre, phrase et deux gestes : un seul bouton plein', (
    tester,
  ) async {
    fixerVue(tester, vueMobile);
    int agi = 0;
    int relache = 0;
    await tester.pumpWidget(
      hoteTheme(_barre(onAction: () => agi++, onRelacher: () => relache++)),
    );
    expect(find.text('3 candidatures retenues'), findsOneWidget);
    expect(find.text('Choisissez l\'action à lancer.'), findsOneWidget);
    expect(_pleins(), 1);
    verifierUnSeulBoutonPlein(tester);
    await tester.tap(find.byKey(BarreSelection.cleAction));
    await tester.tap(find.byKey(BarreSelection.cleRelacher));
    expect(agi, 1);
    expect(relache, 1);
  });

  testWidgets('sans action : elle n\'est pas rendue, jamais grisee', (
    tester,
  ) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(_barre()));
    expect(find.byKey(BarreSelection.cleAction), findsNothing);
    expect(find.text('Agir sur la sélection'), findsNothing);
    expect(_pleins(), 0);
    expect(find.byKey(BarreSelection.cleRelacher), findsOneWidget);
  });

  testWidgets('un complement se pose avant les boutons', (tester) async {
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(
      hoteTheme(
        _barre(onAction: () {}, avant: const Text('Exporter la sélection')),
      ),
    );
    final double complement = tester
        .getTopLeft(find.text('Exporter la sélection'))
        .dy;
    final double bouton = tester
        .getTopLeft(find.byKey(BarreSelection.cleAction))
        .dy;
    expect(complement, lessThan(bouton));
  });

  for (final Brightness luminosite in Brightness.values) {
    testWidgets('320 px, texte x2, $luminosite : rien ne deborde', (
      tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          _barre(onAction: () {}),
          echelleTexte: 2,
          luminosite: luminosite,
        ),
      );
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester);
    });
  }
}
