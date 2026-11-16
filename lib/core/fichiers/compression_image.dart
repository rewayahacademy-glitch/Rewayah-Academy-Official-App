// IMAGES-MESSAGERIE (plan du directeur du 16/11/2026) : la photo choisie est
// reduite SUR L'APPAREIL avant tout envoi, jamais sur le serveur.
//
// - le plus grand cote tient en 1600 points ; JPEG qualite 0,8 (puis 0,6 une
//   seule fois si l'image depasse 2 Mo). Navigateur : le canevas ne recopie
//   ni l'EXIF ni le GPS. Ailleurs : `flutter_image_compress`, `keepExif: false` ;
// - une miniature de 320 de cote, et la couleur moyenne lue sur elle ;
// - limites du serveur : image 2 Mo, miniature 100 Ko, source 15 Mo.
//
// Un seul point d'entree, [preparerImage] ; le travail natif change selon la
// plateforme (`compression_image_web.dart`, `compression_image_autre.dart`),
// comme `conversion_heic.dart`. Le travail du navigateur est asynchrone (il ne
// bloque pas l'ecran) ; celui de `dart:ui` se fait dans le moteur d'images.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import '../communications/image_message.dart';
import 'compression_image_autre.dart'
    if (dart.library.js_interop) 'compression_image_web.dart'
    as natif;

/// Une source plus lourde est refusee tout de suite.
const int sourceImageMaxOctets = 15 * 1024 * 1024;

/// La limite du serveur pour l'image.
const int imageMaxOctets = 2097152;

/// La limite du serveur pour la miniature.
const int miniatureMaxOctets = 102400;

/// Le plus grand cote de l'image envoyee.
const int coteImage = 1600;

/// Le plus grand cote de la miniature.
const int coteMiniature = 320;

/// Le resultat d'une reduction native.
class ReductionImage {
  /// Cree la reduction.
  const ReductionImage({
    required this.octets,
    required this.mime,
    required this.largeur,
    required this.hauteur,
    this.couleurMoyenne,
  });

  /// L'image reduite et reencodee, sans metadonnees.
  final Uint8List octets;

  /// `image/jpeg` ou `image/png`.
  final String mime;

  /// Sa largeur.
  final int largeur;

  /// Sa hauteur.
  final int hauteur;

  /// `#rrggbb` si demande.
  final String? couleurMoyenne;
}

/// Reduit [source] a [coteMax] et la reencode. `null` : illisible.
typedef Reducteur = Future<ReductionImage?> Function(
  Uint8List source, {
  required int coteMax,
  required double qualite,
  required bool couleur,
});

/// Prepare [source] : image, miniature, dimensions, couleur moyenne.
///
/// Leve [EchecImage] : [RefusImage.imageTropGrosse] (source de plus de 15 Mo,
/// ou impossible a ramener sous les limites), [RefusImage.imageIllisible].
/// [reducteur] se remplace dans les tests.
Future<ImagePrete> preparerImage(
  Uint8List source, {
  Reducteur reducteur = natif.reduire,
}) async {
  if (source.length > sourceImageMaxOctets) {
    throw const EchecImage(RefusImage.imageTropGrosse);
  }
  if (source.isEmpty) throw const EchecImage(RefusImage.imageIllisible);
  final Stopwatch chrono = Stopwatch()..start();
  // Qualite 0,8, puis 0,6 une seule fois, puis refus.
  const List<(int, double)> essais = <(int, double)>[
    (coteImage, 0.8),
    (coteImage, 0.6),
  ];
  ReductionImage? image;
  for (final (int cote, double q) in essais) {
    final ReductionImage? r = await reducteur(
      source,
      coteMax: cote,
      qualite: q,
      couleur: false,
    );
    if (r == null) throw const EchecImage(RefusImage.imageIllisible);
    if (r.octets.length <= imageMaxOctets) {
      image = r;
      break;
    }
  }
  if (image == null) throw const EchecImage(RefusImage.imageTropGrosse);
  // La miniature se tire de l'image deja reduite (moins de pixels a lire).
  ReductionImage? mini;
  for (final (int cote, double q) in const <(int, double)>[
    (coteMiniature, 0.8),
    (coteMiniature, 0.6),
    (240, 0.6),
  ]) {
    final ReductionImage? r = await reducteur(
      image.octets,
      coteMax: cote,
      qualite: q,
      couleur: true,
    );
    if (r == null) throw const EchecImage(RefusImage.imageIllisible);
    if (r.octets.length <= miniatureMaxOctets) {
      mini = r;
      break;
    }
  }
  if (mini == null) throw const EchecImage(RefusImage.imageTropGrosse);
  // Mesure du temps de preparation sur l'appareil (IMAGES-CORRECTIF, B).
  debugPrint(
    '[images-temps] preparation sur l\'appareil : ${chrono.elapsedMilliseconds} ms '
    '(source ${source.length} o, image ${image.octets.length} o, '
    'miniature ${mini.octets.length} o)',
  );
  return ImagePrete(
    octets: image.octets,
    mime: image.mime,
    largeur: image.largeur,
    hauteur: image.hauteur,
    miniature: mini.octets,
    mimeMiniature: mini.mime,
    couleurMoyenne: mini.couleurMoyenne,
  );
}

/// `#rrggbb` depuis trois canaux de 0 a 255.
String couleurHex(int r, int g, int b) {
  String c(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${c(r)}${c(g)}${c(b)}';
}
