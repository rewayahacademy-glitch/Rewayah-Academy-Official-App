// Doubles partages de FORM-L2 : le test de comportement et les captures
// montent les memes donnees (horloge fixe : toutes les dates sont posees).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/personnes_proposables.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';

final DateTime _inscrit = DateTime(2026, 9, 1, 10);

/// « Aujourd'hui » dans les tests de formulaires : le 4 octobre 2026.
final DateTime aujourdhuiFormL2 = DateTime(2026, 10, 4, 9, 30);

/// Un compte d'administration, inscrit a date fixe.
CompteAdmin compteFormL2(
  String id,
  String identifiant,
  String prenom,
  String nom,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
}) => CompteAdmin(
  profilId: id,
  identifiant: identifiant,
  prenom: prenom,
  nom: nom,
  role: role,
  etat: etat,
  inscritLe: _inscrit,
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.validee,
  contrats: 1,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

/// Deux enseignants actifs, un en attente ; trois eleves actifs (dont un
/// provisoire), un desactive ; un tuteur.
final List<CompteAdmin> comptesFormL2 = <CompteAdmin>[
  compteFormL2('t-amina', 'ENS-AD-001', 'Amina', 'Diallo', AppRole.teacher),
  compteFormL2('t-yacine', 'ENS-YB-002', 'Yacine', 'Benali', AppRole.teacher),
  compteFormL2(
    't-attente',
    'ENS-KO-003',
    'Karim',
    'Ouali',
    AppRole.teacher,
    etat: AccountStatus.pendingKyc,
  ),
  compteFormL2('e-mariam', 'ELV-MS-010', 'Mariam', 'Sow', AppRole.student),
  compteFormL2(
    'e-elias',
    'ELV-EH-011',
    'Élias',
    'Haddad',
    AppRole.student,
    etat: AccountStatus.provisionalActive,
  ),
  compteFormL2('e-ines', 'ELV-IK-012', 'Inès', 'Kader', AppRole.student),
  compteFormL2(
    'e-coupe',
    'ELV-XX-013',
    'Sami',
    'Coupé',
    AppRole.student,
    etat: AccountStatus.disabled,
  ),
  compteFormL2('g-fatou', 'TUT-FN-020', 'Fatou', 'Ndiaye', AppRole.guardian),
];

/// Une lecture des comptes en memoire, qui peut echouer [echecs] fois.
/// D5 : le double de `eleves_proposables_classe`, tire des memes comptes que
/// [FauxComptesFormL2] (les eleves actifs, sans adulte titulaire). Retient
/// les classes lues.
class FauxElevesProposablesFormL2 implements LecteurElevesProposables {
  /// Cree le double.
  FauxElevesProposablesFormL2(this.comptes);

  /// Les comptes dont on tire les eleves.
  final List<CompteAdmin> comptes;

  /// Les classes lues, dans l'ordre.
  final List<String> classesLues = <String>[];

  @override
  Future<List<PersonneProposee>> pourClasse(String groupeId) async {
    classesLues.add(groupeId);
    return personnesProposablesDepuis(comptes, AppRole.student);
  }
}

class FauxComptesFormL2 implements ServiceComptes {
  /// Cree le double.
  FauxComptesFormL2(this.rendus, {this.echecs = 0});

  /// Les comptes rendus.
  final List<CompteAdmin> rendus;

  /// Le nombre de lectures qui echouent avant la premiere qui aboutit.
  int echecs;

  /// Le nombre de lectures faites.
  int lectures = 0;

  @override
  Future<List<CompteAdmin>> comptes() async {
    lectures++;
    if (echecs > 0) {
      echecs--;
      throw Exception('reseau coupe');
    }
    return rendus;
  }
}

/// Une classe active.
GroupeAdmin groupeFormL2() => const GroupeAdmin(
  id: 'g1',
  libelle: 'An-Nour',
  type: TypePublicGroupe.enfant,
  seuilMax: 5,
  teacherId: 't-amina',
  teacherIdentifiant: 'ENS-AD-001',
  teacherPrenom: 'Amina',
  teacherNom: 'Diallo',
  creneau: Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  nombreMembres: 2,
  actif: true,
);

/// Ce qu'une creation a recu, champ par champ (CLASSE-FORM-1 : les valeurs
/// envoyees se mesurent, elles ne se supposent pas).
typedef CreationRecue = ({
  String teacherId,
  TypePublicGroupe type,
  GenreClasse? genre,
  String libelle,
  Creneau creneau,
  int? seuilMax,
});

/// Un service de classes qui retient ce qu'on lui demande.
class FauxGroupesFormL2 implements ServiceGroupes {
  /// Les enseignants pour qui une classe a ete creee.
  final List<String> creesPour = <String>[];

  /// Chaque creation, avec tout ce que le service a recu (pas de genre :
  /// `ServiceGroupes.creer` ne le prend pas).
  final List<CreationRecue> creations = <CreationRecue>[];

  /// Les seuils envoyes par la feuille « Seuil maximal ».
  final List<int> seuilsModifies = <int>[];

  /// L'erreur que `modifier` leve quand elle est posee (CLASSES-DUREE : le
  /// serveur refuse l'horaire que la feuille renvoie).
  Exception? echecModification;

  /// Les ajouts : eleve et motif.
  final List<(String, String)> ajouts = <(String, String)>[];

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[groupeFormL2()];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async =>
      const <MembreGroupe>[];

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  }) async {
    creesPour.add(teacherId);
    creations.add((
      teacherId: teacherId,
      type: type,
      genre: null,
      libelle: libelle,
      creneau: creneau,
      seuilMax: seuilMax,
    ));
    return 'g2';
  }

  @override
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  }) async {
    final Exception? echec = echecModification;
    if (echec != null) throw echec;
    seuilsModifies.add(seuilMax);
  }

  @override
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async => ajouts.add((studentId, motif));

  @override
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> cloturer({
    required String groupeId,
    required String motif,
  }) async {}
}

/// Une creation de classe qui retient tout, genre et fuseau compris
/// (CLASSE-FORM-1), et qui peut echouer [echecs] fois.
class FauxCreationClasse implements PortCreationClasse {
  /// Cree le double.
  FauxCreationClasse({
    this.retientGenre = true,
    this.retientFuseau = true,
    this.echecs = 0,
  });

  @override
  final bool retientGenre;

  @override
  final bool retientFuseau;

  /// Le nombre d'envois qui echouent avant le premier qui aboutit.
  int echecs;

  /// Chaque creation recue.
  final List<CreationRecue> creations = <CreationRecue>[];

  /// Les creneaux suivants de chaque creation (D2, 29/10/2026).
  final List<List<Creneau>> autresCreneauxRecus = <List<Creneau>>[];

  /// La duree de chaque creneau de chaque creation (30/10/2026).
  final List<List<int?>> dureesRecues = <List<int?>>[];

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
    List<int?> durees = const <int?>[],
  }) async {
    if (echecs > 0) {
      echecs--;
      throw Exception('enseignant deja pris a ce creneau');
    }
    creations.add((
      teacherId: teacherId,
      type: type,
      genre: genre,
      libelle: libelle,
      creneau: creneau,
      seuilMax: seuilMax,
    ));
    autresCreneauxRecus.add(autresCreneaux);
    dureesRecues.add(durees);
    return 'c1';
  }
}

/// Une source d'enseignants en memoire (CLASSE-FORM-1).
class FauxEnseignantsClasse implements PortEnseignantsClasse {
  /// Cree le double.
  FauxEnseignantsClasse(this.rendus);

  /// Les enseignants rendus.
  final List<EnseignantPropose> rendus;

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async => rendus;
}

/// Un service d'evaluations qui retient les planifications.
class FauxEvaluationsFormL2 implements ServiceEvaluations {
  /// Eleve, niveau, date.
  final List<(String, String, DateTime)> planifiees =
      <(String, String, DateTime)>[];

  @override
  Future<List<EvaluationAdmin>> toutes() async => const <EvaluationAdmin>[];

  @override
  Future<String> planifier({
    required String studentId,
    required String niveauId,
    required TypeEvaluation type,
    required DateTime datePrevue,
  }) async {
    planifiees.add((studentId, niveauId, datePrevue));
    return 'ev1';
  }

  @override
  Future<void> enregistrerResultat({
    required String evaluationId,
    required ResultatEvaluation resultat,
    String? notes,
  }) async {}

  @override
  Future<void> annuler({
    required String evaluationId,
    required String motif,
  }) async {}
}

final VersionProgramme _version = VersionProgramme(
  id: 'v1',
  statut: StatutVersionProgramme.publiee,
  numeroVersion: 1,
  creeParIdentifiant: 'ADM-001',
  creeParPrenom: null,
  creeParNom: null,
  publieeAt: DateTime(2026, 9, 1),
  nombreNiveaux: 1,
  createdAt: DateTime(2026, 8, 30),
);

/// Le seul niveau du programme publie.
const NiveauProgramme niveauFormL2 = NiveauProgramme(
  id: 'n1',
  codeTechnique: 'F1-PHO-01',
  nomHumain: 'Fondations de lecture',
  cycle: 'Fondations',
  ordre: 1,
  description: null,
);

/// Les surcharges des ecrans Classes et Evaluations.
List<Override> surchargesFormL2({
  required FauxComptesFormL2 comptes,
  FauxGroupesFormL2? groupes,
  FauxEvaluationsFormL2? evaluations,
}) => <Override>[
  // Horloge fixe : les bornes du calendrier de date (FORM-L4) en dependent.
  horlogeFormulairesProvider.overrideWithValue(() => aujourdhuiFormL2),
  serviceComptesProvider.overrideWithValue(comptes),
  lecteurElevesProposablesProvider.overrideWithValue(
    FauxElevesProposablesFormL2(comptes.rendus),
  ),
  serviceGroupesProvider.overrideWithValue(groupes ?? FauxGroupesFormL2()),
  serviceEvaluationsProvider.overrideWithValue(
    evaluations ?? FauxEvaluationsFormL2(),
  ),
  versionActiveProgrammeProvider.overrideWith((Ref ref) async => _version),
  niveauxProgrammeProvider.overrideWith(
    (Ref ref, String versionId) async => const <NiveauProgramme>[niveauFormL2],
  ),
];
