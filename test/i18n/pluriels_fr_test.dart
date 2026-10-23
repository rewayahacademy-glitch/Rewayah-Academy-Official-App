// Reserve de la verification AR-CORR-2 : chaque pluriel slang du francais
// porte ses DEUX formes, `one` et `other`. Une seule forme compile, mais
// slang rend alors la cle brute ou la mauvaise forme pour l'autre nombre
// (« 1 élèves », ou rien pour 1). La garde lit tout `assets/i18n/fr.i18n.json`
// et nomme chaque pluriel incomplet.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les formes du pluriel que slang reconnait.
const Set<String> _formes = <String>{
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
};

/// Vrai quand [noeud] est un pluriel slang : une table non vide dont chaque
/// cle est une forme du pluriel.
bool estPluriel(Object? noeud) =>
    noeud is Map<String, dynamic> &&
    noeud.isNotEmpty &&
    noeud.keys.every(_formes.contains);

/// Les pluriels de [racine] auxquels manque `one` ou `other`, avec leur
/// chemin complet.
List<String> plurielsIncomplets(Map<String, dynamic> racine) {
  final List<String> defauts = <String>[];
  void parcourir(String chemin, Object? noeud) {
    if (estPluriel(noeud)) {
      final Map<String, dynamic> pluriel = noeud! as Map<String, dynamic>;
      for (final String forme in <String>['one', 'other']) {
        if (!pluriel.containsKey(forme)) defauts.add('$chemin.$forme');
      }
    } else if (noeud is Map<String, dynamic>) {
      noeud.forEach(
        (String k, Object? v) =>
            parcourir(chemin.isEmpty ? k : '$chemin.$k', v),
      );
    }
  }

  parcourir('', racine);
  return defauts;
}

void main() {
  final Map<String, dynamic> fr = jsonDecode(
    File('assets/i18n/fr.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('le detecteur voit une forme manquante, de chaque cote', () {
    expect(
      plurielsIncomplets(<String, dynamic>{
        'a(param=n)': <String, dynamic>{'one': '{n} x', 'other': '{n} xs'},
      }),
      isEmpty,
    );
    expect(
      plurielsIncomplets(<String, dynamic>{
        'b': <String, dynamic>{
          'c(param=n)': <String, dynamic>{'one': '{n} x'},
        },
      }),
      <String>['b.c(param=n).other'],
    );
    expect(
      plurielsIncomplets(<String, dynamic>{
        'd': <String, dynamic>{'other': '{n} xs'},
      }),
      <String>['d.one'],
    );
  });

  test('le fichier francais porte des pluriels a verifier', () {
    int nombre = 0;
    void compter(Object? noeud) {
      if (estPluriel(noeud)) {
        nombre++;
      } else if (noeud is Map<String, dynamic>) {
        noeud.values.forEach(compter);
      }
    }

    compter(fr);
    expect(nombre, greaterThan(50));
  });

  test('chaque pluriel francais a ses formes one ET other', () {
    expect(plurielsIncomplets(fr), isEmpty);
  });
}
