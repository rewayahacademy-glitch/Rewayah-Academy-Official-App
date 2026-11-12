// CRASH-MON-ESPACE (12/11/2026) : une page poussee hors du routeur
// (`Navigator.push` d'une `MaterialPageRoute`) dans une branche de coquille,
// sous le plan du fil d'Ariane, faisait boucler `GoRouterState.of`
// (go_router 18.0.1) sans fin : l'application gelait. Sans le correctif de
// `positionDansLaPile`, ce test ne finit pas (le fil principal ne rend jamais
// la main) ; avec, la sous-page s'affiche. Pour le plan de chaque role.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

SessionState _session(AppRole role, {bool autonome = false}) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: AccountStatus.active,
  eleveAutonome: autonome,
  lectureProfil: LectureProfil.presente,
);

GoRouter _routeur() => GoRouter(
  initialLocation: '/compte',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext _,
        GoRouterState _,
        StatefulNavigationShell coquille,
      ) => coquille,
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/compte',
              builder: (BuildContext _, GoRouterState _) => Builder(
                builder: (BuildContext contexte) => PageShell(
                  titre: 'Compte',
                  child: TextButton(
                    onPressed: () => Navigator.of(contexte).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => const PageShell(
                          titre: 'Sous-page',
                          child: Text('corps de la sous-page'),
                        ),
                      ),
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (String nom, SessionState session) in <(String, SessionState)>[
    ('enseignant', _session(AppRole.teacher)),
    ('tuteur', _session(AppRole.guardian)),
    ('adulte', _session(AppRole.guardian, autonome: true)),
    ('direction', _session(AppRole.admin)),
  ]) {
    testWidgets('$nom : une sous-page poussee par Navigator.push s affiche '
        'sans geler', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = _routeur();
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext _, Widget? rendu) => ContexteFilAriane(
                plan: planFilPour(session),
                child: rendu ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('corps de la sous-page'), findsOneWidget);
    });
  }
}
