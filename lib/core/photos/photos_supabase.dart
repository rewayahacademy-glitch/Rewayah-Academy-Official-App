// L'adaptateur Supabase de la photo des personnes (PHOTOS-2a), sur les
// fonctions de la migration 20261107300000 : `photos_personnes`,
// `poser_ma_photo`, `poser_photo_eleve`. L'envoi du fichier passe par le seau
// que le serveur rend pour la personne ; la politique du seau n'autorise que
// son propre dossier (`avatar_ecriture_soi`, `photos_enseignants_ecriture`)
// ou celui d'un enfant de son foyer.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../appairage/service_avatar.dart';
import '../dossier/depot_resilient.dart';
import 'photo_personne.dart';

/// Duree de validite demandee pour une URL signee, en secondes (borne du
/// serveur : 600).
const int dureeUrlPhotoSecondes = 600;

/// La photo des personnes, lue et posee au serveur.
class PhotosSupabase implements PortPhotos {
  /// Cree l'adaptateur.
  const PhotosSupabase(this._client, {this.attendre = attenteReelle});

  final SupabaseClient _client;

  /// L'attente avant un nouvel essai (remplacee dans les tests).
  final Attente attendre;

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
    // PE-B10 : nouveaux essais sur une panne passagere, cle stable (un
    // nouvel essai qui trouve le fichier deja la le tient pour envoye).
    await envoyerAuSeau(
      _client,
      seau: seau,
      cle: cle,
      octets: photo.octets,
      typeMime: photo.typeMime,
      attendre: attendre,
    );
    return cle;
  }

  @override
  ///
  /// PE-B10 (relecture du 20/11, S2) : la pose remplace la cle de la photo
  /// (idempotente) ; elle se reessaie seule sur une panne passagere, comme
  /// celle du candidat.
  Future<SourcePhoto?> poserMaPhoto(String? cle) async => lignes(
    await avecNouveauxEssais<Object?>(
      () => _client.rpc<Object?>(
        'poser_ma_photo',
        params: <String, dynamic>{'p_cle': cle},
      ),
      attendre: attendre,
      delai: delaiEtapeCourte,
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
  ///
  /// PE-B10 : la pose est idempotente (elle remplace la cle de la photo du
  /// candidat) ; elle est reessayee seule sur une panne passagere.
  @override
  Future<SourcePhoto?> poserPhotoCandidat(String? cle) async => lignes(
    await avecNouveauxEssais<Object?>(
      () => _client.rpc<Object?>(
        'poser_photo_candidat',
        params: <String, dynamic>{'p_cle': cle},
      ),
      attendre: attendre,
      delai: delaiEtapeCourte,
    ),
  ).values.firstOrNull;

  /// PHOTO-CAPACITE : `photo_adulte_moi()` (PHOTOS-1), la regle de
  /// `poser_ma_photo` et de l'ecriture dans le seau. Seul un `true` explicite
  /// vaut oui.
  @override
  Future<bool> peutPoserMaPhoto() async =>
      await _client.rpc<Object?>('photo_adulte_moi') == true;
}
