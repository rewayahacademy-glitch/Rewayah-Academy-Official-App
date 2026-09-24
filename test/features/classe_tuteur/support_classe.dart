// Doubles et surcharges partages des tests et captures de la Classe du tuteur
// (lot C, sous-paquet 2). Donnees fictives uniquement : aucune n'est servie
// par un provider de `lib/`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_observation/activation_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';

/// Le premier profil retenu : « Eleve A1 » (tri par prenom, contrat K1).
const String eleveA1 = 'foyer-a-eleve-1';

/// La classe fictive du foyer A.
const String classeA = 'classe-a';

/// Une seance a venir, salle ouverte (fenetre fictive de 20 min), dans 10 min
/// et 30 s par defaut.
SeanceFamille seanceSalleOuverte({
  StatutSeance? statut = StatutSeance.planifiee,
  Duration avant = const Duration(minutes: 10, seconds: 30),
  String seanceId = 's1',
  bool avecHorloge = true,
  String heure = '18:10',
  String date = 'Lundi 21 septembre',
}) => seanceFictive(
  seanceId: seanceId,
  eleveId: eleveA1,
  debutUtc: instantServeurFige.add(avant),
  statut: statut,
  avecHorloge: avecHorloge,
  heureFoyer: heureRendue('Europe/Paris', 'Paris', heure, date: date),
);

/// Une seance en direct depuis dix minutes (scenario de la maquette M1).
SeanceFamille seanceEnDirect({Duration duree = const Duration(minutes: 45)}) =>
    seanceFictive(
      seanceId: 's1',
      eleveId: eleveA1,
      debutUtc: instantServeurFige.subtract(const Duration(minutes: 10)),
      duree: duree,
      statut: StatutSeance.enCours,
      heureFoyer: heureRendue('Europe/Paris', 'Paris', '17:50'),
    );

/// La presence d'Eleve A1 : en salle.
const PresenceParticipant presenceA1 = PresenceParticipant(
  profilId: eleveA1,
  role: 'student',
  prenom: 'Eleve A1',
  identifiantImmuable: 'STUD-FA-000001',
  etat: EtatPresence.presente,
  consolide: false,
);

/// La politique et le budget d'observation, en memoire.
class FaussePolitiqueClasse implements PortPolitiqueObservation {
  /// Cree le faux.
  FaussePolitiqueClasse(this.budgetRendu);

  /// Le budget rendu.
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
class FausseVisiteClasse implements PortVisiteObservation {
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
LibraryResource ressourceFictive(
  String id,
  String titre, {
  TypeRessource type = TypeRessource.pdf,
}) => LibraryResource(
  id: id,
  title: titre,
  shortTitle: titre,
  resourceType: type,
  language: 'fr',
  category: 'fictive',
  accessPolicy: PolitiqueAcces.groupeAssigne,
  offlinePolicy: PolitiqueOffline.jamais,
);

/// Un catalogue BRANCHE (pas le catalogue local), en memoire.
class FauxCatalogueClasse implements PortCatalogue {
  /// Cree le faux.
  const FauxCatalogueClasse(this.ressources);

  /// Les ressources de la classe A.
  final List<LibraryResource> ressources;

  @override
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre}) async =>
      ressources;

  @override
  Future<List<LibraryResource>> recents({int limite = 10}) async =>
      const <LibraryResource>[];

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async =>
      groupeId == classeA ? ressources : const <LibraryResource>[];

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
class FausseProgressionClasse implements PortProgressionFamille {
  /// Cree le faux.
  const FausseProgressionClasse(this.rendue);

  /// La progression rendue.
  final ProgressionEleve rendue;

  @override
  Future<ProgressionEleve> progression(String eleveId) async => rendue;
}

/// La classe fictive A avec un parcours lisible (ligne « cours · niveau » de
/// la maquette M1), en donnees fictives.
PortClassesFoyer classesAvecParcours() => FauxClassesFoyer(
  classes: <ClasseFoyer>[
    const ClasseFoyer(
      eleveId: eleveA1,
      classe: GroupSummaryVM(
        groupeId: classeA,
        libelle: 'Classe fictive A',
        couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'g0'),
        enseignant: EnseignantVM(
          enseignantId: 'enseignant-x',
          titre: TitreEnseignant.sayyid,
          nomAffichage: 'Enseignant X',
        ),
        nombreMembres: 3,
        seuilMax: 6,
        typePublic: TypePublicGroupeVM.enfant,
        actif: true,
        nomCours: 'Cours fictif',
        niveauHumain: 'Niveau fictif',
      ),
    ),
  ],
);

/// Un port des classes qui echoue a la premiere lecture (reseau, service),
/// puis rend la classe fictive A : « Reessayer » relit vraiment.
class ClassesEnEchecPuisRendues implements PortClassesFoyer {
  /// Le nombre de lectures demandees.
  int lectures = 0;

  final FauxClassesFoyer _rendues = FauxClassesFoyer(
    classes: <ClasseFoyer>[
      ClasseFoyer(eleveId: eleveA1, classe: classeFictive()),
    ],
  );

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) =>
      _rendues.classesDe(eleveId);

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async {
    lectures++;
    if (lectures == 1) {
      throw StateError('lecture fictive en echec');
    }
    return _rendues.classe(groupeId: groupeId, eleveId: eleveId);
  }
}

/// Trois travaux fictifs, dont un fait et un retire (jamais montre).
Future<AssignationsMemoire> travauxFictifs() async {
  final AssignationsMemoire depot = AssignationsMemoire(
    'enseignant-x',
    maintenant: () => instantServeurFige,
  );
  await depot.creerDepuisSelection(
    groupId: classeA,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aRevoir,
    instructions: 'Consigne fictive 1',
    dueAtUtc: instantServeurFige.add(const Duration(days: 2)),
  );
  final LearningAssignment fait = await depot.creerDepuisSelection(
    groupId: classeA,
    studentId: eleveA1,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aApprendre,
    instructions: 'Consigne fictive 2',
  );
  await depot.changerStatut(fait.id, StatutAssignation.fait);
  final LearningAssignment retire = await depot.creerDepuisSelection(
    groupId: classeA,
    resourceId: 'r1',
    purpose: IntentionPedagogique.aEntretenir,
    instructions: 'Consigne retiree',
  );
  await depot.changerStatut(retire.id, StatutAssignation.annule);
  return depot;
}

/// Les surcharges d'un montage du vrai routeur pour la Classe : tuteur actif,
/// foyer fictif A (un appareil pret pour A1), seances, classe fictive A,
/// observation (interrupteur, politique, budget, presence), travail,
/// bibliotheque et progression.
List<Override> surchargesClasse({
  List<SeanceFamille>? seances,
  PortClassesFoyer? portClasses,
  bool observation = false,
  BudgetObservation? budget,
  List<PresenceParticipant>? presence,
  PortAssignations? travail,
  PortCatalogue? catalogue,
  PortProgressionFamille? progression,
  bool horlogeAbsente = false,
  bool horsLigne = false,
  bool seancesIndisponibles = false,
}) {
  final FauxSeancesFamille faux = FauxSeancesFamille(
    seances: seances ?? <SeanceFamille>[seanceSalleOuverte()],
  );
  if (horlogeAbsente) {
    faux.maintenant = null;
  }
  if (seancesIndisponibles) {
    faux.erreurAJeter = const CapaciteIndisponible('DB-CRS-03');
  }
  return <Override>[
    ...surchargesRouteur(
      FausseSourceSession(sessionActive(AppRole.guardian)),
      appairage: FauxServiceAppairage()
        ..elevesRendus = FoyersFictifs.foyerA
        ..appareilsRendus = <AppareilAppaire>[
          AppareilAppaire(
            id: 'app-1',
            profilId: eleveA1,
            prenom: 'Eleve A1',
            plateforme: 'Android',
            appaireA: DateTime.utc(2026, 9, 1),
          ),
        ],
    ),
    portSeancesFamilleProvider.overrideWithValue(faux),
    portClassesFoyerProvider.overrideWithValue(
      portClasses ??
          FauxClassesFoyer(
            classes: <ClasseFoyer>[
              ClasseFoyer(eleveId: eleveA1, classe: classeFictive()),
            ],
          ),
    ),
    observationTuteurReelleProvider.overrideWithValue(observation),
    portPolitiqueObservationProvider.overrideWithValue(
      FaussePolitiqueClasse(budget ?? budgetDeuxVisites),
    ),
    portVisiteObservationProvider.overrideWithValue(FausseVisiteClasse()),
    moteurSalleProvider.overrideWithValue(FauxMoteurSalle()),
    presenceSeanceProvider.overrideWith(
      (Ref _, String _) => Stream<List<PresenceParticipant>?>.value(presence),
    ),
    assignationsFamilleProvider.overrideWithValue(travail),
    if (catalogue != null) portCatalogueProvider.overrideWithValue(catalogue),
    if (progression != null)
      portProgressionFamilleProvider.overrideWithValue(progression),
    if (horsLigne)
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
  ];
}
