// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_position.dart (Agent B)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 7.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// ECART DECLARE, a arbitrer par Agent B ou Agent 0.
// Le contrat ecrit `const ContentPosition._();` et annonce en commentaire
// « Constructeurs nommes attendus : .page(...), .ayah(...), .section(...),
// .fraction(...) », sans leurs corps. Recopiee litteralement, la classe NE
// COMPILE PAS : des champs `final` non nullables restent non initialises.
// Les quatre constructeurs annonces sont donc materialises ici, sans rien
// ajouter au jeu de champs du contrat. Agent B reste la source de verite : si
// sa forme differe, c'est la sienne qui prime, et la divergence est consignee
// dans docs/teaching-core/TC_CONTRACT_REQUEST_A.md section 8.

import 'package:flutter/foundation.dart';

/// La nature de l'ancrage d'une position.
enum TypeAncrage {
  /// Une page.
  page,

  /// Un verset du Coran.
  ayah,

  /// Une section d'un texte structure.
  section,

  /// Une fraction du document, repli de dernier recours.
  fraction,
}

/// La position canonique dans un support, independante du zoom.
@immutable
class ContentPosition {
  const ContentPosition._({
    required this.resourceId,
    required this.typeAncrage,
    this.resourceVersionId,
    this.page,
    this.sourate,
    this.ayah,
    this.sectionId,
    this.fraction,
  });

  /// Une position de page.
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

  /// Une position de verset.
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

  /// Une position de section.
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

  /// Une position par fraction, de 0.0 a 1.0.
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

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// La nature de l'ancrage. **Un seul a la fois.**
  final TypeAncrage typeAncrage;

  /// La page, si `typeAncrage == page`.
  final int? page;

  /// La sourate, si `typeAncrage == ayah`.
  final int? sourate;

  /// Le verset, si `typeAncrage == ayah`.
  final int? ayah;

  /// La section, si `typeAncrage == section`.
  final String? sectionId;

  /// La fraction, si `typeAncrage == fraction`.
  final double? fraction;
}
