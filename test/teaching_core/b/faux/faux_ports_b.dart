import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart';

/// Un service de reseau en memoire.
///
/// Aucun test de CI ne peut couper le reseau d'une machine : sans ce faux, le
/// comportement hors ligne de la Bibliotheque ne serait pas mesurable.
class FauxServiceReseau implements ServiceReseau {
  /// Cree le faux.
  FauxServiceReseau({this.horsLigneRendu = false});

  /// Ce que [horsLigne] emettra.
  bool horsLigneRendu;

  final StreamController<bool> _controleur = StreamController<bool>.broadcast();

  @override
  Stream<bool> horsLigne() async* {
    yield horsLigneRendu;
    yield* _controleur.stream;
  }

  /// Bascule l'etat du reseau en cours de test.
  void basculer({required bool horsLigne}) {
    horsLigneRendu = horsLigne;
    _controleur.add(horsLigne);
  }

  /// Ferme le flux.
  Future<void> fermer() => _controleur.close();
}

/// Un catalogue qui echoue.
///
/// Une absence n'est pas un echec : ce faux sert a mesurer le second cas, que
/// l'ecran doit distinguer du premier.
class CatalogueEnEchec implements PortCatalogue {
  @override
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre}) =>
      Future<List<LibraryResource>>.error(
        const EchecCatalogue('lecture refusee'),
      );

  @override
  Future<List<LibraryResource>> recents({int limite = 10}) =>
      Future<List<LibraryResource>>.error(
        const EchecCatalogue('lecture refusee'),
      );

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) =>
      Future<List<LibraryResource>>.error(
        const EchecCatalogue('lecture refusee'),
      );

  @override
  Future<LibraryResource?> parId(String resourceId) =>
      Future<LibraryResource?>.error(const EchecCatalogue('lecture refusee'));

  @override
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  }) => Future<List<LibraryResource>>.error(
    const EchecCatalogue('lecture refusee'),
  );

  @override
  Future<ReprisLecture?> derniereLecture() =>
      Future<ReprisLecture?>.error(const EchecCatalogue('lecture refusee'));
}

/// Un enregistrement de fichier qui n'ouvre aucune boite de dialogue.
class FauxEnregistrementFichier implements PortEnregistrementFichier {
  /// Cree le faux.
  FauxEnregistrementFichier({this.destinationRendue = 'file:///copie.pdf'});

  /// Ce que le selecteur rendra. `null` simule une renonciation.
  String? destinationRendue;

  /// Les appels recus, pour verifier le nom et le type propose.
  final List<({String nom, String mime, int taille})> appels =
      <({String nom, String mime, int taille})>[];

  @override
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    appels.add((
      nom: nomFichierPropose,
      mime: typeMime,
      taille: octets.length,
    ));
    return destinationRendue;
  }
}

/// Une ressource de test.
///
/// Toutes les valeurs ont un defaut credible : un test ne dit que ce qui
/// compte pour lui, et le reste ne le distrait pas.
LibraryResource ressource({
  required String id,
  String? titre,
  String? titreCourt,
  TypeRessource type = TypeRessource.lecon,
  String langue = 'fr',
  String categorie = 'Tajwid',
  List<String> niveaux = const <String>['F1'],
  String? versionCourante = 'v1',
  String? couverture,
  String? edition,
  PolitiqueAcces acces = PolitiqueAcces.inscrits,
  PolitiqueOffline horsLigne = PolitiqueOffline.surDemande,
  Set<CapaciteRessource> capacites = const <CapaciteRessource>{
    CapaciteRessource.searchable,
    CapaciteRessource.supportsOffline,
    CapaciteRessource.presentableInClass,
  },
}) => LibraryResource(
  id: id,
  title: titre ?? 'Support $id',
  shortTitle: titreCourt ?? 'S $id',
  resourceType: type,
  language: langue,
  category: categorie,
  levelScope: niveaux,
  accessPolicy: acces,
  offlinePolicy: horsLigne,
  currentVersionId: versionCourante,
  coverAsset: couverture,
  edition: edition,
  capabilities: capacites,
);

/// Une version publiee de test.
ResourceVersion version({
  required String id,
  required String resourceId,
  int numero = 1,
  String? artefactId,
  StatutVersionRessource statut = StatutVersionRessource.publiee,
}) => ResourceVersion(
  id: id,
  resourceId: resourceId,
  numeroVersion: numero,
  statut: statut,
  publieeLeUtc: DateTime.utc(2026, 9, 1),
  downloadAssetId: artefactId,
);

/// Un artefact PDF de test.
DownloadAsset artefact({
  required String id,
  required String versionId,
  String cle = 'supports/demo.pdf',
  int taille = 1024,
}) => DownloadAsset(
  id: id,
  resourceVersionId: versionId,
  format: FormatArtefact.pdf,
  cleStockage: cle,
  tailleOctets: taille,
  origine: OrigineArtefact.importeTelQuel,
  creeLeUtc: DateTime.utc(2026, 9, 1),
);

/// Les versions publiees implicites d'un jeu de ressources.
///
/// Sans elles, une ressource qui declare `current_version_id` n'aurait aucune
/// version en face : l'etat hors ligne vaudrait `indisponible` pour tout le
/// catalogue, et chaque test devrait recopier la meme carte de versions. La
/// coherence du double est ici, pas dans chaque test.
Map<String, List<ResourceVersion>> versionsImplicites(
  List<LibraryResource> ressources,
) => <String, List<ResourceVersion>>{
  for (final LibraryResource r in ressources)
    if (r.currentVersionId != null)
      r.id: <ResourceVersion>[
        version(id: r.currentVersionId!, resourceId: r.id),
      ],
};

/// Le cablage complet d'un catalogue de test.
///
/// Une seule fonction pour les surcharges : chaque test qui composerait la
/// sienne finirait par en oublier une, et le provider reel irait alors chercher
/// un catalogue vide sans que rien ne le dise.
List<Override> surchargesCatalogue({
  List<LibraryResource> ressources = const <LibraryResource>[],
  Map<String, List<ResourceVersion>> versions =
      const <String, List<ResourceVersion>>{},
  Map<String, List<String>> assignations = const <String, List<String>>{},
  List<String> recents = const <String>[],
  ReprisLecture? reprise,
  Map<String, List<DownloadAsset>> artefacts =
      const <String, List<DownloadAsset>>{},
  Map<String, List<int>> octets = const <String, List<int>>{},
  DepotOctetsLocal? depot,
  ServiceReseau? reseau,
  PortCatalogue? catalogue,
  PortEnregistrementFichier? enregistrement,
}) {
  final ArtefactsLocaux depotArtefacts = ArtefactsLocaux(
    parVersion: artefacts,
    octetsParCle: octets,
  );
  return <Override>[
    portCatalogueProvider.overrideWithValue(
      catalogue ??
          CatalogueLocal(
            ressources: ressources,
            assignationsParGroupe: assignations,
            ordreRecents: recents,
            reprise: reprise,
          ),
    ),
    portVersionsRessourceProvider.overrideWithValue(
      VersionsLocales(
        parRessource: versions.isEmpty
            ? versionsImplicites(ressources)
            : versions,
      ),
    ),
    portTelechargementProvider.overrideWithValue(depotArtefacts),
    lecteurArtefactProvider.overrideWithValue(depotArtefacts),
    depotOctetsProvider.overrideWithValue(depot ?? DepotOctetsMemoire()),
    serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
    portEnregistrementFichierProvider.overrideWithValue(
      enregistrement ?? FauxEnregistrementFichier(),
    ),
  ];
}
