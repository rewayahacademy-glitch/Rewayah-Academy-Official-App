// CORRECTIF-BARRE (directeur, 11/11/2026, production, enseignant au
// telephone : « la barre disparait sans raison et on est oblige de fermer
// l'app »). Une feuille du bas ouverte dans un onglet, puis l'onglet quitte
// sans fermer la feuille (retour, lien, notification) : la feuille reste
// montee hors scene dans la pile indexee des onglets. La barre doit revenir
// dans l'autre onglet, s'effacer de nouveau au retour sur la feuille, et
// revenir quand la feuille se ferme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../support/harnais.dart';

const Key _ouvrir = Key('ouvrir-feuille');

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
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                body: Builder(
                  builder: (BuildContext contexte) => TextButton(
                    key: _ouvrir,
                    onPressed: () => AppBottomSheet.ouvrir<void>(
                      contexte,
                      titre: 'Feuille',
                      constructeur: (BuildContext _) =>
                          const SizedBox(height: 80),
                    ),
                    child: const Text('Ouvrir'),
                  ),
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
  testWidgets('une feuille laissee dans un onglet quitte ne retire pas la '
      'barre des autres onglets', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();
    final Finder barre = find.byKey(NavShell.barreBasseKey);
    expect(barre, findsOneWidget);

    // 1. La feuille s'ouvre sur /a : la barre s'efface.
    await tester.tap(find.byKey(_ouvrir));
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    expect(barre, findsNothing);

    // 2. On quitte l'onglet sans fermer la feuille : la barre revient, la
    //    feuille reste montee hors scene.
    routeur.go('/b');
    await tester.pumpAndSettle();
    expect(find.text('Onglet B'), findsOneWidget);
    expect(barre, findsOneWidget);
    expect(find.text('Feuille'), findsNothing);
    expect(find.text('Feuille', skipOffstage: false), findsOneWidget);

    // 3. Retour sur /a : la feuille est la, la barre s'efface.
    routeur.go('/a');
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsOneWidget);
    expect(barre, findsNothing);

    // 4. La feuille se ferme : la barre revient.
    Navigator.of(tester.element(find.text('Feuille'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Feuille'), findsNothing);
    expect(barre, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
