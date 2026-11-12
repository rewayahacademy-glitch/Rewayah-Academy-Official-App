// SOMMAIRE-SOURATES (11/11/2026) : le corpus du Coran tel que le depot le
// porte (`supabase/migrations/0013_corpus_coranique.sql`, source Tanzil), lu
// par les tests. Jamais une liste recopiee : les noms et les pages viennent
// du fichier que la base a recu.
import 'dart:io';

import 'package:rewayah_academy/core/coran/service_coran.dart';

const String _fichier = 'supabase/migrations/0013_corpus_coranique.sql';

/// Les 114 sourates du corpus du depot, dans l'ordre du fichier.
List<Sourate> souratesDuCorpus() {
  final RegExp ligne = RegExp(
    r"^\s*\((\d+), '((?:[^']|'')+)', '((?:[^']|'')+)', '(mecque|medine)', "
    r'(\d+)\)',
    multiLine: true,
  );
  return <Sourate>[
    for (final RegExpMatch m in ligne.allMatches(
      File(_fichier).readAsStringSync(),
    ))
      Sourate(
        numero: int.parse(m.group(1)!),
        nomArabe: m.group(2)!.replaceAll("''", "'"),
        nomTranslittere: m.group(3)!.replaceAll("''", "'"),
        lieuRevelation: m.group(4)!,
        nombreVersets: int.parse(m.group(5)!),
      ),
  ];
}

/// La plus petite page de chaque sourate dans le corpus du depot : la page ou
/// elle commence. Cle : le numero de la sourate.
Map<int, int> pagesDeDepartDuCorpus() {
  final RegExp verset = RegExp(r"^\s*\((\d+), (\d+), '.*', (\d+)\)[,;]?\s*$");
  final Map<int, int> pages = <int, int>{};
  bool dansLesVersets = false;
  for (final String l in File(_fichier).readAsLinesSync()) {
    if (l.startsWith('insert into public.verset')) {
      dansLesVersets = true;
      continue;
    }
    if (!dansLesVersets) continue;
    final RegExpMatch? m = verset.firstMatch(l);
    if (m == null) continue;
    final int sourate = int.parse(m.group(1)!);
    final int page = int.parse(m.group(3)!);
    final int? connue = pages[sourate];
    if (connue == null || page < connue) pages[sourate] = page;
  }
  return pages;
}
