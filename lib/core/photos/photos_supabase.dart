// PHOTOS-2 : l'adaptateur Supabase des photos (fonctions de PHOTOS-1,
// migration 20261107300000 ; seaux `avatars` et `photos_enseignants`).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../appairage/service_avatar.dart';
import '../capacites/capacite_indisponible.dart';
import 'photos_personnes.dart';

/// Les photos servies par Supabase.
class PhotosSupabase implements PortPhotos {
  /// Cree l'adaptateur.
  const PhotosSupabase(this._client);

  final SupabaseClient _client;

  /// Duree de vie d'une URL de photo, en secondes (celle de
  /// `ServiceAvatarSupabase`).
  static const int dureeUrlSecondes = ServiceAvatarSupabase.dureeUrlSecondes;

  Future<Object?> _rpc(String fonction, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      // Fonction absente (serveur d'avant PHOTOS-1) ou refus de droit.
      if (e.code == 'PGRST202' || e.code == '42883' || e.code == '42501') {
        throw PhotosIndisponibles.manque;
      }
      rethrow;
    }
  }

  static SourcePhoto _source(Map<String, dynamic> m) => SourcePhoto(
    seau: m['seau'] as String? ?? ServiceAvatarSupabase.seauAvatars,
    cle: m['cle'] as String?,
  );

  @override
  Future<Map<String, SourcePhoto>> lire(List<String> ids) async {
    if (ids.isEmpty) return const <String, SourcePhoto>{};
    final Object? brut = await _rpc('photos_personnes', <String, dynamic>{
      'p_ids': ids,
    });
    final Map<String, SourcePhoto> sources = <String, SourcePhoto>{};
    if (brut is List) {
      for (final Object? ligne in brut) {
        if (ligne is Map<String, dynamic>) {
          final String? id = ligne['profile_id'] as String?;
          if (id != null) sources[id] = _source(ligne);
        }
      }
    }
    return sources;
  }

  @override
  Future<String> urlSignee(SourcePhoto source) {
    final String? cle = source.cle;
    if (cle == null) {
      return Future<String>.error(const CapaciteIndisponible('photo'));
    }
    return _client.storage
        .from(source.seau)
        .createSignedUrl(cle, dureeUrlSecondes);
  }

  @override
  Future<String> televerser({
    required String personneId,
    required String seau,
    required PhotoEnfant photo,
  }) async {
    // Le premier segment est l'identifiant de la personne : c'est lui que les
    // politiques du seau comparent.
    final String cle =
        '$personneId/${DateTime.now().toUtc().millisecondsSinceEpoch}'
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

  SourcePhoto _premiere(Object? brut) {
    if (brut is List && brut.isNotEmpty && brut.first is Map<String, dynamic>) {
      return _source(brut.first as Map<String, dynamic>);
    }
    throw StateError('reponse de photo vide');
  }

  @override
  Future<SourcePhoto> poserMaPhoto(String? cle) async =>
      _premiere(await _rpc('poser_ma_photo', <String, dynamic>{'p_cle': cle}));

  @override
  Future<bool> puisPoserMaPhoto() async =>
      await _rpc('photo_adulte_moi', <String, dynamic>{}) == true;

  @override
  Future<SourcePhoto> poserPhotoEleve(String eleveId, String? cle) async =>
      _premiere(
        await _rpc('poser_photo_eleve', <String, dynamic>{
          'p_eleve': eleveId,
          'p_cle': cle,
        }),
      );
}
