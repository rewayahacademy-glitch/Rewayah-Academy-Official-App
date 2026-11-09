import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/features/tc_catalogue/bibliotheque_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

import 'faux/faux_ports_b.dart';
import 'support/hote_b.dart';

/// Le groupe effectivement recu par l'ecran, depuis l'adresse [depart].
Future<String?> groupeMonte(WidgetTester tester, String depart) async {
  fenetreTelephone(tester);
  await tester.pumpWidget(
    hoteRoutantB(
      depart: depart,
      routes: routesTcB(),
      surcharges: surchargesCatalogue(),
    ),
  );
  await tester.pumpAndSettle();
  return tester
      .widget<BibliothequePage>(find.byType(BibliothequePage))
      .groupeId;
}

void main() {
  test('routesTcB rend des routes, elle ne construit pas de routeur', () {
    final List<RouteBase> routes = routesTcB();
    expect(routes, hasLength(1));
    final GoRoute racine = routes.first as GoRoute;
    expect(racine.path, RoutesTcB.bibliotheque);
    expect(racine.routes, hasLength(1));
    expect(
      (racine.routes.first as GoRoute).path,
      ':${RoutesTcB.parametreRessource}',
    );
  });

  test('le groupe se compose en requete, jamais en segment de chemin', () {
    expect(RoutesTcB.avecGroupe('g1'), '/tc/bibliotheque?groupe=g1');
    // Un segment supplementaire entrerait en collision avec la fiche d'une
    // ressource : l'adresse composee doit rester celle de la Bibliotheque.
    expect(
      Uri.parse(RoutesTcB.avecGroupe('g1')).path,
      RoutesTcB.bibliotheque,
    );
    expect(
      Uri.parse(
        RoutesTcB.avecGroupe('g1'),
      ).queryParameters[RoutesTcB.parametreGroupe],
      'g1',
    );
  });

  test('un identifiant a caracteres reserves reste lisible apres composition', () {
    final String adresse = RoutesTcB.avecGroupe('a b&c');
    expect(adresse.contains(' '), isFalse);
    expect(
      Uri.parse(adresse).queryParameters[RoutesTcB.parametreGroupe],
      'a b&c',
    );
  });

  testWidgets('l adresse composee porte le groupe jusqu a l ecran', (
    WidgetTester tester,
  ) async {
    expect(await groupeMonte(tester, RoutesTcB.avecGroupe('g1')), 'g1');
  });

  testWidgets('sans requete, le groupe reste nul', (WidgetTester tester) async {
    expect(await groupeMonte(tester, RoutesTcB.bibliotheque), isNull);
  });

  testWidgets('une requete vide ou blanche vaut absence, pas identifiant vide', (
    WidgetTester tester,
  ) async {
    expect(await groupeMonte(tester, '/tc/bibliotheque?groupe='), isNull);
    expect(await groupeMonte(tester, '/tc/bibliotheque?groupe=%20%20'), isNull);
  });
}
