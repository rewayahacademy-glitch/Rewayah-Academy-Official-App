// TC-DOUBLE-CONTRAT: canoniques = lib/core/tc_bibliotheque/library_resource.dart,
// lib/core/tc_bibliotheque/resource_version.dart,
// lib/core/tc_telechargement/download_asset.dart,
// lib/core/tc_telechargement/port_etat_offline.dart (Agent B).
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md sections 4, 5 et 6.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test, pas une implementation. Agent Z le supprime a l'integration et fait
// pointer les tests sur les chemins canoniques.

import 'package:flutter/foundation.dart';

/// Le type d'une ressource de la Bibliotheque (CONTRACTS section 4).
enum TypeRessource {
  /// Le corpus coranique structure.
  quran('quran'),

  /// Un texte structure (lecon redigee, matn, commentaire).
  texteStructure('structured_text'),

  /// Un PDF importe ou derive.
  pdf('pdf'),

  /// Une image.
  image('image'),

  /// Une lecon du programme.
  lecon('lesson');

  const TypeRessource(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. `null` sur valeur inconnue : le
  /// contrat commun interdit un repli silencieux.
  static TypeRessource? depuisSql(String? valeur) {
    for (final TypeRessource t in TypeRessource.values) {
      if (t.valeurSql == valeur) return t;
    }
    return null;
  }
}

/// Ce qu'une ressource permet de faire. **Seule source du comportement offert.**
///
/// Une interface ne devine jamais qu'un PDF est annotable : elle lit cet
/// ensemble (CONTRACTS section 4, invariant 4).
enum CapaciteRessource {
  /// Se parcourt page a page.
  pageable,

  /// Se cherche.
  searchable,

  /// Se zoome.
  zoomable,

  /// Se selectionne.
  selectable,

  /// Se met en focus.
  focusable,

  /// S'annote.
  annotatable,

  /// S'assigne comme travail.
  assignable,

  /// Se presente en classe.
  presentableInClass,

  /// Reconnait le stylet.
  supportsStylus,

  /// Se consulte hors ligne.
  supportsOffline,
}

/// Qui accede a une ressource.
enum PolitiqueAcces { publique, inscrits, groupeAssigne, enseignantSeul, admin }

/// Comment une ressource descend hors ligne.
enum PolitiqueOffline { jamais, surDemande, automatique }

/// L'etat hors ligne d'une ressource, **par ressource**.
enum EtatOffline { aTelecharger, enCours, enCache, telecharge, indisponible }

/// Le manifeste d'une ressource de la Bibliotheque (CONTRACTS section 4).
///
/// **Une seule Bibliotheque** (decision D-20) : la meme ressource sert hors
/// classe et en classe. Il n'existe pas de variante « en classe ».
@immutable
class LibraryResource {
  /// Cree un manifeste.
  const LibraryResource({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.resourceType,
    required this.language,
    required this.category,
    required this.levelScope,
    required this.accessPolicy,
    required this.offlinePolicy,
    required this.capabilities,
    this.coverAsset,
    this.edition,
    this.currentVersionId,
  });

  /// L'identifiant de la ressource.
  final String id;

  /// Le titre complet.
  final String title;

  /// Le titre court, pour une carte etroite.
  final String shortTitle;

  /// La cle d'asset ou de Storage de la couverture.
  ///
  /// **JAMAIS une URL signee** : une URL signee expire, une cle non
  /// (CONTRACTS section 4, invariant 2).
  final String? coverAsset;

  /// Le type de ressource.
  final TypeRessource resourceType;

  /// L'edition, quand la ressource en a une (ex. `madina-hafs-604`).
  final String? edition;

  /// La langue du contenu.
  final String language;

  /// La categorie de rangement.
  final String category;

  /// Les codes de niveau du programme auxquels elle s'adresse.
  final List<String> levelScope;

  /// Qui y accede.
  final PolitiqueAcces accessPolicy;

  /// Comment elle descend hors ligne.
  final PolitiqueOffline offlinePolicy;

  /// La version publiee courante. `null` si aucune.
  final String? currentVersionId;

  /// Ce qu'elle permet de faire.
  final Set<CapaciteRessource> capabilities;
}

/// Le statut d'une version de ressource, calque sur `programme_versions`.
enum StatutVersionRessource {
  /// En cours de redaction.
  brouillon('brouillon'),

  /// Publiee, donc **immuable**.
  publiee('publiee'),

  /// Retiree de la circulation, mais conservee.
  archivee('archivee');

  const StatutVersionRessource(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` sur valeur inconnue.
  static StatutVersionRessource? depuisSql(String? valeur) {
    for (final StatutVersionRessource s in StatutVersionRessource.values) {
      if (s.valeurSql == valeur) return s;
    }
    return null;
  }
}

/// Une version immuable publiee (CONTRACTS section 5).
///
/// **Une version publiee ne change plus.** Toute evolution cree un nouveau
/// brouillon, et [empreinte] permet de le prouver.
@immutable
class ResourceVersion {
  /// Cree une version.
  ResourceVersion({
    required this.id,
    required this.resourceId,
    required this.numeroVersion,
    required this.statut,
    this.publieeLeUtc,
    this.publieePar,
    this.downloadAssetId,
    this.empreinte,
  }) : assert(
         publieeLeUtc == null || publieeLeUtc.isUtc,
         'tout DateTime de contrat est en UTC',
       );

  /// L'identifiant de la version.
  final String id;

  /// La ressource dont elle est une version.
  final String resourceId;

  /// Le numero, unique par ressource.
  final int numeroVersion;

  /// Le statut.
  final StatutVersionRessource statut;

  /// L'instant de publication, en UTC.
  final DateTime? publieeLeUtc;

  /// Qui l'a publiee.
  final String? publieePar;

  /// Le PDF derive, **genere une seule fois a la publication**.
  final String? downloadAssetId;

  /// Le sha256 du contenu, pour prouver l'immuabilite.
  final String? empreinte;

  @override
  bool operator ==(Object other) =>
      other is ResourceVersion &&
      other.id == id &&
      other.resourceId == resourceId &&
      other.numeroVersion == numeroVersion &&
      other.statut == statut &&
      other.publieeLeUtc == publieeLeUtc &&
      other.publieePar == publieePar &&
      other.downloadAssetId == downloadAssetId &&
      other.empreinte == empreinte;

  @override
  int get hashCode => Object.hash(
    id,
    resourceId,
    numeroVersion,
    statut,
    publieeLeUtc,
    publieePar,
    downloadAssetId,
    empreinte,
  );
}

/// Le format d'un artefact telechargeable.
enum FormatArtefact { pdf, epub, audio, image }

/// D'ou vient l'artefact.
enum OrigineArtefact {
  /// Produit une fois, au moment de la publication de la version.
  genereALaPublication,

  /// Importe tel quel : Rewayah n'en genere rien, il l'habille.
  importeTelQuel,
}

/// L'artefact telechargeable d'une version (CONTRACTS section 6).
@immutable
class DownloadAsset {
  /// Cree un artefact.
  DownloadAsset({
    required this.id,
    required this.resourceVersionId,
    required this.format,
    required this.cleStockage,
    required this.tailleOctets,
    required this.origine,
    required this.creeLeUtc,
    this.empreinte,
  }) : assert(creeLeUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// L'identifiant de l'artefact.
  final String id;

  /// La version dont il derive.
  final String resourceVersionId;

  /// Le format.
  final FormatArtefact format;

  /// La cle Storage. **JAMAIS une URL signee.**
  final String cleStockage;

  /// La taille en octets.
  final int tailleOctets;

  /// Le sha256, quand il est connu.
  final String? empreinte;

  /// L'origine.
  final OrigineArtefact origine;

  /// L'instant de creation, en UTC.
  final DateTime creeLeUtc;
}
