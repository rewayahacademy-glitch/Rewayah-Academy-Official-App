// B2.2 bis (b) : « Rejoindre » appelle le concierge (`seance_a_rejoindre`)
// quand la seance n'est pas lisible alors que la fenetre d'entree est
// ouverte ; une seance connue entre comme avant, sans appel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance_memoire.dart';
import 'package:rewayah_academy/core/tc_groupe/concierge_seance_supabase.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/chemins_tc_a.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/routes_tc_a.dart';

import '../support/harnais.dart';
import '../teaching_core/a/faux/faux_groupes.dart';
import '../teaching_core/a/support/hote_tc_a.dart';

const String _groupeId = 'g1';
const String _seanceConnue = 's-connue';
const String _seanceRendue = 's-rendue';

/// Une horloge dont la salle est ouverte depuis cinq minutes (le cours
/// commence dans quinze), avec ou sans seance lisible.
SessionClockVM _horloge({String? sessionId}) {
  final DateTime debut = DateTime.utc(2026, 10, 25, 17);
  return SessionClockVM.depuisFenetre(
    fenetre: FenetreSeance(
      debutUtc: debut,
      finPrevueUtc: debut.add(const Duration(minutes: 60)),
      fenetreAcces: const Duration(minutes: 20),
      graceApresFin: const Duration(minutes: 15),
    ),
    maintenantServeurUtc: debut.subtract(const Duration(minutes: 15)),
    sessionId: sessionId,
    horlogeUtilisateur: const HorlogeAffichee(
      fuseauIana: 'Europe/Paris',
      libelleVille: 'Paris',
      heureLocaleRendue: '18:00',
      dateLocaleRendue: 'Dimanche 25 octobre',
    ),
  );
}

GroupSummaryVM _classe({String? sessionId}) => const GroupSummaryVM(
  groupeId: _groupeId,
  libelle: 'Perles du Coran',
  couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'g00'),
  enseignant: EnseignantVM(
    enseignantId: 'ens',
    titre: TitreEnseignant.sayyid,
    nomAffichage: 'Youssouf',
    photoUrlOuCle: 'p.jpg',
  ),
  nombreMembres: 3,
  seuilMax: 5,
  typePublic: TypePublicGroupeVM.enfant,
  actif: true,
).avecHorloge(_horloge(sessionId: sessionId));

/// Un port du temps qui emet une horloge, puis se tait.
class _HorlogeFixe implements PortHorlogeSeance {
  const _HorlogeFixe(this.horloge);

  final SessionClockVM horloge;

  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async => horloge;

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) => Stream<SessionClockVM>.value(horloge);

  @override
  Future<DateTime> maintenantServeurUtc() async => horloge.calculeeAUtc;
}

// ---------------------------------------------------------------------------
// Enseignant : la fiche de la Classe.
// ---------------------------------------------------------------------------

List<Override> _surchargesEnseignant({
  required String? sessionId,
  required ConciergeMemoire concierge,
}) {
  final GroupSummaryVM classe = _classe(sessionId: sessionId);
  return <Override>[
    serviceEnseignantProvider.overrideWithValue(
      FauxServiceEnseignant()
        ..groupesRendus = <GroupeEnseignant>[
          GroupeEnseignant(
            id: _groupeId,
            libelle: 'Perles du Coran',
            type: TypePublicGroupe.enfant,
            seuilMax: 5,
            creneau: const Creneau(jour: 7, heure: 18, fuseau: 'Europe/Paris'),
            nbMembres: 3,
            creeLe: DateTime(2026, 10),
          ),
        ]
        ..membresRendus = <String, List<MembreSeance>>{
          _groupeId: <MembreSeance>[membreDeTest()],
        },
    ),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    groupeProvider(_groupeId).overrideWith((Ref _) async => classe),
    horlogeGroupeProvider(_groupeId)
        .overrideWith((Ref _) => Stream<SessionClockVM>.value(classe.horloge!)),
    portConciergeProvider.overrideWithValue(concierge),
  ];
}

Future<List<String>> _appuyerEnseignant(
  WidgetTester tester, {
  required String? sessionId,
  required ConciergeMemoire concierge,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<String> entrees = <String>[];
  await tester.pumpWidget(
    hote(
      FicheGroupePage(groupeId: _groupeId, onPreparer: entrees.add),
      surcharges: _surchargesEnseignant(
        sessionId: sessionId,
        concierge: concierge,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final Finder bouton = find.widgetWithText(
    ActionPrincipale,
    t.enseignant.journee.rejoindreSalle,
  );
  expect(bouton, findsOneWidget, reason: 'le bouton est rendu, jamais grise');
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
  return entrees;
}

// ---------------------------------------------------------------------------
// Eleve : Mes classes (carte) et l'Espace Classe (carte de seance).
// ---------------------------------------------------------------------------

Future<BilletSalle?> _appuyerEleve(
  WidgetTester tester, {
  required String depart,
  required String? sessionId,
  required ConciergeMemoire concierge,
}) async {
  BilletSalle? billet;
  final GroupSummaryVM classe = _classe(sessionId: sessionId);
  await avecLargeur(tester, largeurMobile, () async {
    await tester.pumpWidget(
      hoteRoutantTcA(
        depart: depart,
        routes: <RouteBase>[
          ...routesTcA(),
          GoRoute(
            path: Routes.salle,
            builder: (BuildContext _, GoRouterState e) {
              billet = e.extra as BilletSalle?;
              return const Text('salle');
            },
          ),
        ],
        surcharges: <Override>[
          portGroupesProvider.overrideWithValue(
            FauxPortGroupes(groupes: <GroupSummaryVM>[classe]),
          ),
          portHorlogeSeanceProvider.overrideWithValue(
            _HorlogeFixe(classe.horloge!),
          ),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          portConciergeProvider.overrideWithValue(concierge),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final Finder bouton = find.widgetWithText(
      ActionPrincipale,
      t.classe.entree.rejoindre,
    );
    expect(bouton, findsOneWidget, reason: 'le bouton est rendu, jamais grise');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
  });
  return billet;
}

void main() {
  test('les codes du serveur deviennent des refus types', () {
    expect(motifRefusConcierge(code: '42501'), MotifRefusConcierge.nonAutorise);
    expect(
      motifRefusConcierge(message: 'SeanceNonAutorisee'),
      MotifRefusConcierge.nonAutorise,
    );
    expect(
      motifRefusConcierge(code: '22023'),
      MotifRefusConcierge.classeInconnue,
    );
    expect(motifRefusConcierge(code: '08006', message: 'reseau'), isNull);
  });

  group('Enseignant, fiche de la Classe', () {
    testWidgets('seance connue : on entre, aucun appel au concierge', (
      WidgetTester tester,
    ) async {
      final ConciergeMemoire concierge = ConciergeMemoire(
        seances: <String, String>{_groupeId: _seanceRendue},
      );
      final List<String> entrees = await _appuyerEnseignant(
        tester,
        sessionId: _seanceConnue,
        concierge: concierge,
      );
      expect(concierge.appels, isEmpty);
      expect(entrees, <String>[_seanceConnue]);
    });

    testWidgets('fenetre ouverte sans seance : le concierge, une fois, '
        'puis on entre avec la seance rendue', (WidgetTester tester) async {
      final ConciergeMemoire concierge = ConciergeMemoire(
        seances: <String, String>{_groupeId: _seanceRendue},
      );
      final List<String> entrees = await _appuyerEnseignant(
        tester,
        sessionId: null,
        concierge: concierge,
      );
      expect(concierge.appels, <String>[_groupeId]);
      expect(entrees, <String>[_seanceRendue]);
      expect(find.text(t.classe.entree.accesInverifiable), findsNothing);
    });

    testWidgets('aucune seance rendue : la phrase de la salle, sans entrer', (
      WidgetTester tester,
    ) async {
      final ConciergeMemoire concierge = ConciergeMemoire();
      final List<String> entrees = await _appuyerEnseignant(
        tester,
        sessionId: null,
        concierge: concierge,
      );
      expect(concierge.appels, <String>[_groupeId]);
      expect(entrees, isEmpty);
      expect(find.byKey(EmplacementEntreeVue.cleRefus), findsOneWidget);
      expect(find.text(t.salle.refusAcces), findsOneWidget);
    });

    testWidgets('refus du serveur : la phrase de la salle, sans entrer', (
      WidgetTester tester,
    ) async {
      final ConciergeMemoire concierge = ConciergeMemoire(
        refus: MotifRefusConcierge.nonAutorise,
      );
      final List<String> entrees = await _appuyerEnseignant(
        tester,
        sessionId: null,
        concierge: concierge,
      );
      expect(entrees, isEmpty);
      expect(find.text(t.salle.refusAcces), findsOneWidget);
    });

    testWidgets('panne : la phrase de la seance illisible, sans entrer', (
      WidgetTester tester,
    ) async {
      final ConciergeMemoire concierge = ConciergeMemoire(
        panne: Exception('reseau'),
      );
      final List<String> entrees = await _appuyerEnseignant(
        tester,
        sessionId: null,
        concierge: concierge,
      );
      expect(entrees, isEmpty);
      expect(find.text(t.classe.entree.indisponible), findsOneWidget);
    });
  });

  for (final (String nom, String depart, Key cleRefus) surface
      in <(String, String, Key)>[
        ('Mes classes (carte)', CheminsTcA.mesGroupes, CarteGroupe.cleRefus),
        (
          'Espace Classe (carte de seance)',
          CheminsTcA.espaceGroupe(_groupeId),
          EmplacementEntreeVue.cleRefus,
        ),
      ]) {
    group('Eleve, ${surface.$1}', () {
      testWidgets('seance connue : /salle avec elle, aucun appel', (
        WidgetTester tester,
      ) async {
        final ConciergeMemoire concierge = ConciergeMemoire(
          seances: <String, String>{_groupeId: _seanceRendue},
        );
        final BilletSalle? billet = await _appuyerEleve(
          tester,
          depart: surface.$2,
          sessionId: _seanceConnue,
          concierge: concierge,
        );
        expect(concierge.appels, isEmpty);
        expect(billet?.sessionId, _seanceConnue);
      });

      testWidgets('fenetre ouverte sans seance : le concierge, une fois, '
          'puis /salle avec la seance rendue', (WidgetTester tester) async {
        final ConciergeMemoire concierge = ConciergeMemoire(
          seances: <String, String>{_groupeId: _seanceRendue},
        );
        final BilletSalle? billet = await _appuyerEleve(
          tester,
          depart: surface.$2,
          sessionId: null,
          concierge: concierge,
        );
        expect(concierge.appels, <String>[_groupeId]);
        expect(find.text('salle'), findsOneWidget);
        expect(billet?.sessionId, _seanceRendue);
        expect(billet?.preparation, isTrue);
        expect(billet?.groupeId, _groupeId);
      });

      testWidgets('aucune seance rendue : la phrase, sans entrer', (
        WidgetTester tester,
      ) async {
        final ConciergeMemoire concierge = ConciergeMemoire();
        final BilletSalle? billet = await _appuyerEleve(
          tester,
          depart: surface.$2,
          sessionId: null,
          concierge: concierge,
        );
        expect(concierge.appels, <String>[_groupeId]);
        expect(billet, isNull);
        expect(find.byKey(surface.$3), findsOneWidget);
        expect(find.text(t.salle.refusAcces), findsOneWidget);
      });

      testWidgets('refus du serveur : la phrase, sans entrer', (
        WidgetTester tester,
      ) async {
        final ConciergeMemoire concierge = ConciergeMemoire(
          refus: MotifRefusConcierge.nonAutorise,
        );
        final BilletSalle? billet = await _appuyerEleve(
          tester,
          depart: surface.$2,
          sessionId: null,
          concierge: concierge,
        );
        expect(billet, isNull);
        expect(find.text(t.salle.refusAcces), findsOneWidget);
      });
    });
  }
}
