import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';

import '../../support/harnais.dart';

/// `DataCollection` en tableau dense : l'etat `selected` n'existe que pour un
/// tableau qui a une selection (`estSelectionnee`). Les autres tableaux
/// (journal, comptes, observations) ne doivent pas faire entendre « non
/// selectionne » sur chacune de leurs lignes.
void _fenetreBureau(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const List<String> _lignes = <String>['Alif', 'Ba'];

final List<ColonneDonnees<String>> _colonnes = <ColonneDonnees<String>>[
  ColonneDonnees<String>(
    titre: 'Nom',
    texte: (String l) => l,
    role: RoleColonne.identifiante,
  ),
];

Iterable<Semantics> _semantiquesDeSelection(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .where((Semantics s) => s.properties.selected != null);

/// Les noeuds de l'arbre semantique qui portent un etat de selection.
int _noeudsAvecEtatDeSelection(WidgetTester tester) {
  int n = 0;
  void parcourir(SemanticsNode noeud) {
    // ignore: deprecated_member_use
    if (noeud.getSemanticsData().hasFlag(SemanticsFlag.hasSelectedState)) n++;
    noeud.visitChildren((SemanticsNode enfant) {
      parcourir(enfant);
      return true;
    });
  }

  parcourir(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return n;
}

void main() {
  testWidgets('tableau sans estSelectionnee : aucune ligne n\'a d\'etat de '
      'selection', (WidgetTester tester) async {
    _fenetreBureau(tester);
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: DataCollection<String>(colonnes: _colonnes, lignes: _lignes),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alif'), findsOneWidget);
    expect(_semantiquesDeSelection(tester), isEmpty);
    expect(_noeudsAvecEtatDeSelection(tester), 0);
    semantique.dispose();
  });

  testWidgets('tableau avec estSelectionnee : chaque ligne dit son etat', (
    WidgetTester tester,
  ) async {
    _fenetreBureau(tester);
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: DataCollection<String>(
            colonnes: _colonnes,
            lignes: _lignes,
            estSelectionnee: (String l) => l == 'Ba',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final List<bool?> etats = _semantiquesDeSelection(tester)
        .map((Semantics s) => s.properties.selected)
        .toList();
    expect(etats, <bool?>[false, true]);
    expect(_noeudsAvecEtatDeSelection(tester), 2);
    semantique.dispose();
  });
}
