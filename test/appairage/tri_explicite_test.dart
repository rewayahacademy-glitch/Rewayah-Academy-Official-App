import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tri PostgREST (`03` section 1 ter bis-2 ; demandes B-2 et D-2).
///
/// PostgREST trie en DECROISSANT quand l'appel n'ecrit rien : c'est ce sens
/// implicite qui a fait lire le Coran a l'envers. Le client Supabase n'est pas
/// simulable ici sans ajouter une dependance de test : la garde est donc
/// lexicale, sur tous les `.order(` des services d'appairage.
void main() {
  final List<File> sources = Directory('lib/core/appairage')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();

  /// Chaque appel `.order(...)`, parentheses equilibrees, espaces compris.
  List<String> appelsOrder(String source) {
    final List<String> appels = <String>[];
    int debut = source.indexOf('.order(');
    while (debut >= 0) {
      int profondeur = 0;
      int fin = debut + '.order'.length;
      for (; fin < source.length; fin++) {
        if (source[fin] == '(') {
          profondeur++;
        } else if (source[fin] == ')') {
          profondeur--;
          if (profondeur == 0) {
            break;
          }
        }
      }
      appels.add(source.substring(debut, fin + 1));
      debut = source.indexOf('.order(', fin);
    }
    return appels;
  }

  test('les sources d appairage sont trouvees', () {
    expect(sources, isNotEmpty);
  });

  test('chaque .order( des services d appairage ecrit son sens', () {
    final List<String> sansSens = <String>[
      for (final File f in sources)
        for (final String appel in appelsOrder(f.readAsStringSync()))
          if (!appel.contains('ascending:')) '${f.path}: $appel',
    ];
    expect(sansSens, isEmpty);
  });

  test('les appareils du foyer arrivent du plus recent au plus ancien', () {
    final String service = File('lib/core/appairage/service_appairage.dart')
        .readAsStringSync();
    final List<String> appels = appelsOrder(
      service.substring(service.indexOf("from('mes_appareils_v')")),
    );
    expect(appels, isNotEmpty);
    expect(
      appels.first.replaceAll(RegExp(r'\s'), ''),
      ".order('paired_at',ascending:false)",
    );
  });
}
