import 'package:flutter/foundation.dart';

/// Le format d'un artefact telechargeable.
enum FormatArtefact {
  /// Un PDF.
  pdf('pdf', 'application/pdf', 'pdf'),

  /// Un livre numerique.
  epub('epub', 'application/epub+zip', 'epub'),

  /// Un fichier audio.
  audio('audio', 'audio/mpeg', 'mp3'),

  /// Une image.
  image('image', 'image/png', 'png');

  const FormatArtefact(this.valeurSql, this.typeMime, this.extension);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Le type MIME a passer au selecteur de fichiers du systeme.
  final String typeMime;

  /// L'extension proposee dans le nom de fichier.
  final String extension;

  /// Lit un format depuis sa valeur SQL. `null` sur valeur inconnue.
  static FormatArtefact? depuisSql(String? valeur) {
    for (final FormatArtefact f in FormatArtefact.values) {
      if (f.valeurSql == valeur) return f;
    }
    return null;
  }
}

/// D'ou vient l'artefact.
enum OrigineArtefact {
  /// Produit une seule fois a la publication d'une version structuree.
  genereALaPublication('genere_a_la_publication'),

  /// Depose tel quel : c'est l'original, et il le reste.
  importeTelQuel('importe_tel_quel');

  const OrigineArtefact(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une origine depuis sa valeur SQL. `null` sur valeur inconnue.
  static OrigineArtefact? depuisSql(String? valeur) {
    for (final OrigineArtefact o in OrigineArtefact.values) {
      if (o.valeurSql == valeur) return o;
    }
    return null;
  }
}

/// L'artefact telechargeable derive d'une version publiee (CONTRACTS
/// section 6).
///
/// Trois regles portees par le type plutot que par la vigilance :
///
/// 1. **Genere une seule fois a la publication**, puis reutilise. Jamais a
///    chaque clic : c'est pour cela que l'artefact porte un identifiant et une
///    empreinte, et non une fonction de generation ;
/// 2. **[cleStockage] est une cle, jamais une URL signee.** Une URL signee
///    expire ; la lecon est deja inscrite dans
///    `lib/core/appairage/service_avatar.dart` ;
/// 3. un PDF **importe** ([OrigineArtefact.importeTelQuel]) reste l'artefact
///    source telechargeable. Rewayah fabrique autour de lui ses metadonnees,
///    sa couverture et son index, sans le remplacer.
@immutable
class DownloadAsset {
  /// Cree un artefact.
  ///
  /// Non `const` : l'assertion d'UTC lit un getter d'instance, qui ne
  /// s'evalue pas a la compilation.
  DownloadAsset({
    required this.id,
    required this.resourceVersionId,
    required this.format,
    required this.cleStockage,
    required this.tailleOctets,
    required this.origine,
    required this.creeLeUtc,
    this.empreinte,
  }) : assert(creeLeUtc.isUtc, 'tout DateTime d un contrat est en UTC');

  /// Lit un artefact rendu par la couche serveur.
  factory DownloadAsset.depuisJson(Map<String, dynamic> json) => DownloadAsset(
    id: json['id'] as String,
    resourceVersionId: json['resource_version_id'] as String,
    format:
        FormatArtefact.depuisSql(json['format'] as String?) ??
        FormatArtefact.pdf,
    cleStockage: json['cle_stockage'] as String? ?? '',
    tailleOctets: (json['taille_octets'] as num?)?.toInt() ?? 0,
    empreinte: json['empreinte'] as String?,
    origine:
        OrigineArtefact.depuisSql(json['origine'] as String?) ??
        OrigineArtefact.importeTelQuel,
    creeLeUtc:
        DateTime.tryParse(json['cree_le'] as String? ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// L'identifiant de l'artefact.
  final String id;

  /// La version dont il derive.
  final String resourceVersionId;

  /// Son format.
  final FormatArtefact format;

  /// Sa cle dans le stockage. **Jamais une URL signee.**
  final String cleStockage;

  /// Sa taille, en octets. Sert a prevenir avant un telechargement lourd.
  final int tailleOctets;

  /// Son sha256, quand il est connu.
  final String? empreinte;

  /// D'ou il vient.
  final OrigineArtefact origine;

  /// Quand il a ete cree, en UTC.
  final DateTime creeLeUtc;
}
