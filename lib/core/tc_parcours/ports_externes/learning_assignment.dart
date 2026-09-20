// TC-STUB-PORT: canonique = lib/core/tc_outils/learning_assignment.dart (Agent D)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 11, verifiee
// mot pour mot contre le fichier publie par Agent D.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
import 'package:flutter/foundation.dart';

import '../../tc_bibliotheque/content_range.dart';
import 'intention_pedagogique.dart';

/// Ou en est un travail a preparer.
enum StatutAssignation {
  /// Pose, pas encore ouvert.
  aFaire('a_faire'),

  /// Commence.
  enCours('en_cours'),

  /// Termine.
  fait('fait'),

  /// L'echeance est passee sans que le travail soit fait.
  expire('expire'),

  /// Retire par qui l'a pose.
  annule('annule');

  const StatutAssignation(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` sur valeur inconnue.
  static StatutAssignation? depuisSql(String? valeur) {
    for (final StatutAssignation statut in StatutAssignation.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// Le travail a preparer, cree depuis une selection.
///
/// **Contrat produit par Agent D** (`TEACHING_CORE_CONTRACTS.md` section 11),
/// consomme par A (slot « Avant le prochain cours »), E et H.
@immutable
class LearningAssignment {
  /// Cree un travail a preparer.
  LearningAssignment({
    required this.id,
    required this.groupId,
    required this.resourceId,
    required this.purpose,
    required this.startsAtUtc,
    required this.createdBy,
    required this.status,
    this.studentId,
    this.resourceVersionId,
    this.contentRange,
    this.instructions,
    this.dueAtUtc,
  }) : assert(startsAtUtc.isUtc, 'tout instant de contrat est en UTC'),
       assert(
         dueAtUtc == null || dueAtUtc.isUtc,
         'tout instant de contrat est en UTC',
       ),
       assert(
         dueAtUtc == null || !dueAtUtc.isBefore(startsAtUtc),
         'une echeance ne precede pas le debut',
       ),
       assert(
         contentRange == null || contentRange.resourceId == resourceId,
         'la plage appartient a la ressource assignee',
       );

  /// L'identifiant du travail.
  final String id;

  /// Le groupe concerne.
  final String groupId;

  /// L'eleve concerne. `null` = tout le groupe, et **c'est le cas par defaut**.
  final String? studentId;

  /// La ressource a travailler.
  final String resourceId;

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// La plage a travailler. `null` = la ressource entiere.
  final ContentRange? contentRange;

  /// L'intention. **Le meme vocabulaire que les marqueurs**, jamais un second.
  final IntentionPedagogique purpose;

  /// Une consigne courte, facultative.
  final String? instructions;

  /// Le debut de la periode de travail, en UTC.
  final DateTime startsAtUtc;

  /// L'echeance, en UTC. `null` = aucune echeance.
  final DateTime? dueAtUtc;

  /// Le profil qui a pose le travail.
  final String createdBy;

  /// L'etat courant.
  final StatutAssignation status;

  /// Vrai quand le travail s'adresse a tout le groupe.
  bool get estDeGroupe => studentId == null;

  /// Le meme travail, dans un autre etat.
  LearningAssignment avecStatut(StatutAssignation nouveau) =>
      LearningAssignment(
        id: id,
        groupId: groupId,
        studentId: studentId,
        resourceId: resourceId,
        resourceVersionId: resourceVersionId,
        contentRange: contentRange,
        purpose: purpose,
        instructions: instructions,
        startsAtUtc: startsAtUtc,
        dueAtUtc: dueAtUtc,
        createdBy: createdBy,
        status: nouveau,
      );

  @override
  bool operator ==(Object other) =>
      other is LearningAssignment &&
      other.id == id &&
      other.groupId == groupId &&
      other.studentId == studentId &&
      other.resourceId == resourceId &&
      other.resourceVersionId == resourceVersionId &&
      other.contentRange == contentRange &&
      other.purpose == purpose &&
      other.instructions == instructions &&
      other.startsAtUtc == startsAtUtc &&
      other.dueAtUtc == dueAtUtc &&
      other.createdBy == createdBy &&
      other.status == status;

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    studentId,
    resourceId,
    resourceVersionId,
    contentRange,
    purpose,
    instructions,
    startsAtUtc,
    dueAtUtc,
    createdBy,
    status,
  );
}
