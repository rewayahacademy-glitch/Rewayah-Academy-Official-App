import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/harnais.dart';

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: _monId,
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

EleveEnAttente _enAttente({
  required String eleveId,
  required int jour,
  required int heure,
  String prenom = 'Ibrahim',
}) => EleveEnAttente(
  eleveId: eleveId,
  prenom: prenom,
  identifiantImmuable: 'STUD-IB-000004',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now(),
  mode: InterfaceMode.enfant,
);

PresenceParticipant _presence({
  required EtatPresence etat,
  String profilId = 'e1',
  String prenom = 'Khadija',
  String role = 'student',
  String identifiant = 'STUD-KB-000003',
}) => PresenceParticipant(
  profilId: profilId,
  role: role,
  prenom: prenom,
  identifiantImmuable: identifiant,
  etat: etat,
  consolide: false,
);

FauxServiceRegles _reglesAvecPause(int minutes) =>
    FauxServiceRegles()
      ..parProfil[_monId] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.pauseEntreCours,
          valeurEffective: minutes,
          valeurPlateforme: 30,
        ),
      ];

List<Override> _surcharges({
  FauxServiceEnseignant? enseignant,
  FauxServiceMatching? matching,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
  FauxServicePreVol? preVol,
  FauxServicePresence? presence,
  FauxServiceReseau? reseau,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  // `seancesEnseignantProvider` et non `seancesProvider` : une entree par
  // seance, et non une par eleve.
  serviceEnseignantProvider.overrideWithValue(
    enseignant ?? FauxServiceEnseignant(),
  ),
  serviceMatchingProvider.overrideWithValue(matching ?? FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(priere ?? FauxServicePriere()),
  // Sans ces trois faux, l'ecran lirait le materiel, le reseau et la presence
  // de la machine qui execute les tests : le pre-vol echouerait faute de
  // peripherique, et Supabase n'est pas initialise.
  servicePreVolProvider.overrideWithValue(preVol ?? FauxServicePreVol()),
  servicePresenceProvider.overrideWithValue(presence ?? FauxServicePresence()),
  serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
];

/// L'heure locale d'un instant, comme l'ecran l'ecrit.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// Une fenetre haute, le temps d'un test.
///
/// La colonne d'une journee chargee depasse l'ecran d'un telephone, et un
/// `ListView` ne construit pas ce qui n'est pas visible : sans cette fenetre,
/// le test mesure la hauteur du viewport et non le contenu de la colonne. La
/// deuxieme priere du jour manquait pour cette seule raison.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// La fenetre du telephone ou l'enseignant travaille.
void _fenetreTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Un instant du jour civil local courant, a l'heure demandee.
DateTime _aujourdhuiA(int heure, [int minute = 0]) {
  final DateTime maintenant = DateTime.now();
  return DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
    heure,
    minute,
  );
}

/// Le routeur minimal du lot : la Journee, et les deux ecrans contextuels
/// qu'elle ouvre. Ils sont reduits a un marqueur : ce qui se mesure ici est le
/// chemin, pas l'ecran d'arrivee, qui appartient a un autre agent.
List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: Routes.enseignantJournee,
    builder: (BuildContext _, GoRouterState _) => const JourneePage(),
  ),
  GoRoute(
    path: '/enseignant/groupe/:groupeId',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('groupe:${etat.pathParameters['groupeId']}'),
  ),
  GoRoute(
    path: '/enseignant/seance/:seanceId/cahier',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('cahier:${etat.pathParameters['seanceId']}'),
  ),
];

void main() {
  group('ENS-02 : les six etats de l ecran', () {
    testWidgets('loading : la premiere lecture montre un squelette', (
      WidgetTester tester,
    ) async {
      // Sans delai, le faux resout son futur dans la micro-tache que le premier
      // `pump` vide, et l'etat de chargement n'existe jamais.
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..delai = const Duration(milliseconds: 40);

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.commun.chargement), findsNothing);

      await tester.pumpAndSettle();
      // Et le squelette cede la place : un seul chemin de chargement, celui-la.
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('empty : aucun cours a venir, et rien aujourd hui', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges()),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.aucunCours), findsOneWidget);
      expect(find.text(t.enseignant.journee.aucunCoursDetail), findsOneWidget);
      expect(find.text(t.enseignant.journee.rienAujourdhui), findsOneWidget);
    });

    testWidgets('error : une phrase, et de quoi relire', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..erreurLecture = StateError('vue absente');

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      // C'est l'etat que la migration `0025` non appliquee produit en reel :
      // il n'est pas optionnel.
      expect(find.text(t.enseignant.journee.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsWidgets);

      // Et la lecture repart quand on la demande.
      final int avant = enseignant.lecturesSeances;
      enseignant.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer).first);
      await tester.pumpAndSettle();
      expect(enseignant.lecturesSeances, greaterThan(avant));
    });

    testWidgets(
      'offline : dans la fenetre, la salle ne s ouvre pas et le dit',
      (WidgetTester tester) async {
        final DateTime debut = DateTime.now().add(const Duration(minutes: 5));
        final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

        await tester.pumpWidget(
          hote(
            const JourneePage(),
            surcharges: _surcharges(
              enseignant: enseignant,
              reseau: FauxServiceReseau(horsLigneRendu: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Un geste qui echouerait apres le tap coute plus cher que son absence.
        expect(find.text(t.enseignant.journee.lancer), findsNothing);
        expect(
          find.text(t.enseignant.journee.lancerHorsLigne),
          findsOneWidget,
        );
      },
    );
  });

  group('ENS-02 : le bloc dominant', () {
    testWidgets('un cours de groupe porte le nom du groupe et son effectif', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(
        const Duration(minutes: 25, seconds: 30),
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
            seuilMax: 5,
          ),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.prochainCours), findsOneWidget);
      expect(find.text('Perles du Coran'), findsWidgets);
      expect(
        find.text(t.enseignant.journee.effectif(nombre: '5')),
        findsWidgets,
      );
      expect(
        find.text(t.enseignant.journee.minuteurMinutes(minutes: '25')),
        findsOneWidget,
      );
    });

    testWidgets('une seance de groupe ne compte qu une ligne de colonne', (
      WidgetTester tester,
    ) async {
      // C'est le defaut central que ce lot repare : `mes_seances_v` rend une
      // ligne par eleve, et un cours de cinq enfants y apparait cinq fois.
      // `mes_seances_enseignant_v` en rend une seule, et la colonne aussi.
      final DateTime debut = _aujourdhuiA(9);
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Perles du Coran')),
        findsOneWidget,
      );
    });

    testWidgets('hors de la fenetre d ouverture, une phrase remplace le bouton', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 30));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      // La base refuserait le jeton avant `debut - 10 min` (ADR-005).
      expect(find.text(t.enseignant.journee.lancer), findsNothing);
      expect(
        find.text(t.enseignant.journee.lancementPlusTard),
        findsOneWidget,
      );
    });

    testWidgets('dans la fenetre, le pre-vol passe et le bouton existe', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 9));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];
      final FauxServicePreVol preVol = FauxServicePreVol();

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant, preVol: preVol),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.preflightOk), findsOneWidget);
      expect(find.text(t.enseignant.journee.lancer), findsOneWidget);
      expect(find.text(t.enseignant.journee.lancementPlusTard), findsNothing);
      // Le pre-vol est lu par `preVolProvider`, pas par un appel imperatif.
      expect(preVol.verifications, 1);
    });

    testWidgets('un cours deja commence annonce son heure de fin', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().subtract(
        const Duration(minutes: 10),
      );
      final SeanceEnseignant seance = seanceDeTest(
        debut: debut,
        statut: StatutSeance.enCours,
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seance];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.coursEnCours), findsOneWidget);
      expect(find.text(t.etat.enDirect), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.jusqua(heure: _hhmm(seance.fin))),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.lancer), findsOneWidget);
    });

    testWidgets('une seance sans groupe ne promet aucun nom', (
      WidgetTester tester,
    ) async {
      // `SeanceEnseignant` ne porte aucun prenom : plutot qu'un tiret ou un
      // libelle invente, la carte dit ce qu'elle sait.
      final DateTime debut = DateTime.now().add(const Duration(minutes: 30));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.coursIndividuel), findsWidgets);
      expect(find.text(t.enseignant.journee.voirGroupe), findsNothing);
    });
  });

  group('ENS-02 : le pre-vol echoue', () {
    testWidgets('sans micro, pas de bouton : la raison et un reessai', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 5));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];
      final FauxServicePreVol preVol = FauxServicePreVol(
        microDisponible: false,
      );

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant, preVol: preVol),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.lancer), findsNothing);
      expect(
        find.text(t.enseignant.journee.preflightSansMicro),
        findsOneWidget,
      );

      // Le micro branche, « Reessayer » relance vraiment la verification.
      preVol.microDisponible = true;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(preVol.verifications, 2);
      expect(find.text(t.enseignant.journee.lancer), findsOneWidget);
    });

    testWidgets('une permission refusee ne se dit pas « aucun micro »', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 5));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            preVol: FauxServicePreVol(
              microDisponible: false,
              permissionRefusee: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deux pannes, deux remedes : brancher un micro n'a rien a voir avec
      // autoriser le navigateur.
      expect(find.text(t.enseignant.journee.preflightBloque), findsOneWidget);
      expect(find.text(t.enseignant.journee.preflightSansMicro), findsNothing);
    });
  });

  group('ENS-02 : un eleve absent est detecte', () {
    testWidgets('pendant le cours, l absence se dit avec un prenom', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            statut: StatutSeance.enCours,
            nbParticipants: 3,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(etat: EtatPresence.presente, prenom: 'Omar'),
                _presence(
                  etat: EtatPresence.absente,
                  profilId: 'e2',
                  prenom: 'Khadija',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Khadija')),
        findsOneWidget,
      );
    });

    testWidgets('une presence inconnue ne s annonce pas comme une absence', (
      WidgetTester tester,
    ) async {
      // Invariant J3 : `null` dit « je ne sais pas », et ne se dit jamais
      // « absent ». Une liste vide dit « personne ».
      final DateTime debut = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(debut: debut, statut: StatutSeance.enCours),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            // `lignes` nul par defaut : la presence est indisponible.
            presence: FauxServicePresence(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Khadija')),
        findsNothing,
      );
      expect(find.text(t.enseignant.journee.coursEnCours), findsOneWidget);
    });

    testWidgets('les alertes restent rares : deux lignes, puis un compte', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            statut: StatutSeance.enCours,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(etat: EtatPresence.absente, prenom: 'Un'),
                _presence(
                  etat: EtatPresence.absente,
                  profilId: 'e2',
                  prenom: 'Deux',
                ),
                _presence(
                  etat: EtatPresence.absente,
                  profilId: 'e3',
                  prenom: 'Trois',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Un')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Deux')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Trois')),
        findsNothing,
      );
      expect(
        find.text(t.enseignant.journee.autresAbsences(nombre: '1')),
        findsOneWidget,
      );
    });

    testWidgets('avant l heure du cours, aucune absence n est annoncee', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 30));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(etat: EtatPresence.absente),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Personne n'est attendu en salle : une absence n'existe pas encore.
      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Khadija')),
        findsNothing,
      );
    });
  });

  group('ENS-02 : les rapports en attente', () {
    testWidgets('au dela de vingt-quatre heures, la ligne parle de retard', (
      WidgetTester tester,
    ) async {
      final DateTime hier = DateTime.now().subtract(const Duration(days: 2));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..retardsRendus = <CahierEnRetard>[
          CahierEnRetard(
            seanceId: 's9',
            debut: hier,
            fin: hier.add(const Duration(minutes: 45)),
            nbParticipants: 4,
            heuresDeRetard: 30,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.rapportsTitre), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.rapportRetard(heures: '30')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.rapportAttente(heures: '30')),
        findsNothing,
      );
    });

    testWidgets('la ligne mene au cahier de la seance concernee', (
      WidgetTester tester,
    ) async {
      final DateTime hier = DateTime.now().subtract(const Duration(days: 1));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..retardsRendus = <CahierEnRetard>[
          CahierEnRetard(
            seanceId: 's9',
            debut: hier,
            fin: hier.add(const Duration(minutes: 45)),
            nbParticipants: 1,
            heuresDeRetard: 3,
          ),
        ];

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(
          t.enseignant.journee.rapportLigne(
            jour: t.disponibilites.joursLongs[hier.weekday - 1],
            heure: _hhmm(hier),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cahier:s9'), findsOneWidget);
    });

    testWidgets('aucun rapport en attente : aucune section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges()),
      );
      await tester.pumpAndSettle();

      // Une section vide serait un rappel de rien : la ligne disparait d'elle
      // meme des que le cahier est depose.
      expect(find.text(t.enseignant.journee.rapportsTitre), findsNothing);
    });
  });

  group('ENS-02 : une seule colonne, du haut vers le bas', () {
    testWidgets('cours, pause et prieres y sont des entrees de meme nature', (
      WidgetTester tester,
    ) async {
      final DateTime premier = _aujourdhuiA(9);
      final DateTime second = _aujourdhuiA(10, 30);
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: premier,
            duree: const Duration(hours: 1),
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
            nbParticipants: 5,
          ),
          seanceDeTest(
            id: 's2',
            debut: second,
            duree: const Duration(hours: 1),
            groupeId: 'g2',
            groupeLibelle: 'Les Compagnons',
            nbParticipants: 6,
          ),
        ];
      final FauxServicePriere priere = FauxServicePriere()
        ..parEnseignant[_monId] = _paris;

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: enseignant,
            priere: priere,
            regles: _reglesAvecPause(30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Perles du Coran')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Les Compagnons')),
        findsOneWidget,
      );
      // Le trou de trente minutes entre les deux cours est une pause, parce que
      // la regle de cet enseignant le dit.
      expect(find.text(t.enseignant.journee.lignePause), findsOneWidget);

      // Les prieres du jour ne sont pas dans un bloc a part : chacune est une
      // ligne de la meme colonne.
      final List<InterruptionPriere> interruptions = interruptionsEntre(
        reglages: _paris,
        debut: _aujourdhuiA(0),
        fin: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 1,
        ),
      );
      expect(interruptions, isNotEmpty);
      for (final InterruptionPriere interruption in interruptions) {
        expect(
          find.text(libellePriere(interruption.priere)),
          findsWidgets,
          reason: 'la priere doit etre une ligne de la colonne',
        );
      }
    });

    testWidgets('sans regle de pause lisible, aucun trou n est une pause', (
      WidgetTester tester,
    ) async {
      final DateTime premier = _aujourdhuiA(9);
      final DateTime second = _aujourdhuiA(10, 30);
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: premier,
            duree: const Duration(hours: 1),
            groupeLibelle: 'Perles du Coran',
            groupeId: 'g1',
          ),
          seanceDeTest(
            id: 's2',
            debut: second,
            duree: const Duration(hours: 1),
            groupeLibelle: 'Les Compagnons',
            groupeId: 'g2',
          ),
        ];

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          // La meme journee, sans la regle : la valeur ne se remplace pas par
          // une constante, et les deux cours restent exacts.
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.lignePause), findsNothing);
      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Perles du Coran')),
        findsOneWidget,
      );
    });

    testWidgets('une journee vide dit quand le prochain cours arrive', (
      WidgetTester tester,
    ) async {
      final DateTime plusTard = DateTime.now().add(const Duration(days: 2));
      final DateTime debut = DateTime(
        plusTard.year,
        plusTard.month,
        plusTard.day,
        17,
      );
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[seanceDeTest(debut: debut)];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.rienAujourdhui), findsOneWidget);
      expect(
        find.text(
          t.enseignant.journee.rienAujourdhuiDetail(
            jour: t.disponibilites.joursLongs[debut.weekday - 1],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
      // Le bloc dominant n'est pas borne a aujourd'hui : il dit quand on
      // reprend, au lieu de rester vide.
      expect(
        find.text(
          t.enseignant.journee.unAutreJour(
            jour: t.disponibilites.joursLongs[debut.weekday - 1],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la journee finie se dit en une phrase, au singulier', (
      WidgetTester tester,
    ) async {
      // Le premier instant du jour civil, et une minute de cours : la seule
      // fenetre ou ce test pourrait mentir dure soixante secondes par nuit.
      final DateTime debut = _aujourdhuiA(0);
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            duree: const Duration(minutes: 1),
            statut: StatutSeance.terminee,
            cahierDepose: true,
          ),
        ];

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.journeeTermineeUn),
        findsOneWidget,
      );
    });
  });

  group('ENS-02 : les acces contextuels et le secondaire', () {
    testWidgets('la carte de seance mene a la fiche de son groupe', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 30));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.journee.voirGroupe));
      await tester.pumpAndSettle();

      expect(find.text('groupe:g1'), findsOneWidget);
    });

    testWidgets('le compteur compte les eleves, pas les lignes du feed', (
      WidgetTester tester,
    ) async {
      // Le feed rend une ligne par creneau compatible : Ibrahim y figure trois
      // fois. Compter les lignes annoncerait quatre familles pour deux.
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[
          _enAttente(eleveId: 'e1', jour: 2, heure: 17),
          _enAttente(eleveId: 'e1', jour: 3, heure: 17),
          _enAttente(eleveId: 'e1', jour: 4, heure: 18),
          _enAttente(eleveId: 'e2', jour: 5, heure: 9, prenom: 'Fatou'),
        ];

      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges(matching: matching)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
      expect(find.text(t.enseignant.journee.enAttenteLibelle), findsOneWidget);
    });

    testWidgets('un compteur a zero s affiche, il ne disparait pas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges()),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
      expect(find.text(t.enseignant.journee.voirCreneaux), findsOneWidget);
    });
  });

  group('ENS-02 : mobile d abord', () {
    testWidgets('a 390 x 844, rien ne deborde', (WidgetTester tester) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 5));
      final DateTime hier = DateTime.now().subtract(const Duration(days: 2));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ]
        ..retardsRendus = <CahierEnRetard>[
          CahierEnRetard(
            seanceId: 's9',
            debut: hier,
            fin: hier.add(const Duration(minutes: 45)),
            nbParticipants: 4,
            heuresDeRetard: 30,
          ),
        ];
      final FauxServicePriere priere = FauxServicePriere()
        ..parEnseignant[_monId] = _paris;

      _fenetreTelephone(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant, priere: priere),
        ),
      );
      await tester.pumpAndSettle();

      // `tester.takeException()` remonte les debordements de mise en page :
      // l'ecran de l'enseignant se lit sur un telephone, ou nulle part.
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 200 % de taille de texte, rien ne deborde', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 5));
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: debut,
            nbParticipants: 5,
            groupeId: 'g1',
            groupeLibelle: 'Perles du Coran',
          ),
        ];

      _fenetreTelephone(tester);
      // L'echelle se pose sur le dispatcher, pas dans un `MediaQuery` local :
      // `MaterialApp` reconstruit le sien depuis la vue et ecraserait celui-la.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
