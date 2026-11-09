// NAV-REFONTE (decisions du directeur du 09/11/2026) : dans la barre flottante
// du telephone, seul l'onglet ouvert ecrit son nom ; les autres n'ont que leur
// icone, et leur nom reste lu par le lecteur d'ecran. Un test touche donc une
// destination de la coquille par son nom LU, le meme a toutes les largeurs
// (barre, rail, colonne) et dans les deux modes.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

/// La destination [libelle] de la coquille [NavShell], par son nom lu.
Finder destinationNav(String libelle) => find
    .descendant(
      of: find.byType(NavShell),
      matching: find.bySemanticsLabel(libelle),
    )
    .first;
