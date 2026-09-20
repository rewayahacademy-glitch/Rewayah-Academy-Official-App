// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_position.dart (Agent B)
// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_range.dart (Agent B)
// Declarations recopiees A L'IDENTIQUE depuis ces deux fichiers du worktree
// D:\RA_TC\b, conformement a l'AMENDEMENT 1 de TEACHING_CORE_CONTRACTS.md, qui
// prevaut sur les sections 7 et 8 du meme document et les declare perimees.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Les deux fichiers d'Agent B sont reunis ici en un seul, pour ne pas multiplier
// les ports d'un stub appele a disparaitre. Aucune declaration n'est modifiee :
// memes champs, memes constructeurs, memes assertions, meme constness.

import 'package:flutter/foundation.dart';

/// La nature de l'ancrage d'une position (CONTRACTS section 7).
enum TypeAncrage {
  /// Une page, pour un support pagine.
  page('page'),

  /// Un verset, pour le Coran.
  ayah('ayah'),

  /// Une section nommee, pour un texte structure ou une lecon.
  section('section'),

  /// Une fraction du support, **repli** quand rien de semantique n'existe.
  fraction('fraction');

  const TypeAncrage(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un ancrage depuis sa valeur SQL. `null` sur valeur inconnue.
  static TypeAncrage? depuisSql(String? valeur) {
    for (final TypeAncrage a in TypeAncrage.values) {
      if (a.valeurSql == valeur) return a;
    }
    return null;
  }
}

/// La position canonique dans un support, tous types confondus.
///
/// **Un seul ancrage a la fois.** Les champs qui ne concernent pas
/// [typeAncrage] valent `null`, et une assertion le garantit a la
/// construction : une position qui porterait a la fois une page et un verset
/// laisserait chaque consommateur choisir, donc diverger.
///
/// **Le zoom n'en fait pas partie.** Le zoom est local a chaque personne, il
/// ne fait pas partie de la position pedagogique partagee (decision D-21).
///
/// Sur un rendu reflowable, l'ancrage semantique ([ayah], [section]) est
/// **prefere** a [fraction] : une fraction se decale des que la largeur change.
@immutable
class ContentPosition {
  /// Le constructeur interne. Les quatre fabriques nommees passent par lui.
  ///
  /// Le contrat ecrit `const ContentPosition._();` sans parametre ; des champs
  /// `final` ne peuvent pas etre initialises ainsi. La forme retenue garde la
  /// surface publique exacte -- quatre constructeurs nommes -- et rend le
  /// constructeur prive utilisable. Ecart signale dans
  /// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
  const ContentPosition._({
    required this.resourceId,
    required this.typeAncrage,
    this.resourceVersionId,
    this.page,
    this.sourate,
    this.ayah,
    this.sectionId,
    this.fraction,
  }) : assert(
         typeAncrage != TypeAncrage.page ||
             (page != null &&
                 sourate == null &&
                 ayah == null &&
                 sectionId == null &&
                 fraction == null),
         'ancrage page : seul page est renseigne',
       ),
       assert(
         typeAncrage != TypeAncrage.ayah ||
             (sourate != null &&
                 ayah != null &&
                 page == null &&
                 sectionId == null &&
                 fraction == null),
         'ancrage ayah : seuls sourate et ayah sont renseignes',
       ),
       assert(
         typeAncrage != TypeAncrage.section ||
             (sectionId != null &&
                 page == null &&
                 sourate == null &&
                 ayah == null &&
                 fraction == null),
         'ancrage section : seul sectionId est renseigne',
       ),
       assert(
         typeAncrage != TypeAncrage.fraction ||
             (fraction != null &&
                 fraction >= 0 &&
                 fraction <= 1 &&
                 page == null &&
                 sourate == null &&
                 ayah == null &&
                 sectionId == null),
         'ancrage fraction : seul fraction est renseigne, entre 0 et 1',
       );

  /// Une position sur une page.
  const ContentPosition.page({
    required String resourceId,
    required int page,
    String? resourceVersionId,
  }) : this._(
         resourceId: resourceId,
         resourceVersionId: resourceVersionId,
         typeAncrage: TypeAncrage.page,
         page: page,
       );

  /// Une position sur un verset.
  const ContentPosition.ayah({
    required String resourceId,
    required int sourate,
    required int ayah,
    String? resourceVersionId,
  }) : this._(
         resourceId: resourceId,
         resourceVersionId: resourceVersionId,
         typeAncrage: TypeAncrage.ayah,
         sourate: sourate,
         ayah: ayah,
       );

  /// Une position sur une section nommee.
  const ContentPosition.section({
    required String resourceId,
    required String sectionId,
    String? resourceVersionId,
  }) : this._(
         resourceId: resourceId,
         resourceVersionId: resourceVersionId,
         typeAncrage: TypeAncrage.section,
         sectionId: sectionId,
       );

  /// Une position par fraction du support. **Repli seulement.**
  const ContentPosition.fraction({
    required String resourceId,
    required double fraction,
    String? resourceVersionId,
  }) : this._(
         resourceId: resourceId,
         resourceVersionId: resourceVersionId,
         typeAncrage: TypeAncrage.fraction,
         fraction: fraction,
       );

  /// La ressource concernee.
  final String resourceId;

  /// La version concernee. `null` quand la position vaut pour toute version.
  final String? resourceVersionId;

  /// La nature de l'ancrage.
  final TypeAncrage typeAncrage;

  /// Le numero de page, pour [TypeAncrage.page].
  final int? page;

  /// Le numero de sourate, pour [TypeAncrage.ayah].
  final int? sourate;

  /// Le numero de verset, pour [TypeAncrage.ayah].
  final int? ayah;

  /// L'identifiant de section, pour [TypeAncrage.section].
  final String? sectionId;

  /// La fraction du support, pour [TypeAncrage.fraction].
  final double? fraction;

  @override
  bool operator ==(Object other) =>
      other is ContentPosition &&
      other.resourceId == resourceId &&
      other.resourceVersionId == resourceVersionId &&
      other.typeAncrage == typeAncrage &&
      other.page == page &&
      other.sourate == sourate &&
      other.ayah == ayah &&
      other.sectionId == sectionId &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(
    resourceId,
    resourceVersionId,
    typeAncrage,
    page,
    sourate,
    ayah,
    sectionId,
    fraction,
  );
}

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
