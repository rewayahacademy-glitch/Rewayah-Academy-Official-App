// Classe du tuteur et ses sous-pages (lot C, sous-paquet 2) : parcours touches
// depuis la barre de navigation, sur le VRAI routeur, puis etats de chaque
// ecran et fonctions pures.
//
// Donnees : fixtures isolees de `test/fixtures/tuteur/` et doubles locaux de
// ce fichier (politique d'observation, catalogue, progression). Aucun service
// reel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_observation/activation_observation.dart';
import 'package:rewayah_academy/core/tc_observation/disponibilite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';
import 'package:rewayah_academy/features/classe_tuteur/bloc_observation_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/planning_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/progression_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/ressources_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/travail_classe_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/entree_observation_page.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Le premier profil retenu : « Eleve A1 » (tri par prenom, contrat K1).
const String _a1 = 'foyer-a-eleve-1';
const String _classe = 'classe-a';

/// Une seance a venir, salle ouverte (fenetre fictive de 20 min), dans 10 min
/// et 30 s.
SeanceFamille _salleOuverte({
  StatutSeance? statut = StatutSeance.planifiee,
  Duration avant = const Duration(minutes: 10, seconds: 30),
  String seanceId = 's1',
  bool avecHorloge = true,
}) => seanceFictive(
  seanceId: seanceId,
  eleveId: _a1,
  debutUtc: instantServeurFige.add(avant),
  statut: statut,
  avecHorloge: avecHorloge,
  heureFoyer: heureRendue('Europe/Paris', 'Paris', '18:10'),
);

/// Une seance en direct depuis dix minutes.
SeanceFamille _enDirect() => seanceFictive(
  seanceId: 's1',
  eleveId: _a1,
  debutUtc: instantServeurFige.subtract(const Duration(minutes: 10)),
  statut: StatutSeance.enCours,
  heureFoyer: heureRendue('Europe/Paris', 'Paris', '17:50'),
);

/// La politique et le budget d'observation, en memoire.
class _FauxPolitique implements PortPolitiqueObservation {
  _FauxPolitique(this.budgetRendu);

  final BudgetObservation budgetRendu;

  @override
  Future<BudgetObservation> budget({required String sessionId}) async =>
      budgetRendu;

  @override
  Future<GuardianObservationPolicy> politiqueEffective({
    required String groupeId,
  }) async => politiqueA2;

  @override
  Stream<BudgetObservation> suivreBudget({required String sessionId}) =>
      Stream<BudgetObservation>.value(budgetRendu);

  @override
  Future<GuardianObservationPolicy> definirPolitiqueGroupe({
    required String groupeId,
    required GuardianObservationPolicy politique,
  }) => throw UnimplementedError();
}

/// Les visites, en memoire : rien n'est ouvert, rien ne s'ouvre ici.
class _FausseVisite implements PortVisiteObservation {
  @override
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  }) => throw UnimplementedError();

  @override
  Future<void> sortir({required String sessionId}) async {}

  @override
  Future<List<GuardianSessionVisit>> visites({
    required String sessionId,
  }) async => const <GuardianSessionVisit>[];
}

/// Une ressource fictive.
const LibraryResource _ressource = LibraryResource(
  id: 'r1',
  title: 'Support fictif 1',
  shortTitle: 'Support 1',
  resourceType: TypeRessource.pdf,
  language: 'fr',
  category: 'fictive',
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.jamais,
);

/// Un catalogue BRANCHE (pas le catalogue local), en memoire.
class _FauxCatalogue implements PortCatalogue {
  const _FauxCatalogue(this.ressources);

  final List<LibraryResource> ressources;

  @override
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre}) async =>
      ressources;

  @override
  Future<List<LibraryResource>> recents({int limite = 10}) async =>
      const <LibraryResource>[];

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async =>
      groupeId == _classe ? ressources : const <LibraryResource>[];

  @override
  Future<LibraryResource?> parId(String resourceId) async {
    for (final LibraryResource r in ressources) {
      if (r.id == resourceId) {
        return r;
      }
    }
    return null;
  }

  @override
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  }) async => ressources;

  @override
  Future<ReprisLecture?> derniereLecture() async => null;
}

/// La progression, en memoire.
class _FausseProgression implements PortProgressionFamille {
  const _FausseProgression(this.rendue);

  final ProgressionEleve rendue;

  @override
  Future<ProgressionEleve> progression(String eleveId) async => rendue;
}

/// Deux travaux fictifs, dont un fait et un retire (jamais montre).
Future<AssignationsMemoire> _travaux() async {
  final AssignationsMemoire depot = AssignationsMemoire(
    'enseignant-x',
    maintenant: () => instantServeurFige,
  );
  await depot.creerDepuisSelection(
    groupId: _classe,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aRevoir,
    instructions: 'Consigne fictive 1',
    dueAtUtc: instantServeurFige.add(const Duration(days: 2)),
  );
  final LearningAssignment fait = await depot.creerDepuisSelection(
    groupId: _classe,
    studentId: _a1,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aApprendre,
    instructions: 'Consigne fictive 2',
  );
  await depot.changerStatut(fait.id, StatutAssignation.fait);
  final LearningAssignment retire = await depot.creerDepuisSelection(
    groupId: _classe,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aEntretenir,
    instructions: 'Consigne retiree',
  );
  await depot.changerStatut(retire.id, StatutAssignation.annule);
  return depot;
}

/// Monte l'application sur son vrai routeur, tuteur actif, foyer fictif A,
/// puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  String depart = Routes.tuteurFoyer,
  List<SeanceFamille>? seances,
  PortClassesFoyer? portClasses,
  bool observation = false,
  BudgetObservation? budget,
  List<PresenceParticipant>? presence,
  PortAssignations? travail,
  PortCatalogue? catalogue,
  PortProgressionFamille? progression,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()
            ..elevesRendus = FoyersFictifs.foyerA
            ..appareilsRendus = <AppareilAppaire>[
              AppareilAppaire(
                id: 'app-1',
                profilId: _a1,
                prenom: 'Eleve A1',
                plateforme: 'Android',
                appaireA: DateTime.utc(2026, 9, 1),
              ),
            ],
        ),
        portSeancesFamilleProvider.overrideWithValue(
          FauxSeancesFamille(
            seances: seances ?? <SeanceFamille>[_salleOuverte()],
          ),
        ),
        portClassesFoyerProvider.overrideWithValue(
          portClasses ??
              FauxClassesFoyer(
                classes: <ClasseFoyer>[
                  ClasseFoyer(eleveId: _a1, classe: classeFictive()),
                ],
              ),
        ),
        observationTuteurReelleProvider.overrideWithValue(observation),
        portPolitiqueObservationProvider.overrideWithValue(
          _FauxPolitique(budget ?? budgetDeuxVisites),
        ),
        portVisiteObservationProvider.overrideWithValue(_FausseVisite()),
        moteurSalleProvider.overrideWithValue(FauxMoteurSalle()),
        presenceSeanceProvider.overrideWith(
          (Ref _, String _) =>
              Stream<List<PresenceParticipant>?>.value(presence),
        ),
        assignationsFamilleProvider.overrideWithValue(travail),
        if (catalogue != null)
          portCatalogueProvider.overrideWithValue(catalogue),
        if (progression != null)
          portProgressionFamilleProvider.overrideWithValue(progression),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche un element apres l'avoir amene a l'ecran.
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// De la barre basse a la classe : Accueil, puis « Voir la classe ».
Future<void> _ouvrirLaClasse(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.accueil),
    ),
  );
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);
  await _toucher(tester, find.text(t.tuteur.accueil.voirLaClasse));
  expect(find.byType(ClasseTuteurPage), findsOneWidget);
}

/// Revient par le disque retour de l'en-tete.
Future<void> _retour(WidgetTester tester) async {
  await _toucher(tester, find.byType(DisqueRetour));
}

/// Une rubrique de la carte groupee de la classe (la barre de navigation porte
/// aussi « Historique »).
Finder _rubrique(String libelle) => find.descendant(
  of: find.byType(GroupeReglages),
  matching: find.text(libelle),
);

String _lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

PresenceParticipant _presente() => const PresenceParticipant(
  profilId: _a1,
  role: 'student',
  prenom: 'Eleve A1',
  identifiantImmuable: 'STUD-FA-000001',
  etat: EtatPresence.presente,
  consolide: false,
);

void main() {
  group('Classe : parcours touches depuis la barre de navigation', () {
    testWidgets('la classe dit l enseignant, la seance et ses rubriques ; '
        'le disque retour ramene a l Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirLaClasse(tester);

      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
      // En-tete et carte : la classe, l'eleve et l'enseignant nomme.
      expect(find.text('Classe fictive A'), findsNWidgets(2));
      expect(
        find.text(
          t.classe.sousTitre(
            prenom: 'Eleve A1',
            enseignant: '${t.tc.groupe.enseignant.sayyid} Enseignant X',
          ),
        ),
        findsOneWidget,
      );
      // Meme calcul que l'Accueil : salle ouverte et compte a rebours.
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsOneWidget);
      expect(find.text(LibellesGroupe.dansMinutes(10)), findsOneWidget);
      for (final String rubrique in <String>[
        t.classe.planning,
        t.classe.travail,
        t.classe.ressources,
        t.classe.progression,
        t.classe.historique,
      ]) {
        expect(_rubrique(rubrique), findsOneWidget, reason: rubrique);
      }
      // Aucune entree « Rejoindre » pour le tuteur.
      expect(find.text(LibellesGroupe.rejoindre), findsNothing);
      // L'onglet Accueil reste actif sur cette page de niveau 2.
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);

      await _retour(tester);
      expect(_lieu(routeur), Routes.tuteurAccueil);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Planning » ouvre les seances a venir, le retour ramene a '
        'la classe', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[
          _salleOuverte(),
          _salleOuverte(
            seanceId: 's2',
            avant: const Duration(days: 2),
            statut: StatutSeance.annulee,
          ),
        ],
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.planning));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
      );
      expect(find.byType(PlanningClassePage), findsOneWidget);
      expect(find.text(t.classe.pagePlanning.prochaines), findsOneWidget);
      // L'annulation se voit : jamais un cours normal.
      expect(
        find.widgetWithText(StatusPill, t.tuteur.accueil.pastilleAnnulee),
        findsOneWidget,
      );

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Travail a preparer » liste le travail sans limite de '
        'trois, statut du service, jamais le travail retire', (
      WidgetTester tester,
    ) async {
      final AssignationsMemoire travaux = await _travaux();
      final GoRouter routeur = await _monter(tester, travail: travaux);
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.travail));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
      );
      expect(find.byType(TravailClassePage), findsOneWidget);
      expect(find.textContaining('Consigne fictive 1'), findsOneWidget);
      expect(find.textContaining('Consigne fictive 2'), findsOneWidget);
      expect(find.textContaining('Consigne retiree'), findsNothing);
      expect(
        find.widgetWithText(StatusPill, t.classe.pageTravail.statut.fait),
        findsOneWidget,
      );
      expect(find.text(t.classe.pageTravail.nonCochable), findsOneWidget);

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
    });

    testWidgets('« Bibliotheque » liste les ressources ; une ressource ouvre '
        'le detail existant, dont le disque retour revient ici', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        catalogue: const _FauxCatalogue(<LibraryResource>[_ressource]),
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.ressources));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.byType(RessourcesClassePage), findsOneWidget);

      await _toucher(tester, find.text('Support fictif 1'));
      expect(_lieu(routeur), startsWith('${Routes.tcBibliotheque}/r1?retour='));
      expect(find.byType(DetailRessourcePage), findsOneWidget);

      await _retour(tester);
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.byType(RessourcesClassePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Progression » dit le niveau et les etapes partagees', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        progression: const _FausseProgression(
          ProgressionEleve(
            eleveId: _a1,
            niveauHumain: 'Niveau fictif',
            jalons: <String>['Etape fictive 1'],
          ),
        ),
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.progression));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'progression')}?eleve=$_a1',
      );
      expect(find.byType(ProgressionClassePage), findsOneWidget);
      expect(find.text('Niveau fictif'), findsOneWidget);
      expect(find.text('Etape fictive 1'), findsOneWidget);

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
    });

    testWidgets('« Historique » ouvre l Historique filtre sur l eleve et la '
        'classe', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.historique));
      expect(
        _lieu(routeur),
        '${Routes.tuteurSuivi}?eleve=$_a1&classe=$_classe',
      );
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 2);
    });

    testWidgets('observation ouverte (simulation) : « Observer la seance » et '
        '« Comment ca marche ? » ouvrent l entree du lot O avec le contexte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[_enDirect()],
        observation: true,
        presence: <PresenceParticipant>[_presente()],
      );
      await _ouvrirLaClasse(tester);

      expect(find.text(t.tuteur.accueil.seanceEnDirect), findsOneWidget);
      expect(
        find.text(
          t.classe.observation.resume(
            visites: t.classe.observation.visites(nombre: 2),
            duree: t.classe.observation.minutes(minutes: 2),
          ),
        ),
        findsOneWidget,
      );

      await _toucher(tester, find.text(t.classe.observer));
      expect(
        _lieu(routeur),
        '${Routes.tcObservation('s1')}?classe=$_classe&eleve=$_a1',
      );
      expect(find.byType(EntreeObservationPage), findsOneWidget);
    });

    testWidgets('« Comment ca marche ? » ouvre l explication seule', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[_enDirect()],
        observation: true,
        presence: <PresenceParticipant>[_presente()],
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, find.text(t.classe.observation.commentCaMarche));
      expect(
        _lieu(routeur),
        '${Routes.tcObservation('s1')}?classe=$_classe&eleve=$_a1&aide=1',
      );
    });
  });

  group('Classe : etats', () {
    testWidgets('production (P3) : aucune porte d observation appelee, une '
        'phrase, aucun CTA', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[_enDirect()],
      );
      expect(
        find.text(t.classe.observation.motif.garantieServeurAbsente),
        findsOneWidget,
      );
      expect(find.text(t.classe.observer), findsNothing);
    });

    testWidgets('visites epuisees : le motif et « Aucune visite restante »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[_enDirect()],
        observation: true,
        budget: budgetEpuise,
        presence: <PresenceParticipant>[_presente()],
      );
      expect(
        find.text(t.classe.observation.motif.visitesEpuisees),
        findsOneWidget,
      );
      expect(find.text(t.classe.observation.restanteAucune), findsOneWidget);
      expect(find.text(t.classe.observer), findsNothing);
    });

    testWidgets('presence non lue : « en cours de verification », jamais une '
        'absence', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[_enDirect()],
        observation: true,
      );
      expect(
        find.text(
          t.classe.observation.motif.presenceEnVerification(prenom: 'Eleve A1'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(t.presence.absente), findsNothing);
    });

    testWidgets('seance a venir : l observation ouvre quand elle commence', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[
          _salleOuverte(
            avant: const Duration(hours: 3, minutes: 28, seconds: 30),
          ),
        ],
        observation: true,
      );
      expect(
        find.text(LibellesGroupe.dansHeures(heures: 3, minutes: 28)),
        findsOneWidget,
      );
      expect(
        find.text(t.classe.observation.motif.seanceNonCommencee),
        findsOneWidget,
      );
    });

    testWidgets(
      'seance annulee : bandeau d alerte, jamais de compte a rebours',
      (WidgetTester tester) async {
        await _monter(
          tester,
          depart: Routes.classePour(_classe, eleveId: _a1),
          seances: <SeanceFamille>[_salleOuverte(statut: StatutSeance.annulee)],
        );
        expect(find.text(t.tuteur.accueil.seanceAnnulee), findsOneWidget);
        expect(find.text(LibellesGroupe.dansMinutes(10)), findsNothing);
      },
    );

    testWidgets('sans horloge serveur : heure de l appareil dite comme telle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[_salleOuverte(avecHorloge: false)],
      );
      expect(find.text(t.tuteur.accueil.horaireIncertain), findsOneWidget);
      expect(find.text(t.tuteur.accueil.heureAppareil), findsOneWidget);
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsNothing);
    });

    testWidgets('aucune seance : la classe reste lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: const <SeanceFamille>[],
      );
      expect(find.text(t.classe.seance.aucune), findsOneWidget);
      expect(find.text(t.classe.planning), findsOneWidget);
    });

    testWidgets('classes indisponibles (production) : pas encore disponible, '
        'jamais « introuvable »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        portClasses: const ClassesFoyerIndisponible(),
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.indisponible);
      expect(find.text(t.classe.indisponiblePhrase), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('classe d un autre eleve ou inconnue : introuvable, retour a '
        'l accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        depart: Routes.classePour('inconnue', eleveId: _a1),
      );
      expect(find.text(t.classe.introuvableTitre), findsOneWidget);
      await _toucher(tester, find.text(t.commun.etats.actions.retourAccueil));
      expect(_lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('un eleve d un autre foyer dans l adresse : introuvable', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: 'foyer-b-eleve-1'),
      );
      expect(find.text(t.classe.introuvableTitre), findsOneWidget);
    });

    testWidgets('bureau 1440 : deux colonnes, carte a gauche, rubriques a '
        'droite', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        taille: const Size(1440, 900),
      );
      final Offset carte = tester.getTopLeft(find.byType(CarteSeanceClasse));
      final Offset planning = tester.getTopLeft(find.text(t.classe.planning));
      expect(planning.dx, greaterThan(carte.dx + 400));
      expect(planning.dy, lessThan(carte.dy + 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone 390 : une colonne, rubriques sous la carte', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.classePour(_classe, eleveId: _a1));
      final Rect carte = tester.getRect(find.byType(CarteSeanceClasse));
      await tester.ensureVisible(find.text(t.classe.planning));
      await stabiliser(tester);
      final Rect carteApres = tester.getRect(find.byType(CarteSeanceClasse));
      final Offset planning = tester.getTopLeft(find.text(t.classe.planning));
      expect(planning.dy, greaterThan(carteApres.bottom));
      expect(carte.width, carteApres.width);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sous-pages : etats', () {
    testWidgets('travail non branche (production) : phrase honnete, jamais '
        '« Rien a preparer »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
      );
      expect(find.text(t.classe.pageTravail.indisponible), findsOneWidget);
      expect(find.text(t.classe.pageTravail.aucun), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('travail branche et vide : « Rien a preparer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
        travail: AssignationsMemoire('enseignant-x'),
      );
      expect(find.text(t.classe.pageTravail.aucun), findsOneWidget);
    });

    testWidgets('bibliotheque locale (production) : pas encore reliee, jamais '
        '« aucune ressource »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.text(t.classe.pageRessources.indisponible), findsOneWidget);
      expect(find.text(t.classe.pageRessources.aucune), findsNothing);
    });

    testWidgets('bibliotheque branchee et vide : aucune ressource', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
        catalogue: const _FauxCatalogue(<LibraryResource>[]),
      );
      expect(find.text(t.classe.pageRessources.aucune), findsOneWidget);
    });

    testWidgets('progression (production) : pas encore partagee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'progression')}?eleve=$_a1',
      );
      expect(
        find.text(t.classe.pageProgression.indisponible(prenom: 'Eleve A1')),
        findsOneWidget,
      );
    });

    testWidgets('planning vide : aucune seance a venir', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
        seances: const <SeanceFamille>[],
      );
      expect(find.text(t.classe.pagePlanning.aucune), findsOneWidget);
    });

    testWidgets('sous-page sans eleve dans l adresse : l eleve inscrit est '
        'retrouve', (WidgetTester tester) async {
      await _monter(tester, depart: Routes.classeSousPage(_classe, 'planning'));
      expect(
        find.text(LibellesGroupe.joindre('Classe fictive A', 'Eleve A1')),
        findsOneWidget,
      );
    });
  });

  group('Fonctions pures', () {
    test('visites accordees et restantes, au singulier et au pluriel', () {
      expect(visitesDisponibles(1), t.classe.observation.uneVisite);
      expect(visitesDisponibles(2), t.classe.observation.visites(nombre: 2));
      expect(visitesRestantes(0), t.classe.observation.restanteAucune);
      expect(visitesRestantes(1), t.classe.observation.restanteUne);
      expect(visitesRestantes(2), t.classe.observation.restantes(nombre: 2));
    });

    test('duree d une visite : minutes, secondes, jamais arrondie', () {
      expect(
        dureeVisite(const Duration(seconds: 120)),
        t.classe.observation.minutes(minutes: 2),
      );
      expect(
        dureeVisite(const Duration(seconds: 80)),
        t.classe.observation.minutesSecondes(minutes: 1, secondes: 20),
      );
      expect(
        dureeVisite(const Duration(seconds: 40)),
        t.classe.observation.secondes(secondes: 40),
      );
    });

    test('chaque motif a sa phrase, aucun code', () {
      for (final MotifIndisponibilite motif in MotifIndisponibilite.values) {
        final String texte = texteMotif(motif, prenom: 'Eleve A1');
        expect(texte, isNotEmpty, reason: motif.name);
        expect(texte.contains('_'), isFalse, reason: motif.name);
      }
    });

    test('le budget ne se lit que salle ouverte, en direct ou horaire '
        'incertain', () {
      expect(budgetUtile(EtatSeanceFamille.enDirect), isTrue);
      expect(budgetUtile(EtatSeanceFamille.horaireIncertain), isTrue);
      expect(budgetUtile(EtatSeanceFamille.aVenir), isFalse);
      expect(budgetUtile(EtatSeanceFamille.annulee), isFalse);
    });

    test('bandeau : salle ouverte a droite le compte a rebours, en direct la '
        'presence', () {
      final AffichageSeance salle = AffichageSeance.depuis(
        _salleOuverte(),
        maintenantServeurUtc: instantServeurFige,
      );
      final ({String gauche, String? droite, TonEtat ton}) b1 = bandeauSeance(
        salle,
      );
      expect(b1.gauche, LibellesGroupe.salleOuverteCourt);
      expect(b1.droite, LibellesGroupe.dansMinutes(10));
      expect(b1.ton, TonEtat.succes);

      final AffichageSeance direct = AffichageSeance.depuis(
        _enDirect(),
        maintenantServeurUtc: instantServeurFige,
      );
      final ({String gauche, String? droite, TonEtat ton}) b2 = bandeauSeance(
        direct,
        presence: 'presence fictive',
      );
      expect(b2.gauche, t.tuteur.accueil.seanceEnDirect);
      expect(b2.droite, 'presence fictive');
    });

    test('seances a venir : de la plus proche a la plus lointaine, closes et '
        'passees ecartees, autre classe ecartee', () {
      final List<SeanceFamille> seances = <SeanceFamille>[
        _salleOuverte(seanceId: 'loin', avant: const Duration(days: 3)),
        _salleOuverte(seanceId: 'proche'),
        _salleOuverte(
          seanceId: 'passee',
          avant: const Duration(days: -2),
          statut: StatutSeance.terminee,
        ),
        seanceFictive(
          seanceId: 'autre-eleve',
          eleveId: 'foyer-a-eleve-2',
          debutUtc: instantServeurFige.add(const Duration(days: 1)),
        ),
      ];
      final List<SeanceFamille> retenues = seancesAVenir(
        seances,
        classeId: _classe,
        eleveId: _a1,
        referenceUtc: instantServeurFige,
      );
      expect(retenues.map((SeanceFamille s) => s.seanceId), <String>[
        'proche',
        'loin',
      ]);
    });

    test(
      'travaux : echeance la plus proche d abord, retires ecartes',
      () async {
        final List<LearningAssignment> travaux = travauxAffiches(
          await (await _travaux()).pourGroupe(_classe, studentId: _a1),
        );
        expect(travaux, hasLength(2));
        expect(travaux.first.instructions, 'Consigne fictive 1');
        expect(
          statutTravail(StatutAssignation.fait).libelle,
          t.classe.pageTravail.statut.fait,
        );
      },
    );

    test('progression vide : ni niveau ni etape', () {
      expect(progressionVide(const ProgressionEleve(eleveId: _a1)), isTrue);
      expect(
        progressionVide(
          const ProgressionEleve(eleveId: _a1, niveauHumain: 'N'),
        ),
        isFalse,
      );
    });
  });
}
