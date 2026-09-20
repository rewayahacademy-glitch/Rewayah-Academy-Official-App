// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_range.dart (Agent B)
// Signature copiee A L'IDENTIQUE depuis le fichier canonique d'Agent B
// (AMENDEMENT 1 de TEACHING_CORE_CONTRACTS.md : la section 8 du contrat ne
// compile pas, la forme publiee par Agent B fait foi).
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Agent E n'en fait qu'un usage TRANSITIF : `LearningAssignment.contentRange`
// en a besoin, et `LearningAssignment` est un champ de
// `TeacherStudentProjection.currentAssignments`. Aucune ligne de la salle ne
// construit une plage.

import 'package:flutter/foundation.dart';

import 'content_position.dart';

/// Une plage de travail dans un support (CONTRACTS section 8).
@immutable
class ContentRange {
  /// Cree une plage. [fin] est **inclusive**.
  ContentRange({
    required this.resourceId,
    required this.debut,
    required this.fin,
    this.resourceVersionId,
  }) : assert(
         debut.resourceId == resourceId && fin.resourceId == resourceId,
         'les deux bornes portent la ressource de la plage',
       ),
       assert(
         debut.typeAncrage == fin.typeAncrage,
         'les deux bornes partagent le type d ancrage',
       ),
       assert(
         _rang(debut) <= _rang(fin),
         'debut avant fin dans l ordre naturel de l ancrage',
       );

  /// La ressource concernee.
  final String resourceId;

  /// La version concernee, quand la plage n'est valable que pour elle.
  final String? resourceVersionId;

  /// La borne basse.
  final ContentPosition debut;

  /// La borne haute, **incluse**.
  final ContentPosition fin;

  /// La nature de l'ancrage de la plage.
  TypeAncrage get typeAncrage => debut.typeAncrage;

  /// Vrai quand [p] tombe dans la plage.
  bool contient(ContentPosition p) {
    if (p.resourceId != resourceId) return false;
    if (p.typeAncrage != typeAncrage) return false;
    final double rang = _rang(p);
    return rang >= _rang(debut) && rang <= _rang(fin);
  }

  /// Vrai quand deux plages se recouvrent, ne serait-ce que d'une borne.
  bool chevauche(ContentRange autre) {
    if (autre.resourceId != resourceId) return false;
    if (autre.typeAncrage != typeAncrage) return false;
    return _rang(debut) <= _rang(autre.fin) &&
        _rang(autre.debut) <= _rang(fin);
  }

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

/// L'ordre naturel d'une position, dans son propre type d'ancrage.
double _rang(ContentPosition p) => switch (p.typeAncrage) {
  TypeAncrage.page => (p.page ?? 0).toDouble(),
  TypeAncrage.ayah => (p.sourate ?? 0) * 1000.0 + (p.ayah ?? 0),
  TypeAncrage.section => _rangTexte(p.sectionId ?? ''),
  TypeAncrage.fraction => p.fraction ?? 0,
};

/// Un rang monotone tire des huit premiers caracteres d'un identifiant.
double _rangTexte(String valeur) {
  double rang = 0;
  final int n = valeur.length < 8 ? valeur.length : 8;
  for (int i = 0; i < n; i++) {
    rang = rang * 128 + (valeur.codeUnitAt(i) & 0x7f);
  }
  for (int i = n; i < 8; i++) {
    rang = rang * 128;
  }
  return rang;
}
