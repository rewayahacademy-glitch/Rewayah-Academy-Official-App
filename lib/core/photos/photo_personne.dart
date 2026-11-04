// Une seule photo par personne, la meme partout (PHOTOS-2a, PLAN-LOTS §11).
//
// Demande du directeur (03/11/2026) : « pour les photos il faut penser a les
// synchroniser partout ou elles doivent etre, et c'est pour tous les roles ».
//
// La regle de qui voit quoi vit au serveur (`photos_personnes`, migration
// 20261107300000) : un ecran demande la photo d'une personne par son
// identifiant de profil, et recoit son seau et sa cle seulement s'il a le
// droit de la voir. Sinon, rien : `AvatarTile` montre les initiales.
//
// L'URL signee vit 600 s au serveur. Le fournisseur se relit seul avant
// (`dureeVieUrl`), et il est `autoDispose` : une URL n'est jamais gardee
// au-dela de sa validite. Apres un envoi, `photoPersonneProvider(id)` est
// invalide : toutes les vues de cette personne se relisent ensemble.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale
// (meme convention que `donnees_catalogue.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../appairage/service_avatar.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// Ou vit la photo d'une personne : son seau et sa cle (nulle sans photo).
@immutable
class SourcePhoto {
  /// Cree une source.
  const SourcePhoto({required this.seau, this.cle});

  /// Le seau de stockage (`avatars` ou `photos_enseignants`).
  final String seau;

  /// La cle de l'objet, ou `null` quand la personne n'a pas de photo.
  final String? cle;
}

/// La photo des personnes, lue et posee au serveur.
abstract interface class PortPhotos {
  /// La source de chaque personne visible par l'appelant. Une personne
  /// absente de la reponse n'est pas visible : on montre ses initiales.
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds);

  /// Une URL signee de courte duree pour un objet d'un seau.
  Future<String> urlSignee(String seau, String cle);

  /// Envoie le fichier de la photo dans le dossier de [profileId], dans
  /// [seau], et rend sa cle.
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  });

  /// Pose (ou retire, avec `null`) sa propre photo.
  Future<SourcePhoto?> poserMaPhoto(String? cle);

  /// Le tuteur pose (ou retire) la photo d'un enfant mineur de son foyer.
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle);

  /// PHOTO-CAPACITE (04/11/2026) : vrai si la personne connectee peut poser
  /// sa propre photo. C'est la regle du serveur (`photo_adulte_moi()` :
  /// compte valide et adulte, `private.photo_adulte`), la meme que celle de
  /// `poser_ma_photo` et de l'ecriture dans le seau.
  Future<bool> peutPoserMaPhoto();
}

/// Aucune source : les ecrans montrent les initiales. Remplace dans
/// `main.dart` par l'adaptateur Supabase.
class PhotosNeutres implements PortPhotos {
  /// Cree le port neutre.
  const PhotosNeutres();

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async =>
      const <String, SourcePhoto>{};

  @override
  Future<String> urlSignee(String seau, String cle) =>
      Future<String>.error(UnsupportedError('photos non branchees'));

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) => Future<String>.error(UnsupportedError('photos non branchees'));

  @override
  Future<SourcePhoto?> poserMaPhoto(String? cle) =>
      Future<SourcePhoto?>.error(UnsupportedError('photos non branchees'));

  @override
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle) =>
      Future<SourcePhoto?>.error(UnsupportedError('photos non branchees'));

  /// Sans serveur, aucun geste n'est propose.
  @override
  Future<bool> peutPoserMaPhoto() async => false;
}

/// Le port employe par l'application.
final Provider<PortPhotos> portPhotosProvider = Provider<PortPhotos>(
  (Ref ref) => const PhotosNeutres(),
);

/// Duree de vie d'une URL de photo cote application : sous les 600 s du
/// serveur, pour qu'une image ne parte jamais sur une URL expiree.
const Duration dureeVieUrl = Duration(minutes: 9);

/// L'URL signee de la photo d'une personne, ou `null` (pas de photo, ou pas
/// le droit de la voir). Relue seule avant expiration ; liberee quand plus
/// aucun ecran ne la lit.
final FutureProviderFamily<String?, String> photoPersonneProvider =
    FutureProvider.autoDispose.family<String?, String>((
      Ref ref,
      String profileId,
    ) async {
      final PortPhotos port = ref.watch(portPhotosProvider);
      final SourcePhoto? source = (await port.sources(<String>[
        profileId,
      ]))[profileId];
      final String? cle = source?.cle;
      if (source == null || cle == null) return null;
      final String url = await port.urlSignee(source.seau, cle);
      // PHOTOS-2b : la relecture n'est armee que pour une URL qui expire ;
      // sans photo, rien ne se perime (et aucune minuterie ne reste en
      // attente). Une photo posee ensuite invalide ce fournisseur.
      final Timer relecture = Timer(dureeVieUrl, ref.invalidateSelf);
      ref.onDispose(relecture.cancel);
      return url;
    });

/// PHOTO-CAPACITE : la personne connectee peut-elle poser sa photo ? Relue
/// quand la personne change. Une lecture refusee ou impossible n'est jamais
/// un oui : le lien « Choisir une photo » reste cache tant que la reponse
/// n'est pas lue, et en cas d'erreur (aucune nouvelle tentative
/// automatique : on ne propose pas un geste qu'on n'a pas verifie).
final FutureProvider<bool> peutPoserMaPhotoProvider =
    FutureProvider.autoDispose<bool>((Ref ref) {
      ref.watch(
        sessionProvider.select((SessionState session) => session.profileId),
      );
      return ref.watch(portPhotosProvider).peutPoserMaPhoto();
    }, retry: (int _, Object _) => null);

/// Le seau ou un adulte range sa propre photo : celui que le serveur rend pour
/// lui (`photos_enseignants` pour un enseignant, `avatars` sinon).
Future<String> seauDeMaPhoto(PortPhotos port, String moi) async =>
    (await port.sources(<String>[moi]))[moi]?.seau ?? 'avatars';

/// Envoie puis pose la photo de l'appelant, et fait relire toutes ses vues.
Future<void> envoyerMaPhoto(
  WidgetRef ref, {
  required String moi,
  required PhotoEnfant photo,
}) async {
  final PortPhotos port = ref.read(portPhotosProvider);
  final String seau = await seauDeMaPhoto(port, moi);
  final String cle = await port.televerser(
    profileId: moi,
    seau: seau,
    photo: photo,
  );
  await port.poserMaPhoto(cle);
  ref.invalidate(photoPersonneProvider(moi));
}

/// Le nom de fichier d'une photo dont on n'a que les octets, d'apres ses
/// premiers octets (JPEG, PNG, WebP, HEIC ; JPEG a defaut). Le type envoye au
/// seau en decoule (`PhotoEnfant.typeMime`).
String nomFichierDepuisOctets(Uint8List octets) {
  bool debut(List<int> attendu, [int decalage = 0]) {
    if (octets.length < decalage + attendu.length) return false;
    for (int i = 0; i < attendu.length; i++) {
      if (octets[decalage + i] != attendu[i]) return false;
    }
    return true;
  }

  if (debut(<int>[0x89, 0x50, 0x4e, 0x47])) return 'photo.png';
  if (debut(<int>[0x52, 0x49, 0x46, 0x46]) &&
      debut(<int>[0x57, 0x45, 0x42, 0x50], 8)) {
    return 'photo.webp';
  }
  if (debut(<int>[0x66, 0x74, 0x79, 0x70], 4)) return 'photo.heic';
  return 'photo.jpg';
}
