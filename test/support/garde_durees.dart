// DUREE-INSECABLE-3 : garde de source, appel par appel, des libelles a duree
// ou a unite.
//
// La garde de DUREE-INSECABLE-2 cherchait `insecable(` dans les 400
// caracteres qui precedaient un appel : l'enveloppe de l'appel voisin
// suffisait, et un appel remis a nu passait. Ici, chaque appel est juge seul :
// l'appel qui l'entoure IMMEDIATEMENT (la parenthese ouvrante non fermee la
// plus proche) doit etre `insecable(` ou `valeurSeule(`.
//
// Les libelles gardes ne sont pas une liste tenue a la main : ce sont tous les
// libelles francais ou un parametre est suivi d'une unite (« {minutes} min »,
// « {n} s », « {jours} jours », « {heure} h »...). Un libelle a unite ajoute
// demain est garde sans qu'on y pense.

import 'dart:convert';
import 'dart:io';

/// Un appel a un libelle a unite, dans `lib/`.
typedef AppelLibelle = ({
  String fichier,
  int ligne,
  String cle,
  String enveloppe,
});

/// Les unites qui suivent un parametre dans un libelle a duree ou a unite.
final RegExp _parametreEtUnite = RegExp(
  r'\{\w+\}[  ]?'
  r'(min|s|h|j|sem\.|minutes?|secondes?|heures?|jours?|semaines?)'
  r'(?=$|[\s.,;:)!?])',
);

/// Les noms de formes plurielles de slang : une cle dont les enfants sont
/// tous de ces noms est UN libelle (`visites(n: ...)`).
const Set<String> _formesPlurielles = <String>{
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
};

/// Les cles (chemin pointe) des libelles francais a unite.
List<String> libellesAUnite({String fichier = 'assets/i18n/fr.i18n.json'}) {
  final Object? racine = jsonDecode(File(fichier).readAsStringSync());
  final List<String> cles = <String>[];
  void parcourir(Object? noeud, List<String> chemin) {
    if (noeud is String) {
      if (_parametreEtUnite.hasMatch(noeud)) cles.add(chemin.join('.'));
      return;
    }
    if (noeud is! Map<String, Object?> || noeud.isEmpty) return;
    if (noeud.keys.every(_formesPlurielles.contains)) {
      if (noeud.values.whereType<String>().any(_parametreEtUnite.hasMatch)) {
        cles.add(chemin.join('.'));
      }
      return;
    }
    noeud.forEach(
      (String k, Object? v) => parcourir(v, <String>[...chemin, k]),
    );
  }

  parcourir(racine, <String>[]);
  return cles;
}

/// Les sources Dart de `lib/`, hors code genere et hors outils de
/// developpement (`_dev/`, force a faux en production).
Iterable<File> sourcesDart() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (File f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.contains(
                '${Platform.pathSeparator}_dev${Platform.pathSeparator}',
              ),
        );

/// Le nom de l'appel qui entoure immediatement la position [i] de [source] :
/// `LibellesGroupe.insecable`, `Text`, ou `''` si [i] n'est dans aucune
/// parenthese.
String enveloppe(String source, int i) {
  int profondeur = 0;
  for (int j = i - 1; j >= 0; j--) {
    final String c = source[j];
    if (c == ')') {
      profondeur++;
    } else if (c == '(') {
      if (profondeur > 0) {
        profondeur--;
        continue;
      }
      int k = j - 1;
      while (k >= 0 && RegExp(r'[\w.]').hasMatch(source[k])) {
        k--;
      }
      return source.substring(k + 1, j);
    }
  }
  return '';
}

/// Un appel de libelle : `t.a.b.c(` ou `alias.b.c(`.
final RegExp _appel = RegExp(r'(?<![\w.])([A-Za-z_]\w*)((?:\.\w+)+)\(');

/// Un alias de libelles : `final e = t.tuteur.accueil.etatCourt;`.
final RegExp _alias = RegExp(
  r'final\s+(?:[\w<>?]+\s+)?(\w+)\s*=\s*(t(?:\.\w+)+)\s*;',
);

/// Tous les appels, dans [sources], des libelles [cles]. Les alias locaux
/// (`final h = t.controleur.historique;` puis `h.duree(`) sont suivis : la
/// derniere declaration qui precede l'appel decide.
List<AppelLibelle> appelsDe(Iterable<String> cles, Iterable<File> sources) {
  final Set<String> voulues = cles.toSet();
  final List<AppelLibelle> appels = <AppelLibelle>[];
  for (final File f in sources) {
    final String source = f.readAsStringSync();
    final List<({int position, String nom, String chemin})> alias =
        <({int position, String nom, String chemin})>[
          for (final RegExpMatch m in _alias.allMatches(source))
            (position: m.start, nom: m[1]!, chemin: m[2]!),
        ];
    for (final RegExpMatch m in _appel.allMatches(source)) {
      final String tete = m[1]!;
      final String suite = m[2]!;
      String? chemin;
      if (tete == 't') {
        chemin = 't$suite';
      } else {
        for (final ({int position, String nom, String chemin}) a in alias) {
          if (a.position >= m.start) break;
          if (a.nom == tete) chemin = '${a.chemin}$suite';
        }
      }
      if (chemin == null) continue;
      final String cle = chemin.substring(2);
      if (!voulues.contains(cle)) continue;
      appels.add((
        fichier: f.path,
        ligne: '\n'.allMatches(source.substring(0, m.start)).length + 1,
        cle: cle,
        enveloppe: enveloppe(source, m.start),
      ));
    }
  }
  return appels;
}

/// Vrai si [enveloppe] rend la duree insecable.
bool estInsecable(String enveloppe) {
  final String nom = enveloppe.split('.').last;
  return nom == 'insecable' || nom == 'valeurSeule';
}
