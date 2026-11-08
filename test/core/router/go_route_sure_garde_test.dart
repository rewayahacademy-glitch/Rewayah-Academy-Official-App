// Selection du texte (directeur, 07/11/2026) : aucune `GoRoute` nue dans le
// code. Une route qui n'est pas une `GoRouteSure` n'enveloppe pas sa page dans
// `SelectionSiVisible` : cachee sous une page opaque ou dans une branche non
// affichee, elle inscrit son texte a la selection racine (assertion
// `hasSize` du tri, « Tout selectionner » qui copie un ecran cache).
//
// Les coquilles `ShellRoute` et `StatefulShellRoute` ne sont pas des
// `GoRoute` ; leur contenu (la barre de navigation) reste copiable, et leurs
// pages, des `GoRouteSure`, sont enveloppees (preuve :
// `selection_routes_test.dart`, onglet cache).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le seul fichier qui a le droit d'appeler `GoRoute(` : il definit
/// `GoRouteSure`.
const String _definition = 'lib/core/router/go_route_sure.dart';

final RegExp _goRouteNue = RegExp(r'(?<![A-Za-z0-9_])GoRoute\s*\(');

void main() {
  test('aucune GoRoute nue dans lib/ : GoRouteSure partout', () {
    final List<String> nues = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String chemin = f.path.replaceAll(r'\', '/');
      if (chemin == _definition) continue;
      final List<String> lignes = f.readAsLinesSync();
      for (int i = 0; i < lignes.length; i++) {
        final String ligne = lignes[i].trimLeft();
        if (ligne.startsWith('//')) continue;
        if (_goRouteNue.hasMatch(ligne)) nues.add('$chemin:${i + 1}');
      }
    }
    expect(
      nues,
      isEmpty,
      reason:
          'Utiliser GoRouteSure (lib/core/router/go_route_sure.dart) :\n'
          '${nues.join('\n')}',
    );
  });

  test('la regle voit une GoRoute nue (contre-epreuve)', () {
    expect(_goRouteNue.hasMatch("GoRoute(path: '/')"), isTrue);
    expect(_goRouteNue.hasMatch("  GoRoute (path: '/')"), isTrue);
    expect(_goRouteNue.hasMatch("GoRouteSure(path: '/')"), isFalse);
    expect(_goRouteNue.hasMatch('MaGoRoute(x)'), isFalse);
  });
}
