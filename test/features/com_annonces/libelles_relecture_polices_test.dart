// Relecture croisee des libelles COM (05/10) : « Droits de publication »
// remplace « Regles de portee » dans les indicateurs de l'Administration
// des communications. Mesure avec les vraies polices du depot (la police de
// test coupe tout mot de onze lettres a 320 en texte x2) : a 320 en texte
// x2, aucun mot des tuiles n'est coupe ni tronque.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import 'admin_banc.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('320, texte x2, vraies polices : « Droits de publication » '
      'se lit sans mot coupe', (WidgetTester tester) async {
    await monterAdministration(
      tester,
      taille: const Size(320, 844),
      echelleTexte: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text(t.com.annonces.administration.indicateurs.regles),
      findsOneWidget,
    );
    verifierAucunMotCoupe(tester, find.byType(StatTile));
  });
}
