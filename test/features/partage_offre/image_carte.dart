// Lire les pixels de la carte (CAND-06) : le vrai `toImage` de Flutter, decode,
// pour que les tests mesurent ce qu'une personne voit sur l'image exportee et
// non ce que l'arbre de widgets declare. Importe par les tests seulement.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/decor_carte.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';

import 'hote_partage.dart';

/// Une image decodee : ses pixels RGBA.
class ImageCarte {
  /// Cree l'image.
  ImageCarte(this.largeur, this.hauteur, this._octets);

  /// La largeur en pixels.
  final int largeur;

  /// La hauteur en pixels.
  final int hauteur;
  final ByteData _octets;

  /// Le pixel en ([x], [y]).
  Color pixel(int x, int y) {
    final int i = (y * largeur + x) * 4;
    return Color.fromARGB(
      _octets.getUint8(i + 3),
      _octets.getUint8(i),
      _octets.getUint8(i + 1),
      _octets.getUint8(i + 2),
    );
  }

  /// Le pixel du point [p] de la carte (en points logiques, 360 x 640), a
  /// l'echelle de l'export.
  Color enPoints(Offset p) => pixel(
    (p.dx * CartePartage.echelleExport).round(),
    (p.dy * CartePartage.echelleExport).round(),
  );
}

/// Decode un PNG, dans `runAsync` (decodage reel).
Future<ImageCarte> decoderCarte(Uint8List png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData octets = (await image.toByteData())!;
  final ImageCarte rendu = ImageCarte(image.width, image.height, octets);
  image.dispose();
  return rendu;
}

/// Monte la carte dans sa `RepaintBoundary`, comme la page, et la rend en PNG.
Future<Uint8List> rendreCarte(
  WidgetTester tester, {
  LangueCarte langue = LangueCarte.francais,
  VarianteCarte variante = VarianteCarte.hommes,
  Brightness luminosite = Brightness.light,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  Uri? lien,
  Size? vue,
}) async {
  tester.view.physicalSize = vue ?? const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GlobalKey cle = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(mode, luminosite),
      builder: (BuildContext contexte, Widget? app) => MediaQuery(
        data: MediaQuery.of(contexte)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: app!,
      ),
      home: Center(
        child: RepaintBoundary(
          key: cle,
          child: CartePartage(
            lien: lien ?? lienDeTest,
            langue: langue,
            variante: variante,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (await tester.runAsync(() => rendreCarteEnPng(cle)))!;
}

/// La carte rendue puis decodee : ses pixels, tels que l'export les porte.
Future<ImageCarte> imageCarte(
  WidgetTester tester, {
  LangueCarte langue = LangueCarte.francais,
  VarianteCarte variante = VarianteCarte.hommes,
  Uri? lien,
}) async {
  final Uint8List png = await rendreCarte(
    tester,
    langue: langue,
    variante: variante,
    lien: lien,
  );
  return (await tester.runAsync(() => decoderCarte(png)))!;
}

/// Le filigrane seul, sur le fond uni de la variante des hommes, a l'echelle de
/// l'export, dans le sens de lecture [sens] : ses pixels. Sans texte, sans
/// scene, sans logo : seul le symbole contour passe.
Future<ImageCarte> imageFiligrane(
  WidgetTester tester, {
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GlobalKey cle = GlobalKey();
  const AppPaletteCarte c = AppPaletteCarte.hommes;
  await tester.pumpWidget(
    Directionality(
      textDirection: sens,
      child: Center(
        child: RepaintBoundary(
          key: cle,
          child: SizedBox(
            width: CartePartage.largeur,
            height: CartePartage.hauteur,
            child: ColoredBox(
              color: c.fond.background,
              child: const FiligraneCarte(couleurs: c),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final Uint8List png = (await tester.runAsync(() => rendreCarteEnPng(cle)))!;
  return (await tester.runAsync(() => decoderCarte(png)))!;
}

/// La scene seule, a l'echelle de l'export, dans le sens de lecture [sens] : les
/// tenebres, la porte, son halo et son faisceau, plus la branche fleurie si
/// [variante] est celle des femmes, sur le fond uni de [couleurs]. Sans texte, sans
/// logo ni QR ; le filigrane n'y est que si [avecFiligrane]. Les couleurs et la
/// variante sont independantes, pour mesurer ce que la branche ajoute.
Future<ImageCarte> imageScene(
  WidgetTester tester, {
  AppPaletteCarte couleurs = AppPaletteCarte.hommes,
  VarianteCarte variante = VarianteCarte.hommes,
  TextDirection sens = TextDirection.ltr,
  bool avecFiligrane = false,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GlobalKey cle = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: sens,
      child: Center(
        child: RepaintBoundary(
          key: cle,
          child: SizedBox(
            width: CartePartage.largeur,
            height: CartePartage.hauteur,
            child: ColoredBox(
              color: couleurs.fond.background,
              child: Stack(
                children: <Widget>[
                  if (avecFiligrane)
                    Positioned.fill(child: FiligraneCarte(couleurs: couleurs)),
                  Positioned.fill(
                    child: ScenePortail(couleurs: couleurs, variante: variante),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final Uint8List png = (await tester.runAsync(() => rendreCarteEnPng(cle)))!;
  return (await tester.runAsync(() => decoderCarte(png)))!;
}

/// Vrai quand [a] et [b] portent les memes octets.
bool memesOctets(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Vrai quand [a] et [b] different d'au plus [ecart] sur chaque canal.
bool proches(Color a, Color b, [int ecart = 2]) =>
    ((a.r - b.r).abs() * 255).round() <= ecart &&
    ((a.g - b.g).abs() * 255).round() <= ecart &&
    ((a.b - b.b).abs() * 255).round() <= ecart;
