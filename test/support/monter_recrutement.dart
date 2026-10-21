// L'hote commun des tests du recrutement (RECRUT-ECRANS) : un ecran dans un
// routeur minimal, dont les destinations sont des temoins.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';

import 'harnais.dart';

/// Une destination qui ne dit que son nom.
GoRoute temoin(String chemin) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) =>
      Scaffold(body: Text('temoin:$chemin')),
);

/// Monte [chemin] (servi par [ecran]) avec les destinations [autres].
Future<void> monterRecrutement(
  WidgetTester tester, {
  required String chemin,
  required Widget Function(GoRouterState) ecran,
  List<String> autres = const <String>[],
  List<Override> surcharges = const <Override>[],
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
  String? depart,
}) async {
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart ?? chemin,
      echelle: echelle,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: chemin,
          builder: (BuildContext _, GoRouterState etat) => ecran(etat),
        ),
        for (final String a in autres) temoin(a),
      ],
      surcharges: <Override>[
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
        ...surcharges,
      ],
    ),
  );
  await laisser(tester);
}

/// Laisse passer les futurs en memoire et les animations courtes.
Future<void> laisser(WidgetTester tester, {int fois = 8}) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
