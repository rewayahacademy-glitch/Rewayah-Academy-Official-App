// L'adaptateur Supabase de l'ouverture d'un document (BIBLIOTHEQUE-UNE, fil
// mort branche) : `PortTelechargement` et `LecteurArtefact`.
//
// La chaine, entierement au serveur : document publie -> droit verifie
// (`autoriser_lecture_version`, avec le jeton de l'appelant) -> URL signee de
// 60 s (fonction Edge `bibliotheque-lecture`). Le client ne fabrique, ne garde
// ni ne journalise aucune URL : `lienLecture` en demande une a chaque
// ouverture. Aucune cle de stockage ne transite.
//
// La description du fichier (format, taille) vient de `VersionsSupabase`, qui
// la lit avec la version ; sans version lue, `artefactDe` rend `null` : on ne
// fabrique pas un artefact (spec section 6.5).

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_bibliotheque/versions_supabase.dart';
import 'download_asset.dart';
import 'port_telechargement.dart';

/// L'ouverture des documents, au serveur.
class TelechargementSupabase implements PortTelechargement, LecteurArtefact {
  /// Cree l'adaptateur. [transport] se remplace dans les tests.
  TelechargementSupabase(
    this._client,
    this._versions, {
    http.Client? transport,
  }) : _transport = transport ?? http.Client();

  final SupabaseClient _client;
  final VersionsSupabase _versions;
  final http.Client _transport;

  /// La taille au-dela de laquelle on ne charge pas un fichier en memoire pour
  /// l'afficher ou en faire une copie (le depot accepte jusqu'a 100 Mio).
  static const int octetsMax = 100 * 1024 * 1024;

  @override
  bool get lienLectureServi => true;

  @override
  Future<DownloadAsset?> artefactDe(
    String resourceVersionId,
    FormatArtefact format,
  ) async {
    final DownloadAsset? a = _versions.artefactEnMemoire(resourceVersionId);
    return a != null && a.format == format ? a : null;
  }

  @override
  Future<Uri> urlEphemere(DownloadAsset asset) =>
      lienLecture(asset.resourceVersionId);

  @override
  Future<Uri> lienLecture(String resourceVersionId) async {
    final FunctionResponse reponse;
    try {
      reponse = await _client.functions.invoke(
        'bibliotheque-lecture',
        body: <String, Object?>{'resource_version_id': resourceVersionId},
      );
    } on FunctionException catch (e) {
      // 401 et 403 : aucun droit ou aucun artefact pour cette version.
      if (e.status == 401 || e.status == 403) {
        throw const EchecArtefact('lecture refusee');
      }
      rethrow;
    }
    return lireLien(reponse.data);
  }

  /// L'URL d'une reponse `{url, expire_dans_secondes}`. N'accepte que de
  /// l'https.
  static Uri lireLien(Object? brut) {
    final Object? url = brut is Map ? brut['url'] : null;
    final Uri? uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const EchecArtefact('lien de lecture illisible');
    }
    return uri;
  }

  @override
  Future<List<int>?> octets(DownloadAsset asset) async {
    if (asset.tailleOctets > octetsMax) return null;
    try {
      final Uri lien = await lienLecture(asset.resourceVersionId);
      final http.Response reponse = await _transport.get(lien);
      if (reponse.statusCode != 200 || reponse.bodyBytes.length > octetsMax) {
        return null;
      }
      return reponse.bodyBytes;
    } on Object {
      // L'indisponibilite d'un fichier est un etat normal : l'ecran
      // l'explique et propose de reessayer, il ne plante pas.
      return null;
    }
  }
}
