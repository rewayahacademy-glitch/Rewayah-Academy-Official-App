import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/garde_sortie_salle.dart';

// Point 4 (consigne du pilote du 30/10/2026) : le retour du telephone ou du
// navigateur ne quitte plus la salle tant qu'elle retient la route.

GoRouter _routeur() => GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext _, GoRouterState _) => const Text('accueil'),
    ),
    GoRoute(
      path: '/salle',
      onExit: GardeSortieSalle.instance.autoriserSortie,
      builder: (BuildContext _, GoRouterState _) => const Text('salle'),
    ),
  ],
);

void main() {
  testWidgets('sans salle inscrite, le retour part comme avant', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = _routeur();
    addTearDown(routeur.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
    unawaited(routeur.push('/salle'));
    await tester.pumpAndSettle();
    expect(find.text('salle'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('accueil'), findsOneWidget);
  });

  testWidgets('la salle inscrite retient le retour du systeme et celui du '
      'navigateur, puis laisse partir quand elle le dit', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = _routeur();
    addTearDown(routeur.dispose);
    int questions = 0;
    bool laisserPartir = false;
    Future<bool> demande() async {
      questions++;
      return laisserPartir;
    }

    GardeSortieSalle.instance.inscrire(demande);
    addTearDown(() => GardeSortieSalle.instance.retirer(demande));
    await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
    routeur.go('/salle');
    await tester.pumpAndSettle();
    expect(find.text('salle'), findsOneWidget);

    // Le geste ou le bouton retour d'Android.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('salle'), findsOneWidget);
    expect(questions, 1);

    // Le bouton retour du navigateur : l'adresse precedente revient.
    await tester.binding.handlePushRoute('/');
    await tester.pumpAndSettle();
    expect(find.text('salle'), findsOneWidget);
    expect(questions, 2);

    laisserPartir = true;
    await tester.binding.handlePushRoute('/');
    await tester.pumpAndSettle();
    expect(find.text('accueil'), findsOneWidget);
    expect(questions, 3);
  });

  testWidgets('une salle retiree ne retient plus rien, meme si une autre '
      'avait ete inscrite avant elle', (WidgetTester tester) async {
    final GoRouter routeur = _routeur();
    addTearDown(routeur.dispose);
    Future<bool> ancienne() async => false;
    Future<bool> courante() async => false;
    GardeSortieSalle.instance.inscrire(ancienne);
    GardeSortieSalle.instance.inscrire(courante);
    // L'ancienne salle se demonte apres : elle ne retire pas la courante.
    GardeSortieSalle.instance.retirer(ancienne);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
    routeur.go('/salle');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('salle'), findsOneWidget);

    GardeSortieSalle.instance.retirer(courante);
    await tester.binding.handlePushRoute('/');
    await tester.pumpAndSettle();
    expect(find.text('accueil'), findsOneWidget);
  });
}
