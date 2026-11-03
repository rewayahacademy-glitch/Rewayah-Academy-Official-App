// Lot O1 (02/11/2026) : « Regarder la salle » dans le planning de la
// direction. Propose seulement a qui a la capacite d'observer en direction,
// et seulement pendant la seance (un geste qui ne peut pas aboutir n'est pas
// rendu) ; il ouvre la porte d'observation de la seance.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';

import 'session_direction.dart';

final DateTime _maintenant = DateTime.now();

List<SeancePlanning> _seances() => <SeancePlanning>[
  SeancePlanning(
    id: 's-direct',
    classe: 'Alif',
    debut: _maintenant.subtract(const Duration(minutes: 10)),
    dureeMinutes: 60,
    statut: StatutSeance.enCours,
    enseignant: 'Titulaire A',
  ),
  SeancePlanning(
    id: 's-futur',
    classe: 'Ba',
    debut: _maintenant.add(const Duration(hours: 3)),
    dureeMinutes: 60,
    statut: StatutSeance.planifiee,
    enseignant: 'Titulaire A',
  ),
];

class _Planning implements PortPlanningDirection {
  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async => _seances();
}

Future<List<String>> _monter(WidgetTester tester, AppRole role) async {
  tester.view.physicalSize = const Size(1440, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<String> ouvertes = <String>[];
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) =>
            PlanningPage(semaineInitiale: lundiDe(_maintenant)),
      ),
      GoRoute(
        path: RoutesTcG.observation,
        builder: (BuildContext _, GoRouterState etat) {
          ouvertes.add(etat.uri.path);
          return const SizedBox.shrink();
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portPlanningDirectionProvider.overrideWithValue(_Planning()),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        sessionProvider.overrideWith(() => SessionPlanning(role)),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return ouvertes;
}

String _libelle(String classe) => t.admin.planning.o1.regarder(
  deClasse: deDevant(classe, cle: 'admin.planning.o1.regarder'),
);

void main() {
  testWidgets('la direction regarde la salle d\'une seance en direct', (
    WidgetTester tester,
  ) async {
    final List<String> ouvertes = await _monter(tester, AppRole.admin);
    final Finder menu = find.bySemanticsLabel(
      t.commun.listes.actionsDe(objet: 'Alif'),
    );
    expect(menu, findsOneWidget);
    // La seance a venir n'a aucun geste : pas de menu du tout.
    expect(
      find.bySemanticsLabel(t.commun.listes.actionsDe(objet: 'Ba')),
      findsNothing,
    );
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text(_libelle('Alif')), findsOneWidget);
    await tester.tap(find.text(_libelle('Alif')));
    await tester.pumpAndSettle();
    expect(ouvertes, <String>[RoutesTcG.versObservation('s-direct')]);
  });

  testWidgets('sans la capacite d\'observer en direction, aucun geste', (
    WidgetTester tester,
  ) async {
    await _monter(tester, AppRole.accountant);
    expect(
      find.bySemanticsLabel(t.commun.listes.actionsDe(objet: 'Alif')),
      findsNothing,
    );
  });
}
