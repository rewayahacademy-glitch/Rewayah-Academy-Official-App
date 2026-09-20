// TC-STUB-PORT: canonique = lib/core/tc_outils/annotation_layer.dart (Agent D)
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md section 10.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Seuls les deux types de valeur dont `SharedContentState` a besoin sont
// copies : le moteur Coran affiche les marqueurs d'une classe, il n'en cree
// aucun et ne connait ni les traits, ni les couches d'annotation.

import 'package:flutter/foundation.dart';

import 'content_position.dart';

/// L'intention pedagogique d'un marqueur.
///
/// **La couleur derive de l'intention, jamais l'inverse.**
enum IntentionPedagogique {
  /// « A apprendre ».
  aApprendre,

  /// « A revoir ».
  aRevoir,

  /// « A renforcer ».
  aRenforcer,

  /// « A entretenir ».
  aEntretenir,

  /// « Pour l'evaluation ».
  pourEvaluation,
}

/// Un marqueur pose sur une plage de contenu.
@immutable
class MarqueurSemantique {
  /// Cree un marqueur.
  const MarqueurSemantique({
    required this.id,
    required this.plage,
    required this.intention,
    this.note,
  });

  /// Son identifiant.
  final String id;

  /// La plage marquee.
  final ContentRange plage;

  /// Ce que le marqueur veut dire.
  final IntentionPedagogique intention;

  /// Une note courte, quand l'enseignant en a laisse une.
  final String? note;
}
