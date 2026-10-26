// Plan de la salle du 26/10/2026 (§3) : les dix couleurs du nuancier des
// traits, mesurees sur ce qui les porte (la page, claire dans les deux
// themes, et la feuille blanche du tableau) : au moins 3:1 pour toutes
// (WCAG 1.4.11, objet graphique), 4,5:1 pour les six franches ; dix
// couleurs deux a deux differentes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/couleur_intention.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart'
    show couleursEcriture;

import 'support/contraste.dart';

void main() {
  final AppPalette claire = AppPalette.claire();
  final Map<String, Color> fonds = <String, Color>{
    'page': claire.surfaceCanvas.background,
    'tableau': claire.surfaceRaised.background,
  };
  final Map<String, Color> intentions = <String, Color>{
    for (final i in couleursEcriture)
      i.valeurSql: CouleurIntention.encre(claire, i).couleur(),
  };
  final Map<String, Color> franches = <String, Color>{
    for (final CouleurFranche c in CouleurFranche.values)
      c.valeurSql: encreFranche(c).couleur(),
  };

  test('dix couleurs, toutes differentes', () {
    final Map<String, Color> toutes = <String, Color>{
      ...intentions,
      ...franches,
    };
    expect(toutes, hasLength(10));
    expect(toutes.values.toSet(), hasLength(10));
  });

  for (final MapEntry<String, Color> fond in fonds.entries) {
    for (final MapEntry<String, Color> c in intentions.entries) {
      test('${c.key} sur ${fond.key} : 3:1 au moins', () {
        expect(contraste(c.value, fond.value), greaterThanOrEqualTo(3));
      });
    }
    for (final MapEntry<String, Color> c in franches.entries) {
      test('${c.key} sur ${fond.key} : 4,5:1 au moins', () {
        expect(contraste(c.value, fond.value), greaterThanOrEqualTo(4.5));
      });
    }
  }
}
