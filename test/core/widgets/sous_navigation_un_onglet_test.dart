// PORTS-COMPTABLE (garde-cap, 11/11/2026) : une sous-navigation reduite a un
// seul onglet n'est pas montree ; a deux onglets ou plus, elle l'est. Le
// selecteur de section garde son assertion (au moins deux sections) : la
// sous-navigation ne lui passe jamais moins de deux onglets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../../support/harnais.dart';

const List<({String libelle, String chemin})> _deux =
    <({String libelle, String chemin})>[
      (libelle: 'Paiements à effectuer', chemin: '/a'),
      (libelle: 'Contractuels', chemin: '/b'),
    ];

void main() {
  testWidgets('un seul onglet : aucune barre', (WidgetTester tester) async {
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: SousNavigationDomaine(
            onglets: _deux.sublist(0, 1),
            indexActif: 0,
          ),
        ),
      ),
    );
    expect(find.byType(SelecteurSection<int>), findsNothing);
    expect(find.text('Paiements à effectuer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deux onglets : la barre est montree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: SousNavigationDomaine(onglets: _deux, indexActif: 0),
        ),
      ),
    );
    expect(find.byType(SelecteurSection<int>), findsOneWidget);
    expect(find.text('Contractuels'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('depuis une liste filtree a un onglet : aucune barre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: SousNavigationDomaine.depuis((
            onglets: _deux.sublist(0, 1),
            indexActif: 0,
          )),
        ),
      ),
    );
    expect(find.byType(SelecteurSection<int>), findsNothing);
  });
}
