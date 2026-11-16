import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'compression_image.dart';

/// Les dimensions de [octets], sans le decoder en entier ; `null` : illisible.
Future<(int, int)?> _taille(Uint8List octets) async {
  try {
    final ui.ImmutableBuffer tampon = await ui.ImmutableBuffer.fromUint8List(
      octets,
    );
    try {
      final ui.ImageDescriptor d = await ui.ImageDescriptor.encoded(tampon);
      final (int, int) taille = (d.width, d.height);
      d.dispose();
      return taille;
    } finally {
      tampon.dispose();
    }
  } on Object {
    return null;
  }
}

/// Reduit [source] a [coteMax] (plus grand cote) et la reencode en JPEG a
/// [qualite] (0 a 1), SANS EXIF (`keepExif: false` : ni orientation, ni GPS).
/// `null` : illisible.
Future<ReductionImage?> reduire(
  Uint8List source, {
  required int coteMax,
  required double qualite,
  required bool couleur,
}) async {
  try {
    final (int, int)? origine = await _taille(source);
    if (origine == null) return null;
    final int plus = origine.$1 > origine.$2 ? origine.$1 : origine.$2;
    final double echelle = plus > coteMax ? coteMax / plus : 1;
    // Les deux bornes au meme rapport : le plus grand cote tient dans
    // [coteMax], quelle que soit la regle de mise a l'echelle du plugin.
    final int l = (origine.$1 * echelle).round().clamp(1, coteMax);
    final int h = (origine.$2 * echelle).round().clamp(1, coteMax);
    final Uint8List jpeg = await FlutterImageCompress.compressWithList(
      source,
      minWidth: l,
      minHeight: h,
      quality: (qualite * 100).round(),
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    final (int, int)? taille = await _taille(jpeg);
    if (jpeg.isEmpty || taille == null) return null;
    return ReductionImage(
      octets: jpeg,
      mime: 'image/jpeg',
      largeur: taille.$1,
      hauteur: taille.$2,
      couleurMoyenne: couleur ? await _moyenne(jpeg) : null,
    );
  } on Object {
    return null;
  }
}

/// La couleur moyenne : le moteur ramene l'image a un seul point.
Future<String?> _moyenne(Uint8List jpeg) async {
  try {
    final ui.Codec codec = await ui.instantiateImageCodec(
      jpeg,
      targetWidth: 1,
      targetHeight: 1,
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    final ByteData? px = await image.toByteData();
    image.dispose();
    codec.dispose();
    if (px == null || px.lengthInBytes < 3) return null;
    return couleurHex(px.getUint8(0), px.getUint8(1), px.getUint8(2));
  } on Object {
    return null;
  }
}
