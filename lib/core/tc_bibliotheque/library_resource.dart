import 'package:flutter/foundation.dart';

/// Le type d'une ressource de la Bibliotheque (spec section 6.3).
///
/// Chaque type a son renderer, mais **le type ne decide de rien a lui seul** :
/// c'est [LibraryResource.capabilities] qui dit ce qu'une surface a le droit
/// d'offrir. Un PDF n'est pas annotable parce qu'il est un PDF, il l'est parce
/// que sa capacite le dit.
enum TypeRessource {
  /// Coran. Son rendu appartient au moteur d'Agent C, jamais a ce module.
  quran('quran'),

  /// Texte structure : sections, recherche, zoom.
  texteStructure('structured_text'),

  /// PDF natif ou importe.
  pdf('pdf'),

  /// Image pedagogique.
  image('image'),

  /// Lecon Rewayah structuree en blocs.
  lecon('lesson'),

  /// Un enregistrement audio (la voix de la direction, une recitation).
  audio('audio'),

  /// Une video. Elle se depose par lien (le poids des fichiers video depasse ce
  /// que le depot accepte) : voir `LibraryResource.lienExterne`.
  video('video'),

  /// Un lien externe, montre en petite carte avec sa description.
  lienExterne('external_link');

  const TypeRessource(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. **Rend `null` sur valeur inconnue**,
  /// jamais un repli silencieux : meme regle que `lib/core/domain/enums.dart`.
  static TypeRessource? depuisSql(String? valeur) {
    for (final TypeRessource type in TypeRessource.values) {
      if (type.valeurSql == valeur) return type;
    }
    return null;
  }

  /// Vrai pour la famille « document » du filtre de l'eleve : un PDF, un texte
  /// ou une lecon. Le filtre par type (document, audio, video, lien externe)
  /// regroupe ainsi les valeurs de la base sans en doubler aucune.
  bool get estDocument =>
      this == TypeRessource.pdf ||
      this == TypeRessource.texteStructure ||
      this == TypeRessource.lecon;
}

/// Un rayon de la Bibliotheque : une place du catalogue, en donnee (« Documents
/// des cours », « Pour aller plus loin »). Le serveur en tient la liste ; aucun
/// ecran n'en code le nom. **Aucun prix** : le second rayon est une place
/// preparee, rien n'y est vendu (directeur, 12/11/2026).
@immutable
class RayonBibliotheque {
  /// Cree un rayon.
  const RayonBibliotheque({
    required this.code,
    required this.titreFr,
    required this.titreAr,
    required this.ordre,
  });

  /// Lit un rayon rendu par le serveur.
  factory RayonBibliotheque.depuisJson(Map<String, dynamic> json) =>
      RayonBibliotheque(
        code: json['code'] as String? ?? codeRayonCours,
        titreFr: json['titre_fr'] as String? ?? '',
        titreAr: json['titre_ar'] as String? ?? '',
        ordre: (json['ordre'] as num?)?.toInt() ?? 1,
      );

  /// Le code stable du rayon.
  final String code;

  /// Son intitule en francais.
  final String titreFr;

  /// Son intitule en arabe.
  final String titreAr;

  /// Sa place : les rayons s'affichent par ordre croissant.
  final int ordre;

  /// L'intitule dans la langue demandee (`ar` ou, par defaut, `fr`).
  String titrePour(String langue) =>
      langue == 'ar' && titreAr.isNotEmpty ? titreAr : titreFr;

  @override
  bool operator ==(Object other) =>
      other is RayonBibliotheque &&
      other.code == code &&
      other.titreFr == titreFr &&
      other.titreAr == titreAr &&
      other.ordre == ordre;

  @override
  int get hashCode => Object.hash(code, titreFr, titreAr, ordre);
}

/// Les quatre tranches d'age (codes de `cohortes_age`).
const List<String> tranchesToutes = <String>[
  'enfant_6_9',
  'enfant_10_13',
  'ado_14_17',
  'adulte_18_plus',
];

/// Les tranches par defaut d'un document donne par un lien : la tranche 6-9
/// en est exclue, la direction la coche expressement (decision du 12/11/2026).
const List<String> tranchesParDefautLien = <String>[
  'enfant_10_13',
  'ado_14_17',
  'adulte_18_plus',
];

/// Le rayon des documents fournis avec les cours.
const String codeRayonCours = 'cours';

/// Le second rayon : une place preparee, sans vente.
const String codeRayonPlusLoin = 'plus_loin';

/// Les dix capacites du manifeste (spec section 6.4).
///
/// **La seule source du comportement offert.** Une UI ne devine jamais qu'un
/// support est annotable ou presentable : elle lit cet ensemble.
enum CapaciteRessource {
  /// Le support a des pages.
  pageable('pageable'),

  /// Le support se cherche en texte.
  searchable('searchable'),

  /// Le support se zoome.
  zoomable('zoomable'),

  /// Une selection est possible dans le support.
  selectable('selectable'),

  /// Le support accepte un focus sur une portion.
  focusable('focusable'),

  /// Le support accepte une couche d'annotation (Agent D).
  annotatable('annotatable'),

  /// Le support peut etre assigne comme travail (Agent D).
  assignable('assignable'),

  /// Le support peut devenir le support actif d'une classe (Agent E / F).
  presentableInClass('presentable_in_class'),

  /// Le stylet est pris en charge par le renderer du support.
  supportsStylus('supports_stylus'),

  /// Le support peut exister hors ligne.
  supportsOffline('supports_offline');

  const CapaciteRessource(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une capacite depuis sa valeur SQL. `null` sur valeur inconnue.
  static CapaciteRessource? depuisSql(String? valeur) {
    for (final CapaciteRessource c in CapaciteRessource.values) {
      if (c.valeurSql == valeur) return c;
    }
    return null;
  }
}

/// Qui peut voir une ressource.
///
/// **Ce champ ne decide aucun acces.** La RLS et les vues bornees decident ;
/// ce champ dit seulement a l'interface ce qu'elle doit expliquer quand le
/// serveur refuse (CONTRACTS section 18).
enum PolitiqueAcces {
  /// Visible sans compte.
  publique('publique'),

  /// Visible de toute personne inscrite.
  inscrits('inscrits'),

  /// Visible du groupe auquel la ressource est assignee.
  groupeAssigne('groupe_assigne'),

  /// Visible du seul enseignant.
  enseignantSeul('enseignant_seul'),

  /// Visible de l'administration.
  admin('admin');

  const PolitiqueAcces(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une politique depuis sa valeur SQL. `null` sur valeur inconnue.
  static PolitiqueAcces? depuisSql(String? valeur) {
    for (final PolitiqueAcces p in PolitiqueAcces.values) {
      if (p.valeurSql == valeur) return p;
    }
    return null;
  }
}

/// Ce que la ressource autorise en matiere de hors ligne.
enum PolitiqueOffline {
  /// Jamais disponible hors ligne. Droits de distribution, poids, ou les deux.
  jamais('jamais'),

  /// Telechargeable a la demande de la personne.
  surDemande('sur_demande'),

  /// Mise a disposition automatique quand le contexte s'y prete.
  automatique('automatique');

  const PolitiqueOffline(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une politique depuis sa valeur SQL. `null` sur valeur inconnue.
  static PolitiqueOffline? depuisSql(String? valeur) {
    for (final PolitiqueOffline p in PolitiqueOffline.values) {
      if (p.valeurSql == valeur) return p;
    }
    return null;
  }
}

/// Le manifeste d'une ressource de la Bibliotheque (CONTRACTS section 4).
///
/// **Une seule Bibliotheque** : cette meme classe sert hors classe et en
/// classe. Il n'existe pas de `LibraryOutsideClass` ni de `LibraryInsideClass`
/// (decision D-20).
///
/// **La source est immuable.** Aucune annotation, aucun marqueur, aucun focus
/// ne cree une copie du support : ils vivent dans des couches separees, qui
/// referencent une [ContentPosition] et non une copie des octets.
///
/// **[coverAsset] n'est jamais une URL signee** : une URL signee expire, et la
/// lecon est deja inscrite dans `lib/core/appairage/service_avatar.dart`. On
/// persiste la cle de stockage, l'URL se redemande.
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
    required this.accessPolicy,
    required this.offlinePolicy,
    this.coverAsset,
    this.edition,
    this.levelScope = const <String>[],
    this.currentVersionId,
    this.capabilities = const <CapaciteRessource>{},
    this.description,
    this.lienExterne,
    this.ordre = 0,
    this.rayon = codeRayonCours,
    this.etapes = const <String>[],
    this.aVignette = false,
    this.tranches = tranchesToutes,
    this.lectureCoran,
    this.ecolePriere,
  });

  /// Lit un manifeste rendu par la couche serveur.
  ///
  /// La forme attendue est celle demandee dans
  /// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_B.md` : tant que la table
  /// n'existe pas, cette fabrique n'a aucun appelant en production, mais elle
  /// fige le contrat de nommage cote SQL.
  factory LibraryResource.depuisJson(Map<String, dynamic> json) {
    final List<dynamic> capacites =
        json['capabilities'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> niveaux =
        json['level_scope'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> etapes =
        json['etapes'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> tranches =
        json['tranches'] as List<dynamic>? ?? const <dynamic>[];

    return LibraryResource(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      shortTitle: json['short_title'] as String? ?? '',
      coverAsset: json['cover_asset'] as String?,
      // Un type inconnu se replie sur `lecon` : l'appelant garde une
      // ressource listable, et la capacite absente ferme les surfaces qui
      // exigeraient un renderer particulier.
      resourceType:
          TypeRessource.depuisSql(json['resource_type'] as String?) ??
          TypeRessource.lecon,
      edition: json['edition'] as String?,
      language: json['language'] as String? ?? 'fr',
      category: json['category'] as String? ?? '',
      levelScope: niveaux
          .map((dynamic n) => n.toString())
          .toList(growable: false),
      accessPolicy:
          PolitiqueAcces.depuisSql(json['access_policy'] as String?) ??
          PolitiqueAcces.admin,
      offlinePolicy:
          PolitiqueOffline.depuisSql(json['offline_policy'] as String?) ??
          PolitiqueOffline.jamais,
      currentVersionId: json['current_version_id'] as String?,
      capabilities: capacites
          .map((dynamic c) => CapaciteRessource.depuisSql(c.toString()))
          .whereType<CapaciteRessource>()
          .toSet(),
      description: json['description'] as String?,
      lienExterne: json['lien_externe'] as String?,
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      rayon: _codeRayon(json['rayon']),
      etapes: etapes.map((dynamic e) => e.toString()).toList(growable: false),
      aVignette: json['vignette'] == true,
      tranches: tranches.isEmpty
          ? tranchesToutes
          : tranches.map((dynamic e) => e.toString()).toList(growable: false),
      lectureCoran: json['lecture_coran'] as String?,
      ecolePriere: json['ecole_priere'] as String?,
    );
  }

  /// Le code du rayon, rendu par le serveur sous forme d'objet
  /// (`{code, titre_fr, titre_ar, ordre}`) ou de simple code.
  static String _codeRayon(Object? brut) {
    if (brut is Map) return brut['code'] as String? ?? codeRayonCours;
    if (brut is String && brut.isNotEmpty) return brut;
    return codeRayonCours;
  }

  /// L'identifiant de la ressource (uuid).
  final String id;

  /// Le titre humain complet.
  final String title;

  /// Le titre court, employe sur la carte et dans les listes denses.
  final String shortTitle;

  /// La cle d'asset ou de Storage de la couverture. **Jamais une URL signee.**
  /// `null` quand aucune couverture n'a ete deposee : la vignette se replie
  /// alors sur une couverture calculee, deterministe et distincte.
  final String? coverAsset;

  /// Le type de ressource.
  final TypeRessource resourceType;

  /// L'edition, quand la notion s'applique (ex. `madina-hafs-604`).
  final String? edition;

  /// La langue principale du contenu (`fr`, `ar`, ...).
  final String language;

  /// La categorie de rangement (texte libre administre).
  final String category;

  /// Les codes de niveau du programme auxquels la ressource se rattache.
  final List<String> levelScope;

  /// Qui peut voir la ressource. Information, jamais une barriere.
  final PolitiqueAcces accessPolicy;

  /// Ce que la ressource autorise hors ligne.
  final PolitiqueOffline offlinePolicy;

  /// La version publiee courante. `null` quand aucune version n'est publiee :
  /// la ressource existe alors au catalogue sans contenu consultable.
  final String? currentVersionId;

  /// Les capacites offertes.
  final Set<CapaciteRessource> capabilities;

  /// La description courte, montree sur la carte. Obligatoire pour un lien
  /// externe (la base l'exige).
  final String? description;

  /// L'adresse https d'un lien externe ou d'une video par lien. Validee par la
  /// base ; `null` pour tout autre document.
  final String? lienExterne;

  /// L'ordre d'affichage dans le rayon (croissant).
  final int ordre;

  /// Le code du rayon : [codeRayonCours] ou [codeRayonPlusLoin]. Les intitules
  /// viennent de `PortCatalogue.rayons()`, jamais d'un ecran.
  final String rayon;

  /// Les codes stables des etapes du programme auxquelles le document se
  /// rattache (aucune cle vers une version du programme).
  final List<String> etapes;

  /// Les tranches d'age auxquelles le document s'adresse (codes de
  /// `cohortes_age`), fixees par la direction. Le serveur filtre la lecture ;
  /// ce champ ne decide aucun acces, il dit a la direction a qui le document
  /// s'adresse.
  final List<String> tranches;

  /// La lecture du Coran concernee (`hafs`, `warsh`, `qalun`, `shuba`), quand
  /// la direction l'a precisee.
  final String? lectureCoran;

  /// L'ecole suivie pour un document de priere ou d'ablutions (texte libre
  /// court), quand la direction l'a precisee.
  final String? ecolePriere;

  /// Vrai quand une vignette a ete deposee. L'URL signee ne vient jamais du
  /// manifeste : elle se demande au serveur (`PortVignettes`). Sans vignette,
  /// la couverture par defaut du type s'applique.
  final bool aVignette;

  /// Vrai quand la ressource porte la capacite demandee.
  bool peut(CapaciteRessource capacite) => capabilities.contains(capacite);

  /// Vrai quand une version publiee existe : sans elle, il n'y a rien a ouvrir.
  bool get publiee => currentVersionId != null;
}
