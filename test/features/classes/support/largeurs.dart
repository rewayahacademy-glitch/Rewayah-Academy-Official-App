import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les cinq largeurs que le sprint impose pour les ecrans P0.
///
/// **Aucun test ne compare une largeur a un nombre lui-meme** : ces valeurs
/// encadrent les seuils d'`AppGabarit`, seul fichier du produit autorise a
/// les connaitre. 360 et 390 sont sous le seuil tablette, 768 et 1024 entre
/// tablette et bureau, 1440 au dela.
const List<double> largeursP0 = <double>[360, 390, 768, 1024, 1440];

/// Largeur de telephone etroit.
const double largeurEtroite = 360;

/// Largeur de telephone de reference.
const double largeurMobile = 390;

/// Largeur de tablette en portrait.
const double largeurTablette = 768;

/// Largeur de tablette en paysage.
const double largeurTabletteLarge = 1024;

/// Largeur de bureau.
const double largeurDesktop = 1440;

/// Pose une largeur d'ecran pour un test, et la rend a la fin.
///
/// La hauteur est haute a dessein : `PageShell` construit tout son contenu
/// d'un coup, et un widget hors du cadre ne se laisse pas taper.
Future<void> avecLargeur(
  WidgetTester tester,
  double largeur,
  Future<void> Function() corps, {
  double hauteur = 1600,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, hauteur);
  addTearDown(tester.view.reset);
  await corps();
}
