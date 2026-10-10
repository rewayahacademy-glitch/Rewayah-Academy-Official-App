// JONCTION-LIGNES-1 (verification du 10/10) : une fusion avait laisse deux
// blocs « nav » au premier niveau de ar.i18n.json. Le decodeur JSON garde le
// dernier en silence : les 43 libelles arabes de la navigation (ligne des
// Communications) disparaissaient, et la barre retombait sur le francais
// (fallback_strategy: base_locale). Ce test lit le texte brut, pas l'objet
// decode, pour voir les cles en double a toute profondeur.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les chemins des cles en double dans [texte], un JSON valide.
List<String> clesEnDouble(String texte) {
  final List<String> doublons = <String>[];
  int i = 0;

  void blancs() {
    while (i < texte.length && ' \t\r\n'.contains(texte[i])) {
      i++;
    }
  }

  String chaine() {
    final int debut = i;
    i++;
    while (texte[i] != '"') {
      if (texte[i] == r'\') i++;
      i++;
    }
    i++;
    return jsonDecode(texte.substring(debut, i)) as String;
  }

  void valeur(String chemin) {
    blancs();
    final String c = texte[i];
    if (c == '{') {
      i++;
      final Set<String> vues = <String>{};
      blancs();
      if (texte[i] == '}') {
        i++;
        return;
      }
      while (true) {
        blancs();
        final String cle = chaine();
        final String ici = chemin.isEmpty ? cle : '$chemin.$cle';
        if (!vues.add(cle)) doublons.add(ici);
        blancs();
        i++; // :
        valeur(ici);
        blancs();
        if (texte[i++] == '}') return;
      }
    } else if (c == '[') {
      i++;
      blancs();
      if (texte[i] == ']') {
        i++;
        return;
      }
      while (true) {
        valeur(chemin);
        blancs();
        if (texte[i++] == ']') return;
      }
    } else if (c == '"') {
      chaine();
    } else {
      while (i < texte.length && !',}] \t\r\n'.contains(texte[i])) {
        i++;
      }
    }
  }

  valeur('');
  return doublons;
}

/// Les feuilles de [arbre], en chemins pointes.
Set<String> feuilles(Map<String, dynamic> arbre, [String chemin = '']) {
  final Set<String> sortie = <String>{};
  arbre.forEach((String cle, dynamic v) {
    final String ici = chemin.isEmpty ? cle : '$chemin.$cle';
    if (v is Map<String, dynamic>) {
      sortie.addAll(feuilles(v, ici));
    } else {
      sortie.add(ici);
    }
  });
  return sortie;
}

void main() {
  final List<File> fichiers = <File>[
    ...Directory('assets/i18n')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json')),
    File('tool/libelles_sources.json'),
  ];

  test('le detecteur voit une cle en double, meme imbriquee', () {
    expect(
      clesEnDouble('{"a": {"b": 1, "b": 2}, "c": [1, {"d": "x"}]}'),
      <String>['a.b'],
    );
    expect(clesEnDouble('{"nav": {}, "x": "\\"", "nav": {}}'), <String>['nav']);
    expect(clesEnDouble('{"a": {"b": 1}, "c": {"b": 2}}'), isEmpty);
  });

  for (final File f in fichiers) {
    test('${f.path} : aucune cle en double', () {
      expect(clesEnDouble(f.readAsStringSync()), isEmpty);
    });
  }

  test('la navigation est entierement traduite en arabe', () {
    Map<String, dynamic> nav(String langue) =>
        (jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
                as Map<String, dynamic>)['nav']
            as Map<String, dynamic>;
    expect(feuilles(nav('fr')).difference(feuilles(nav('ar'))), isEmpty);
  });

  test('la barre servie en arabe ne retombe pas sur le francais', () async {
    final Traductions ar = await AppLocale.ar.build();
    final Traductions fr = await AppLocale.fr.build();
    expect(ar.nav.eleve.accueil, isNot(fr.nav.eleve.accueil));
    expect(ar.nav.admin.tableauDeBord, isNot(fr.nav.admin.tableauDeBord));
    expect(ar.nav.tuteur.foyer, isNot(fr.nav.tuteur.foyer));
  });
}
