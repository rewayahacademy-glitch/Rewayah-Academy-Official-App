// AR-SALLE-1 (tranche de AR-COMPLET-1) : la salle est entierement traduite
// en arabe.
//
// Chaque cle `salle.*` du francais a sa traduction arabe, avec exactement les
// memes parametres ; chaque parametre ajoute par cette tranche est isole
// (U+2068 ... U+2069), pour qu'un nom latin ne renverse pas la phrase.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

Map<String, String> _aplatir(
  Map<String, dynamic> carte, [
  String prefixe = '',
]) {
  final Map<String, String> sortie = <String, String>{};
  carte.forEach((String cle, dynamic valeur) {
    if (valeur is Map<String, dynamic>) {
      sortie.addAll(_aplatir(valeur, '$prefixe$cle.'));
    } else {
      sortie['$prefixe$cle'] = valeur as String;
    }
  });
  return sortie;
}

Map<String, String> _salle(String langue) => _aplatir(
  (jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
          as Map<String, dynamic>)['salle']
      as Map<String, dynamic>,
  'salle.',
);

/// Les cles de la salle traduites avant cette tranche, sans isolation.
const Set<String> _anciennes = <String>{'salle.secours.indisponible'};

final RegExp _parametre = RegExp(r'\{\w+\}');

List<String> _parametres(String texte) =>
    _parametre.allMatches(texte).map((Match m) => m[0]!).toList()..sort();

void main() {
  final Map<String, String> fr = _salle('fr');
  final Map<String, String> ar = _salle('ar');

  test('chaque cle salle.* a sa traduction arabe', () {
    expect(fr.length, greaterThan(300));
    final List<String> manquantes = fr.keys
        .where((String cle) => !ar.containsKey(cle))
        .toList();
    expect(manquantes, isEmpty);
    expect(ar.keys.toSet().difference(fr.keys.toSet()), isEmpty);
  });

  test('memes parametres qu\'en francais', () {
    for (final String cle in fr.keys) {
      expect(_parametres(ar[cle]!), _parametres(fr[cle]!), reason: cle);
    }
  });

  test('parametres isoles (U+2068 ... U+2069)', () {
    final RegExp nu = RegExp('(?<!\u2068)\\{\\w+\\}(?!\u2069)');
    for (final MapEntry<String, String> e in ar.entries) {
      if (_anciennes.contains(e.key)) continue;
      expect(nu.hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test('du texte arabe, jamais le francais recopie', () {
    final RegExp arabe = RegExp('[؀-ۿ]');
    // Codes de situation et marque : gardes tels quels, suivis d'arabe.
    const Set<String> latins = <String>{
      'salle.seance.rail.marque',
      'salle.seance.rail.sousMarque',
    };
    for (final MapEntry<String, String> e in ar.entries) {
      if (latins.contains(e.key) ||
          _parametre.hasMatch(e.value) &&
              e.value
                      .replaceAll(_parametre, '')
                      .trim()
                      .replaceAll(RegExp('[\u2068\u2069 ·/%،,]'), '') ==
                  '') {
        continue;
      }
      expect(arabe.hasMatch(e.value), isTrue, reason: e.key);
      expect(e.value, isNot(fr[e.key]), reason: e.key);
    }
  });

  test('slang rend l\'arabe a l\'execution', () async {
    final Traductions traductions = await AppLocale.ar.build();
    expect(traductions.salle.seance.bibliotheque.presenter, 'عرض');
    expect(
      traductions.salle.seance.surface.page(titre: 'X', page: 1, pages: 2),
      '\u2068X\u2069، الصفحة \u20681\u2069 من \u20682\u2069',
    );
    expect(
      traductions.salle.seance.surface.aucunSupport,
      isNot(t.salle.seance.surface.aucunSupport),
    );
  });
}
