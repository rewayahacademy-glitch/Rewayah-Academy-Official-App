// Repere les textes francais identiques portes par plusieurs cles.
//
// Lecture seule : ne modifie aucun fichier. Sert a toute vague de fusion
// (K-41 : une cle = un sens, donc un doublon de texte n'est pas un doublon de
// sens tant qu'un humain ne l'a pas dit).
//
// Lancement : dart run tool/doublons_i18n.dart [--ar]
// Sortie : n<TAB>valeur<TAB>cle1,cle2,..., tri decroissant sur n.
// Avec --ar, une colonne finale donne le nombre de traductions arabes
// distinctes parmi ces cles (1 = fusion possible sans perdre de nuance).

import 'dart:convert';
import 'dart:io';

const String _fichierFr = 'assets/i18n/fr.i18n.json';
const String _fichierAr = 'assets/i18n/ar.i18n.json';

void main(List<String> arguments) {
  final Map<String, String> fr = _aplatir(_lire(_fichierFr));
  final bool avecAr = arguments.contains('--ar');
  final Map<String, String> ar = avecAr
      ? _aplatir(_lire(_fichierAr))
      : <String, String>{};

  final Map<String, List<String>> groupes = <String, List<String>>{};
  for (final MapEntry<String, String> e in fr.entries) {
    final String valeur = e.value.trim();
    if (valeur.isEmpty) continue;
    groupes.putIfAbsent(valeur, () => <String>[]).add(e.key);
  }
  final List<MapEntry<String, List<String>>> doublons =
      groupes.entries
          .where((MapEntry<String, List<String>> g) => g.value.length >= 2)
          .toList()
        ..sort((
          MapEntry<String, List<String>> a,
          MapEntry<String, List<String>> b,
        ) {
          final int c = b.value.length.compareTo(a.value.length);
          return c != 0 ? c : a.key.compareTo(b.key);
        });

  for (final MapEntry<String, List<String>> g in doublons) {
    final StringBuffer ligne = StringBuffer()
      ..write(g.value.length)
      ..write('\t')
      ..write(g.key.replaceAll('\t', ' ').replaceAll('\n', r'\n'))
      ..write('\t')
      ..write(g.value.join(','));
    if (avecAr) {
      final int distinctes = g.value
          .map((String k) => (ar[k] ?? '').trim())
          .toSet()
          .length;
      ligne
        ..write('\t')
        ..write(distinctes);
    }
    stdout.writeln(ligne);
  }
}

Map<String, dynamic> _lire(String chemin) =>
    jsonDecode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

Map<String, String> _aplatir(
  Map<String, dynamic> arbre, [
  String prefixe = '',
]) {
  final Map<String, String> sortie = <String, String>{};
  arbre.forEach((String cle, dynamic v) {
    final String chemin = prefixe.isEmpty ? cle : '$prefixe.$cle';
    if (v is Map<String, dynamic>) {
      sortie.addAll(_aplatir(v, chemin));
    } else if (v is String) {
      sortie[chemin] = v;
    }
  });
  return sortie;
}
