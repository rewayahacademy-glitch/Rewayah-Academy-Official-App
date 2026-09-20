// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_range.dart (Agent B)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 8.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// DIVERGENCE DECLAREE, voir TC_CONTRACT_REQUEST_D.md section 1 : le contrat
// declare `contient` et `chevauche` sans en donner le corps, et sans definir
// l'ordre naturel d'un ancrage `section`. Les deux methodes portent donc ici un
// DOUBLE LOCAL, ecrit au plus juste : l'ordre des pages, celui des versets
// (sourate puis ayah) et celui des fractions sont sans ambiguite ; l'ordre des
// sections ne l'est pas, et [ContentRange.contient] le declare plutot que de le
// deviner. Aucun champ n'a ete ajoute.

import 'package:flutter/foundation.dart';

import 'content_position.dart';

/// La plage de travail : de [debut] a [fin], bornes comprises.
///
/// Une plage est une **metadonnee**, jamais un dessin. Les marqueurs
/// « A revoir » et « A renforcer » sont des metadonnees de plage (spec 8.3).
@immutable
class ContentRange {
  /// Cree une plage.
  ContentRange({
    required this.resourceId,
    required this.debut,
    required this.fin,
    this.resourceVersionId,
  }) : assert(
         debut.resourceId == fin.resourceId,
         'une plage ne traverse pas deux ressources',
       ),
       assert(
         debut.typeAncrage == fin.typeAncrage,
         'les deux bornes partagent le meme type d ancrage',
       ),
       assert(
         debut.resourceId == resourceId,
         'les bornes appartiennent a la ressource de la plage',
       );

  /// La plage reduite a une seule position.
  ContentRange.ponctuelle(ContentPosition position)
    : this(
        resourceId: position.resourceId,
        resourceVersionId: position.resourceVersionId,
        debut: position,
        fin: position,
      );

  /// La ressource concernee.
  final String resourceId;

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// La borne de debut, comprise.
  final ContentPosition debut;

  /// La borne de fin, comprise.
  final ContentPosition fin;

  /// Le type d'ancrage commun aux deux bornes.
  TypeAncrage get typeAncrage => debut.typeAncrage;

  /// Vrai quand [p] tombe dans la plage.
  ///
  /// Une position d'un autre type d'ancrage ou d'une autre ressource est hors
  /// de la plage : on ne compare pas une page a un verset.
  bool contient(ContentPosition p) {
    if (p.resourceId != resourceId || p.typeAncrage != typeAncrage) {
      return false;
    }
    if (typeAncrage == TypeAncrage.section) {
      // Aucun ordre n'est defini entre deux sections : seule l'egalite est
      // decidable. Une plage de sections large reste a definir par Agent B.
      return p.sectionId == debut.sectionId || p.sectionId == fin.sectionId;
    }
    final int? rang = _rang(p);
    final int? bas = _rang(debut);
    final int? haut = _rang(fin);
    if (rang == null || bas == null || haut == null) {
      return false;
    }
    return rang >= bas && rang <= haut;
  }

  /// Vrai quand les deux plages se recouvrent, ne serait-ce que d'une position.
  bool chevauche(ContentRange autre) {
    if (autre.resourceId != resourceId || autre.typeAncrage != typeAncrage) {
      return false;
    }
    if (typeAncrage == TypeAncrage.section) {
      return contient(autre.debut) || contient(autre.fin);
    }
    final int? monBas = _rang(debut);
    final int? monHaut = _rang(fin);
    final int? sonBas = _rang(autre.debut);
    final int? sonHaut = _rang(autre.fin);
    if (monBas == null || monHaut == null || sonBas == null || sonHaut == null) {
      return false;
    }
    return monBas <= sonHaut && sonBas <= monHaut;
  }

  /// Le rang d'une position dans l'ordre naturel de son type d'ancrage.
  ///
  /// `null` quand le type n'a pas d'ordre total connu.
  static int? _rang(ContentPosition p) => switch (p.typeAncrage) {
    TypeAncrage.page => p.page,
    TypeAncrage.ayah => p.sourate == null || p.ayah == null
        ? null
        : p.sourate! * 1000 + p.ayah!,
    // Le millionieme : deux fractions plus proches que cela designent le meme
    // endroit a l'ecran, quel que soit le support.
    TypeAncrage.fraction => p.fraction == null
        ? null
        : (p.fraction! * 1000000).round(),
    TypeAncrage.section => null,
  };

  @override
  bool operator ==(Object other) =>
      other is ContentRange &&
      other.resourceId == resourceId &&
      other.resourceVersionId == resourceVersionId &&
      other.debut == debut &&
      other.fin == fin;

  @override
  int get hashCode => Object.hash(resourceId, resourceVersionId, debut, fin);
}
