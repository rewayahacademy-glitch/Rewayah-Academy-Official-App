// Le controle `nav-recomposee` doit voir une barre de navigation recomposee
// quelle que soit la mise en forme : espace, retour a la ligne, point.
import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_revue.dart';

void main() {
  group('motifNavRecomposee', () {
    const Map<String, String> vus = <String, String>{
      'collee': 'return NavigationBar(destinations: d);',
      'espace avant la parenthese': 'return NavigationBar (destinations: d);',
      'retour a la ligne': 'return NavigationBar\n    (destinations: d);',
      'retour a la ligne et retrait': 'x = NavigationRail\r\n      (a: 1);',
      'constructeur nomme': 'NavigationBar.new(destinations: d)',
      'bas d\'application': 'BottomAppBar\t(child: c)',
      'cupertino': 'CupertinoTabBar (items: i)',
    };
    vus.forEach((String nom, String code) {
      test('detecte : $nom', () {
        expect(motifNavRecomposee.hasMatch(code), isTrue);
      });
    });

    test('ne confond pas avec un autre identifiant', () {
      expect(
        motifNavRecomposee.hasMatch('final NavigationBarTheme t;'),
        isFalse,
      );
      expect(
        motifNavRecomposee.hasMatch('// NavigationBar est interdit'),
        isFalse,
      );
    });
  });
}
