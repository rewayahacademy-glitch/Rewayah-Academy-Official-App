// PHOTOS-2 (03/11/2026, PLAN-LOTS §11) : une seule photo par personne, la
// meme partout, lue par un seul fournisseur.
//
// * La source est le serveur : `photos_personnes(ids)` (PHOTOS-1, migration
//   20261107300000) rend, pour chaque personne que l'appelant a le droit de
//   voir, son seau et sa cle ; rien pour les autres. L'ecran ne decide jamais
//   qui voit quoi : sans ligne, il montre les initiales.
// * Une lecture groupee : les personnes demandees pendant une meme image
//   partent en un seul appel.
// * L'URL signee vit 600 s cote serveur. Le fournisseur se libere quand plus
//   personne ne l'ecoute, et se relit avant l'expiration : jamais une URL
//   gardee au-dela de sa vie.
// * Apres un envoi, `relirePhoto` relit toutes les vues de cette personne.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/service_avatar.dart';
import '../capacites/capacite_indisponible.dart';

/// Ou est la photo d'une personne : son seau et sa cle (nulle sans photo).
@immutable
class SourcePhoto {
  /// Cree la source.
  const SourcePhoto({required this.seau, required this.cle});

  /// Le seau de stockage (`avatars` ou `photos_enseignants`).
  final String seau;

  /// La cle dans le seau, `null` quand la personne n'a pas de photo.
  final String? cle;
}

/// Les photos des personnes, cote serveur.
abstract interface class PortPhotos {
  /// La source de chaque personne visible parmi [ids] ; les autres sont
  /// absentes de la reponse.
  Future<Map<String, SourcePhoto>> lire(List<String> ids);

  /// Une URL signee de courte duree pour [source].
  Future<String> urlSignee(SourcePhoto source);

  /// Depose [photo] dans le dossier de [personneId], dans [seau], et rend la
  /// cle. Le nom est horodate : une photo remplacee n'est jamais servie par
  /// un cache qui ne l'a pas vue changer.
  Future<String> televerser({
    required String personneId,
    required String seau,
    required PhotoEnfant photo,
  });

  /// Pose (ou retire, avec `null`) la photo de l'appelant ; rend sa source.
  Future<SourcePhoto> poserMaPhoto(String? cle);

  /// Pose (ou retire) la photo d'un enfant mineur du foyer de l'appelant.
  Future<SourcePhoto> poserPhotoEleve(String eleveId, String? cle);

  /// Vrai si l'appelant peut poser sa propre photo (un adulte au compte
  /// valide, `photo_adulte_moi`) : une capacite lue au serveur, jamais un role.
  Future<bool> puisPoserMaPhoto();
}

/// La source tant qu'aucune n'est branchee : chaque appel le dit.
class PhotosIndisponibles implements PortPhotos {
  /// Cree l'implementation.
  const PhotosIndisponibles();

  /// Ce qui manque.
  static const CapaciteIndisponible manque = CapaciteIndisponible('PHOTOS-1');

  @override
  Future<Map<String, SourcePhoto>> lire(List<String> ids) =>
      Future<Map<String, SourcePhoto>>.error(manque);

  @override
  Future<String> urlSignee(SourcePhoto source) => Future<String>.error(manque);

  @override
  Future<String> televerser({
    required String personneId,
    required String seau,
    required PhotoEnfant photo,
  }) => Future<String>.error(manque);

  @override
  Future<SourcePhoto> poserMaPhoto(String? cle) =>
      Future<SourcePhoto>.error(manque);

  @override
  Future<SourcePhoto> poserPhotoEleve(String eleveId, String? cle) =>
      Future<SourcePhoto>.error(manque);

  @override
  Future<bool> puisPoserMaPhoto() => Future<bool>.error(manque);
}

/// Le port employe par l'application ; `PhotosSupabase` en production
/// (`main.dart`).
final Provider<PortPhotos> portPhotosProvider = Provider<PortPhotos>(
  (Ref ref) => const PhotosIndisponibles(),
);

/// Regroupe les demandes d'une meme image en un seul appel au serveur.
class LotPhotos {
  /// Cree le lot sur [port].
  LotPhotos(this._port);

  final PortPhotos _port;
  final Map<String, Completer<SourcePhoto?>> _attente =
      <String, Completer<SourcePhoto?>>{};
  bool _planifie = false;

  /// La source de [id], ou `null` si l'appelant ne la voit pas (ou si la
  /// lecture echoue : l'ecran montre alors les initiales, jamais une erreur).
  Future<SourcePhoto?> source(String id) {
    final Completer<SourcePhoto?> c = _attente.putIfAbsent(
      id,
      Completer<SourcePhoto?>.new,
    );
    if (!_planifie) {
      _planifie = true;
      scheduleMicrotask(_envoyer);
    }
    return c.future;
  }

  Future<void> _envoyer() async {
    final Map<String, Completer<SourcePhoto?>> lot =
        Map<String, Completer<SourcePhoto?>>.of(_attente);
    _attente.clear();
    _planifie = false;
    try {
      final Map<String, SourcePhoto> lues = await _port.lire(lot.keys.toList());
      for (final MapEntry<String, Completer<SourcePhoto?>> e in lot.entries) {
        e.value.complete(lues[e.key]);
      }
    } on Object {
      for (final Completer<SourcePhoto?> c in lot.values) {
        c.complete(null);
      }
    }
  }
}

/// Le lot de lecture de l'application.
final Provider<LotPhotos> lotPhotosProvider = Provider<LotPhotos>(
  (Ref ref) => LotPhotos(ref.watch(portPhotosProvider)),
);

/// Avant les 600 s de l'URL signee, le fournisseur se relit.
const Duration delaiRelecturePhoto = Duration(minutes: 8);

/// L'URL signee de la photo d'une personne, par son identifiant de profil ;
/// `null` sans photo, sans droit, ou si la lecture echoue (l'ecran montre les
/// initiales).
// Le type d'une famille autoDispose n'est pas exporte par Riverpod 3 : il
// se deduit de l'appel.
// ignore: specify_nonobvious_property_types
final photoPersonneProvider = FutureProvider.autoDispose
    .family<String?, String>((Ref ref, String personneId) async {
      // Relu avant l'expiration de l'URL, tant qu'un ecran l'ecoute.
      final Timer relecture = Timer(delaiRelecturePhoto, ref.invalidateSelf);
      ref.onDispose(relecture.cancel);
      final SourcePhoto? source = await ref
          .watch(lotPhotosProvider)
          .source(personneId);
      final String? cle = source?.cle;
      if (source == null || cle == null || cle.isEmpty) return null;
      try {
        return await ref.watch(portPhotosProvider).urlSignee(source);
      } on Object {
        return null;
      }
    });

/// Vrai si la personne connectee peut poser sa propre photo ; faux si le
/// serveur ne le dit pas (l'entree « Changer ma photo » n'est pas rendue).
// ignore: specify_nonobvious_property_types
final peutPoserMaPhotoProvider = FutureProvider.autoDispose<bool>((
  Ref ref,
) async {
  try {
    return await ref.watch(portPhotosProvider).puisPoserMaPhoto();
  } on Object {
    return false;
  }
});

/// Apres un envoi : toutes les vues de [personneId] relisent sa photo.
void relirePhoto(WidgetRef ref, String personneId) {
  ref
    ..invalidate(photoPersonneProvider(personneId))
    // Les ecrans qui lisent encore une cle de stockage (PHOTOS-2b).
    ..invalidate(avatarUrlProvider)
    ..invalidate(photoEnseignantUrlProvider);
}
