/// L'intention pedagogique : ce qu'un marqueur, un trait ou un travail VEUT
/// dire, et non la couleur qu'il prend.
///
/// **Contrat produit par Agent D** (`TEACHING_CORE_CONTRACTS.md` section 10),
/// consomme par C, E, F, H et Q. Il n'existe **pas** un second vocabulaire
/// d'intentions : `LearningAssignment.purpose` reutilise exactement celui-ci
/// (invariant 3 de la section 11).
///
/// **La couleur derive de l'intention, jamais l'inverse.** La derivation vit
/// dans `couleur_intention.dart`, elle n'est ni dans cet enum ni dans un ecran :
/// on marque une intention semantique, on ne choisit pas une couleur brute.
library;

/// Les cinq intentions pedagogiques.
///
/// Les libelles utilisateur sont fixes par la spec section 8.2 et vivent dans
/// `libelles_tc_outils.dart` : « A apprendre », « A revoir », « A renforcer »,
/// « A entretenir », « Pour l'evaluation ».
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
  ///
  /// Les valeurs sont celles que `TEACHING_CORE_CONTRACTS.md` section 11 donne
  /// en commentaire de `LearningAssignment.purpose` : `learn | review |
  /// reinforce | maintain | assessment`. La table n'existe pas encore : la
  /// demande SQL de `TC_CONTRACT_REQUEST_D.md` reprend ces cinq valeurs
  /// litteralement, pour que le miroir Dart et l'enum SQL ne puissent pas
  /// diverger en silence.
  final String valeurSql;

  /// Lit une intention depuis sa valeur SQL.
  ///
  /// Rend `null` sur valeur inconnue : **jamais de repli silencieux** sur une
  /// intention par defaut, qui ferait passer une faiblesse pour une revision.
  static IntentionPedagogique? depuisSql(String? valeur) {
    for (final IntentionPedagogique intention in IntentionPedagogique.values) {
      if (intention.valeurSql == valeur) {
        return intention;
      }
    }
    return null;
  }
}
