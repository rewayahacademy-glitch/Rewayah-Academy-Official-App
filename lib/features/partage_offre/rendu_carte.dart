// Le rendu de la carte en image : la carte est peinte par Flutter, puis lue en
// PNG a 1080 x 1920 (`CartePartage.echelleExport`). Aucun serveur n'intervient.
//
// Le rendu est une dependance injectable : sous `flutter test`, `toImage` ne
// rend la main que dans `tester.runAsync`, et les tests de la page n'ont besoin
// que d'octets. Un test dedie rend la vraie carte (`rendu_carte_test.dart`).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'carte_partage.dart';

/// Lit en PNG la carte que porte la `RepaintBoundary` de [cle].
typedef RenduCarte = Future<Uint8List> Function(GlobalKey cle);

/// Le nom du fichier que la personne enregistre ou partage.
const String nomFichierCarte = 'rewayah-carte.png';

/// Le rendu reel : la bordure de repeinture est lue a sa taille propre (360 x
/// 640), quelle que soit l'echelle a laquelle l'ecran l'affiche en apercu.
Future<Uint8List> rendreCarteEnPng(GlobalKey cle) async {
  final RenderObject? objet = cle.currentContext?.findRenderObject();
  if (objet is! RenderRepaintBoundary) {
    throw StateError('La carte n\'est pas encore peinte.');
  }
  final ui.Image image = await objet.toImage(
    pixelRatio: CartePartage.echelleExport,
  );
  try {
    final ByteData? donnees = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (donnees == null) {
      throw StateError('La carte n\'a pas pu etre encodee.');
    }
    return donnees.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Le rendu de la carte employe par la page.
final Provider<RenduCarte> renduCarteProvider = Provider<RenduCarte>(
  (Ref _) => rendreCarteEnPng,
);
