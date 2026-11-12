// Fixtures de projection enseignant, et l'outillage qui prouve l'absence de
// PII famille.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.
//
// CE QUE CE FICHIER PROUVE, ET CE QU'IL NE PROUVE PAS.
// Il ne remplace pas la protection reelle, qui est SERVEUR : `teacher_roster_v`
// ne delivre pas les colonnes interdites, et `profiles` n'accorde aucune
// policy `select` a l'enseignant (CONTRACTS section 0). Ce fichier verifie la
// seconde ligne de defense : qu'aucun code client ne reconstitue, ne recopie
// ni ne laisse passer une donnee interdite qui arriverait quand meme.

import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';

import 'contrats/contrats_d_outils.dart';
import 'contrats/contrats_e_classe.dart';

/// Le vocabulaire interdit dans toute projection enseignant.
///
/// Chaque entree est un fragment en minuscules, cherche **dans les noms de
/// champs comme dans les valeurs**. La liste suit mot pour mot l'invariant PII
/// de CONTRACTS section 0, augmentee des formes anglaises que porte le schema
/// et des variantes qu'un copier-coller produirait.
const List<String> motsInterditsPii = <String>[
  // Nom de famille -- y compris une initiale (decision D-08).
  'last_name',
  'lastname',
  'nom_famille',
  'nomfamille',
  'surname',
  'family_name',
  'initiale',
  // Coordonnees.
  'phone',
  'telephone',
  'mobile',
  'email',
  'courriel',
  'adresse',
  'address',
  'postal',
  'code_postal',
  // Geolocalisation.
  'latitude',
  'longitude',
  'geoloc',
  'gps',
  'coordonnees_gps',
  // Tuteurs et foyer.
  'tuteur',
  'guardian',
  'household',
  'foyer',
  'parent',
  // Argent.
  'iban',
  'paiement',
  'payment',
  'facture',
  'invoice',
  'solde',
  'balance',
  'wallet',
  'payout',
  'carte_bancaire',
  // Appareil.
  'device_id',
  'deviceid',
  'identifiant_appareil',
  'push_token',
  'fcm',
];

/// Une ligne serveur **empoisonnee** : ce qu'une vue qui fuirait renverrait.
///
/// Elle sert de piege : la projection doit ignorer toutes ces colonnes. Les
/// valeurs sont volontairement reconnaissables, pour qu'un test puisse les
/// chercher telles quelles dans la sortie.
Map<String, Object?> ligneServeurEmpoisonnee() => <String, Object?>{
  // Les colonnes legitimes de `teacher_roster_v`.
  'first_name': 'Amina',
  'immutable_id': 'RA-AB0012',
  'level': 'n2',
  'riwaya': 'hafs',
  // Tout ce qui suit ne doit JAMAIS ressortir.
  'last_name': 'Benali',
  'nom_famille': 'Benali',
  'initiale_nom': 'B.',
  'email': 'famille.benali@exemple.invalid',
  'phone': '+33600000000',
  'adresse': '12 rue des Oliviers, Lyon',
  'latitude': 45.764,
  'longitude': 4.835,
  'household_id': 'foyer-77',
  'guardian_first_name': 'Nadia',
  'iban': 'FR7630001007941234567890185',
  'solde_minor': 12_500,
  'device_id': 'ANDROID-9f2c41',
};

/// Construit une projection a partir d'une ligne serveur.
///
/// **Elle ne lit que les colonnes autorisees, nommement.** Aucune boucle
/// generique sur les cles, aucun `Map.from`, aucun passe-plat : un jour ou la
/// vue gagnerait une colonne, ce code ne la propagerait pas par accident.
///
/// C'est le double de ce que le service d'Agent E doit faire ; la vraie
/// barriere reste la vue serveur.
TeacherStudentProjection projectionDepuisLigneServeur(
  Map<String, Object?> ligne, {
  EtatPresenceProjete liveStatus = EtatPresenceProjete.inconnu,
  bool interfaceGuidee = false,
  List<LearningAssignment> assignations = const <LearningAssignment>[],
}) {
  final Object? prenom = ligne['first_name'];
  final Object? identifiant = ligne['immutable_id'];
  final Object? niveau = ligne['level'];
  return TeacherStudentProjection(
    firstName: prenom is String ? prenom : '',
    academyId: identifiant is String ? identifiant : '',
    level: niveau is String ? niveau : null,
    activeGoals: const <String>[],
    currentAssignments: assignations,
    authorizedPedagogicalNotes: const <String>[],
    liveStatus: liveStatus,
    interfaceGuidee: interfaceGuidee,
  );
}

/// Aplatit une projection en couples cle / valeur, **imbrication comprise**.
///
/// Un test qui ne regarderait que le premier niveau laisserait passer une PII
/// cachee dans `lastLesson` ou dans une assignation. Celui-ci descend.
Map<String, Object?> aplatirPourAudit(TeacherStudentProjection p) {
  final Map<String, Object?> plat = <String, Object?>{
    'firstName': p.firstName,
    'academyId': p.academyId,
    'level': p.level,
    'curriculumPath': p.curriculumPath,
    'currentUnit': p.currentUnit,
    'liveStatus': p.liveStatus.name,
    'interfaceGuidee': p.interfaceGuidee,
  };
  for (int i = 0; i < p.activeGoals.length; i++) {
    plat['activeGoals[$i]'] = p.activeGoals[i];
  }
  for (int i = 0; i < p.authorizedPedagogicalNotes.length; i++) {
    plat['authorizedPedagogicalNotes[$i]'] = p.authorizedPedagogicalNotes[i];
  }
  final ResumeSeance? derniere = p.lastLesson;
  if (derniere != null) {
    plat['lastLesson.dateUtc'] = derniere.dateUtc.toIso8601String();
    plat['lastLesson.pointARevoir'] = derniere.pointARevoir;
    plat.addAll(
      _aplatirPosition(
        'lastLesson.positionAtteinte',
        derniere.positionAtteinte,
      ),
    );
  }
  plat.addAll(_aplatirPosition('resumePoints', p.resumePoints));
  final AssiduiteRecente? assiduite = p.recentAttendance;
  if (assiduite != null) {
    plat['recentAttendance.presences'] = assiduite.presences;
    plat['recentAttendance.total'] = assiduite.total;
  }
  for (int i = 0; i < p.currentAssignments.length; i++) {
    final LearningAssignment a = p.currentAssignments[i];
    plat['currentAssignments[$i].id'] = a.id;
    plat['currentAssignments[$i].groupId'] = a.groupId;
    plat['currentAssignments[$i].studentId'] = a.studentId;
    plat['currentAssignments[$i].resourceId'] = a.resourceId;
    plat['currentAssignments[$i].purpose'] = a.purpose.valeurSql;
    plat['currentAssignments[$i].instructions'] = a.instructions;
    plat['currentAssignments[$i].createdBy'] = a.createdBy;
    plat['currentAssignments[$i].status'] = a.status.name;
  }
  return plat;
}

Map<String, Object?> _aplatirPosition(String prefixe, ContentPosition? p) {
  if (p == null) return const <String, Object?>{};
  return <String, Object?>{
    '$prefixe.resourceId': p.resourceId,
    '$prefixe.typeAncrage': p.typeAncrage.valeurSql,
    '$prefixe.page': p.page,
    '$prefixe.sourate': p.sourate,
    '$prefixe.ayah': p.ayah,
  };
}

/// Une projection complete, riche, et **sans aucune PII**.
///
/// Riche volontairement : un test de PII sur un objet vide ne prouve rien.
final TeacherStudentProjection projectionAmina = TeacherStudentProjection(
  firstName: 'Amina',
  academyId: 'RA-AB0012',
  level: 'n2',
  curriculumPath: 'coran/memorisation',
  currentUnit: 'Juz 30 - An-Naba',
  activeGoals: const <String>['Fluidite sur An-Naba', 'Madd de 4 temps'],
  lastLesson: ResumeSeance(
    dateUtc: DateTime.utc(2026, 10, 12, 16),
    positionAtteinte: const ContentPosition.ayah(
      resourceId: 'res-coran',
      sourate: 78,
      ayah: 20,
    ),
    pointARevoir: 'Confusion sad / sin',
  ),
  resumePoints: const ContentPosition.ayah(
    resourceId: 'res-coran',
    sourate: 78,
    ayah: 21,
  ),
  recentAttendance: const AssiduiteRecente(presences: 8, total: 9),
  currentAssignments: const <LearningAssignment>[],
  authorizedPedagogicalNotes: const <String>[
    'Travaille mieux quand elle recite en premier.',
  ],
  liveStatus: EtatPresenceProjete.present,
  interfaceGuidee: true,
);

/// Une projection minimale : lecture partielle, presence inconnue.
///
/// `liveStatus == inconnu` et **jamais `absent`** : ne pas savoir n'est pas
/// une absence (invariant J3 du depot).
const TeacherStudentProjection projectionLectureEchouee =
    TeacherStudentProjection(
      firstName: 'Idriss',
      academyId: 'RA-CD0044',
      activeGoals: <String>[],
      currentAssignments: <LearningAssignment>[],
      authorizedPedagogicalNotes: <String>[],
      liveStatus: EtatPresenceProjete.inconnu,
      interfaceGuidee: false,
    );

/// Deux eleves de meme prenom : la desambiguisation passe par l'academyId.
const TeacherStudentProjection projectionAminaHomonyme =
    TeacherStudentProjection(
      firstName: 'Amina',
      academyId: 'RA-ZZ0901',
      activeGoals: <String>[],
      currentAssignments: <LearningAssignment>[],
      authorizedPedagogicalNotes: <String>[],
      liveStatus: EtatPresenceProjete.attendu,
      interfaceGuidee: false,
    );

/// Le roster de fixture.
List<TeacherStudentProjection> rosterDeFixture() => <TeacherStudentProjection>[
  projectionAmina,
  projectionLectureEchouee,
  projectionAminaHomonyme,
];
