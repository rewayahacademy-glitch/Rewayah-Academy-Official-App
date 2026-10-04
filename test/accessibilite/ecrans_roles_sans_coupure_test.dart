// Revue COUPE-MOTS-1-R (M2) : la mesure « aucun mot coupe ni tronque sur
// l'ECRAN ENTIER » tourne toujours, en CI, pour un ecran reel par role, a
// 320 px et texte x2, en vraies polices (comme les captures de recette, mais
// sans CAPTURE_DIR et sans PNG).
//
// Les ecrans sont ceux des captures COUPE-MOTS-1 (`test/support/ecrans_roles.dart`) :
// enseignant (Mes Classes dans sa coquille, barre basse « Disponibilites »),
// controleur (Echanges), tuteur (Historique), administration (Dossiers), salle
// (« Seance en direct »). Clair et sombre : la mise en page ne change pas,
// mais le cout est faible et un style propre au sombre serait vu.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../capture/outil_capture.dart';
import '../support/ecrans_roles.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('garde-fou : les vraies polices sont actives', (
    WidgetTester tester,
  ) async {
    expect(
      largeurSonde('PlusJakartaSans'),
      lessThan(largeurSonde('FamilleInexistante') * 0.6),
    );
  });

  for (final EcranRole ecran in ecransParRole) {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${ecran.nom} 320 x2 ${mode.name} : aucun mot coupe sur '
          "l'ecran entier", (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 700), 2);
        await monterEcranRole(tester, ecran, mode: mode, echelle: 2);
        expect(tester.takeException(), isNull);
        mesurerEcranEntier(tester);
      });
    }
  }
}
