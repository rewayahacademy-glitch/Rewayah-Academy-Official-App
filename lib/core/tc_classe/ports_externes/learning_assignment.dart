// TC-STUB-PORT: canonique = lib/core/tc_outils/learning_assignment.dart (Agent D)
//            + lib/core/tc_outils/intention_pedagogique.dart (Agent D)
// Signature copiee A L'IDENTIQUE depuis les fichiers canoniques d'Agent D, eux
// memes conformes a TEACHING_CORE_CONTRACTS.md sections 10 et 11.
// Agent Z supprime ce fichier a l'integration et pointe sur les canoniques.
//
// Pourquoi Agent E le stube : `TeacherStudentProjection.currentAssignments` est
// une `List<LearningAssignment>` dans le contrat. La fiche pedagogique de seance
// n'en lit que `purpose`, `instructions` et `contentRange` -- elle n'en
// construit aucun.

import 'package:flutter/foundation.dart';

import 'content_range.dart';

/// Les cinq intentions pedagogiques.
///
/// **La couleur derive de l'intention, jamais l'inverse.** La derivation
/// appartient a Agent D ; Agent E n'affiche qu'un libelle.
enum IntentionPedagogique {
  /// Contenu nouveau.
  aApprendre('learn'),

  /// Revision normale.
  aRevoir('review'),

  /// Faiblesse constatee, a retravailler.
  aRenforcer('reinforce'),

  /// Maintien de l'acquis.
  aEntretenir('maintain'),

  /// Perimetre evalue.
  pourEvaluation('assessment');

  const IntentionPedagogique(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit une intention depuis sa valeur SQL. `null` sur valeur inconnue.
  static IntentionPedagogique? depuisSql(String? valeur) {
    for (final IntentionPedagogique intention in IntentionPedagogique.values) {
      if (intention.valeurSql == valeur) {
        return intention;
      }
    }
    return null;
  }
}

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
