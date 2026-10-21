// SUPERPOS-1 (decision du 05/10/2026, prise par delegation) : la zone de
// saisie partagee est le seul point d'entree d'un champ de plusieurs lignes.
//
// Garde de source : aucun `TextField` / `TextFormField` multiligne (minLines
// ou maxLines) hors de `lib/core/widgets/zone_saisie.dart`. Les voies
// actives d'autres equipes (communications et messages, finance et
// comptable, salle et classe en direct) sont hors de ce lot : leurs defauts
// sont releves dans la fiche SUPERPOS-1 pour relais.
//
// Contre-epreuve faite : sur la base `corrections/revue-directeur-2026-10`
// (6e2c91c4), ce test echoue sur 18 fichiers.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les dossiers des autres voies (relais dans la fiche).
const List<String> _horsLot = <String>[
  'lib/features/communications/',
  'lib/features/com_messages/',
  // JONCTION-LIGNES-1 : la voie Communications (ui/communications-v1) a ses
  // ecrans sous lib/features/com_* et son fil partage ; leur passage sur
  // ZoneSaisie reste a la voie COM (releve de b061fd81, relais 47).
  'lib/features/com_',
  'lib/core/widgets/fil_discussion.dart',
  'lib/features/finance',
  // La voie Finance a aussi ses ecrans de direction (JONCTION-LIGNES-1).
  'lib/features/admin_finance/',
  'lib/features/comptable',
  'lib/features/salle/',
  'lib/features/_dev/',
];

/// Les appels `TextField(` ou `TextFormField(` de [source], parentheses
/// equilibrees.
Iterable<String> _champs(String source) sync* {
  for (final RegExpMatch m in RegExp(
    r'\bText(Form)?Field\(',
  ).allMatches(source)) {
    int i = m.end;
    int profondeur = 1;
    while (profondeur > 0 && i < source.length) {
      final String c = source[i];
      if (c == '(') profondeur++;
      if (c == ')') profondeur--;
      i++;
    }
    yield source.substring(m.start, i);
  }
}

void main() {
  test('aucun champ multiligne hors de ZoneSaisie', () {
    final List<String> fautes = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String chemin = f.path.replaceAll(r'\', '/');
      if (chemin.endsWith('core/widgets/zone_saisie.dart')) continue;
      if (chemin.endsWith('.g.dart')) continue;
      if (_horsLot.any(chemin.contains)) continue;
      for (final String champ in _champs(f.readAsStringSync())) {
        if (RegExp(r'\b(minLines|maxLines)\s*:').hasMatch(champ)) {
          fautes.add('$chemin : ${champ.split('\n').first}');
        }
      }
    }
    expect(fautes, isEmpty, reason: fautes.join('\n'));
  });
}
