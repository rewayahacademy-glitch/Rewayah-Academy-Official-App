// L2-05-reprise (D-3) : garde de source contre la cause trouvee dans le
// navigateur.
//
// En web release, `String? echec;` suivi de `try { await port.xxx(...); }
// catch { echec = ...; }` donnait a `echec`, apres un `await` reussi dont le
// resultat est ignore, la valeur d'un autre registre de la machine d'etat
// d'dart2js (« Widget » a l'affichage) : l'ecran lisait un refus, le
// formulaire restait ouvert, la liste n'etait pas relue, alors que l'offre
// etait creee. Les tests widget, sur la VM comme sur `--platform chrome`, ne
// le voient pas ; ce test garde donc la forme du code : le resultat d'un envoi
// passe par un `return` d'une fonction a part, jamais par une variable
// nullable non initialisee que le `catch` renseigne.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final RegExp variablePuisTry = RegExp(
    r'String\? (\w+);\s*try \{\s*await ',
    multiLine: true,
  );

  test('aucun envoi de l administration des offres ne passe par une variable '
      'renseignee dans un catch apres un await', () {
    final List<File> fichiers = Directory('lib/features/admin_offres')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();
    expect(fichiers, isNotEmpty);
    final List<String> fautifs = <String>[
      for (final File f in fichiers)
        if (variablePuisTry.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(fautifs, isEmpty, reason: 'rendre le resultat par un return');
  });

  test('la creation et le retrait rendent leur resultat par un return', () {
    for (final String chemin in <String>[
      'lib/features/admin_offres/nouvelle_offre_page.dart',
      'lib/features/admin_offres/feuille_retrait_offre.dart',
    ]) {
      final String source = File(chemin).readAsStringSync();
      expect(
        RegExp(r'final String\? echec = await _\w+\(').hasMatch(source),
        isTrue,
        reason: chemin,
      );
    }
  });
}
