import 'package:flutter/foundation.dart';

import 'content_position.dart';

/// Une plage de travail dans un support (CONTRACTS section 8).
///
/// **Une plage est une metadonnee, jamais un dessin.** Les marqueurs
/// pedagogiques d'Agent D s'y accrochent ; ils ne recopient pas le support.
///
/// Les deux bornes partagent la ressource et le type d'ancrage : une plage qui
/// irait d'une page a un verset n'aurait pas d'ordre, donc pas de milieu.
@immutable
class ContentRange {
  /// Cree une plage. [fin] est **inclusive**.
  ///
  /// Le constructeur n'est pas `const` : les assertions comparent les bornes
  /// par [_rang], et une fonction ne s'evalue pas a la compilation.
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
  ///
  /// Une position d'une autre ressource ou d'un autre type d'ancrage n'y tombe
  /// **jamais** : elle n'est pas comparable, et repondre `true` ou `false` par
  /// defaut reviendrait a inventer un ordre.
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
///
/// Fonction privee et non methode publique : l'ordre est un detail de la
/// plage, et [ContentPosition] est un contrat consomme par six agents. Lui
/// ajouter une methode ferait diverger les stubs locaux du contrat canonique.
///
/// Pour [TypeAncrage.section], l'ordre est celui des identifiants : un
/// identifiant de section est deja un ordre de lecture dans les corpus
/// structures du produit. Quand ce n'est pas vrai, la plage ne doit pas etre
/// construite sur des sections.
double _rang(ContentPosition p) => switch (p.typeAncrage) {
  TypeAncrage.page => (p.page ?? 0).toDouble(),
  // Un verset se range apres tous ceux de la sourate precedente. 1000 borne
  // large : la plus longue sourate compte 286 versets.
  TypeAncrage.ayah => (p.sourate ?? 0) * 1000.0 + (p.ayah ?? 0),
  TypeAncrage.section => _rangTexte(p.sectionId ?? ''),
  TypeAncrage.fraction => p.fraction ?? 0,
};

/// Un rang monotone tire des huit premiers caracteres d'un identifiant.
///
/// Huit caracteres suffisent : au dela, un `double` perdrait les bits de poids
/// faible et deux sections voisines deviendraient egales sans que rien ne le
/// dise.
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
