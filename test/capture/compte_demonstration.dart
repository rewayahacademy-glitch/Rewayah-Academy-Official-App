// Le compte de demonstration des captures (pilote, 11/11/2026) : une photo
// synthetique dessinee ici, jamais l'image d'une personne reelle. Partage par
// les captures du panneau des roles et de la direction.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Le prenom fictif du compte de demonstration.
const String prenomDeDemonstration = 'Yasmine';

/// Une photo synthetique (degrade et silhouette), dessinee ici : aucune image
/// d'une personne reelle.
Future<Uint8List> photoDeDemonstration() async {
  const double t = 256;
  final ui.PictureRecorder enregistreur = ui.PictureRecorder();
  final Canvas toile = Canvas(enregistreur);
  toile.drawRect(
    const Rect.fromLTWH(0, 0, t, t),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(t, t),
        const <Color>[Color(0xFFB9A4F2), Color(0xFF6538E4)],
      ),
  );
  final Paint silhouette = Paint()..color = const Color(0xFFF3EEFF);
  toile.drawCircle(const Offset(t / 2, t * 0.4), t * 0.18, silhouette);
  toile.drawOval(
    const Rect.fromLTWH(t * 0.18, t * 0.64, t * 0.64, t * 0.6),
    silhouette,
  );
  final ui.Image image = await enregistreur.endRecording().toImage(
    t.toInt(),
    t.toInt(),
  );
  final ByteData? octets = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  return octets!.buffer.asUint8List();
}
