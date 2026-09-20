// TC-DOUBLE-CONTRAT: canonique =
// lib/core/tc_etat_partage/shared_content_state.dart (Agent F).
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 9.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test. Agent Z le supprime a l'integration.

import 'package:flutter/foundation.dart';

import 'content_position.dart';
import 'content_range.dart';
import 'contrats_d_outils.dart';

/// Comment la classe voit le support partage.
enum ModeAffichagePartage { page, verse, focus }

/// La fiabilite d'un canal temps reel.
enum CanalFiabilite {
  /// Ordonne et garanti : etat partage, mode, stroke termine, rappel discret.
  fiable,

  /// Perte acceptee : pointeur, apercu de trait en cours de geste.
  ephemere,
}

/// Les capacites pedagogiques projetees pour l'appelant.
///
/// **Derivees du jeton serveur, jamais calculees ici** (CONTRACTS section 18).
@immutable
class CapacitesPedagogiques {
  /// Cree un jeu de capacites.
  const CapacitesPedagogiques({
    required this.peutPiloterSupport,
    required this.peutAnnoter,
    required this.peutEmettreNudge,
    required this.estObservateurSilencieux,
  });

  /// Peut changer le support actif de la classe.
  final bool peutPiloterSupport;

  /// Peut annoter.
  final bool peutAnnoter;

  /// Peut emettre un rappel discret.
  final bool peutEmettreNudge;

  /// Observe sans rien pouvoir emettre.
  final bool estObservateurSilencieux;
}

/// Le support actif de la classe (CONTRACTS section 9).
///
/// **`revision` est strictement croissante par seance.** Un paquet dont la
/// revision est inferieure ou egale a l'etat courant est ignore : la meme
/// regle couvre le paquet duplique et le paquet arrive dans le desordre.
@immutable
class SharedContentState {
  /// Cree un etat partage.
  SharedContentState({
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
  }) : assert(revision >= 0, 'une revision ne peut pas etre negative'),
       assert(updatedAtUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// La seance concernee.
  final String sessionId;

  /// La ressource presentee.
  final String resourceId;

  /// La version presentee.
  final String? resourceVersionId;

  /// La position presentee.
  final ContentPosition contentPosition;

  /// La plage de travail en cours.
  final ContentRange? contentRange;

  /// Le mode d'affichage impose a la classe.
  final ModeAffichagePartage displayMode;

  /// Les plages masquees.
  final List<ContentRange> hiddenRanges;

  /// Les marqueurs poses.
  final List<MarqueurSemantique> semanticMarkers;

  /// La position de reprise proposee au groupe.
  ///
  /// **Distincte de `student_reading_position`** : une page tournee par
  /// l'enseignant pour toute la classe n'ecrit jamais la position personnelle
  /// d'un eleve (invariant J2 du depot).
  final ContentPosition? groupResumePosition;

  /// La revision, strictement croissante par seance.
  final int revision;

  /// Le `profile_id` de l'emetteur.
  final String updatedBy;

  /// L'instant de mise a jour, en UTC.
  final DateTime updatedAtUtc;
}
