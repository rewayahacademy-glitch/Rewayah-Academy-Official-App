// Selection du texte et routes hors ecran (directeur, 07/11/2026) : une route
// que le `Navigator` garde construite sous une page opaque est hors ecran et
// n'est parfois jamais mise en page. Ses textes ne doivent ni lever
// l'assertion `hasSize` du tri des selectionnables (constatee sur le detail
// d'un dossier de la direction, `entrees_admin_test`), ni etre copies par
// « Tout selectionner ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/go_route_sure.dart';
import 'package:rewayah_academy/core/widgets/selection_racine.dart';
import 'package:rewayah_academy/core/widgets/selection_si_visible.dart';

import '../../support/hote_selection.dart';

Widget _entrees({required bool sure}) => SizedBox(
  height: 200,
  child: Overlay(
    initialEntries: <OverlayEntry>[
      // Dessous, gardee construite, recouverte des la premiere image : jamais
      // mise en page.
      OverlayEntry(
        maintainState: true,
        builder: (BuildContext _) {
          final Widget page = Transform.scale(
            scale: 0.5,
            child: const Text('cache'),
          );
          return sure ? SelectionSiVisible(child: page) : page;
        },
      ),
      OverlayEntry(
        opaque: true,
        builder: (BuildContext _) => const Text('visible'),
      ),
    ],
  ),
);

void main() {
  testWidgets('avec SelectionSiVisible : aucune erreur, le texte masque n\'est '
      'pas copie', (WidgetTester tester) async {
    await tester.pumpWidget(hoteSelection(_entrees(sure: true)));
    await tester.pump();
    final String copie = await toutCopier(tester);
    expect(tester.takeException(), isNull);
    expect(copie, contains('visible'));
    expect(copie, isNot(contains('cache')));
  });

  testWidgets('GoRouteSure : deux pages empilees dans la meme image, seule la '
      'page visible se copie', (WidgetTester tester) async {
    final GoRouter routeur = GoRouter(
      routes: <RouteBase>[
        GoRouteSure(
          path: '/',
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('accueil')),
          routes: <RouteBase>[
            GoRouteSure(
              path: 'dossier',
              builder: (BuildContext _, GoRouterState _) => Scaffold(
                body: const Text('dossier'),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            GoRouteSure(
              path: 'messages',
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('messages')),
            ),
          ],
        ),
      ],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: routeur,
        builder: (BuildContext _, Widget? app) => SelectionRacine(child: app!),
      ),
    );
    await tester.pump();
    unawaited(routeur.push<void>('/dossier'));
    unawaited(routeur.push<void>('/messages'));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final String copie = await toutCopier(tester);
    expect(tester.takeException(), isNull);
    expect(copie, contains('messages'));
    expect(copie, isNot(contains('dossier')));
  });

  testWidgets('StatefulShellRoute : « Tout selectionner » sur l\'onglet '
      'Accueil ne copie rien de l\'onglet Foyer (branche cachee)', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = GoRouter(
      initialLocation: '/accueil',
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder:
              (BuildContext _, GoRouterState _, StatefulNavigationShell n) =>
                  Scaffold(
                    body: n,
                    bottomNavigationBar: BottomNavigationBar(
                      currentIndex: n.currentIndex,
                      onTap: n.goBranch,
                      items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'onglet-accueil',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.group),
                          label: 'onglet-foyer',
                        ),
                      ],
                    ),
                  ),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteSure(
                  path: '/accueil',
                  builder: (BuildContext _, GoRouterState _) =>
                      const Text('contenu-accueil'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteSure(
                  path: '/foyer',
                  builder: (BuildContext _, GoRouterState _) =>
                      const Text('contenu-foyer'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: routeur,
        builder: (BuildContext _, Widget? app) => SelectionRacine(child: app!),
      ),
    );
    await tester.pump();
    // Visite Foyer, puis revient : la branche Foyer reste construite, cachee.
    await tester.tap(find.text('onglet-foyer'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('onglet-accueil'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('contenu-foyer', skipOffstage: false),
      findsOneWidget,
      reason: 'la branche cachee est bien construite',
    );
    final String copie = await toutCopier(tester);
    expect(tester.takeException(), isNull);
    expect(copie, contains('contenu-accueil'));
    expect(copie, isNot(contains('contenu-foyer')));
  });
}
