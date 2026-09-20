import 'package:flutter/foundation.dart';

/// Le statut d'une version de ressource (CONTRACTS section 5).
///
/// Le vocabulaire est **exactement** celui de `StatutVersionProgramme`
/// (`lib/core/admin/service_programme.dart`, migration `0020`) : le triplet,
/// le repli sur `publiee` et la publication irreversible imposee en base y
/// sont deja ecrits et testes. Un second vocabulaire de statuts ferait
/// diverger deux moities du meme produit.
enum StatutVersionRessource {
  /// Modifiable.
  brouillon('brouillon'),

  /// Figee. Toute evolution cree une nouvelle version.
  publiee('publiee'),

  /// Figee, remplacee par une version publiee plus recente.
  archivee('archivee');

  const StatutVersionRessource(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL.
  ///
  /// Se replie sur `publiee`, comme `0020` : un statut mal lu ne doit jamais
  /// laisser croire qu'une version est encore modifiable.
  static StatutVersionRessource depuisSql(String? valeur) => switch (valeur) {
    'brouillon' => StatutVersionRessource.brouillon,
    'archivee' => StatutVersionRessource.archivee,
    _ => StatutVersionRessource.publiee,
  };
}

/// Une version immuable publiee d'une ressource.
///
/// **Une version publiee ne se modifie plus.** La contrainte appartient a la
/// base, pas au client : c'est ce que fait deja `0020` pour le programme
/// pedagogique, et c'est ce que demande
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md` pour les ressources.
///
/// **[downloadAssetId] est renseigne une seule fois, a la publication.** On ne
/// regenere jamais un PDF a chaque clic (spec section 6.5).
@immutable
class ResourceVersion {
  /// Cree une version.
  ///
  /// Non `const` : l'assertion d'UTC lit un getter d'instance, qui ne
  /// s'evalue pas a la compilation.
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
         'tout DateTime d un contrat est en UTC',
       );

  /// Lit une version rendue par la couche serveur.
  factory ResourceVersion.depuisJson(Map<String, dynamic> json) =>
      ResourceVersion(
        id: json['id'] as String,
        resourceId: json['resource_id'] as String,
        numeroVersion: (json['numero_version'] as num?)?.toInt() ?? 0,
        statut: StatutVersionRessource.depuisSql(json['statut'] as String?),
        publieeLeUtc: DateTime.tryParse(
          json['publiee_le'] as String? ?? '',
        )?.toUtc(),
        publieePar: json['publiee_par'] as String?,
        downloadAssetId: json['download_asset_id'] as String?,
        empreinte: json['empreinte'] as String?,
      );

  /// L'identifiant de la version.
  final String id;

  /// La ressource dont elle est une version.
  final String resourceId;

  /// Le numero de version, unique par ressource.
  final int numeroVersion;

  /// Le statut courant.
  final StatutVersionRessource statut;

  /// Quand la version a ete publiee. `null` tant qu'elle est brouillon.
  final DateTime? publieeLeUtc;

  /// Qui l'a publiee.
  final String? publieePar;

  /// L'artefact telechargeable derive, s'il existe.
  final String? downloadAssetId;

  /// Le sha256 du contenu, qui prouve l'immuabilite.
  final String? empreinte;

  /// Vrai quand la version est encore modifiable.
  bool get modifiable => statut == StatutVersionRessource.brouillon;
}
