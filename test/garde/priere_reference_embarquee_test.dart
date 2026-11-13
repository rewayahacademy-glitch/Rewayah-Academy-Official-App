// PRIERE-1 : la matrice de reference d'`adhan` est embarquee dans le scenario
// SQL (rejouable depuis n'importe quel dossier) ; elle doit rester la copie
// exacte du fichier CSV que ecrit tool/priere/generer_reference.dart.
// Apres une regeneration du CSV : dart run tool/priere/integrer_reference.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la matrice embarquee dans le scenario est le CSV de reference', () {
    final String csv = File(
      'supabase/tests/fixtures/priere_reference_adhan.csv',
    ).readAsStringSync();
    final String sql = File('supabase/tests/scenarios_priere_serveur.sql')
        .readAsStringSync();
    const String debut = '\\copy ref FROM STDIN CSV HEADER\n';
    final int i = sql.indexOf(debut);
    expect(i, greaterThan(0), reason: 'le \\copy embarque a disparu');
    final int j = sql.indexOf('\n\\.\n', i);
    expect(j, greaterThan(i), reason: 'le terminateur \\. a disparu');
    final String embarque = sql.substring(i + debut.length, j + 1);
    expect(embarque, csv);
  });
}
