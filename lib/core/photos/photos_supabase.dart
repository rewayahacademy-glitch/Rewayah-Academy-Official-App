// L'adaptateur Supabase de la photo des personnes (PHOTOS-2a), sur les
// fonctions de la migration 20261107300000 : `photos_personnes`,
// `poser_ma_photo`, `poser_photo_eleve`. L'envoi du fichier passe par le seau
// que le serveur rend pour la personne ; la politique du seau n'autorise que
// son propre dossier (`avatar_ecriture_soi`, `photos_enseignants_ecriture`)
// ou celui d'un enfant de son foyer.
//
// PERSONNES-PERF (20/11/2026) : une liste de 50 personnes posait 50 appels
// `photos_personnes` (un par avatar ; 7 555 appels en 24 h en production). Les
// demandes faites dans la meme tache (la construction d'une image de l'ecran)
// sont regroupees en UN appel, et une demande deja partie pour une personne
// est rejointe au lieu d'etre refaite. Ce que rend [PhotosSupabase.sources]
// ne change pas : le serveur filtre toujours chaque personne (droit de voir sa
// photo), une personne sans photo visible reste absente de la reponse.

import 'dart:async';

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

  /// Le regroupement des demandes, un par client (l'adaptateur reste `const`).
  static final Expando<RegroupementPhotos> _regroupements =
      Expando<RegroupementPhotos>('photos_personnes');

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) {
    if (profileIds.isEmpty) {
      return Future<Map<String, SourcePhoto>>.value(
        const <String, SourcePhoto>{},
      );
    }
    final RegroupementPhotos regroupement = _regroupements[_client] ??=
        RegroupementPhotos(
          (List<String> ids) async => lignes(
            await _client.rpc<Object?>(
              'photos_personnes',
              params: <String, dynamic>{'p_ids': ids},
            ),
          ),
        );
    return regroupement.demander(profileIds);
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

/// Regroupe les demandes de photos faites dans la meme tache en un seul appel
/// au serveur, et rejoint une demande deja en vol pour la meme personne.
///
/// Public pour les tests. [lire] recoit des identifiants distincts et rend les
/// sources trouvees (une personne sans photo visible n'y est pas).
class RegroupementPhotos {
  /// Cree le regroupement sur la lecture [lire].
  RegroupementPhotos(this.lire);

  /// La lecture d'un lot d'identifiants.
  final Future<Map<String, SourcePhoto>> Function(List<String> ids) lire;

  /// Les personnes demandees, pas encore parties au serveur.
  final Map<String, Completer<SourcePhoto?>> _enAttente =
      <String, Completer<SourcePhoto?>>{};

  /// Les personnes parties au serveur, reponse pas encore arrivee.
  final Map<String, Future<SourcePhoto?>> _enVol =
      <String, Future<SourcePhoto?>>{};

  bool _planifie = false;

  /// Les sources de [ids] : rendues par un appel commun aux demandes de la
  /// meme tache.
  Future<Map<String, SourcePhoto>> demander(List<String> ids) async {
    final List<String> distincts = ids.toSet().toList();
    final List<Future<SourcePhoto?>> attentes = <Future<SourcePhoto?>>[
      for (final String id in distincts) _une(id),
    ];
    final List<SourcePhoto?> trouvees = await Future.wait(attentes);
    return <String, SourcePhoto>{
      for (int i = 0; i < distincts.length; i++)
        if (trouvees[i] case final SourcePhoto s) distincts[i]: s,
    };
  }

  Future<SourcePhoto?> _une(String id) {
    final Future<SourcePhoto?>? deja = _enVol[id] ?? _enAttente[id]?.future;
    if (deja != null) return deja;
    final Completer<SourcePhoto?> attente = Completer<SourcePhoto?>();
    _enAttente[id] = attente;
    if (!_planifie) {
      _planifie = true;
      scheduleMicrotask(() => unawaited(_partir()));
    }
    return attente.future;
  }

  Future<void> _partir() async {
    _planifie = false;
    final Map<String, Completer<SourcePhoto?>> lot =
        Map<String, Completer<SourcePhoto?>>.of(_enAttente);
    _enAttente.clear();
    for (final MapEntry<String, Completer<SourcePhoto?>> e in lot.entries) {
      _enVol[e.key] = e.value.future;
    }
    try {
      final Map<String, SourcePhoto> lues = await lire(lot.keys.toList());
      for (final MapEntry<String, Completer<SourcePhoto?>> e in lot.entries) {
        e.value.complete(lues[e.key]);
      }
    } on Object catch (erreur, pile) {
      for (final Completer<SourcePhoto?> c in lot.values) {
        c.completeError(erreur, pile);
      }
    } finally {
      _enVol.removeWhere(
        (String id, Future<SourcePhoto?> _) => lot.containsKey(id),
      );
    }
  }
}
