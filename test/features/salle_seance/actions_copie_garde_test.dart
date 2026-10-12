// ACTIONS-COPIE-GARDE : `ActionsSeance.avecAgrandir` recopie chaque rappel du
// constructeur. Un champ ajoute au constructeur et oublie dans la copie
// disparaitrait en silence de la salle (defaut vu avec `onPause`). Ce test lit
// le source du fichier (analyse de texte, sans reflexion) et compare :
// les parametres `this.xxx` du constructeur, les champs `final ... xxx;` et
// les arguments nommes de la copie. Il tombe si l'un des trois ensembles
// differe des autres.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _chemin = 'lib/features/salle_seance/actions_seance.dart';

String _bloc(String source, String debut) {
  final int i = source.indexOf(debut);
  expect(i, isNonNegative, reason: 'repere introuvable : $debut');
  final int fin = source.indexOf(');', i);
  expect(fin, greaterThan(i));
  return source.substring(i, fin);
}

Set<String> _constructeur(String source) =>
    RegExp(r'this\.(\w+)')
        .allMatches(_bloc(source, 'const ActionsSeance({'))
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

Set<String> _champs(String source) => RegExp(
  r'^\s*final\s+[^;(=]*?\b(on\w+)\s*;',
  multiLine: true,
).allMatches(source).map((RegExpMatch m) => m.group(1)!).toSet();

Set<String> _copie(String source) =>
    RegExp(r'^\s*(\w+):\s*(\w+),', multiLine: true)
        .allMatches(_bloc(source, 'avecAgrandir('))
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

void main() {
  final String source = File(_chemin).readAsStringSync();

  test('le constructeur, les champs et la copie portent les memes rappels', () {
    final Set<String> constructeur = _constructeur(source);
    final Set<String> champs = _champs(source);
    final Set<String> copie = _copie(source);
    expect(constructeur, isNotEmpty);
    expect(
      champs.difference(constructeur),
      isEmpty,
      reason: 'champ absent du constructeur',
    );
    expect(
      constructeur.difference(champs),
      isEmpty,
      reason: 'parametre sans champ',
    );
    expect(
      constructeur.difference(copie),
      isEmpty,
      reason: 'rappel non copie par avecAgrandir',
    );
    expect(
      copie.difference(constructeur),
      isEmpty,
      reason: 'argument inconnu du constructeur',
    );
  });

  test('l\'analyse voit un champ oublie (contre-epreuve du detecteur)', () {
    final String fautif = source.replaceFirst(
      '  final VoidCallback? onPause;',
      '  final VoidCallback? onPause;\n  final VoidCallback? onNouveau;',
    );
    expect(fautif, isNot(source));
    expect(_champs(fautif).difference(_copie(fautif)), contains('onNouveau'));
  });
}
