// CPT-DIR-2, Q-10 = a (decide par delegation le 05/10) : tout l'espace
// Comptable est traduit en arabe. Ce test echoue des qu'une cle `comptable.*`,
// `admin.finance.aValider` ou un texte des composants partages affiches dans
// l'espace Comptable manque dans `assets/i18n/ar.i18n.json`, est vide, ou n'a
// pas les memes parametres que le francais. slang retomberait sinon en
// silence sur le francais (fallback_strategy: base_locale).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les formes du pluriel reconnues par slang.
const Set<String> _formesPluriel = <String>{
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
};

/// Les textes des composants partages que l'espace Comptable affiche hors
/// de `comptable.*` (etats systeme, dates du journal, choix, confirmation
/// destructive, bandeau hors ligne, coquille).
const List<String> _prefixesPartages = <String>[
  'commun.etats.',
  'commun.dates.jours',
  'commun.dates.mois',
  'commun.dates.jourDate',
  'commun.reessayer',
  'commun.annuler',
  'commun.choix.indisponible',
  'commun.sections.page',
  'choix.',
  'destructif.irreversible',
  'reseau.horsLigne',
  'nav.principale',
  'nav.replier',
  'nav.deplier',
];

/// Vrai pour une cle que l'arabe doit porter.
bool estCleComptable(String cle) =>
    cle.startsWith('comptable.') ||
    cle == 'admin.finance.aValider' ||
    _prefixesPartages.any(
      (String p) => p.endsWith('.') ? cle.startsWith(p) : cle == p,
    );

/// Les feuilles d'un fichier slang : une chaine, une liste, ou une table de
/// pluriel (gardee entiere).
Map<String, Object> feuilles(Map<String, dynamic> arbre, [String chemin = '']) {
  final Map<String, Object> sortie = <String, Object>{};
  arbre.forEach((String cle, dynamic valeur) {
    final String ici = '$chemin$cle';
    if (valeur is Map<String, dynamic>) {
      if (valeur.isNotEmpty && _formesPluriel.containsAll(valeur.keys)) {
        sortie[ici] = valeur;
      } else {
        sortie.addAll(feuilles(valeur, '$ici.'));
      }
    } else {
      sortie[ici] = valeur as Object;
    }
  });
  return sortie;
}

/// Les parametres `{x}` d'une valeur (chaine, liste ou pluriel).
Set<String> parametres(Object valeur) =>
    RegExp(r'\{(\w+)\}')
        .allMatches(jsonEncode(valeur))
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

/// Les ecarts entre le francais et l'arabe, une ligne par cle fautive.
List<String> ecarts(Map<String, Object> fr, Map<String, Object> ar) {
  final List<String> fautes = <String>[];
  for (final MapEntry<String, Object> e in fr.entries) {
    if (!estCleComptable(e.key)) continue;
    final Object? traduit = ar[e.key];
    if (traduit == null) {
      fautes.add('manquante : ${e.key}');
      continue;
    }
    if (jsonEncode(traduit).replaceAll(RegExp(r'[\s"\[\]{},:]'), '').isEmpty) {
      fautes.add('vide : ${e.key}');
      continue;
    }
    final Object source = e.value;
    if (source is List &&
        (traduit is! List || traduit.length != source.length)) {
      fautes.add('liste de taille differente : ${e.key}');
      continue;
    }
    // Un pluriel peut ajouter ou retirer {n} d'une forme a l'autre.
    final bool pluriel = source is Map;
    Set<String> sans(Set<String> s) => pluriel ? (s..remove('n')) : s;
    final Set<String> attendus = sans(parametres(source));
    final Set<String> trouves = sans(parametres(traduit));
    if (attendus.length != trouves.length || !attendus.containsAll(trouves)) {
      fautes.add('parametres ${e.key} : $attendus / $trouves');
    }
    if (traduit is Map && !traduit.containsKey('other')) {
      fautes.add('pluriel sans « other » : ${e.key}');
    }
  }
  return fautes;
}

Map<String, Object> _lire(String chemin) => feuilles(
  jsonDecode(File(chemin).readAsStringSync()) as Map<String, dynamic>,
);

void main() {
  final Map<String, Object> fr = _lire('assets/i18n/fr.i18n.json');
  final Map<String, Object> ar = _lire('assets/i18n/ar.i18n.json');

  test('chaque cle de l espace Comptable existe en arabe, non vide, '
      'avec les memes parametres', () {
    expect(ecarts(fr, ar), isEmpty);
  });

  test('le perimetre couvre tout comptable.* et l onglet A valider', () {
    final int comptable = fr.keys
        .where((String k) => k.startsWith('comptable.'))
        .length;
    expect(comptable, greaterThan(800));
    expect(fr.containsKey('admin.finance.aValider'), isTrue);
    expect(fr.keys.where(estCleComptable).length, greaterThan(comptable));
  });

  test('contre-epreuve : une cle retiree, un parametre perdu, une liste '
      'tronquee sont signales', () {
    final Map<String, Object> retire = Map<String, Object>.of(ar)
      ..remove('comptable.paiements.titre')
      ..remove('admin.finance.aValider');
    expect(
      ecarts(fr, retire),
      containsAll(<String>[
        'manquante : comptable.paiements.titre',
        'manquante : admin.finance.aValider',
      ]),
    );

    final Map<String, Object> sansParametre = Map<String, Object>.of(ar)
      ..['comptable.commun.atteint'] = 'تحقق';
    expect(
      ecarts(fr, sansParametre).single,
      startsWith('parametres comptable.commun.atteint'),
    );

    final Map<String, Object> vide = Map<String, Object>.of(ar)
      ..['comptable.nav.compte'] = ' ';
    expect(ecarts(fr, vide), <String>['vide : comptable.nav.compte']);

    final Map<String, Object> tronquee = Map<String, Object>.of(ar)
      ..['commun.dates.mois'] = <String>['يناير'];
    expect(ecarts(fr, tronquee), <String>[
      'liste de taille differente : commun.dates.mois',
    ]);
  });
}
