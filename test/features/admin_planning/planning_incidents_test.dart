// DASH-ADM-PLANNING et DASH-ADM-INC : le planning de la direction et les
// incidents des 24 dernieres heures, sur port de demonstration.
//
// Ce que le test prouve :
// - le planning range les seances par jour, dit « Sans enseignant » quand il
//   manque, pose la pastille d'annulation ; aller d'une semaine a l'autre
//   relit le port avec le bon lundi et propose de revenir a la semaine en
//   cours ;
// - les incidents listent les seances que compte la tuile, plus recentes
//   d'abord ;
// - les 5 etats des deux pages : chargement, contenu, vide, erreur, hors
//   ligne (et port absent, « disponible au branchement serveur ») ;
// - 320 px, texte a 200 %, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_incidents_seances.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_journal/incidents_page.dart';
import 'package:rewayah_academy/features/admin_planning/planning_libelles.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';
import 'package:rewayah_academy/features/demo/planning_incidents_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

/// Un lundi connu : le 12 octobre 2026.
final DateTime _lundi = DateTime(2026, 10, 12);
final DateTime _maintenant = DateTime(2026, 10, 14, 12);

class _PlanningFictif implements PortPlanningDirection {
  _PlanningFictif({this.echec = false, this.attente});

  final bool echec;
  final Completer<void>? attente;
  final List<DateTime> demandes = <DateTime>[];

  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async {
    demandes.add(lundi);
    if (attente != null) await attente!.future;
    if (echec) throw StateError('hors portee');
    return PlanningDirectionDemo(maintenant: () => _maintenant).semaine(lundi);
  }
}

class _IncidentsFictif implements PortIncidentsSeances {
  _IncidentsFictif({this.echec = false, this.vide = false, this.attente});

  final bool echec;
  final bool vide;
  final Completer<void>? attente;

  @override
  Future<List<IncidentSeance>> dernieres24h(DateTime maintenant) async {
    if (attente != null) await attente!.future;
    if (echec) throw StateError('hors portee');
    if (vide) return const <IncidentSeance>[];
    return const IncidentsSeancesDemo().dernieres24h(maintenant);
  }
}

Future<void> _monter(
  WidgetTester tester,
  Widget page, {
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(1440, 3000),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surcharges,
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? enfant) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: enfant!,
            ),
          ),
          home: page,
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  final Widget planning = PlanningPage(semaineInitiale: _lundi);

  group('Les fonctions pures', () {
    test('lundiDe : tout jour de la semaine ramene au lundi a minuit', () {
      expect(lundiDe(DateTime(2026, 10, 18, 23, 59)), _lundi);
      expect(lundiDe(DateTime(2026, 10, 12, 8)), _lundi);
      expect(lundiDe(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
    });

    test('parJour : un jour par groupe, les heures dans l ordre', () {
      final List<SeancePlanning> seances = <SeancePlanning>[
        SeancePlanning(
          id: 'b',
          classe: 'B',
          debut: DateTime(2026, 10, 12, 18),
          dureeMinutes: 45,
          statut: StatutSeance.planifiee,
        ),
        SeancePlanning(
          id: 'a',
          classe: 'A',
          debut: DateTime(2026, 10, 12, 9),
          dureeMinutes: 45,
          statut: StatutSeance.planifiee,
        ),
        SeancePlanning(
          id: 'c',
          classe: 'C',
          debut: DateTime(2026, 10, 14, 9),
          dureeMinutes: 45,
          statut: StatutSeance.planifiee,
        ),
      ];
      final Map<DateTime, List<SeancePlanning>> jours = parJour(seances);
      expect(jours.keys.toList(), <DateTime>[
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 14),
      ]);
      expect(
        jours[DateTime(2026, 10, 12)]!.map((SeancePlanning s) => s.id),
        <String>['a', 'b'],
      );
    });
  });

  group('Planning', () {
    testWidgets('contenu : les seances par jour, enseignant et annulee', (
      WidgetTester tester,
    ) async {
      final _PlanningFictif port = _PlanningFictif();
      await _monter(
        tester,
        planning,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(port),
        ],
      );
      expect(_cle('planning-jours'), findsOneWidget);
      expect(port.demandes, <DateTime>[_lundi]);
      expect(find.text(libelleSemaine(_lundi)), findsOneWidget);
      // Un enseignant manque a une classe : la ligne le dit.
      expect(
        find.textContaining(t.admin.planning.sansEnseignant),
        findsWidgets,
      );
      // La seance annulee porte la pastille d'annulation (mot, pas couleur).
      expect(find.text(t.etat.seanceAnnulee), findsOneWidget);
      // Rien ne propose de revenir : c'est la semaine en cours.
      expect(_cle('planning-cette-semaine'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('semaine suivante : le port est relu avec le bon lundi', (
      WidgetTester tester,
    ) async {
      final _PlanningFictif port = _PlanningFictif();
      await _monter(
        tester,
        planning,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(port),
        ],
      );
      await tester.tap(find.bySemanticsLabel(t.admin.planning.suivante));
      await _laisser(tester);
      expect(port.demandes.last, DateTime(2026, 10, 19));
      expect(_cle('planning-cette-semaine'), findsOneWidget);
      await tester.tap(_cle('planning-cette-semaine'));
      await _laisser(tester);
      expect(_cle('planning-cette-semaine'), findsNothing);
      expect(find.text(libelleSemaine(_lundi)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : aucune seance cette semaine', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        planning,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(_PlanningVide()),
        ],
      );
      expect(_cle('planning-vide'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette, pas de contenu', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(
        tester,
        planning,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(
            _PlanningFictif(attente: attente),
          ),
        ],
      );
      expect(_cle('planning-jours'), findsNothing);
      expect(_cle('planning-vide'), findsNothing);
      attente.complete();
      await _laisser(tester);
      expect(_cle('planning-jours'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un message et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        planning,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(
            _PlanningFictif(echec: true),
          ),
        ],
      );
      expect(_cle('planning-erreur'), findsOneWidget);
      expect(find.text(t.admin.planning.erreur), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hors ligne, sans donnees : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        planning,
        horsLigne: true,
        surcharges: <Override>[
          portPlanningDirectionProvider.overrideWithValue(
            _PlanningFictif(echec: true),
          ),
        ],
      );
      expect(_cle('planning-sans-donnees'), findsOneWidget);
      expect(find.text(t.admin.planning.sansDonnees), findsOneWidget);
      expect(find.textContaining('hors ligne'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('port absent : « disponible au branchement serveur »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, planning);
      expect(_cle('planning-indisponible'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Incidents des 24 dernieres heures', () {
    final List<Override> avecPort = <Override>[
      portIncidentsSeancesProvider.overrideWithValue(_IncidentsFictif()),
    ];

    testWidgets('contenu : les trois natures, une ligne par seance', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const IncidentsPage(), surcharges: avecPort);
      expect(_cle('incidents-liste'), findsOneWidget);
      expect(_cle('incident-inc-1'), findsOneWidget);
      expect(_cle('incident-inc-2'), findsOneWidget);
      expect(_cle('incident-inc-3'), findsOneWidget);
      expect(find.text(t.admin.incidents.natureTechnique), findsOneWidget);
      expect(
        find.text(t.admin.incidents.natureEnseignantAbsent),
        findsOneWidget,
      );
      expect(find.text(t.admin.incidents.natureEleveAbsent), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : aucun incident depuis 24 heures', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const IncidentsPage(),
        surcharges: <Override>[
          portIncidentsSeancesProvider.overrideWithValue(
            _IncidentsFictif(vide: true),
          ),
        ],
      );
      expect(_cle('incidents-vide'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette, pas de contenu', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(
        tester,
        const IncidentsPage(),
        surcharges: <Override>[
          portIncidentsSeancesProvider.overrideWithValue(
            _IncidentsFictif(attente: attente),
          ),
        ],
      );
      expect(_cle('incidents-liste'), findsNothing);
      expect(_cle('incidents-vide'), findsNothing);
      attente.complete();
      await _laisser(tester);
      expect(_cle('incidents-liste'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un message et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const IncidentsPage(),
        surcharges: <Override>[
          portIncidentsSeancesProvider.overrideWithValue(
            _IncidentsFictif(echec: true),
          ),
        ],
      );
      expect(_cle('incidents-erreur'), findsOneWidget);
      expect(find.text(t.admin.incidents.erreur), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hors ligne, sans donnees : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const IncidentsPage(),
        horsLigne: true,
        surcharges: <Override>[
          portIncidentsSeancesProvider.overrideWithValue(
            _IncidentsFictif(echec: true),
          ),
        ],
      );
      expect(_cle('incidents-sans-donnees'), findsOneWidget);
      expect(find.text(t.admin.incidents.sansDonnees), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('port absent : « disponible au branchement serveur »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const IncidentsPage());
      expect(_cle('incidents-indisponible'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('planning, aucun debordement (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          planning,
          surcharges: <Override>[
            portPlanningDirectionProvider.overrideWithValue(_PlanningFictif()),
          ],
          taille: const Size(320, 3000),
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('incidents, aucun debordement (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          const IncidentsPage(),
          surcharges: <Override>[
            portIncidentsSeancesProvider.overrideWithValue(_IncidentsFictif()),
          ],
          taille: const Size(320, 3000),
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}

class _PlanningVide implements PortPlanningDirection {
  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async =>
      const <SeancePlanning>[];
}
