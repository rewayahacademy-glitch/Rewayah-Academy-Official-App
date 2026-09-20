// TC-STUB-PORT: canonique = lib/core/tc_classe/teacher_student_projection.dart (Agent E)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 12, verifiee
// mot pour mot contre le fichier publie par Agent E.
//
// L'AMENDEMENT 2 conseille de ne PAS stuber une chaine de types ouverte. Ici
// elle est **close pour le lot H** : `ContentPosition` et `LearningAssignment`
// sont deja stubes parce que `PostCoursVM` en a besoin par ailleurs, et il ne
// reste que trois types de valeur. Et `PostCoursVM` porte, par contrat,
// `List<TeacherStudentProjection>` : ne pas le stuber aurait oblige a faire
// diverger un contrat produit par le lot H, ce qui coute plus cher.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
import 'package:flutter/foundation.dart';

import '../../tc_bibliotheque/content_position.dart';
import '../../tc_outils/learning_assignment.dart';

/// L'etat d'un eleve dans la seance, projete pour l'enseignant.
///
/// **Neuf valeurs, dont [inconnu], et [inconnu] n'est pas « absent ».** C'est
/// l'invariant J3 du depot : une lecture qui echoue rend `inconnu`. « Absente »
/// est un fait qui compte pour le suivi et la facturation ; ne pas savoir n'en
/// est pas un.
enum EtatPresenceProjete {
  /// L'etat live n'est pas derivable. **Jamais « absent ».**
  inconnu('inconnu'),

  /// Inscrit, la fenetre est ouverte, personne n'est encore entre.
  attendu('attendu'),

  /// Un jeton vient d'etre emis, la connexion est en cours.
  enConnexion('en_connexion'),

  /// Entre, et toujours la.
  present('present'),

  /// Entre apres l'heure, au-dela du seuil configure.
  enRetard('en_retard'),

  /// Le lien a lache sans geste volontaire.
  deconnecte('deconnecte'),

  /// Le lien a lache, la fenetre de retour court encore.
  enReconnexion('en_reconnexion'),

  /// Parti volontairement.
  sorti('sorti'),

  /// La seance est finie et cette personne n'est jamais entree.
  absent('absent');

  const EtatPresenceProjete(this.valeurSql);

  /// La valeur de projection. Elle n'est **pas** celle de `presence_state`.
  final String valeurSql;

  /// Vrai quand l'enseignant a quelque chose a faire de cet etat.
  bool get demandeUneReaction => switch (this) {
    EtatPresenceProjete.inconnu ||
    EtatPresenceProjete.absent ||
    EtatPresenceProjete.enRetard ||
    EtatPresenceProjete.deconnecte ||
    EtatPresenceProjete.enReconnexion => true,
    EtatPresenceProjete.attendu ||
    EtatPresenceProjete.enConnexion ||
    EtatPresenceProjete.present ||
    EtatPresenceProjete.sorti => false,
  };

  /// Vrai quand la personne est effectivement dans la salle en ce moment.
  bool get enSalle =>
      this == EtatPresenceProjete.present ||
      this == EtatPresenceProjete.enRetard;
}

/// Ce que la seance precedente a laisse.
@immutable
class ResumeSeance {
  /// Cree un resume de seance.
  ResumeSeance({
    required this.dateUtc,
    this.positionAtteinte,
    this.pointARevoir,
  }) : assert(dateUtc.isUtc, 'tout instant de contrat est en UTC');

  /// La date de la seance concernee, en UTC.
  final DateTime dateUtc;

  /// Ou la lecture s'est arretee.
  final ContentPosition? positionAtteinte;

  /// Le point a reprendre, redige court.
  final String? pointARevoir;
}

/// L'assiduite recente, telle qu'elle se lit : « 8 / 9 cours ».
///
/// **Le sort du cours prime sur l'etat de la personne** : un cours annule ou non
/// tenu n'entre pas dans [total], sans quoi l'eleve porterait l'absence de son
/// professeur (`SortDuCours`, deja tranche dans le depot).
@immutable
class AssiduiteRecente {
  /// Cree une assiduite.
  const AssiduiteRecente({required this.presences, required this.total})
    : assert(presences >= 0, 'un compte de presences n est jamais negatif'),
      assert(presences <= total, 'on ne peut pas etre present plus que prevu');

  /// Le nombre de cours ou l'eleve etait la.
  final int presences;

  /// Le nombre de cours **reellement tenus** sur la periode.
  final int total;
}

/// La vue pedagogique restreinte d'un eleve, pour l'enseignant.
///
/// **Le contrat le plus important du chantier** : connaissance pedagogique
/// forte, connaissance privee minimale (spec section 10). Ce type ne porte, a
/// aucun niveau d'imbrication : ni telephone, ni email, ni adresse, ni
/// geolocalisation, ni identite des tuteurs, ni paiement, **ni nom de famille,
/// pas meme une initiale** (decision D-08, ADR-008).
@immutable
class TeacherStudentProjection {
  /// Cree une projection.
  const TeacherStudentProjection({
    required this.firstName,
    required this.academyId,
    required this.liveStatus,
    required this.interfaceGuidee,
    this.level,
    this.curriculumPath,
    this.currentUnit,
    this.activeGoals = const <String>[],
    this.lastLesson,
    this.resumePoints,
    this.recentAttendance,
    this.currentAssignments = const <LearningAssignment>[],
    this.authorizedPedagogicalNotes = const <String>[],
  });

  /// Le prenom. **Seul, et jamais accompagne d'une initiale de nom.**
  final String firstName;

  /// L'identifiant d'academie, `profiles.immutable_id`, par exemple `RA-AB0012`.
  final String academyId;

  /// Le niveau humain, jamais un code technique. `null` quand il est inconnu.
  final String? level;

  /// Le parcours dans le programme.
  final String? curriculumPath;

  /// L'unite en cours.
  final String? currentUnit;

  /// Les objectifs actifs, courts.
  final List<String> activeGoals;

  /// Ce que la derniere seance a laisse.
  final ResumeSeance? lastLesson;

  /// Ou reprendre la lecture.
  final ContentPosition? resumePoints;

  /// L'assiduite recente. `null` = indisponible, **jamais zero par defaut**.
  final AssiduiteRecente? recentAttendance;

  /// Le travail en cours, pose par le Teaching Dock.
  final List<LearningAssignment> currentAssignments;

  /// Les notes pedagogiques que cet enseignant a le droit de lire.
  final List<String> authorizedPedagogicalNotes;

  /// L'etat de presence projete. [EtatPresenceProjete.inconnu] si la lecture
  /// echoue.
  final EtatPresenceProjete liveStatus;

  /// Miroir de `student_profiles.interface_mode == 'child'`.
  ///
  /// **Le nom visible est « Interface guidee »** (decision D-07).
  final bool interfaceGuidee;

  /// Vrai quand cette projection porte au moins un fait pedagogique a montrer.
  bool get aDuContenuPedagogique =>
      level != null ||
      curriculumPath != null ||
      currentUnit != null ||
      activeGoals.isNotEmpty ||
      lastLesson != null ||
      resumePoints != null ||
      recentAttendance != null ||
      currentAssignments.isNotEmpty ||
      authorizedPedagogicalNotes.isNotEmpty;
}
