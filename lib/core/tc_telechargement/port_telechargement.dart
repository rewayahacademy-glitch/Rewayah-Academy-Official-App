import 'download_asset.dart';

/// L'acces aux artefacts telechargeables d'une version (CONTRACTS section 6).
abstract class PortTelechargement {
  /// L'artefact d'une version dans un format donne. `null` quand la version
  /// n'en porte pas : **on n'en genere pas un a la volee.**
  Future<DownloadAsset?> artefactDe(
    String resourceVersionId,
    FormatArtefact format,
  );

  /// Rend une URL d'acces ephemere.
  ///
  /// Elle n'est **jamais** persistee : on persiste la cle, l'URL se redemande
  /// (patron `ServiceAvatarSupabase.urlSignee`). Leve [EchecArtefact] quand
  /// aucun stockage ne peut la produire.
  Future<Uri> urlEphemere(DownloadAsset asset);
}

/// Comment la Bibliotheque obtient les octets d'un artefact.
///
/// **Port local d'Agent B, hors contrat canonique.** Il manque parce que
/// « Enregistrer une copie » a besoin d'octets, que `PortTelechargement` rend
/// une URL et non un corps, et qu'aucun client HTTP n'est expose dans `lib/`.
/// Sa promotion en contrat partage est demandee dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
abstract interface class LecteurArtefact {
  /// Les octets d'un artefact, ou `null` quand ils ne sont pas obtenables.
  ///
  /// `null` plutot qu'une exception : l'indisponibilite d'un artefact est un
  /// **etat normal** du produit tant que le stockage n'existe pas, et
  /// l'interface doit l'expliquer, pas l'afficher comme une panne.
  Future<List<int>?> octets(DownloadAsset asset);
}

/// Un artefact qu'on ne peut ni situer ni servir.
class EchecArtefact implements Exception {
  /// Cree l'echec.
  const EchecArtefact(this.raison);

  /// Ce qui manque, en une phrase technique.
  final String raison;

  @override
  String toString() => 'EchecArtefact: $raison';
}
