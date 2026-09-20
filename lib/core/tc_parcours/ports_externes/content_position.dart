// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_position.dart (Agent B)
// Declaration copiee A L'IDENTIQUE depuis le fichier canonique d'Agent B, comme
// l'impose l'AMENDEMENT 1 de TEACHING_CORE_CONTRACTS.md : les sections 7 et 8 du
// contrat sont perimees (champs `final` non initialises), et c'est le fichier
// publie par Agent B qui fait foi.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
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
