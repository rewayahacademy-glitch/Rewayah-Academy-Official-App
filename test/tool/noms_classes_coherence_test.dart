// NOMS-CLASSES (08/11/2026) : la banque des noms de classes est un fichier de
// donnees versionne (supabase/donnees/noms_classes.json, decision du directeur
// du 25/10/2026) ; la migration 20261121100000_noms_classes.sql en recopie les
// valeurs une a une. Ce test garde les deux identiques, et la banque conforme a
// la decision : 40 noms au moins par genre, aucun doublon en fr ni en ar.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _Nom = ({int id, String genre, int rang, String fr, String ar});

List<_Nom> _depuisJson() {
  final Map<String, dynamic> d = jsonDecode(
    File('supabase/donnees/noms_classes.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<dynamic> noms = d['noms'] as List<dynamic>;
  return <_Nom>[
    for (int i = 0; i < noms.length; i++)
      (
        id: i + 1,
        genre: (noms[i] as Map<String, dynamic>)['genre'] as String,
        rang: (noms[i] as Map<String, dynamic>)['rang'] as int,
        fr: (noms[i] as Map<String, dynamic>)['fr'] as String,
        ar: (noms[i] as Map<String, dynamic>)['ar'] as String,
      ),
  ];
}

List<_Nom> _depuisMigration() {
  final String sql = File('supabase/migrations/20261121100000_noms_classes.sql')
      .readAsStringSync();
  final RegExp ligne = RegExp(
    r"^\s*\((\d+), '(femmes|hommes)', (\d+), '((?:[^']|'')*)', '((?:[^']|'')*)'\)[,]?$",
    multiLine: true,
  );
  return <_Nom>[
    for (final RegExpMatch m in ligne.allMatches(sql))
      (
        id: int.parse(m.group(1)!),
        genre: m.group(2)!,
        rang: int.parse(m.group(3)!),
        fr: m.group(4)!.replaceAll("''", "'"),
        ar: m.group(5)!.replaceAll("''", "'"),
      ),
  ];
}

void main() {
  test('la banque compte 40 noms au moins par genre, sans doublon', () {
    final List<_Nom> noms = _depuisJson();
    expect(
      noms.where((_Nom n) => n.genre == 'femmes').length,
      greaterThanOrEqualTo(40),
    );
    expect(
      noms.where((_Nom n) => n.genre == 'hommes').length,
      greaterThanOrEqualTo(40),
    );
    expect(
      noms.map((_Nom n) => n.fr.toLowerCase()).toSet().length,
      noms.length,
    );
    expect(noms.map((_Nom n) => n.ar).toSet().length, noms.length);
    for (final String genre in <String>['femmes', 'hommes']) {
      final List<int> rangs = noms
          .where((_Nom n) => n.genre == genre)
          .map((_Nom n) => n.rang)
          .toList();
      expect(
        rangs,
        List<int>.generate(rangs.length, (int i) => i + 1),
        reason: 'rangs continus de 1 a N pour $genre',
      );
    }
    for (final _Nom n in noms) {
      expect(n.fr.trim(), isNotEmpty);
      expect(n.ar.trim(), isNotEmpty);
      // Aucun mot interdit du vocabulaire (mots-rewayah) : jamais « groupe ».
      expect(n.fr.toLowerCase(), isNot(contains('groupe')));
    }
  });

  test('la migration recopie exactement le fichier de donnees', () {
    expect(_depuisMigration(), _depuisJson());
  });
}
