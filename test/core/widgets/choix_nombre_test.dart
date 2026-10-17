// Le choix pas a pas (decision du directeur du 17/10/2026 : tout ce qui peut
// se choisir se choisit, jamais au clavier ; passation point 10).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';

import '../../support/harnais.dart';

Future<List<int>> _monter(
  WidgetTester tester, {
  required int valeur,
  int min = 0,
  int? max,
  double echelle = 1,
  Size taille = const Size(320, 640),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<int> recus = <int>[];
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChoixNombre(
              libelle: 'Ordre',
              valeur: valeur,
              min: min,
              max: max,
              libelleMoins: 'Diminuer l ordre de 1',
              libellePlus: 'Augmenter l ordre de 1',
              onChange: recus.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return recus;
}

void main() {
  testWidgets('moins et plus rendent la valeur voisine, sans clavier', (
    WidgetTester tester,
  ) async {
    final List<int> recus = await _monter(tester, valeur: 3);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(ChoixNombre.clePlus));
    await tester.tap(find.byKey(ChoixNombre.cleMoins));
    expect(recus, <int>[4, 2]);
  });

  testWidgets('aux bornes, le bouton qui en sortirait n existe pas', (
    WidgetTester tester,
  ) async {
    await _monter(tester, valeur: 0, max: 2);
    expect(find.byKey(ChoixNombre.cleMoins), findsNothing);
    expect(find.byKey(ChoixNombre.clePlus), findsOneWidget);
    await _monter(tester, valeur: 2, max: 2);
    expect(find.byKey(ChoixNombre.clePlus), findsNothing);
    expect(find.byKey(ChoixNombre.cleMoins), findsOneWidget);
  });

  testWidgets('la valeur garde sa place quand un bouton disparait', (
    WidgetTester tester,
  ) async {
    await _monter(tester, valeur: 1, max: 2);
    final double centre = tester
        .getCenter(find.byKey(ChoixNombre.cleValeur))
        .dx;
    await _monter(tester, valeur: 2, max: 2);
    expect(tester.getCenter(find.byKey(ChoixNombre.cleValeur)).dx, centre);
  });

  testWidgets('les boutons se nomment pour le lecteur d ecran', (
    WidgetTester tester,
  ) async {
    await _monter(tester, valeur: 3);
    expect(find.bySemanticsLabel('Diminuer l ordre de 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Augmenter l ordre de 1'), findsOneWidget);
  });

  testWidgets('320 px, texte x2 : rien ne deborde', (
    WidgetTester tester,
  ) async {
    await _monter(tester, valeur: 12, echelle: 2);
    expect(tester.takeException(), isNull);
  });
}
