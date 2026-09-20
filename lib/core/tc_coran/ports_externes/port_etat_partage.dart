// TC-STUB-PORT: canonique = lib/core/tc_etat_partage/shared_content_state.dart (Agent F)
// TC-STUB-PORT: canonique = lib/core/tc_etat_partage/port_etat_partage.dart (Agent F)
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md section 9.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.

import 'package:flutter/foundation.dart';

import '../../tc_bibliotheque/content_position.dart';
import '../../tc_bibliotheque/content_range.dart';
import '../../tc_outils/annotation_layer.dart';

/// Le mode d'affichage impose a la classe.
enum ModeAffichagePartage {
  /// Page du mushaf.
  page,

  /// Verset agrandi.
  verse,

  /// Focus dirige.
  focus,
}

/// Le support actif de la classe.
@immutable
class SharedContentState {
  /// Cree un etat partage.
  const SharedContentState({
    required this.sessionId,
    required this.resourceId,
    required this.contentPosition,
    required this.displayMode,
    required this.hiddenRanges,
    required this.semanticMarkers,
    required this.revision,
    required this.updatedBy,
    required this.updatedAtUtc,
    this.resourceVersionId,
    this.contentRange,
    this.groupResumePosition,
  });

  /// La seance concernee.
  final String sessionId;

  /// La ressource presentee.
  final String resourceId;

  /// Sa version, quand elle est connue.
  final String? resourceVersionId;

  /// La position presentee.
  final ContentPosition contentPosition;

  /// La plage de travail, quand l'enseignant en a designe une.
  final ContentRange? contentRange;

  /// Le mode impose a la classe.
  final ModeAffichagePartage displayMode;

  /// Les plages masquees.
  final List<ContentRange> hiddenRanges;

  /// Les marqueurs poses par l'enseignant.
  final List<MarqueurSemantique> semanticMarkers;

  /// La position ou le groupe reprend le cours.
  final ContentPosition? groupResumePosition;

  /// Numero de revision, strictement croissant par seance.
  final int revision;

  /// L'emetteur de cette revision.
  final String updatedBy;

  /// L'instant de la revision, en UTC.
  final DateTime updatedAtUtc;
}

/// L'acces a l'etat partage d'une seance.
abstract class PortEtatPartage {
  /// L'etat courant, ou `null` si aucune presentation n'est en cours.
  Future<SharedContentState?> etatCourant(String sessionId);

  /// Le flux des revisions.
  Stream<SharedContentState> suivre(String sessionId);

  /// Publie une revision.
  Future<void> publier(SharedContentState etat);

  /// Restauration apres reconnexion ou arrivee tardive.
  Future<SharedContentState?> restaurer(String sessionId);
}
