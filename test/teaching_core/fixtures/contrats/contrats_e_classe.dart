// TC-DOUBLE-CONTRAT: canonique =
// lib/core/tc_classe/teacher_student_projection.dart (Agent E).
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 12.
//
// CE FICHIER EST LE PLUS SURVEILLE DU CHANTIER. La liste de ses champs EST
// l'invariant « aucune PII famille chez l'enseignant » (D-08). Le test Q-01
// relit ce fichier caractere par caractere : y ajouter `lastName`, meme sous
// la forme d'une initiale, fait echouer la suite.

import 'package:flutter/foundation.dart';

import 'content_position.dart';
import 'contrats_d_outils.dart';

/// L'etat de presence projete vers l'enseignant.
///
/// `inconnu` quand la lecture echoue. **Jamais `absent`** : c'est l'invariant
/// J3 du depot, deja tenu par `service_presence.dart`.
enum EtatPresenceProjete {
  inconnu,
  attendu,
  enConnexion,
  present,
  enRetard,
  deconnecte,
  enReconnexion,
  sorti,
  absent,
}

/// Le resume de la derniere seance, pour la fiche pedagogique.
@immutable
class ResumeSeance {
  /// Cree un resume.
  ResumeSeance({
    required this.dateUtc,
    this.positionAtteinte,
    this.pointARevoir,
  }) : assert(dateUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// La date, en UTC.
  final DateTime dateUtc;

  /// Ou l'eleve s'est arrete.
  final ContentPosition? positionAtteinte;

  /// Un point a revoir, ex. « Confusion ص / س ».
  final String? pointARevoir;
}

/// L'assiduite recente, sous forme « 8 / 9 cours ».
@immutable
class AssiduiteRecente {
  /// Cree une assiduite.
  const AssiduiteRecente({required this.presences, required this.total})
    : assert(presences >= 0 && total >= presences, 'ratio coherent');

  /// Le nombre de presences.
  final int presences;

  /// Le nombre de cours consideres.
  final int total;
}

/// La vue pedagogique restreinte d'un eleve, cote enseignant.
///
/// **Aucune PII famille, jamais** : ni telephone, ni email, ni adresse, ni
/// geolocalisation, ni identite des tuteurs, ni paiement, ni identifiant
/// d'appareil, ni nom de famille, **y compris une initiale** (CONTRACTS
/// section 0 et section 12, decision D-08).
///
/// La protection tient parce que la vue serveur `teacher_roster_v` ne delivre
/// pas ces colonnes, pas parce qu'une barriere Flutter les filtre. Ce double
/// n'est donc pas la protection : il en est la **specification executable**.
@immutable
class TeacherStudentProjection {
  /// Cree une projection.
  const TeacherStudentProjection({
    required this.firstName,
    required this.academyId,
    required this.activeGoals,
    required this.currentAssignments,
    required this.authorizedPedagogicalNotes,
    required this.liveStatus,
    required this.interfaceGuidee,
    this.level,
    this.curriculumPath,
    this.currentUnit,
    this.lastLesson,
    this.resumePoints,
    this.recentAttendance,
  });

  /// Le **prenom seul**.
  final String firstName;

  /// L'identifiant d'academie, `profiles.immutable_id`, ex. `RA-AB0012`.
  ///
  /// Il remplace le nom de famille dans toute desambiguisation (ADR-008).
  final String academyId;

  /// Le niveau.
  final String? level;

  /// Le chemin de curriculum.
  final String? curriculumPath;

  /// L'unite en cours.
  final String? currentUnit;

  /// Les objectifs actifs.
  final List<String> activeGoals;

  /// La derniere seance.
  final ResumeSeance? lastLesson;

  /// Le point de reprise.
  final ContentPosition? resumePoints;

  /// L'assiduite recente.
  final AssiduiteRecente? recentAttendance;

  /// Les assignations en cours.
  final List<LearningAssignment> currentAssignments;

  /// Les notes pedagogiques que cet enseignant est autorise a lire.
  final List<String> authorizedPedagogicalNotes;

  /// L'etat de presence projete.
  final EtatPresenceProjete liveStatus;

  /// Le miroir de `interface_mode`, **jamais nomme « enfant » en interface**
  /// (decision D-07). La valeur SQL reste `'child'`.
  final bool interfaceGuidee;
}
