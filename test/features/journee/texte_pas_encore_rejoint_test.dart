// LUMIERE 3 (pilote et garde-cap, 11/11/2026 ; mots-rewayah du 01/11) : la
// phrase de l'eleve pas encore entre dans la seance en direct est neutre, sans
// accord, en francais et en arabe : le genre de l'eleve n'est pas servi dans
// l'Aujourd'hui de l'enseignant. Ce test echoue si un participe ou un verbe
// accorde a l'eleve y revient.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _texte(String langue) {
  final Map<String, dynamic> racine = jsonDecode(
    File('assets/i18n/$langue.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> enseignant =
      racine['enseignant'] as Map<String, dynamic>;
  final Map<String, dynamic> journee =
      enseignant['journee'] as Map<String, dynamic>;
  return journee['pasEncoreRejoint'] as String;
}

void main() {
  test(
    'francais : « n a pas encore rejoint », jamais un participe accorde',
    () {
      final String fr = _texte('fr');
      expect(fr, "{eleve} n'a pas encore rejoint la salle.");
      for (final String accorde in <String>[
        'entré',
        'entrée',
        'arrivé',
        'arrivée',
        'rejointe',
        'venu',
        'venue',
      ]) {
        expect(fr.contains(accorde), isFalse, reason: accorde);
      }
    },
  );

  test('arabe : le verbe s accorde au nom « انضمام », jamais a l eleve', () {
    final String ar = _texte('ar');
    expect(ar, contains('لم يُسجَّل انضمام'));
    // Un verbe conjugue a l'eleve porterait son genre (masculin ou feminin).
    for (final String accorde in <String>[
      'لم يدخل',
      'لم تدخل',
      'لم ينضم',
      'لم تنضم',
      'لم يحضر',
      'لم تحضر',
    ]) {
      expect(ar.contains(accorde), isFalse, reason: accorde);
    }
  });
}
