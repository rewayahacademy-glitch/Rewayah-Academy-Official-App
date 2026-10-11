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

  /// Vrai quand la source rend des liens de lecture (BIBLIO-LECTURE, contrat
  /// C-35). Faux (production, tant que le serveur n'en rend pas) : l'ecran ne
  /// pose aucun bouton « Ouvrir » et dit que l'apercu n'existe pas encore ;
  /// jamais un bouton qui echouerait au toucher.
  bool get lienLectureServi;

  /// Un lien de **lecture** court pour la version [resourceVersionId] : un GET
  /// rendu par le serveur, valable 60 s au plus, apres re-controle des droits
  /// (spec CAP-29 §6, C-30 et C-35).
  ///
  /// Le lien n'est **jamais garde ni journalise** : l'appelant l'ouvre
  /// aussitot, puis l'oublie, et en redemande un a chaque ouverture. Leve
  /// [EchecArtefact] quand la source n'en rend aucun pour cette version (ni
  /// droit, ni artefact), et toute autre exception pour une panne a relancer.
  Future<Uri> lienLecture(String resourceVersionId);
}

/// Comment la Bibliotheque obtient les octets d'un artefact.
///
/// **Port local d'Agent B, hors contrat canonique.** Il manque parce que
/// « Enregistrer une copie » a besoin d'octets, que `PortTelechargement` rend
/// une URL et non un corps, et qu'aucun client HTTP n'est expose dans `lib/`.
/// Sa promotion en contrat partage est demandee dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_B.md`.
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
