// CORRECTIF-BARRE (directeur, 11/11/2026) : la meme regle que pour la
// feuille du bas, pour le lecteur du Coran en Mode Accessibilite
// (`CommandesMasquables(effacerBarreBasse: true)`). Commandes masquees, la
// barre s'efface ; l'onglet quitte sans fermer le lecteur, la barre revient
// dans l'autre onglet ; au retour, elle s'efface de nouveau ; les commandes
// revenues, la barre revient.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../support/harnais.dart';

GoRouter _routeur() => GoRouter(
  initialLocation: '/a',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell coquille,
          ) => NavShell(
            destinations: destinationsPour(
              role: AppRole.teacher,
              mode: InterfaceMode.standard,
            ),
            indexActif: coquille.currentIndex,
            onAller: (String _) {},
            child: coquille,
          ),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/a',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(
                    body: CommandesMasquables(
                      effacerBarreBasse: true,
                      delai: Duration(seconds: 1),
                      contenu: SizedBox.expand(child: Text('Lecteur')),
                      commandes: SizedBox(height: 48, child: Text('Commandes')),
                    ),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/b',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Onglet B')),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('le lecteur du Coran laisse dans un onglet quitte ne retire '
      'pas la barre des autres onglets', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GoRouter routeur = _routeur();
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sansPersonneConnectee()],
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            routerConfig: routeur,
          ),
        ),
      ),
    );
    final Finder barre = find.byKey(NavShell.barreBasseKey);
    await tester.pump();
    expect(barre, findsOneWidget);

    // 1. Les commandes se masquent apres le delai : la barre s'efface.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(barre, findsNothing);

    // 2. On quitte l'onglet sans fermer le lecteur : la barre revient.
    routeur.go('/b');
    await tester.pumpAndSettle();
    expect(find.text('Onglet B'), findsOneWidget);
    expect(barre, findsOneWidget);
    expect(find.text('Lecteur', skipOffstage: false), findsOneWidget);

    // 3. Retour sur le lecteur, commandes toujours masquees : la barre
    //    s'efface de nouveau.
    routeur.go('/a');
    await tester.pumpAndSettle();
    expect(find.text('Lecteur'), findsOneWidget);
    expect(barre, findsNothing);

    // 4. Une touche ramene les commandes : la barre revient.
    await tester.tap(find.text('Lecteur'));
    await tester.pumpAndSettle();
    expect(barre, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
