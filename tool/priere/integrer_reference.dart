// PRIERE-1 : recopie le CSV de reference d'`adhan` dans le scenario SQL
// (bloc entre `\copy ref FROM STDIN CSV HEADER` et `\.`).
//   dart run tool/priere/integrer_reference.dart
import 'dart:io';

void main() {
  final String csv = File('supabase/tests/fixtures/priere_reference_adhan.csv')
      .readAsStringSync();
  final File scenario = File('supabase/tests/scenarios_priere_serveur.sql');
  final String sql = scenario.readAsStringSync();
  const String debut = '\\copy ref FROM STDIN CSV HEADER\n';
  final int i = sql.indexOf(debut);
  final int j = sql.indexOf('\n\\.\n', i);
  if (i < 0 || j < 0) {
    stderr.writeln('bloc embarque introuvable');
    exit(1);
  }
  scenario.writeAsStringSync(
    sql.substring(0, i + debut.length) + csv + sql.substring(j + 1),
  );
}
