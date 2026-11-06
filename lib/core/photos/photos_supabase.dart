// L'adaptateur Supabase de la photo des personnes (PHOTOS-2a), sur les
// fonctions de la migration 20261107300000 : `photos_personnes`,
// `poser_ma_photo`, `poser_photo_eleve`. L'envoi du fichier passe par le seau
// que le serveur rend pour la personne ; la politique du seau n'autorise que
// son propre dossier (`avatar_ecriture_soi`, `photos_enseignants_ecriture`)
// ou celui d'un enfant de son foyer.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../appairage/service_avatar.dart';
import 'photo_personne.dart';

/// Duree de validite demandee pour une URL signee, en secondes (borne du
/// serveur : 600).
const int dureeUrlPhotoSecondes = 600;

/// La photo des personnes, lue et posee au serveur.
class PhotosSupabase implements PortPhotos {
  /// Cree l'adaptateur.
  const PhotosSupabase(this._client);

  final SupabaseClient _client;

  /// Les lignes `(profile_id, seau, cle)` rendues par le serveur.
  static Map<String, SourcePhoto> lignes(Object? brut) {
    if (brut is! List) return const <String, SourcePhoto>{};
    return <String, SourcePhoto>{
      for (final Object? l in brut)
        if (l is Map && l['profile_id'] is String && l['seau'] is String)
          l['profile_id'] as String: SourcePhoto(
            seau: l['seau'] as String,
            cle: l['cle'] as String?,
          ),
    };
  }

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async {
    if (profileIds.isEmpty) return const <String, SourcePhoto>{};
    return lignes(
      await _client.rpc<Object?>(
        'photos_personnes',
        params: <String, dynamic>{'p_ids': profileIds},
      ),
    );
  }

  @override
  Future<String> urlSignee(String seau, String cle) =>
      _client.storage.from(seau).createSignedUrl(cle, dureeUrlPhotoSecondes);

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) async {
    final String cle =
        '$profileId/${DateTime.now().toUtc().millisecondsSinceEpoch}'
        '.${photo.extension}';
    await _client.storage
        .from(seau)
        .uploadBinary(
          cle,
          photo.octets,
          fileOptions: FileOptions(contentType: photo.typeMime),
        );
    return cle;
  }

  @override
  Future<SourcePhoto?> poserMaPhoto(String? cle) async => lignes(
    await _client.rpc<Object?>(
      'poser_ma_photo',
      params: <String, dynamic>{'p_cle': cle},
    ),
  ).values.firstOrNull;

  @override
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle) async =>
      lignes(
        await _client.rpc<Object?>(
          'poser_photo_eleve',
          params: <String, dynamic>{'p_eleve': eleveId, 'p_cle': cle},
        ),
      ).values.firstOrNull;

  /// CAND-PHOTO : `poser_photo_candidat` (20261110330000).
  @override
  Future<SourcePhoto?> poserPhotoCandidat(String? cle) async => lignes(
    await _client.rpc<Object?>(
      'poser_photo_candidat',
      params: <String, dynamic>{'p_cle': cle},
    ),
  ).values.firstOrNull;

  /// PHOTO-CAPACITE : `photo_adulte_moi()` (PHOTOS-1), la regle de
  /// `poser_ma_photo` et de l'ecriture dans le seau. Seul un `true` explicite
  /// vaut oui.
  @override
  Future<bool> peutPoserMaPhoto() async =>
      await _client.rpc<Object?>('photo_adulte_moi') == true;
}
