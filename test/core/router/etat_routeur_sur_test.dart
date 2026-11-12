// GOROUTERSTATE-SUR (garde-cap, 12/11/2026) : la lecture de l'etat du routeur
// ne gele jamais, meme dans une feuille du bas ou dans une page poussee par
// `Navigator.push` au-dessus d'un onglet de la coquille ; et aucun autre appel
// de `GoRouterState.of` n'existe dans lib/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/etat_routeur_sur.dart';

/// Ce que le widget sonde a lu.
final List<String?> _lu = <String?>[];

class _Sonde extends StatelessWidget {
  const _Sonde();

  @override
  Widget build(BuildContext context) {
    _lu.add(parametreRouteurSur(context, 'pour'));
    return Text('sonde ${adresseRouteurSur(context)?.path}');
  }
}

GoRouter _routeur() => GoRouter(
  initialLocation: '/onglet/page?pour=parent',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext _,
        GoRouterState _,
        StatefulNavigationShell coquille,
      ) => Scaffold(body: coquille),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/onglet/page',
              builder: (BuildContext _, GoRouterState _) => const _Page(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/autre',
              builder: (BuildContext _, GoRouterState _) => const Text('autre'),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      const _Sonde(),
      Builder(
        builder: (BuildContext c) => GestureDetector(
          key: const ValueKey<String>('feuille'),
          onTapUp: (_) => showModalBottomSheet<void>(
            context: c,
            builder: (BuildContext _) => const _Sonde(),
          ),
          child: const Text('ouvrir la feuille'),
        ),
      ),
      Builder(
        builder: (BuildContext c) => GestureDetector(
          key: const ValueKey<String>('pousser'),
          onTapUp: (_) => Navigator.of(c).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const Scaffold(body: _Sonde()),
            ),
          ),
          child: const Text('pousser une page'),
        ),
      ),
    ],
  );
}

void main() {
  setUp(_lu.clear);

  testWidgets('page du routeur : l etat de la page, par GoRouterState', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _routeur()));
    await tester.pumpAndSettle();
    expect(_lu.last, 'parent');
    expect(find.text('sonde /onglet/page'), findsOneWidget);
  });

  testWidgets('feuille du bas au-dessus d un onglet : aucun gel, l etat de la '
      'page du dessous', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _routeur()));
    await tester.pumpAndSettle();
    _lu.clear();
    await tester.tap(find.byKey(const ValueKey<String>('feuille')));
    await tester.pumpAndSettle();
    // La sonde de la feuille : une route qui n'est pas une page du routeur.
    final BuildContext dansLaFeuille = tester.element(find.byType(_Sonde).last);
    expect(ModalRoute.of(dansLaFeuille)?.settings, isNot(isA<Page<Object?>>()));
    expect(_lu, contains('parent'));
    expect(find.text('sonde /onglet/page'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaterialPageRoute poussee au-dessus d un onglet : aucun gel '
      '(la forme exacte de CRASH-MON-ESPACE)', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _routeur()));
    await tester.pumpAndSettle();
    _lu.clear();
    await tester.tap(find.byKey(const ValueKey<String>('pousser')));
    await tester.pumpAndSettle();
    final BuildContext poussee = tester.element(find.byType(_Sonde).last);
    expect(ModalRoute.of(poussee)?.settings, isNot(isA<Page<Object?>>()));
    // La condition de la boucle de go_router : depuis le contexte du
    // navigateur de l'onglet, `Navigator.maybeOf` rend ce MEME navigateur.
    final NavigatorState onglet = Navigator.of(poussee);
    expect(Navigator.maybeOf(onglet.context), same(onglet));
    expect(_lu, contains('parent'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans routeur : null', (WidgetTester tester) async {
    late BuildContext contexte;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext c) {
            contexte = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(etatRouteurSur(contexte), isNull);
    expect(parametreRouteurSur(contexte, 'x'), isNull);
  });

  test('garde : aucun GoRouterState.of dans lib/ hors de etat_routeur_sur', () {
    final List<String> fautes = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String chemin = f.path.replaceAll(r'\', '/');
      if (chemin.endsWith('core/router/etat_routeur_sur.dart')) continue;
      final List<String> lignes = f.readAsLinesSync();
      for (int i = 0; i < lignes.length; i++) {
        final String ligne = lignes[i];
        if (ligne.trimLeft().startsWith('//')) continue;
        if (ligne.contains('GoRouterState.of(')) {
          fautes.add('$chemin:${i + 1}');
        }
      }
    }
    expect(
      fautes,
      isEmpty,
      reason:
          'GoRouterState.of peut boucler sans fin (go_router 18) : passer par '
          'etatRouteurSur (lib/core/router/etat_routeur_sur.dart).\n'
          '${fautes.join('\n')}',
    );
  });
}
