import 'dart:typed_data';
import 'dart:ui' as ui;

import 'compression_image.dart';

/// Hors navigateur : PNG par `dart:ui`, la qualite ne se regle pas.
bool get qualiteReglable => false;

/// Decode [source], la ramene a [coteMax] (plus grand cote), la reencode en
/// PNG : le moteur ne recopie aucune metadonnee. `null` : illisible.
Future<ReductionImage?> reduire(
  Uint8List source, {
  required int coteMax,
  required double qualite,
  required bool couleur,
}) async {
  try {
    ui.Codec codec = await ui.instantiateImageCodec(source);
    ui.Image image = (await codec.getNextFrame()).image;
    final int plus = image.width > image.height ? image.width : image.height;
    if (plus > coteMax) {
      final bool large = image.width >= image.height;
      image.dispose();
      codec.dispose();
      codec = await ui.instantiateImageCodec(
        source,
        targetWidth: large ? coteMax : null,
        targetHeight: large ? null : coteMax,
      );
      image = (await codec.getNextFrame()).image;
    }
    final ByteData? png = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    String? moyenne;
    if (couleur) {
      final ByteData? brut = await image.toByteData();
      if (brut != null) moyenne = _moyenne(brut);
    }
    final int l = image.width;
    final int h = image.height;
    image.dispose();
    codec.dispose();
    if (png == null) return null;
    return ReductionImage(
      octets: png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
      mime: 'image/png',
      largeur: l,
      hauteur: h,
      couleurMoyenne: moyenne,
    );
  } on Object {
    return null;
  }
}

String? _moyenne(ByteData rgba) {
  final int n = rgba.lengthInBytes ~/ 4;
  if (n == 0) return null;
  int r = 0, g = 0, b = 0;
  for (int i = 0; i < n; i++) {
    r += rgba.getUint8(i * 4);
    g += rgba.getUint8(i * 4 + 1);
    b += rgba.getUint8(i * 4 + 2);
  }
  return couleurHex(r ~/ n, g ~/ n, b ~/ n);
}
