// Contrat K7 : aucun double n'est servi par un provider de production.
//
// Regle du mandat (section 3) : les fixtures vivent dans les tests ou dans un
// environnement de demonstration explicitement isole (Playground, sous
// `PLAYGROUND=true`), jamais comme repli silencieux de production.
//
// **Controle lexical, volontairement simple.** Il lit le corps de chaque
// provider declare dans `lib/` (hors `lib/features/_dev/` et hors fichiers
// generes) et refuse toute instanciation d'un nom en `Faux*`,
// `*Demonstration*`, `*Memoire` ou `*Local(e)(s)`, sauf si ce corps passe par
// `Env.playgroundActif`. Limites connues : un double instancie dans le
// `build()` d'un `Notifier`, ou dans une fonction appelee par le provider, lui
// echappe ; le patron du depot (selecteur `...Selon(demo: Env.playgroundActif)`
// appele depuis le provider) est, lui, reconnu.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les noms qui designent un double.
///
/// `*Local`, `*Locale(s)` ajoutes par la revue phase 0 (routes D9) :
/// `CatalogueLocal()` servait une liste vide trompeuse a la production sans
/// etre releve.
final RegExp _double = RegExp(
  r'(?<![\w.])(Faux\w*|\w*Demonstration\w*|\w*Memoire|\w*Locale?s?)'
  r'\s*(?:<[^()]*>)?\s*\(',
);

/// Le debut d'une declaration de provider Riverpod.
final RegExp _provider = RegExp(
  r'\b(?:Future|Stream|Notifier|AsyncNotifier|State)?Provider\b'
  r'(?:\.(?:family|autoDispose))*\s*',
);

/// Implementations en memoire LEGITIMES : ce ne sont pas des donnees
/// fictives, mais le seul stockage prevu de leur etat. Exemption NOMINATIVE.
const Map<String, String> _memoiresLegitimes = <String, String>{
  // Position du dock enseignant a l'ecran : une preference d'interface qui ne
  // vit que le temps de la session, par conception.
  'PositionDockMemoire': 'lib/core/tc_outils/etat_outils.dart',
  // Etat partage du Teaching Core, lots presents et testes mais non branches
  // depuis `main` (CLAUDE.md, « Etat du code a connaitre ») : sa persistance
  // serveur reste a ecrire, et aucune donnee fictive n'y est semee.
  'EtatPartageMemoire':
      'lib/core/tc_etat_partage/providers_tc_etat_partage.dart',
  // Stockage de la preference d'apparence sur le web (phase 0b) : la base
  // locale Drift n'y est pas configuree, le theme choisi vit donc le temps de
  // la session. Il part vide, aucune valeur fictive n'y est semee ; hors web,
  // le meme provider sert `StockagePreferencesDrift`. Releve a la fusion de
  // 0d dans `ui/tuteur-v1` (phase 0c1).
  'StockagePreferencesMemoire': 'lib/core/preferences/preferences_locales.dart',
  // Brouillons des communications (COM-F, spec Communications V1 section 8.2
  // et section 20) : la memoire de session est le comportement V1 retenu,
  // aucun stockage local n'etant approuve pour le texte d'un message. Elle
  // part vide, aucune donnee fictive n'y est semee, et elle est videe quand
  // la personne connectee change (COM-BR-12).
  'BrouillonsMemoire': 'lib/core/communications/port_brouillons.dart',
};

/// Dette connue : doubles encore servis sans condition a la production, par
/// nom et fichier. Exemption NOMINATIVE et temporaire : une entree doit etre
/// retiree des que sa dette est resorbee, le second test l'exige.
///
/// Les deux entrees d'origine (`GroupesDemonstrationLocale` de
/// `port_groupes.dart`, `HorlogeSeanceDemonstration` de
/// `port_horloge_seance.dart`) sont resorbees par la reprise de `33503fe`
/// (phase 0, point P8).
const Map<String, String> _detteConnue = <String, String>{
  // La Bibliotheque sert un catalogue local vide et ses versions en
  // production (`portCatalogueProvider`, `portVersionsProvider`) : une liste
  // vide trompeuse, que les principes de `00_CONTRATS_PARTAGES` interdisent.
  // Releve par la revue phase 0 (routes D9) ; a remplacer par une
  // implementation `Indisponible` ou l'adaptateur reel (lot C).
  'CatalogueLocal': 'lib/core/tc_bibliotheque/donnees_catalogue.dart',
  'VersionsLocales': 'lib/core/tc_bibliotheque/donnees_catalogue.dart',
};

/// Une instanciation de double relevee dans le corps d'un provider.
typedef Releve = ({String fichier, int ligne, String nom});

/// Releve les doubles instancies dans les providers d'un source Dart.
List<Releve> doublesDansLesProviders(String fichier, String source) {
  final String code = source
      .split('\n')
      .map((String l) {
        final int i = l.indexOf('//');
        return i == -1 ? l : l.substring(0, i);
      })
      .join('\n');
  final List<Releve> releves = <Releve>[];

  for (final RegExpMatch debut in _provider.allMatches(code)) {
    int i = debut.end;
    if (i < code.length && code[i] == '<') {
      i = _apresBalise(code, i, '<', '>');
    }
    while (i < code.length && code[i].trim().isEmpty) {
      i++;
    }
    if (i >= code.length || code[i] != '(') {
      continue;
    }
    final int fin = _apresBalise(code, i, '(', ')');
    final String corps = code.substring(i, fin);
    if (corps.contains('Env.playgroundActif')) {
      continue;
    }
    for (final RegExpMatch double in _double.allMatches(corps)) {
      final int position = i + double.start;
      releves.add((
        fichier: fichier,
        ligne: '\n'.allMatches(code.substring(0, position)).length + 1,
        nom: double.group(1)!,
      ));
    }
  }
  return releves;
}

/// L'indice qui suit la balise fermante appariee a celle ouverte en [debut].
int _apresBalise(String code, int debut, String ouvrante, String fermante) {
  int profondeur = 0;
  for (int i = debut; i < code.length; i++) {
    if (code[i] == ouvrante) {
      profondeur++;
    } else if (code[i] == fermante) {
      profondeur--;
      if (profondeur == 0) {
        return i + 1;
      }
    }
  }
  return code.length;
}

void main() {
  group('K7 : le detecteur, verifie sur des pieges', () {
    test('un double dans un provider est releve', () {
      const String piege = '''
final Provider<PortX> portXProvider = Provider<PortX>(
  (Ref ref) => FauxPortX(),
);
final FutureProvider<List<int>> listeProvider = FutureProvider<List<int>>(
  (Ref ref) async => SourceDemonstration().lire(),
);
final Provider<PortY> portYProvider =
    Provider<PortY>((Ref ref) => PortYMemoire());
final Provider<PortZ> portZProvider = Provider<PortZ>(
  (Ref ref) => CatalogueLocal(),
);
''';
      expect(
        doublesDansLesProviders('piege.dart', piege).map((Releve r) => r.nom),
        <String>[
          'FauxPortX',
          'SourceDemonstration',
          'PortYMemoire',
          'CatalogueLocal',
        ],
      );
    });

    test(
      'la branche Playground, un reel ou une fonction hors provider passent',
      () {
        const String sain = '''
PortX portXSelon({required bool demo}) => demo ? FauxPortX() : PortXReel();
final Provider<PortX> portXProvider = Provider<PortX>(
  (Ref ref) => portXSelon(demo: Env.playgroundActif),
);
final Provider<PortZ> portZProvider = Provider<PortZ>(
  (Ref ref) => const PortZIndisponible(),
);
// final Provider<PortW> ancien = Provider<PortW>((Ref ref) => FauxPortW());
''';
        expect(doublesDansLesProviders('sain.dart', sain), isEmpty);
      },
    );
  });

  group('K7 : aucun double servi par un provider de lib/', () {
    final List<Releve> releves = <Releve>[];
    for (final File fichier
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart'))) {
      final String chemin = fichier.path.replaceAll(r'\', '/');
      if (chemin.contains('lib/features/_dev/') || chemin.endsWith('.g.dart')) {
        continue;
      }
      releves.addAll(
        doublesDansLesProviders(chemin, fichier.readAsStringSync()),
      );
    }

    test('hors Playground, aucun Faux, Demonstration, Memoire ni Local', () {
      final List<String> violations = <String>[
        for (final Releve r in releves)
          if (_memoiresLegitimes[r.nom] != r.fichier &&
              _detteConnue[r.nom] != r.fichier)
            '${r.fichier}:${r.ligne} ${r.nom}',
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('chaque exemption nominative correspond encore a un releve', () {
      // Une exemption qui ne couvre plus rien doit etre retiree, pas oubliee.
      final List<String> perimees = <String>[
        for (final MapEntry<String, String> e in _memoiresLegitimes.entries)
          if (!releves.any(
            (Releve r) => r.nom == e.key && r.fichier == e.value,
          ))
            'memoire legitime ${e.key} (${e.value})',
        for (final MapEntry<String, String> e in _detteConnue.entries)
          if (!releves.any(
            (Releve r) => r.nom == e.key && r.fichier == e.value,
          ))
            'dette resorbee ${e.key} (${e.value}) : retirer l entree',
      ];
      expect(perimees, isEmpty, reason: perimees.join('\n'));
    });
  });
}
