// PERSONNES-UNE-PAGE, etape (f) : le retour du bureau, quand une page est
// empilee. Dans un navigateur, la fleche recule dans l'historique (le routeur
// retire alors la page) ; ailleurs, la page est retiree directement. Sans
// page empilee, rien ne change : le parent logique.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/retour_bureau.dart';

Future<GoRouter> _monter(WidgetTester tester) async {
  final GoRouter routeur = GoRouter(
    initialLocation: '/admin/liste',
    routes: <RouteBase>[
      GoRoute(
        path: '/admin',
        builder: (BuildContext _, GoRouterState _) => const Text('accueil'),
      ),
      GoRoute(
        path: '/admin/liste',
        builder: (BuildContext _, GoRouterState _) => const Text('liste'),
      ),
      GoRoute(
        path: '/admin/detail',
        builder: (BuildContext contexte, GoRouterState _) => TextButton(
          onPressed: () => retourBureau(contexte),
          child: const Text('retour'),
        ),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
  unawaited(routeur.push<void>('/admin/detail'));
  await tester.pumpAndSettle();
  return routeur;
}

void unawaited(Future<void> _) {}

void main() {
  final bool Function() origine = reculerHistorique;
  tearDown(() => reculerHistorique = origine);

  testWidgets('hors du web : la page empilee est retiree', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.tap(find.text('retour'));
    await tester.pumpAndSettle();
    expect(find.text('liste'), findsOneWidget);
    expect(find.text('retour'), findsNothing);
  });

  testWidgets('dans un navigateur : la fleche recule dans l\'historique, et '
      'ne retire pas la page elle-meme', (WidgetTester tester) async {
    int reculs = 0;
    reculerHistorique = () {
      reculs++;
      return true;
    };
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.text('retour'));
    await tester.pumpAndSettle();
    // Le navigateur, ici absent, aurait retire la page : elle est encore la.
    expect(reculs, 1);
    expect(routeur.canPop(), isTrue);
  });

  testWidgets('le navigateur refuse : la page est retiree quand meme', (
    WidgetTester tester,
  ) async {
    reculerHistorique = () => false;
    await _monter(tester);
    await tester.tap(find.text('retour'));
    await tester.pumpAndSettle();
    expect(find.text('liste'), findsOneWidget);
  });
}
