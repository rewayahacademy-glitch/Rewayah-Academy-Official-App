// TC-DOUBLE-CONTRAT: canoniques = lib/core/tc_outils/annotation_layer.dart et
// lib/core/tc_outils/learning_assignment.dart (Agent D).
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md sections 10 et 11.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test. Agent Z le supprime a l'integration.

import 'package:flutter/foundation.dart';

import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';

/// L'intention pedagogique. **La couleur en derive, jamais l'inverse.**
///
/// Un seul vocabulaire d'intentions dans tout le chantier : `LearningAssignment`
/// le reutilise tel quel, il n'en existe pas un second.
enum IntentionPedagogique {
  /// « A apprendre ».
  aApprendre('learn'),

  /// « A revoir ».
  aRevoir('review'),

  /// « A renforcer ».
  aRenforcer('reinforce'),

  /// « A entretenir ».
  aEntretenir('maintain'),

  /// « Pour l'evaluation ».
  pourEvaluation('assessment');

  const IntentionPedagogique(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une intention depuis sa valeur SQL. `null` sur valeur inconnue.
  static IntentionPedagogique? depuisSql(String? valeur) {
    for (final IntentionPedagogique i in IntentionPedagogique.values) {
      if (i.valeurSql == valeur) return i;
    }
    return null;
  }
}

/// Combien de temps une couche d'annotation survit.
enum PorteeAnnotation {
  /// Effacee des que le geste se termine.
  temporaire,

  /// Conservee le temps de la seance.
  seance,

  /// Conservee durablement.
  enregistree,
}

/// L'outil qui a produit un trait.
enum OutilTrait { stylet, surligneur, gomme }

/// Un point en coordonnees normalisees, relatives au bloc ancre.
@immutable
class PointNormalise {
  /// Cree un point.
  const PointNormalise(this.x, this.y)
    : assert(x >= 0 && x <= 1, 'x est normalise entre 0 et 1'),
      assert(y >= 0 && y <= 1, 'y est normalise entre 0 et 1');

  /// L'abscisse, entre 0 et 1.
  final double x;

  /// L'ordonnee, entre 0 et 1.
  final double y;
}

/// Un trait, **stocke en vectoriel**, jamais comme copie du support.
@immutable
class TraitVectoriel {
  /// Cree un trait.
  const TraitVectoriel({
    required this.id,
    required this.ancrage,
    required this.points,
    required this.outil,
    this.intention,
    this.pression,
    this.inclinaison,
  });

  /// L'identifiant du trait.
  final String id;

  /// L'ancrage semantique, prefere en mode reflow.
  final ContentPosition ancrage;

  /// Les points, normalises entre 0 et 1.
  final List<PointNormalise> points;

  /// L'outil.
  final OutilTrait outil;

  /// L'intention dont la couleur derive.
  final IntentionPedagogique? intention;

  /// La pression, `null` quand le materiel ne la fournit pas.
  final double? pression;

  /// L'inclinaison, `null` quand le materiel ne la fournit pas.
  final double? inclinaison;
}

/// Un marqueur pedagogique pose sur une plage. **Une metadonnee, pas un dessin.**
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

  /// L'intention.
  final IntentionPedagogique intention;

  /// Une note courte, facultative.
  final String? note;
}

/// La couche d'annotation, **independante du support** (CONTRACTS section 10).
///
/// Elle **reference** une version de ressource par son identifiant ; elle n'en
/// porte aucune copie. C'est l'invariant que le test Q-06 verifie.
@immutable
class AnnotationLayer {
  /// Cree une couche.
  AnnotationLayer({
    required this.id,
    required this.resourceId,
    required this.auteurProfilId,
    required this.portee,
    required this.traits,
    required this.marqueurs,
    required this.majAUtc,
    this.resourceVersionId,
    this.sessionId,
  }) : assert(majAUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// L'identifiant de la couche.
  final String id;

  /// La ressource annotee, **par reference**.
  final String resourceId;

  /// La version annotee, **par reference**.
  final String? resourceVersionId;

  /// La seance. `null` = couche personnelle hors classe.
  final String? sessionId;

  /// L'auteur.
  final String auteurProfilId;

  /// La portee.
  final PorteeAnnotation portee;

  /// Les traits.
  final List<TraitVectoriel> traits;

  /// Les marqueurs.
  final List<MarqueurSemantique> marqueurs;

  /// La derniere mise a jour, en UTC.
  final DateTime majAUtc;

  /// Une copie avec d'autres traits et marqueurs.
  AnnotationLayer copieAvec({
    List<TraitVectoriel>? traits,
    List<MarqueurSemantique>? marqueurs,
    DateTime? majAUtc,
  }) => AnnotationLayer(
    id: id,
    resourceId: resourceId,
    resourceVersionId: resourceVersionId,
    sessionId: sessionId,
    auteurProfilId: auteurProfilId,
    portee: portee,
    traits: traits ?? this.traits,
    marqueurs: marqueurs ?? this.marqueurs,
    majAUtc: majAUtc ?? this.majAUtc,
  );
}

/// Le statut d'une assignation.
enum StatutAssignation { aFaire, enCours, fait, expire, annule }

/// Le travail a preparer (CONTRACTS section 11).
@immutable
class LearningAssignment {
  /// Cree une assignation.
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
  }) : assert(startsAtUtc.isUtc, 'tout DateTime de contrat est en UTC'),
       assert(
         dueAtUtc == null || dueAtUtc.isUtc,
         'tout DateTime de contrat est en UTC',
       );

  /// L'identifiant.
  final String id;

  /// Le groupe.
  final String groupId;

  /// L'eleve. `null` = assignee a tout le groupe, et c'est le cas par defaut.
  final String? studentId;

  /// La ressource.
  final String resourceId;

  /// La version.
  final String? resourceVersionId;

  /// La plage de travail.
  final ContentRange? contentRange;

  /// L'intention. **Le meme vocabulaire que les annotations.**
  final IntentionPedagogique purpose;

  /// Une consigne courte, jamais un formulaire narratif.
  final String? instructions;

  /// Le debut, en UTC.
  final DateTime startsAtUtc;

  /// L'echeance, en UTC. Facultative.
  final DateTime? dueAtUtc;

  /// Qui l'a creee.
  final String createdBy;

  /// Le statut.
  final StatutAssignation status;
}
