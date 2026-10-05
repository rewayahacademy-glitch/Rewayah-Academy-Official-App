// COM-ANN-1 (reponse du directeur a Q5, 04/10 ; UX_REV-08) : la cloche de la
// Classe live. Pour l'enseignant, elle ouvre le centre de notifications
// partage de son role (`/enseignant/notifications`), choisie par le role de
// la SEANCE, sans quitter la salle ; elle n'ouvre plus la feuille locale
// « pas encore disponibles ». Pour l'eleve, aucune cloche. Monte la VRAIE
// `ClasseLivePage` sur ordinateur, ou seul le coin complet porte la cloche.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/routes_tc_e.dart';

import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart';

ContexteClasseLive _contexte() => const ContexteClasseLive(
  sessionId: 's1',
  groupeId: 'g1',
  libelleGroupe: 'Classe Al-Fatiha',
  enseignant: EnseignantDeClasse(
    nomAffichage: 'Youssouf',
    titre: TitreEnseignant.sayyid,
    photoCleOuUrl: 'https://exemple.invalid/photo.jpg',
  ),
);

Future<GoRouter> _monter(WidgetTester tester, {required String role}) async {
  poserEcran(tester, LargeurEcran.desktop);
  final List<String> journal = <String>[];
  final GoRouter routeur = GoRouter(
    initialLocation: RoutesTcE.classe,
    routes: <RouteBase>[
      GoRoute(
        path: RoutesTcE.classe,
        builder: (BuildContext _, GoRouterState _) =>
            ClasseLivePage(contexte: _contexte()),
      ),
      GoRoute(
        path: Routes.enseignantNotifications,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('centre partage')),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesClasse(
        moteur: FauxMoteurClasse(journal: journal),
        video: FauxServiceVideoClasse(acces0: accesDe(role), journal: journal),
        preVol: FauxPreVolClasse(),
      ),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

void main() {
  testWidgets('enseignant, ordinateur : la cloche ouvre le centre partage de '
      'l enseignant, sans feuille locale', (WidgetTester tester) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final GoRouter routeur = await _monter(tester, role: 'teacher');
    final Finder cloche = find.byType(ClocheNotifications);
    expect(cloche, findsOneWidget);

    await tester.tap(cloche);
    await tester.pumpAndSettle();
    expect(
      routeur.routerDelegate.currentConfiguration.uri.path,
      Routes.enseignantNotifications,
    );
    expect(find.text('centre partage'), findsOneWidget);
    // L'ancienne feuille « pas encore disponibles » n'existe plus.
    expect(find.text(t.notifications.indisponibleTitre), findsNothing);
    semantique.dispose();
  });

  testWidgets('eleve, ordinateur : aucune cloche dans la salle', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: 'student');
    expect(find.byType(ClocheNotifications), findsNothing);
    // Le reste du coin demeure (reglages).
    expect(find.bySemanticsLabel(t.salle.seance.reglages), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
