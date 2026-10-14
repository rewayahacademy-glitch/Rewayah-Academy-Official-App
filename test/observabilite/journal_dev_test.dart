import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Revue P2-11, M1 : aucun `debugPrint` direct dans `lib/`. Les erreurs
/// passent par `journalDev`, muet hors mode debug, pour qu'aucun texte
/// d'exception ni reponse serveur n'atteigne la console en production.
void main() {
  test('lib/ ne journalise que par journalDev', () {
    final List<String> fautifs = <String>[];
    for (final FileSystemEntity entite in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entite is! File || !entite.path.endsWith('.dart')) {
        continue;
      }
      final String chemin = entite.path.replaceAll(r'\', '/');
      if (chemin.endsWith('core/observabilite/journal_dev.dart')) {
        continue;
      }
      if (entite.readAsStringSync().contains('debugPrint(')) {
        fautifs.add(chemin);
      }
    }
    expect(fautifs, isEmpty);
  });
}
