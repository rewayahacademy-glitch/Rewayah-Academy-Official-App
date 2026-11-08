import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La page des migrations (`tool/page_migrations/generer.py`) refuse un fichier
/// qui porte `BEGIN;` ou `COMMIT;` seul sur une ligne, et le dit en mots
/// simples (pilote, 08/11/2026, lot « page-push1 »). Elle laisse passer un
/// fichier sans ces lignes : l'enveloppe ouvre elle-meme la transaction unique.
///
/// Le test lance l'outil Python tel que le pilote le lance (`python3 -I`).
bool get _python =>
    Process.runSync('python3', <String>['--version']).exitCode == 0;

Future<ProcessResult> _page(File sql, File sortie) =>
    Process.run('python3', <String>[
      '-I',
      'tool/page_migrations/generer.py',
      '--sortie',
      sortie.path,
      '${sql.path}::Essai.',
    ]);

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('page_migrations_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File fichier(String nom, String texte) =>
      File('${tmp.path}/$nom')..writeAsStringSync(texte);

  test('un fichier sans BEGIN; ni COMMIT; donne une page', () async {
    final File sql = fichier('20261121000000_ok.sql', '-- ok\nSELECT 1;\n');
    final File page = File('${tmp.path}/page.html');
    final ProcessResult r = await _page(sql, page);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(page.existsSync(), isTrue);
  }, skip: _python ? false : 'python3 absent');

  for (final String commande in <String>[
    'BEGIN;',
    'COMMIT;',
    'begin;',
    '  Commit;  ',
    'BEGIN TRANSACTION;',
    'START TRANSACTION;',
  ]) {
    test('refus de « ${commande.trim()} » seul sur une ligne', () async {
      final File sql = fichier(
        '20261121000000_avec.sql',
        '-- a\n$commande\nSELECT 1;\n',
      );
      final File page = File('${tmp.path}/page.html');
      final ProcessResult r = await _page(sql, page);
      expect(r.exitCode, isNot(0));
      expect('${r.stderr}', contains('page refusee'));
      expect('${r.stderr}', contains('BEGIN; ou COMMIT; seul sur une ligne'));
      expect('${r.stderr}', contains('ligne 2'), reason: 'le numero de ligne');
      expect(page.existsSync(), isFalse, reason: 'aucune page produite');
    }, skip: _python ? false : 'python3 absent');
  }

  test('« end; » ferme une fonction : jamais refuse', () async {
    final File sql = fichier(
      '20261121000000_fonction.sql',
      'CREATE FUNCTION f() RETURNS int LANGUAGE plpgsql AS \$\$\n'
          'BEGIN\n  RETURN 1;\nEND;\n\$\$;\n',
    );
    final File page = File('${tmp.path}/page.html');
    final ProcessResult r = await _page(sql, page);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: _python ? false : 'python3 absent');

  // Les fichiers B (PR 350) et E (PR 353) doivent passer ; ils entrent dans ce
  // controle des qu'ils sont dans `main`.
  for (final String nom in <String>[
    '20261121100000_noms_classes.sql',
    '20261121200000_revenus_presence.sql',
  ]) {
    final File reel = File('supabase/migrations/$nom');
    test(
      'le fichier reel $nom passe',
      () async {
        final File page = File('${tmp.path}/page.html');
        final ProcessResult r = await _page(reel, page);
        expect(r.exitCode, 0, reason: '${r.stderr}');
      },
      skip: !_python
          ? 'python3 absent'
          : (reel.existsSync() ? false : 'pas encore dans main (PR 350/353)'),
    );
  }
}
