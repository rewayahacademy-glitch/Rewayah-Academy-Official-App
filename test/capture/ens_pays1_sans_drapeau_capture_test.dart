// ENS-PAYS-1 : le rendu d'un appareil qui ne sait pas dessiner le drapeau
// (Chrome ou Edge sous Windows, sans police d'emoji qui fusionne les lettres
// regionales). Aucune police d'emoji n'est chargee : le composant mesure que
// la paire de lettres ne se fusionne pas et n'affiche que le nom du pays,
// jamais deux lettres orphelines.
//
// Saute sans CAPTURE_DIR. Nommage : enspays1_sansdrapeau_<ecran>_<largeur>.png.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ens_pays1/support_ens_pays1.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : ENS-PAYS-1 sans drapeau', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final EcranPays e in ecransPays().where(
      (EcranPays e) =>
          e.nom == 'tuteur_accueil' ||
          e.nom == 'controleur_mission' ||
          e.nom == 'admin_attribution',
    )) {
      final String fichier = 'enspays1_sansdrapeau_${e.nom}_390';
      testWidgets(fichier, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.pumpWidget(hotePays(e));
        await stabiliser(tester);
        if (e.toucher != null) {
          await tester.tap(find.text(e.toucher!).first);
          await stabiliser(tester);
        }
        await montrerPays(tester);
        tester.takeException();
        debugPrint('PNG ${await capturer(tester, fichier)}');
      });
    }
  });
}
