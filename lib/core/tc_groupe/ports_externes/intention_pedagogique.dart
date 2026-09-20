// TC-STUB-PORT: canonique = lib/core/tc_outils/annotation_layer.dart (Agent D)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 10.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.

/// Pourquoi un contenu est travaille.
///
/// **La couleur derive de l'intention, jamais l'inverse.** Ce type est le seul
/// vocabulaire d'intention du produit : `LearningAssignment.purpose` le
/// reutilise tel quel, il n'en existe pas un second.
///
/// Libelles utilisateur : « A apprendre », « A revoir », « A renforcer »,
/// « A entretenir », « Pour l'evaluation ».
enum IntentionPedagogique {
  /// A apprendre.
  aApprendre,

  /// A revoir.
  aRevoir,

  /// A renforcer.
  aRenforcer,

  /// A entretenir.
  aEntretenir,

  /// Pour l'evaluation.
  pourEvaluation,
}
