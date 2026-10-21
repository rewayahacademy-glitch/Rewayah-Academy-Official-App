// INTEG-MINEURS-1 point 4 : la source declaree de `enseignant.cahier.echecEnvoi`
// est l'etape qui a ecrit le texte (EN-7c), pas LIB-CAHIER-1 qui l'a seulement
// garde.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  test('echecEnvoi du cahier : source EN-7c, texte d\'EN-7c', () {
    final Map<String, Object?> sources = jsonDecode(
      File('tool/libelles_sources.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final String source = sources['enseignant.cahier.echecEnvoi']! as String;
    expect(source, startsWith('EN-7c'));
    expect(source, isNot(contains('commentaire du directeur')));
    expect(
      t.enseignant.cahier.echecEnvoi,
      'L\'envoi n\'a pas été confirmé. Vérifiez avant de réessayer.',
    );
  });
}
