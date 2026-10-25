// K4 (directeur, 25/10/2026) : le tableau blanc de `/salle` a une forme fixe
// pour toute la classe (16:9) ; chaque appareil l'ajuste a echelle uniforme,
// centre, avec des bandes vides. Constat du directeur : sur le telephone de
// l'eleve, les traits apparaissaient tres etires verticalement (le repere
// suivait la taille de chaque ecran).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/features/salle_seance/repere_page.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

void main() {
  const TableauLibre tableau = TableauLibre.classe;

  test('la forme de la classe est 16:9', () {
    expect(tableau.ratio, closeTo(16 / 9, 1e-9));
  });

  test('meme trait, deux ecrans : meme forme, echelle uniforme, centre', () {
    // Un trait echange en coordonnees du tableau (0 a 1).
    const PointNormalise depart = PointNormalise(0.1, 0.2);
    const PointNormalise arrivee = PointNormalise(0.6, 0.5);
    final Map<String, ({double dx, double dy, Rect feuille})> rendus =
        <String, ({double dx, double dy, Rect feuille})>{};
    for (final (String nom, Size ecran) in <(String, Size)>[
      ('telephone portrait', const Size(390, 844)),
      ('ordinateur', const Size(1366, 768)),
      ('grand ecran', const Size(1920, 1080)),
    ]) {
      final ReperePage repere = ReperePage.de(
        ratio: tableau.ratio,
        boite: ecran,
      );
      final Offset a = repere.versSurface(depart);
      final Offset b = repere.versSurface(arrivee);
      rendus[nom] = (dx: b.dx - a.dx, dy: b.dy - a.dy, feuille: repere.page);
      // La feuille garde le ratio 16:9 et tient dans l'ecran, centree.
      expect(repere.page.width / repere.page.height, closeTo(16 / 9, 1e-6));
      expect(repere.page.width, lessThanOrEqualTo(ecran.width + 1e-6));
      expect(repere.page.height, lessThanOrEqualTo(ecran.height + 1e-6));
      expect(repere.page.center.dx, closeTo(ecran.width / 2, 1e-6));
      expect(repere.page.center.dy, closeTo(ecran.height / 2, 1e-6));
    }
    // Le rapport des longueurs x / y du trait est le meme partout.
    final double attendu = (0.5 * 16) / (0.3 * 9);
    for (final ({double dx, double dy, Rect feuille}) r in rendus.values) {
      expect(r.dx / r.dy, closeTo(attendu, 1e-6));
    }
    // Telephone portrait : le tableau tient en largeur ; bandes vides au-dessus
    // et au-dessous, jamais d'etirement.
    final Rect telephone = rendus['telephone portrait']!.feuille;
    expect(telephone.width, closeTo(390, 1e-6));
    expect(telephone.height, closeTo(390 * 9 / 16, 1e-6));
    // 1920 x 1080 est deja en 16:9 : la feuille est l'ecran entier.
    expect(
      rendus['grand ecran']!.feuille,
      const Rect.fromLTWH(0, 0, 1920, 1080),
    );
  });
}
