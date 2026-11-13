// L'adaptateur Supabase des versions d'un document, cote lecteur
// (BIBLIOTHEQUE-UNE, fil mort branche).
//
// Lecture seule, par `bibliotheque_version_lecteur` (migration
// 20261123921000) : le serveur ne rend la version publiee courante que d'un
// document que l'appelant a le droit de lire, avec son fichier decrit (format,
// taille, empreinte) mais **sans cle de stockage**. L'URL de lecture vient
// ensuite de `TelechargementSupabase`, apres un second controle de droit.
//
// Le port ne connait que « la version courante » : l'historique complet est
// une affaire de la direction (`PortBibliothequeAdmin`), pas du lecteur.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_telechargement/download_asset.dart';
import 'port_catalogue.dart';
import 'port_versions_ressource.dart';
import 'resource_version.dart';

/// Les versions lues au serveur.
class VersionsSupabase implements PortVersionsRessource {
  /// Cree l'adaptateur.
  VersionsSupabase(this._client);

  final SupabaseClient _client;

  /// Les fichiers decrits par les dernieres lectures, par version : c'est ce
  /// que `TelechargementSupabase.artefactDe` rend (le port est cle par
  /// version, la lecture serveur par document).
  final Map<String, DownloadAsset> _artefacts = <String, DownloadAsset>{};

  /// Le fichier decrit pour [versionId], lu en meme temps que sa version.
  DownloadAsset? artefactEnMemoire(String versionId) => _artefacts[versionId];

  @override
  Future<ResourceVersion?> versionCourante(String resourceId) async {
    final Object? brut;
    try {
      brut = await _client.rpc<Object?>(
        'bibliotheque_version_lecteur',
        params: <String, dynamic>{'p_resource_id': resourceId},
      );
    } on PostgrestException catch (e) {
      throw EchecCatalogue(e.code == '42501' ? 'non autorise' : 'refus du serveur');
    } on Exception {
      throw const EchecCatalogue('hors ligne');
    }
    if (brut is! Map) return null;
    final Map<String, dynamic> m = Map<String, dynamic>.from(brut);
    final ResourceVersion version = ResourceVersion.depuisJson(m);
    final Object? asset = m['asset'];
    if (asset is Map) {
      _artefacts[version.id] = DownloadAsset.depuisJson(
        Map<String, dynamic>.from(asset),
      );
    } else {
      _artefacts.remove(version.id);
    }
    return version;
  }

  /// Le lecteur ne lit qu'une version : la courante, par document. Une version
  /// precise n'a pas de lecture serveur (aucun besoin : l'historique est a la
  /// direction).
  @override
  Future<ResourceVersion?> parId(String versionId) async => null;

  @override
  Future<List<ResourceVersion>> historique(String resourceId) async {
    final ResourceVersion? v = await versionCourante(resourceId);
    return v == null ? const <ResourceVersion>[] : <ResourceVersion>[v];
  }
}
