/// La traduction de [SharedContentState] en charge utile serialisable.
///
/// **Le codec vit hors du contrat, et c'est delibere.** `SharedContentState`
/// est stube a l'identique par Agent C ; lui ajouter `versJson` /
/// `depuisJson` ferait diverger son stub du canonique, ce que le controle
/// pre-merge traite en BLOCKER. Des fonctions libres n'ont pas ce defaut.
///
/// **Les cles sont exactement celles d'Agent D** (`evenements_outils.dart`,
/// `_positionJson` et `_plageJson`) : les deux lots ecrivent des positions et
/// des plages sur le meme canal de donnees, et deux encodages voisins mais
/// differents sur un meme fil finissent toujours par etre lus l'un pour
/// l'autre.
///
/// **Toutes les lectures rendent `null` sur donnee illisible, jamais une
/// valeur de repli.** Un paquet vient du reseau, donc d'une version
/// d'application qu'on ne controle pas : le principe du socle
/// (`LiveKitSessionProvider._recevoirDonnees`) est qu'un paquet illisible ne
/// casse rien, et surtout pas le canal pour le reste de la seance.
library;

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_outils/annotation_layer.dart';
import '../tc_outils/intention_pedagogique.dart';
import 'shared_content_state.dart';

/// Ecrit une position.
Map<String, dynamic> positionVersJson(ContentPosition position) =>
    <String, dynamic>{
      'resource_id': position.resourceId,
      'resource_version_id': position.resourceVersionId,
      'type_ancrage': position.typeAncrage.valeurSql,
      'page': position.page,
      'sourate': position.sourate,
      'ayah': position.ayah,
      'section_id': position.sectionId,
      'fraction': position.fraction,
    };

/// Lit une position. `null` si le paquet ne porte pas un ancrage complet.
ContentPosition? positionDepuisJson(Object? brut) {
  if (brut is! Map<String, dynamic>) {
    return null;
  }
  final String? resourceId = brut['resource_id'] as String?;
  final TypeAncrage? type = TypeAncrage.depuisSql(
    brut['type_ancrage'] as String?,
  );
  if (resourceId == null || type == null) {
    return null;
  }
  final String? versionId = brut['resource_version_id'] as String?;
  switch (type) {
    case TypeAncrage.page:
      final int? page = brut['page'] as int?;
      return page == null
          ? null
          : ContentPosition.page(
              resourceId: resourceId,
              page: page,
              resourceVersionId: versionId,
            );
    case TypeAncrage.ayah:
      final int? sourate = brut['sourate'] as int?;
      final int? ayah = brut['ayah'] as int?;
      return sourate == null || ayah == null
          ? null
          : ContentPosition.ayah(
              resourceId: resourceId,
              sourate: sourate,
              ayah: ayah,
              resourceVersionId: versionId,
            );
    case TypeAncrage.section:
      final String? sectionId = brut['section_id'] as String?;
      return sectionId == null
          ? null
          : ContentPosition.section(
              resourceId: resourceId,
              sectionId: sectionId,
              resourceVersionId: versionId,
            );
    case TypeAncrage.fraction:
      final num? fraction = brut['fraction'] as num?;
      if (fraction == null || fraction < 0 || fraction > 1) {
        return null;
      }
      return ContentPosition.fraction(
        resourceId: resourceId,
        fraction: fraction.toDouble(),
        resourceVersionId: versionId,
      );
  }
}

/// Ecrit une plage.
Map<String, dynamic> plageVersJson(ContentRange plage) => <String, dynamic>{
  'resource_id': plage.resourceId,
  'resource_version_id': plage.resourceVersionId,
  'debut': positionVersJson(plage.debut),
  'fin': positionVersJson(plage.fin),
};

/// Lit une plage. `null` si l'une des bornes manque ou si elles ne sont pas
/// comparables.
ContentRange? plageDepuisJson(Object? brut) {
  if (brut is! Map<String, dynamic>) {
    return null;
  }
  final String? resourceId = brut['resource_id'] as String?;
  final ContentPosition? debut = positionDepuisJson(brut['debut']);
  final ContentPosition? fin = positionDepuisJson(brut['fin']);
  if (resourceId == null || debut == null || fin == null) {
    return null;
  }
  // Les assertions de `ContentRange` refusent deux bornes incomparables. En
  // production les assertions ne s'executent pas : le test est donc refait
  // ici, explicitement, pour qu'un paquet incoherent rende `null` des deux
  // cotes plutot qu'une plage sans milieu en release et une erreur en debug.
  if (debut.resourceId != resourceId ||
      fin.resourceId != resourceId ||
      debut.typeAncrage != fin.typeAncrage) {
    return null;
  }
  return ContentRange(
    resourceId: resourceId,
    debut: debut,
    fin: fin,
    resourceVersionId: brut['resource_version_id'] as String?,
  );
}

/// Ecrit un marqueur semantique.
Map<String, dynamic> marqueurVersJson(MarqueurSemantique marqueur) =>
    <String, dynamic>{
      'id': marqueur.id,
      'plage': plageVersJson(marqueur.plage),
      'intention': marqueur.intention.valeurSql,
      'note': marqueur.note,
    };

/// Lit un marqueur semantique. `null` si l'intention ou la plage manquent.
MarqueurSemantique? marqueurDepuisJson(Object? brut) {
  if (brut is! Map<String, dynamic>) {
    return null;
  }
  final String? id = brut['id'] as String?;
  final ContentRange? plage = plageDepuisJson(brut['plage']);
  final IntentionPedagogique? intention = IntentionPedagogique.depuisSql(
    brut['intention'] as String?,
  );
  if (id == null || plage == null || intention == null) {
    return null;
  }
  return MarqueurSemantique(
    id: id,
    plage: plage,
    intention: intention,
    note: brut['note'] as String?,
  );
}

/// Ecrit l'etat partage complet.
///
/// **L'etat voyage en entier, jamais en delta**, et c'est la decision centrale
/// du lot F : un paquet perdu, duplique ou arrive en retard se traite alors
/// par une seule comparaison de revision, sans jamais rejouer un journal.
/// Le prix est la taille du paquet ; le plafond est le paquet fiable LiveKit
/// (de l'ordre de quelques dizaines de kilo-octets). Si un jour les plages
/// masquees et les marqueurs d'une seance depassaient ce plafond, la voie
/// serait de ne plus les transporter du tout et de laisser le late joiner les
/// relire par `PortEtatPartagePersistant` -- surtout pas de passer en delta.
Map<String, dynamic> etatVersJson(SharedContentState etat) => <String, dynamic>{
  'session_id': etat.sessionId,
  'resource_id': etat.resourceId,
  'resource_version_id': etat.resourceVersionId,
  'content_position': positionVersJson(etat.contentPosition),
  'content_range': etat.contentRange == null
      ? null
      : plageVersJson(etat.contentRange!),
  'display_mode': etat.displayMode.valeurSql,
  'hidden_ranges': <Map<String, dynamic>>[
    for (final ContentRange plage in etat.hiddenRanges) plageVersJson(plage),
  ],
  'semantic_markers': <Map<String, dynamic>>[
    for (final MarqueurSemantique m in etat.semanticMarkers)
      marqueurVersJson(m),
  ],
  'group_resume_position': etat.groupResumePosition == null
      ? null
      : positionVersJson(etat.groupResumePosition!),
  'revision': etat.revision,
  'updated_by': etat.updatedBy,
  'updated_at': etat.updatedAtUtc.toUtc().millisecondsSinceEpoch,
};

/// Lit l'etat partage complet. `null` si le paquet est inexploitable.
///
/// Une liste dont un element est illisible **perd cet element seul** : un
/// marqueur ecrit par une version plus recente ne doit pas faire disparaitre
/// la page ouverte devant la classe.
SharedContentState? etatDepuisJson(Object? brut) {
  if (brut is! Map<String, dynamic>) {
    return null;
  }
  final String? sessionId = brut['session_id'] as String?;
  final String? resourceId = brut['resource_id'] as String?;
  final ContentPosition? position = positionDepuisJson(
    brut['content_position'],
  );
  final ModeAffichagePartage? mode = ModeAffichagePartage.depuisSql(
    brut['display_mode'] as String?,
  );
  final int? revision = brut['revision'] as int?;
  final String? updatedBy = brut['updated_by'] as String?;
  final int? instant = brut['updated_at'] as int?;
  if (sessionId == null ||
      resourceId == null ||
      position == null ||
      mode == null ||
      revision == null ||
      revision < 0 ||
      updatedBy == null ||
      instant == null) {
    return null;
  }
  return SharedContentState(
    sessionId: sessionId,
    resourceId: resourceId,
    resourceVersionId: brut['resource_version_id'] as String?,
    contentPosition: position,
    contentRange: plageDepuisJson(brut['content_range']),
    displayMode: mode,
    hiddenRanges: _plages(brut['hidden_ranges']),
    semanticMarkers: _marqueurs(brut['semantic_markers']),
    groupResumePosition: positionDepuisJson(brut['group_resume_position']),
    revision: revision,
    updatedBy: updatedBy,
    updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(instant, isUtc: true),
  );
}

List<ContentRange> _plages(Object? brut) {
  if (brut is! List<dynamic>) {
    return const <ContentRange>[];
  }
  return <ContentRange>[
    for (final Object? element in brut)
      if (plageDepuisJson(element) case final ContentRange plage) plage,
  ];
}

List<MarqueurSemantique> _marqueurs(Object? brut) {
  if (brut is! List<dynamic>) {
    return const <MarqueurSemantique>[];
  }
  return <MarqueurSemantique>[
    for (final Object? element in brut)
      if (marqueurDepuisJson(element) case final MarqueurSemantique m) m,
  ];
}
