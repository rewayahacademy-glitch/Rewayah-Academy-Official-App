// BENTO-3b (m8 de BENTO-3-R) : le controle « aucun mot coupe » lui-meme.
//
// Il doit nommer un mot vraiment coupe, laisser passer un retour a la ligne
// entre deux mots, et ne pas prendre pour une coupure le glyphe d'une police
// de repli (trait d'union insecable U+2011 de « An‑Nour »), dont la boite est
// plus haute sur la MEME ligne.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';

Future<void> _monter(WidgetTester tester, String texte, double largeur) =>
    tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: largeur,
            child: Text(texte, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('un mot plus large que sa place est nomme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Anticonstitutionnellement', 40);
    expect(motsCoupes(tester, find.byType(Text)), <String>[
      'Anticonstitutionnellement : Anticonstitutionnellement',
    ]);
  });

  testWidgets('un retour a la ligne entre deux mots passe', (
    WidgetTester tester,
  ) async {
    // Juste la place du mot le plus long : les deux mots passent chacun
    // sur sa ligne, entiers.
    double largeurDe(String mot) => (TextPainter(
      text: TextSpan(text: mot, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout()).width;
    await _monter(
      tester,
      'Mamadou Diallo',
      largeurDe('Mamadou') + largeurDe('Diallo') / 2,
    );
    // La mesure porte sur deux lignes : le prenom, puis le nom.
    expect(tester.getSize(find.byType(Text)).height, greaterThan(30));
    expect(motsCoupes(tester, find.byType(Text)), isEmpty);
  });

  testWidgets('le trait d union insecable n est pas une coupure', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Classe An‑Nour', 400);
    expect(motsCoupes(tester, find.byType(Text)), isEmpty);
  });

  testWidgets('le meme nom compose, trop etroit, est nomme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, 'Classe An‑Nour', 30);
    expect(motsCoupes(tester, find.byType(Text)), isNotEmpty);
  });
}
