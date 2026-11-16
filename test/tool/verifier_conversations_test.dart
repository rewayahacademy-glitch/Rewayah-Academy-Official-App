// La garde des conversations (CONVERSATIONS-PARTOUT, directeur, 16/11/2026) :
// un fichier de lib/ qui affiche ou ouvre une conversation doit etre dans
// `docs/current/MESSAGERIE-MATRICE.md`, et aucun ecran ne recompose un en-tete
// de conversation au lieu du composant partage.
//
// Ce test fait deux choses : il verifie le depot reel (la CI echoue sur une
// entree oubliee), et il prouve que la garde ECHOUE quand elle doit, sur un
// depot factice.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_conversations.dart';

/// Un depot factice : [fichiers] (chemin relatif -> contenu).
Directory _depot(Map<String, String> fichiers) {
  final Directory d = Directory.systemTemp.createTempSync('conversations_');
  addTearDown(() => d.deleteSync(recursive: true));
  fichiers.forEach((String chemin, String contenu) {
    File('${d.path}/$chemin')
      ..createSync(recursive: true)
      ..writeAsStringSync(contenu);
  });
  return d;
}

String _matrice(List<String> chemins) =>
    '| Fichier | Roles |\n| :--- | :--- |\n'
    '${chemins.map((String c) => '| `$c` | tous |').join('\n')}\n';

void main() {
  test('le depot reel : chaque entree est dans la matrice', () {
    expect(verifier(), isEmpty);
  });

  test('un fichier qui utilise un composant sans sa ligne fait echouer', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/ecran.dart': 'Widget b() => FilEnPlace(filId: "a");',
      fichierMatrice: _matrice(<String>[]),
    });
    final List<String> e = verifier(racine: d.path);
    expect(e, hasLength(1));
    expect(e.single, contains('lib/features/x/ecran.dart'));
    expect(e.single, contains('FilEnPlace'));
  });

  test('avec sa ligne, le meme fichier passe', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/ecran.dart': 'Widget b() => FilEnPlace(filId: "a");',
      fichierMatrice: _matrice(<String>['lib/features/x/ecran.dart']),
    });
    expect(verifier(racine: d.path), isEmpty);
  });

  test('un composant cite en commentaire ne compte pas', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/ecran.dart': '// voir FilDiscussion\n/* FilContextuel */\nWidget b() => Text("a");',
      fichierMatrice: _matrice(<String>[]),
    });
    expect(verifier(racine: d.path), isEmpty);
  });

  test('une ligne de matrice qui nomme un fichier disparu fait echouer', () {
    final Directory d = _depot(<String, String>{
      'lib/vide.dart': 'void f() {}',
      fichierMatrice: _matrice(<String>['lib/features/x/disparu.dart']),
    });
    expect(verifier(racine: d.path).single, contains('n\'existe plus'));
  });

  test('une ligne de matrice sur un fichier sans composant fait echouer', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/ecran.dart': 'Widget b() => Text("a");',
      fichierMatrice: _matrice(<String>['lib/features/x/ecran.dart']),
    });
    expect(
      verifier(racine: d.path).single,
      contains('n\'utilise plus aucun composant'),
    );
  });

  test('une matrice absente fait echouer', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/ecran.dart': 'Widget b() => FilContextuel();',
    });
    expect(
      verifier(racine: d.path).any((String e) => e.contains('absente')),
      isTrue,
    );
  });

  test('un ecran qui empile un titre de panneau au-dessus du fil echoue', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/volet.dart':
          'Widget b() => Column(children: [TetePanneau(titre: "x"), '
          'FilEnPlace(filId: "a")]);',
      fichierMatrice: _matrice(<String>['lib/features/x/volet.dart']),
    });
    final List<String> e = verifier(racine: d.path);
    expect(e.single, contains('entete-recompose'));
  });

  test('un titre « Conversation avec » en titre de feuille echoue, mais pas '
      'en etiquette de lecteur d\'ecran', () {
    final Directory titre = _depot(<String, String>{
      'lib/features/x/feuille.dart':
          'void f() { AppBottomSheet.ouvrirLecture(titre: e.conversationAvec('
          'nom: n), child: FilEnPlace(filId: "a")); }',
      fichierMatrice: _matrice(<String>['lib/features/x/feuille.dart']),
    });
    expect(verifier(racine: titre.path).single, contains('entete-recompose'));
    final Directory etiquette = _depot(<String, String>{
      'lib/features/x/volet.dart':
          'Widget b() => Semantics(label: e.conversationAvec(nom: n), '
          'child: FilEnPlace(filId: "a"));',
      fichierMatrice: _matrice(<String>['lib/features/x/volet.dart']),
    });
    expect(verifier(racine: etiquette.path), isEmpty);
  });

  test('une barre de conversation construite hors du composant echoue', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/barre.dart': 'Widget b() => BarreConversation(fil: f);',
      fichierMatrice: _matrice(<String>['lib/features/x/barre.dart']),
    });
    expect(verifier(racine: d.path).single, contains('barre-recomposee'));
  });

  test('le composant partage a le droit de poser sa barre et son fil', () {
    final Directory d = _depot(<String, String>{
      'lib/features/com_messages/fil_contextuel.dart':
          'Widget b() => BarreConversation(fil: f);',
      'lib/core/widgets/fil_discussion.dart': 'class FilDiscussion {}',
      fichierMatrice: _matrice(<String>[
        'lib/features/com_messages/fil_contextuel.dart',
        'lib/core/widgets/fil_discussion.dart',
      ]),
    });
    expect(verifier(racine: d.path), isEmpty);
  });

  test(
    'un fil pose a la main hors liste toleree echoue ; toleré, il passe',
    () {
      final Map<String, String> base = <String, String>{
        'lib/features/x/page.dart': 'Widget b() => FilDiscussion(messages: m);',
        fichierMatrice: _matrice(<String>['lib/features/x/page.dart']),
      };
      expect(
        verifier(racine: _depot(base).path).single,
        contains('fil-pose-a-la-main'),
      );
      final Directory toleree = _depot(<String, String>{
        ...base,
        fichierTolere:
            '# commentaire\nlib/features/x/page.dart | fil-pose-a-la-main | '
            'raison\n',
      });
      expect(verifier(racine: toleree.path), isEmpty);
    },
  );

  test('une tolerance qui ne correspond plus a rien doit etre retiree', () {
    final Directory d = _depot(<String, String>{
      'lib/features/x/page.dart': 'Widget b() => FilContextuel();',
      fichierMatrice: _matrice(<String>['lib/features/x/page.dart']),
      fichierTolere: 'lib/features/x/page.dart | fil-pose-a-la-main | raison\n',
    });
    expect(verifier(racine: d.path).single, contains('retirer la ligne'));
  });

  test('la matrice du depot est complete : 12 verifications par entree', () {
    final List<String> lignes = File(fichierMatrice).readAsLinesSync();
    final Iterable<String> rangs = lignes.where(
      (String l) => RegExp(r'^\|\s*`lib/').hasMatch(l),
    );
    expect(rangs, isNotEmpty);
    for (final String l in rangs) {
      // Fichier, roles, quoi, 12 verifications, ecart : 16 cellules.
      final int cellules = l.split('|').length - 2;
      expect(cellules, 16, reason: l.split('|')[1]);
      for (final String c in l.split('|').skip(4).take(12)) {
        expect(c.trim(), isNotEmpty, reason: 'case vide : ${l.split('|')[1]}');
      }
    }
  });
}
