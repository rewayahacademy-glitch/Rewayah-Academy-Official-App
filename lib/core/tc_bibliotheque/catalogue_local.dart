import '../tc_telechargement/download_asset.dart';
import '../tc_telechargement/port_telechargement.dart';
import 'content_position.dart';
import 'library_resource.dart';
import 'port_catalogue.dart';
import 'port_versions_ressource.dart';
import 'recherche_catalogue.dart';
import 'resource_version.dart';

/// Le catalogue en memoire.
///
/// **C'est un double local, et il le restera jusqu'a ce que les tables
/// existent.** Aucune table `library_resource`, `resource_version` ni
/// `download_asset` n'est en base : les migrations `0001` a `0029` ont ete
/// relues, et aucun bucket Storage n'existe en dehors de `kyc` et `avatars`.
/// La demande SQL correspondante est dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
///
/// Il n'est pas une maquette pour autant : c'est **le** point d'implementation
/// des regles de tri, de recherche et de reprise, et il applique exactement
/// celles que la version Supabase devra appliquer. Le jour ou la table existe,
/// c'est le corps des methodes qui change, pas leur contrat ni les ecrans.
///
/// **Aucune ressource inventee.** Le catalogue par defaut est vide : livrer un
/// contenu de demonstration ferait passer une maquette pour un produit.
class CatalogueLocal implements PortCatalogue {
  /// Cree un catalogue.
  CatalogueLocal({
    List<LibraryResource> ressources = const <LibraryResource>[],
    Map<String, List<String>> assignationsParGroupe =
        const <String, List<String>>{},
    List<String> ordreRecents = const <String>[],
    ReprisLecture? reprise,
  }) : _ressources = List<LibraryResource>.of(ressources),
       _assignations = Map<String, List<String>>.of(assignationsParGroupe),
       _recents = List<String>.of(ordreRecents),
       // Un parametre nomme ne peut pas s'appeler `_reprise` : la forme que
       // `prefer_initializing_formals` reclame est interdite par le langage
       // des que le champ est prive.
       // ignore: prefer_initializing_formals
       _reprise = reprise;

  final List<LibraryResource> _ressources;
  final Map<String, List<String>> _assignations;
  final List<String> _recents;
  ReprisLecture? _reprise;

  @override
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre}) async =>
      RechercheCatalogue.filtrer(_ressources, filtre);

  @override
  Future<List<LibraryResource>> recents({int limite = 10}) async {
    final List<LibraryResource> sortie = <LibraryResource>[];
    for (final String id in _recents) {
      if (sortie.length >= limite) break;
      final LibraryResource? r = _parId(id);
      if (r != null) sortie.add(r);
    }
    return List<LibraryResource>.unmodifiable(sortie);
  }

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async {
    final List<String> ids = _assignations[groupeId] ?? const <String>[];
    return List<LibraryResource>.unmodifiable(
      ids.map(_parId).whereType<LibraryResource>(),
    );
  }

  @override
  Future<LibraryResource?> parId(String resourceId) async => _parId(resourceId);

  @override
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  }) async => RechercheCatalogue.chercher(
    RechercheCatalogue.filtrer(_ressources, filtre),
    requete,
  );

  @override
  Future<ReprisLecture?> derniereLecture() async => _reprise;

  /// Note une consultation : la ressource remonte en tete des recents et
  /// devient le point de reprise.
  ///
  /// C'est **le seul geste d'ecriture** du catalogue local. Il correspond a ce
  /// que `student_reading_position` fait deja cote eleve, et il ne doit
  /// **jamais** etre declenche par une page tournee pour toute la classe :
  /// l'invariant J2 de `0007` separe la position personnelle de la position de
  /// groupe, et les confondre ecrirait la lecture du professeur dans le
  /// dossier de l'eleve.
  void noterConsultation({
    required String resourceId,
    required ContentPosition position,
    required DateTime maintenantUtc,
  }) {
    final LibraryResource? r = _parId(resourceId);
    if (r == null) return;
    _recents
      ..remove(resourceId)
      ..insert(0, resourceId);
    _reprise = ReprisLecture(
      ressource: r,
      position: position,
      vueLeUtc: maintenantUtc.toUtc(),
    );
  }

  LibraryResource? _parId(String id) {
    for (final LibraryResource r in _ressources) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// Les versions de ressources, en memoire.
///
/// Classe distincte de [CatalogueLocal] et non second role de la meme :
/// `PortCatalogue.parId` et `PortVersionsRessource.parId` portent le meme nom
/// pour deux choses differentes, et une classe ne peut pas honorer les deux.
///
/// [versionCourante] est **la version publiee de numero le plus eleve**, jamais
/// une colonne de pointeur : c'est exactement la regle de
/// `versionActiveProgrammeProvider` (`0020`), et elle evite qu'un pointeur
/// oublie laisse une ressource sur une version archivee.
class VersionsLocales implements PortVersionsRessource {
  /// Cree le depot de versions.
  VersionsLocales({
    Map<String, List<ResourceVersion>> parRessource =
        const <String, List<ResourceVersion>>{},
  }) : _parRessource = Map<String, List<ResourceVersion>>.of(parRessource);

  final Map<String, List<ResourceVersion>> _parRessource;

  @override
  Future<ResourceVersion?> versionCourante(String resourceId) async {
    ResourceVersion? courante;
    for (final ResourceVersion v in _liste(resourceId)) {
      if (v.statut != StatutVersionRessource.publiee) continue;
      if (courante == null || v.numeroVersion > courante.numeroVersion) {
        courante = v;
      }
    }
    return courante;
  }

  @override
  Future<ResourceVersion?> parId(String versionId) async {
    for (final List<ResourceVersion> liste in _parRessource.values) {
      for (final ResourceVersion v in liste) {
        if (v.id == versionId) return v;
      }
    }
    return null;
  }

  @override
  Future<List<ResourceVersion>> historique(String resourceId) async {
    final List<ResourceVersion> trie = List<ResourceVersion>.of(
      _liste(resourceId),
    )..sort(
      (ResourceVersion a, ResourceVersion b) =>
          b.numeroVersion.compareTo(a.numeroVersion),
    );
    return List<ResourceVersion>.unmodifiable(trie);
  }

  List<ResourceVersion> _liste(String resourceId) =>
      _parRessource[resourceId] ?? const <ResourceVersion>[];
}

/// Les artefacts telechargeables, en memoire.
///
/// **Rien n'est genere ici.** Un artefact est depose a la publication, ou il
/// n'existe pas : c'est la regle de la spec section 6.5, et c'est ce qui
/// empeche un PDF d'etre refabrique a chaque clic. Tant qu'aucun bucket
/// Storage n'existe, [urlEphemere] echoue franchement plutot que de rendre une
/// URL qui ne menerait nulle part.
class ArtefactsLocaux implements PortTelechargement, LecteurArtefact {
  /// Cree le depot d'artefacts.
  ArtefactsLocaux({
    Map<String, List<DownloadAsset>> parVersion =
        const <String, List<DownloadAsset>>{},
    Map<String, List<int>> octetsParCle = const <String, List<int>>{},
  }) : _parVersion = Map<String, List<DownloadAsset>>.of(parVersion),
       _octets = Map<String, List<int>>.of(octetsParCle);

  final Map<String, List<DownloadAsset>> _parVersion;
  final Map<String, List<int>> _octets;

  @override
  Future<DownloadAsset?> artefactDe(
    String resourceVersionId,
    FormatArtefact format,
  ) async {
    for (final DownloadAsset a
        in _parVersion[resourceVersionId] ?? const <DownloadAsset>[]) {
      if (a.format == format) return a;
    }
    return null;
  }

  @override
  Future<Uri> urlEphemere(DownloadAsset asset) async {
    throw const EchecArtefact(
      'aucun bucket Storage de supports : voir TC_CONTRACT_REQUEST_B',
    );
  }

  @override
  Future<List<int>?> octets(DownloadAsset asset) async =>
      _octets[asset.cleStockage];
}
