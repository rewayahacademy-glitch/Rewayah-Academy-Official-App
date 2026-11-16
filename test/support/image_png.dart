import 'dart:typed_data';
import 'dart:ui' as ui;

/// Un PNG [largeur] x [hauteur], uni, rouge a peu pres ([r], [g], [b]) : pour
/// les tests d'images (a appeler dans `tester.runAsync`).
Future<Uint8List> fabriquerPng(
  int largeur,
  int hauteur, {
  int r = 200,
  int g = 60,
  int b = 40,
}) async {
  final ui.PictureRecorder enregistreur = ui.PictureRecorder();
  final ui.Canvas toile = ui.Canvas(enregistreur);
  toile.drawRect(
    ui.Rect.fromLTWH(0, 0, largeur.toDouble(), hauteur.toDouble()),
    ui.Paint()..color = ui.Color.fromARGB(255, r, g, b),
  );
  final ui.Image image = await enregistreur.endRecording().toImage(
    largeur,
    hauteur,
  );
  final ByteData? donnees = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  return donnees!.buffer.asUint8List();
}

/// Insere dans [png] un bloc texte `tEXt` (cle `GPS`), comme le ferait un
/// appareil photo avec ses metadonnees : il doit disparaitre a la compression.
Uint8List avecMetadonnees(Uint8List png) {
  final List<int> corps = <int>[
    ...'tEXt'.codeUnits,
    ...'GPS'.codeUnits,
    0,
    ...'48.8566,2.3522'.codeUnits,
  ];
  final int longueur = corps.length - 4;
  final ByteData bloc = ByteData(4 + corps.length + 4)..setUint32(0, longueur);
  for (int i = 0; i < corps.length; i++) {
    bloc.setUint8(4 + i, corps[i]);
  }
  bloc.setUint32(4 + corps.length, _crc32(corps));
  // Apres la signature (8 octets) et le bloc IHDR (25 octets au total).
  return Uint8List.fromList(<int>[
    ...png.sublist(0, 33),
    ...bloc.buffer.asUint8List(),
    ...png.sublist(33),
  ]);
}

int _crc32(List<int> octets) {
  int crc = 0xFFFFFFFF;
  for (final int o in octets) {
    crc ^= o;
    for (int k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

/// Vrai si [octets] contient [mot] en clair.
bool contient(Uint8List octets, String mot) {
  final List<int> cle = mot.codeUnits;
  for (int i = 0; i + cle.length <= octets.length; i++) {
    int j = 0;
    while (j < cle.length && octets[i + j] == cle[j]) {
      j++;
    }
    if (j == cle.length) return true;
  }
  return false;
}
