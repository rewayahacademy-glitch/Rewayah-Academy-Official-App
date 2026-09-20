// TC-STUB-PORT: canonique = lib/core/tc_outils/annotation_layer.dart (Agent D)
// TC-STUB-PORT: canonique = lib/core/tc_outils/intention_pedagogique.dart (Agent D)
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md section 10, verifiees
// contre les fichiers publies par Agent D.
// Agent Z supprime ce fichier a l integration et pointe sur les canoniques.
//
// Agent F ne consomme de la section 10 que `MarqueurSemantique` et
// `IntentionPedagogique`, parce que `SharedContentState.semanticMarkers` les
// porte. La chaine de types est CLOSE une fois `ContentRange` stube, donc la
// regle de l AMENDEMENT 2 -- ne pas stuber un port a chaine ouverte -- ne
// s applique pas ici : on stube les deux types, jamais `AnnotationLayer` ni
// `TraitVectoriel`, qui transitent en charge JSON opaque.

import 'package:flutter/foundation.dart';

import 'content_range.dart';

/// Les cinq intentions pedagogiques.
///
/// **La couleur derive de l'intention, jamais l'inverse.** La derivation vit
/// chez Agent D ; Agent F ne fait que transporter l'intention.
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

/// Un marqueur semantique pose sur une plage.
@immutable
class MarqueurSemantique {
  /// Cree un marqueur.
  const MarqueurSemantique({
    required this.id,
    required this.plage,
    required this.intention,
    this.note,
  });

  /// L'identifiant du marqueur.
  final String id;

  /// La plage marquee.
  final ContentRange plage;

  /// L'intention portee par le marqueur.
  final IntentionPedagogique intention;

  /// Une note courte, facultative. **Jamais un formulaire.**
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is MarqueurSemantique &&
      other.id == id &&
      other.plage == plage &&
      other.intention == intention &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, plage, intention, note);
}
