// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_position.dart (Agent B)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 7.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// DIVERGENCE DECLAREE, voir TC_CONTRACT_REQUEST_D.md section 1 : la declaration
// canonique ne compile pas telle quelle. Elle nomme des constructeurs `.page(...)`
// et `.fraction(...)` alors que la classe porte deja des champs `page` et
// `fraction` -- en Dart, un constructeur nomme ne peut pas porter le nom d'un
// membre. Les CHAMPS sont donc repris a l'identique, et les constructeurs sont
// prefixes `sur...` en attendant l'arbitrage d'Agent 0 ou d'Agent B. Aucun champ
// n'a ete ajoute, retire ni renomme.

import 'package:flutter/foundation.dart';

/// La nature de l'ancrage d'une position dans un support.
enum TypeAncrage {
  /// Une page, au sens de l'edition.
  page,

  /// Un verset, donc un couple sourate + ayah.
  ayah,

  /// Une section identifiee du support.
  section,

  /// Une fraction du support, de 0 a 1. Repli spatial.
  fraction,
}

/// La position canonique dans un support.
///
/// **Un seul ancrage a la fois.** Les champs non pertinents sont `null`, et une
/// assertion le garantit (invariant 1 du contrat).
///
/// Une position est valable **independamment du zoom** : le zoom est local a
/// chaque personne et ne fait pas partie de la position pedagogique partagee.
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

  /// Une position ancree a une page de l'edition.
  factory ContentPosition.surPage({
    required String resourceId,
    required int page,
    String? resourceVersionId,
  }) {
    assert(page > 0, 'une page se compte a partir de 1');
    return ContentPosition._(
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      typeAncrage: TypeAncrage.page,
      page: page,
    );
  }

  /// Une position ancree a un verset.
  factory ContentPosition.surAyah({
    required String resourceId,
    required int sourate,
    required int ayah,
    String? resourceVersionId,
  }) {
    assert(sourate > 0 && ayah > 0, 'sourate et ayah se comptent a partir de 1');
    return ContentPosition._(
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      typeAncrage: TypeAncrage.ayah,
      sourate: sourate,
      ayah: ayah,
    );
  }

  /// Une position ancree a une section identifiee.
  factory ContentPosition.surSection({
    required String resourceId,
    required String sectionId,
    String? resourceVersionId,
  }) => ContentPosition._(
    resourceId: resourceId,
    resourceVersionId: resourceVersionId,
    typeAncrage: TypeAncrage.section,
    sectionId: sectionId,
  );

  /// Une position ancree a une fraction du support. **Repli spatial** : sur un
  /// rendu reflowable, elle se decale quand le texte se recompose.
  factory ContentPosition.surFraction({
    required String resourceId,
    required double fraction,
    String? resourceVersionId,
  }) {
    assert(fraction >= 0 && fraction <= 1, 'une fraction vit entre 0 et 1');
    return ContentPosition._(
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      typeAncrage: TypeAncrage.fraction,
      fraction: fraction,
    );
  }

  /// La ressource concernee.
  final String resourceId;

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// La nature de l'ancrage.
  final TypeAncrage typeAncrage;

  /// La page, quand [typeAncrage] vaut [TypeAncrage.page].
  final int? page;

  /// La sourate, quand [typeAncrage] vaut [TypeAncrage.ayah].
  final int? sourate;

  /// Le verset, quand [typeAncrage] vaut [TypeAncrage.ayah].
  final int? ayah;

  /// La section, quand [typeAncrage] vaut [TypeAncrage.section].
  final String? sectionId;

  /// La fraction, quand [typeAncrage] vaut [TypeAncrage.fraction].
  final double? fraction;

  /// Vrai quand l'ancrage designe une unite de SENS, et non un emplacement.
  ///
  /// C'est la distinction qui decide du sort d'une annotation apres un reflow :
  /// un ancrage semantique suit le texte, un ancrage spatial reste ou il est.
  bool get estSemantique =>
      typeAncrage == TypeAncrage.ayah || typeAncrage == TypeAncrage.section;

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
