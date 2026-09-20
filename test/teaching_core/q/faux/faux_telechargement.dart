// Faux telechargement : le compteur qui prouve qu'on ne regenere pas.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// L'invariant teste est economique autant que technique : « genere une seule
// fois a la publication, puis reutilise. Jamais a chaque clic » (CONTRACTS
// section 6, invariant 1). Un double sans compteur ne pourrait pas le dire.

import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';

/// Le magasin d'artefacts, avec ses deux compteurs.
class FauxDepotTelechargement {
  /// Cree un depot.
  FauxDepotTelechargement({required this.horlogeUtc});

  /// L'horloge de reference, en UTC. Parametre, jamais `DateTime.now()`.
  final DateTime horlogeUtc;

  final Map<String, DownloadAsset> _parVersion = <String, DownloadAsset>{};

  /// Le nombre de generations de PDF. **Doit valoir 1 apres publication.**
  int generations = 0;

  /// Le nombre de lectures d'artefact.
  int lectures = 0;

  /// Le nombre d'URL ephemeres signees.
  int signatures = 0;

  /// Publie une version : **c'est ici, et seulement ici, qu'on genere**.
  DownloadAsset publier({
    required String resourceVersionId,
    required String cleStockage,
    required int tailleOctets,
    FormatArtefact format = FormatArtefact.pdf,
    String? empreinte,
  }) {
    generations++;
    final DownloadAsset asset = DownloadAsset(
      id: 'asset-$resourceVersionId',
      resourceVersionId: resourceVersionId,
      format: format,
      cleStockage: cleStockage,
      tailleOctets: tailleOctets,
      empreinte: empreinte,
      origine: OrigineArtefact.genereALaPublication,
      creeLeUtc: horlogeUtc,
    );
    _parVersion[resourceVersionId] = asset;
    return asset;
  }

  /// Enregistre un artefact **importe tel quel** : rien n'est genere.
  DownloadAsset importer(DownloadAsset asset) {
    _parVersion[asset.resourceVersionId] = asset;
    return asset;
  }

  /// Lit l'artefact d'une version. **Ne genere jamais.**
  DownloadAsset? artefactDe(String resourceVersionId, FormatArtefact format) {
    lectures++;
    final DownloadAsset? asset = _parVersion[resourceVersionId];
    if (asset == null || asset.format != format) return null;
    return asset;
  }

  /// Rend une URL d'acces **ephemere**, differente a chaque appel.
  ///
  /// Elle n'est jamais persistee : on persiste la cle. C'est la lecon deja
  /// inscrite dans `service_avatar.dart`.
  Uri urlEphemere(DownloadAsset asset) {
    signatures++;
    return Uri.parse(
      'https://stockage.invalid/${asset.cleStockage}?signature=s$signatures',
    );
  }
}

/// Le double d'« Enregistrer une copie ».
///
/// Il passe **toujours** par un selecteur systeme et rend `null` quand
/// l'usager annule. Aucun chemin `/sdcard` bricole : `file_picker 12.2.0`
/// expose deja `saveFile()`, aucune dependance nouvelle n'est requise.
class FauxEnregistrementFichier {
  /// Cree un double d'enregistrement.
  FauxEnregistrementFichier({this.annuleParUsager = false});

  /// L'usager annule-t-il la boite de dialogue.
  bool annuleParUsager;

  /// Les noms de fichier proposes, dans l'ordre.
  final List<String> propositions = <String>[];

  /// Le nombre de fois ou le selecteur systeme a ete ouvert.
  int ouverturesSelecteur = 0;

  /// Enregistre une copie. Rend `null` si l'usager annule.
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    ouverturesSelecteur++;
    propositions.add(nomFichierPropose);
    if (annuleParUsager) return null;
    return 'choisi-par-usager/$nomFichierPropose';
  }
}
