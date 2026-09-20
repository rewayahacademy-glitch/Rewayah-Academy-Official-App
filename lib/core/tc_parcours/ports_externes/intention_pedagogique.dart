// TC-STUB-PORT: canonique = lib/core/tc_outils/intention_pedagogique.dart (Agent D)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 10, verifiee
// mot pour mot contre le fichier publie par Agent D.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
library;

/// Les cinq intentions pedagogiques.
///
/// Les libelles utilisateur sont fixes par la spec section 8.2 : « A apprendre »,
/// « A revoir », « A renforcer », « A entretenir », « Pour l'evaluation ». Ils
/// vivent chez leur proprietaire (Agent D) ; le lot H les reprend dans sa propre
/// facade de libelles, sans en inventer un sixieme.
///
/// **Il n'existe pas un second vocabulaire d'intentions** :
/// `LearningAssignment.purpose` reutilise exactement celui-ci (invariant 3 de la
/// section 11).
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

  /// Lit une intention depuis sa valeur SQL.
  ///
  /// Rend `null` sur valeur inconnue : **jamais de repli silencieux**, qui
  /// ferait passer une faiblesse pour une revision.
  static IntentionPedagogique? depuisSql(String? valeur) {
    for (final IntentionPedagogique intention in IntentionPedagogique.values) {
      if (intention.valeurSql == valeur) {
        return intention;
      }
    }
    return null;
  }
}
