// D10 (24/10/2026, decision du pilote deleguee par le directeur) : apres
// « Quitter la reunion », tant que la seance n'est pas close, l'enseignant
// retourne dans la salle depuis la fin de seance (CLV-10) et depuis le cahier,
// avec une base locale saine comme en panne (le web avant D7).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/harnais.dart';

const String _seance = 's1';

void _rien() {}
void _aller(String _) {}

BrouillonCahier _brouillon(DateTime debut) => BrouillonCahier(
  seanceId: _seance,
  debut: debut,
  fin: debut.add(const Duration(minutes: 45)),
  statut: StatutSeance.planifiee,
  dureeMinutes: 45,
  minutesInterruption: 0,
  dejaDepose: false,
  participants: const <ParticipantBrouillon>[],
  evenements: const <EvenementSeance>[],
);

/// Le cahier de la seance, sur un vrai routeur : `/salle` note le billet recu.
Future<List<BilletSalle?>> _monterCahier(
  WidgetTester tester, {
  required DateTime debut,
  required bool baseEnPanne,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<BilletSalle?> billets = <BilletSalle?>[];
  final FauxServiceEnseignant service = FauxServiceEnseignant()
    ..brouillonRendu = _brouillon(debut)
    ..seancesRendues = <SeanceEnseignant>[
      seanceDeTest(debut: debut, groupeId: 'g1', groupeLibelle: 'Classe A'),
    ];
  final GoRouter routeur = GoRouter(
    initialLocation: '/cahier',
    routes: <RouteBase>[
      GoRoute(
        path: '/cahier',
        builder: (BuildContext _, GoRouterState _) =>
            const CahierPage(seanceId: _seance),
      ),
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState etat) {
          billets.add(etat.extra as BilletSalle?);
          return const Text('salle');
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceEnseignantProvider.overrideWithValue(service),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        if (baseEnPanne)
          // L'erreur exacte de drift sur le web sans ses options (D7).
          depotRapportsProvider.overrideWith(
            (Ref _) => throw ArgumentError(
              'When compiling to the web, the `web` parameter needs to be '
              'set.',
            ),
          )
        else
          depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return billets;
}

void main() {
  testWidgets('CLV-10 : « Retourner dans la salle » en haut, et il agit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int retours = 0;
    await tester.pumpWidget(
      hote(
        FinSeanceEnseignant(
          vue: DonneesSeanceDemo.vue(RoleSeance.enseignant, EtatDemoSalle.fin),
          actions: const ActionsSeance(
            onRetour: _rien,
            onNotifications: _rien,
            onReglages: _rien,
            onCompte: _rien,
            onNaviguer: _aller,
          ),
          onOuvrirCahier: _rien,
          onRevenirJournee: _rien,
          onRetournerSalle: () => retours++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder lien = find.byKey(FinSeanceEnseignant.retourSalleKey);
    expect(lien, findsOneWidget);
    expect(find.text(t.salle.retourner), findsOneWidget);
    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(retours, 1);
  });

  for (final bool panne in <bool>[false, true]) {
    testWidgets(
      'cahier, salle ouverte, base locale ${panne ? 'en panne' : 'saine'} : '
      '« Retourner dans la salle » mene a la salle avec son billet',
      (WidgetTester tester) async {
        final List<BilletSalle?> billets = await _monterCahier(
          tester,
          debut: DateTime.now().subtract(const Duration(minutes: 5)),
          baseEnPanne: panne,
        );
        final Finder lien = find.byKey(CahierPage.retourSalleKey);
        expect(lien, findsOneWidget);
        await tester.tap(lien);
        await tester.pumpAndSettle();
        expect(find.text('salle'), findsOneWidget);
        expect(billets.single?.sessionId, _seance);
        expect(billets.single?.groupeId, 'g1');
      },
    );
  }

  testWidgets('cahier, seance close : aucun lien vers la salle', (
    WidgetTester tester,
  ) async {
    await _monterCahier(
      tester,
      debut: DateTime.now().subtract(const Duration(hours: 3)),
      baseEnPanne: true,
    );
    expect(find.byKey(CahierPage.retourSalleKey), findsNothing);
  });
}
