// COUPE-MOTS-FOND-1 (5) et (3) : la garde du rendu sur la coque de
// l'administration aux gabarits intermediaires et grands, ou la fiche a vu
// des mots tronques : 700 x 900 texte x1 (rangee de filtres
// d'Observations, menus sortis de la vue), 800 x 900 texte x2 (rail),
// 1280 x 800 texte x2 (barre laterale et son pied, Journal). Francais et
// arabe, standard et Interface guidee ; memes ecrans que
// `coupe_mots_balayage_admin_test.dart`.

import 'package:flutter/material.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../support/balayage_ecrans.dart';
import '../support/garde_coupe_mots_rendu.dart';
import 'coupe_mots_balayage_admin_test.dart' show ecransAdmin;

/// Les gabarits intermediaires et grands.
const List<GabaritGarde> gabaritsLarges = <GabaritGarde>[
  (nom: '700x1', taille: Size(700, 900), echelle: 1),
  (nom: '800x2', taille: Size(800, 900), echelle: 2),
  (nom: '1280x2', taille: Size(1280, 800), echelle: 2),
];

void main() {
  balayer(
    ecransAdmin(),
    configs: <ConfigBalayage>[
      for (final GabaritGarde g in gabaritsLarges)
        for (final AppLocale l in const <AppLocale>[AppLocale.fr, AppLocale.ar])
          for (final InterfaceMode i in InterfaceMode.values)
            (gabarit: g, langue: l, interface: i),
    ],
  );
}
