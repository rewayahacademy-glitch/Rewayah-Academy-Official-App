// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_position.dart (Agent B)
// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/content_range.dart (Agent B)
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md sections 7 et 8.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// ECART ASSUME, declare dans TC_AGENT_C_REPORT.md : le contrat ecrit
// `const ContentPosition._();` sans initialiser ses champs finaux, et declare
// `contient` / `chevauche` sans corps. Tel quel, il ne compile pas. Le stub
// garde les champs, leurs types et leurs noms **a l'identique**, et donne aux
// quatre constructeurs nommes que le contrat annonce le seul corps possible.
// Aucun champ, aucune methode n'a ete ajoute.

import 'package:flutter/foundation.dart';

/// La nature de l'ancrage d'une position dans un support.
enum TypeAncrage {
  /// Une page d'un support pagine.
  page,

  /// Un verset, dans le corpus coranique.
  ayah,

  /// Une section identifiee d'un texte structure.
  section,

  /// Un repli proportionnel, de 0 a 1.
  fraction,
}

/// La position canonique dans un support.
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

  /// Une position proportionnelle, employee en dernier recours.
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

  /// La ressource visee.
  final String resourceId;

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// L'ancrage retenu. Un seul a la fois.
  final TypeAncrage typeAncrage;

  /// La page, si [typeAncrage] vaut [TypeAncrage.page].
  final int? page;

  /// La sourate, si [typeAncrage] vaut [TypeAncrage.ayah].
  final int? sourate;

  /// Le verset, si [typeAncrage] vaut [TypeAncrage.ayah].
  final int? ayah;

  /// La section, si [typeAncrage] vaut [TypeAncrage.section].
  final String? sectionId;

  /// La fraction, si [typeAncrage] vaut [TypeAncrage.fraction].
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

/// La plage de travail dans un support.
@immutable
class ContentRange {
  /// Cree une plage.
  const ContentRange({
    required this.resourceId,
    required this.debut,
    required this.fin,
    this.resourceVersionId,
  });

  /// La ressource visee.
  final String resourceId;

  /// La version de la ressource, quand elle est connue.
  final String? resourceVersionId;

  /// La borne de debut.
  final ContentPosition debut;

  /// La borne de fin, incluse.
  final ContentPosition fin;

  /// Vrai quand [p] tombe dans la plage.
  bool contient(ContentPosition p) {
    if (p.resourceId != resourceId || p.typeAncrage != debut.typeAncrage) {
      return false;
    }
    final int? rang = _rang(p);
    final int? bas = _rang(debut);
    final int? haut = _rang(fin);
    if (rang == null || bas == null || haut == null) {
      return false;
    }
    return rang >= bas && rang <= haut;
  }

  /// Vrai quand les deux plages se recouvrent, meme partiellement.
  bool chevauche(ContentRange autre) =>
      contient(autre.debut) ||
      contient(autre.fin) ||
      autre.contient(debut) ||
      autre.contient(fin);

  /// L'ordre naturel du type d'ancrage, reduit a un entier comparable.
  ///
  /// Une reference « sourate:verset » se compare comme un nombre a six
  /// chiffres : la sourate pese plus que le verset, et aucune sourate ne
  /// depasse 286 versets.
  static int? _rang(ContentPosition p) => switch (p.typeAncrage) {
    TypeAncrage.page => p.page,
    TypeAncrage.ayah => p.sourate == null || p.ayah == null
        ? null
        : p.sourate! * 1000 + p.ayah!,
    TypeAncrage.fraction => p.fraction == null
        ? null
        : (p.fraction! * 1000000).round(),
    TypeAncrage.section => null,
  };
}
