// UX-010 (revue UX, lot 10) : sur ordinateur, a 1200 x 760 avec les deux
// panneaux, les grandes fleches de page sortaient de l'ecran : la boite
// elargie de la page (plafond 1,4) ne leur laissait pas la place. La boite
// rogne sa marge vide, jamais la page Madina.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';

void main() {
  const double hauteur = 760;
  const double naturelle = hauteur / ratioHauteurPageMadina15;

  test('la place manque aux fleches : la boite rogne sa marge vide', () {
    // Une zone centrale plus etroite que la boite elargie et ses fleches,
    // mais assez large pour la page naturelle et ses fleches (les deux
    // panneaux ouverts a 1200 de large).
    const double largeur =
        naturelle * (1 + plafondLargeurPage) / 2 + 2 * margeFlechePage;
    const Size ecran = Size(largeur, hauteur);
    final Size avant = boitePagePleinEcran(ecran, telephone: false);
    expect(avant.width + 2 * margeFlechePage, greaterThan(largeur));

    final Size boite = boitePageAvecFleches(
      ecran,
      telephone: false,
      avecFleches: true,
    );
    expect(boite.width + 2 * margeFlechePage, lessThanOrEqualTo(largeur));
    expect(boite.width, greaterThanOrEqualTo(naturelle));
    expect(boite.height, hauteur);
  });

  test('la page naturelle ne tient pas avec ses fleches : rien ne change', () {
    const Size ecran = Size(naturelle + margeFlechePage, hauteur);
    expect(
      boitePageAvecFleches(ecran, telephone: false, avecFleches: true),
      boitePagePleinEcran(ecran, telephone: false),
    );
  });

  test('assez de place, telephone, ou sans fleches : la boite elargie', () {
    const Size large = Size(1440, hauteur);
    expect(
      boitePageAvecFleches(large, telephone: false, avecFleches: true),
      boitePagePleinEcran(large, telephone: false),
    );
    const Size etroit = Size(naturelle + 2 * margeFlechePage, hauteur);
    expect(
      boitePageAvecFleches(etroit, telephone: false, avecFleches: false),
      boitePagePleinEcran(etroit, telephone: false),
    );
    expect(
      boitePageAvecFleches(etroit, telephone: true, avecFleches: true),
      etroit,
    );
  });
}
