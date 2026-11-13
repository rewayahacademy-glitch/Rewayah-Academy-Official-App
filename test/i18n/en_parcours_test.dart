// LANGUES-1 (13/11/2026), etape 2 : l'anglais du chemin des candidats et des
// familles. Le fichier n'est qu'un sous-ensemble du francais ; ce qui n'est pas
// traduit retombe sur le francais (`fallback_strategy: base_locale`), jamais
// sur une cle brute.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

Map<String, String> _aplatir(dynamic noeud, [String prefixe = '']) {
  final Map<String, String> sortie = <String, String>{};
  if (noeud is Map<String, dynamic>) {
    noeud.forEach((String cle, dynamic v) {
      sortie.addAll(_aplatir(v, '$prefixe$cle.'));
    });
  } else if (noeud is List<dynamic>) {
    for (int i = 0; i < noeud.length; i++) {
      sortie.addAll(_aplatir(noeud[i], '$prefixe$i.'));
    }
  } else {
    sortie[prefixe.substring(0, prefixe.length - 1)] = noeud as String;
  }
  return sortie;
}

Map<String, String> _lire(String langue) => _aplatir(
  jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync()),
);

final RegExp _parametre = RegExp(r'\{(\w+)\}');

List<String> _parametres(String texte) =>
    _parametre.allMatches(texte).map((Match m) => m[1]!).toList()..sort();

void main() {
  final Map<String, String> fr = _lire('fr');
  final Map<String, String> en = _lire('en');

  test('chaque cle anglaise existe en francais, avec les memes parametres', () {
    for (final MapEntry<String, String> e in en.entries) {
      expect(fr.containsKey(e.key), isTrue, reason: e.key);
      expect(_parametres(e.value), _parametres(fr[e.key]!), reason: e.key);
    }
  });

  test('un pluriel anglais garde ses deux formes, comme le francais', () {
    for (final String cle in en.keys.where((String k) => k.endsWith('.one'))) {
      final String autre = '${cle.substring(0, cle.length - 4)}.other';
      expect(en.containsKey(autre), isTrue, reason: cle);
    }
    for (final String cle in en.keys.where(
      (String k) => k.endsWith('.other'),
    )) {
      final String un = '${cle.substring(0, cle.length - 6)}.one';
      if (fr.containsKey(un)) expect(en.containsKey(un), isTrue, reason: cle);
    }
  });

  test('aucun tiret long, aucun mot interdit (« school ») dans l anglais', () {
    for (final MapEntry<String, String> e in en.entries) {
      expect(e.value.contains('—'), isFalse, reason: e.key);
      expect(RegExp('[Ss]chool').hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test(
    'l anglais est charge a la demande, le reste retombe sur le francais',
    () async {
      await LocaleSettings.setLocale(AppLocale.en);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      expect(t.connexion.titre, 'Sign in');
      expect(t.commun.langue.anglais, 'English');
      // Une cle absente de l'anglais (salle) rend le francais, pas la cle.
      expect(t.salle.fin.enseignant.connectes(n: 1), '1 élève connecté');
      expect(t.parcours.titre(dePrenom: 'Amina'), "Amina's journey");
    },
  );
}
