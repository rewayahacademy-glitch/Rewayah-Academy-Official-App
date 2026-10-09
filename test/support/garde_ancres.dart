// DUREE-INSECABLE-4 : garde de source des ancres de sens (U+200E) glissees au
// milieu d'un libelle.
//
// L'ancre de sens n'a de raison qu'en TETE de libelle (U+200E devant « 45 min » en
// interface de droite a gauche). La garde de DUREE-INSECABLE-3 ne voyait que
// l'appel ancre pose directement dans un libelle (`t.x(valeur:
// valeurSeule(...))`). Elle laissait passer la valeur ancree RANGEE dans une
// variable ou rendue par une fonction, puis inseree dans un autre libelle :
//
//   final String duree = LibellesGroupe.valeurSeule(h.duree(...));
//   ... h.meta(heure: ..., duree: duree)      // ancre au milieu
//
// Ici, chaque valeur ancree est SUIVIE : on part de chaque appel qui ancre
// (`valeurSeule`, `dureeSeule`, `ancreSens`, `heureEtVille`), on regarde ou
// va sa valeur, et on suit la variable ou la fonction qui la recoit jusqu'a
// son affichage. Une faute est une valeur ancree qui finit :
//   - en argument d'un libelle (`t.a.b(x: ...)`, ou un alias de `t`) ;
//   - interpolee dans une chaine ailleurs qu'en tete (`'... $duree'`) ;
//   - concatenee derriere autre chose (`a + duree`) ;
//   - element d'une liste jointe (`[role, duree].join(' · ')`).
//
// L'analyse lit un source « masque » : commentaires effaces, contenu des
// chaines remplace (les interpolations restent du code).
//
// Reprise (relecture adverse) : une valeur rangee dans un CHAMP d'objet
// (argument nomme d'un constructeur) n'est pas toujours affichee seule. Une
// `ColonneDonnees` repliee en carte voit son `texte:` JOINT aux autres
// colonnes par « · » (« Enseignant · En attente · 12 jours »). La garde
// releve donc d'abord, dans tout le source, les champs que du code joint
// lui-meme (`.map((C c) => c.champ(...))` ... `.join(`) ; une valeur ancree
// qui finit dans l'argument `champ:` d'un constructeur `C(` est une faute.
// Un composant qui joint par `enchainer` (lib/core/i18n/isolat_bidi.dart),
// qui ne garde l'ancre qu'en tete de ligne, n'est pas releve.

import 'dart:io';

import 'garde_durees.dart' show sourcesDart;

/// Une valeur ancree qui finit au milieu d'un libelle.
typedef AncreGlissee = ({String fichier, int ligne, String raison});

/// Les appels qui posent l'ancre de sens.
final RegExp _appelAncre = RegExp(
  r'(?<![\w.$])(?:LibellesGroupe\.)?(valeurSeule|dureeSeule|ancreSens|heureEtVille)\(',
);

/// Les mots de controle qui precedent une parenthese sans etre une fonction.
const Set<String> _motsDeControle = <String>{
  'if',
  'for',
  'while',
  'switch',
  'catch',
  'return',
};

/// Le source [s] masque : memes longueur et positions, commentaires en
/// espaces, contenu des chaines en `_` (guillemets et interpolations gardes).
String masquer(String s) => _Masque(s).resultat();

class _Masque {
  _Masque(this.s) : out = s.split('');

  final String s;
  final List<String> out;

  static final RegExp _mot = RegExp(r'\w');

  String resultat() {
    _code(0);
    return out.join();
  }

  int _code(int i, {bool interpolation = false}) {
    int profondeur = 0;
    while (i < s.length) {
      final String c = s[i];
      if (s.startsWith('//', i)) {
        while (i < s.length && s[i] != '\n') {
          out[i++] = ' ';
        }
        continue;
      }
      if (s.startsWith('/*', i)) {
        int d = 0;
        do {
          if (s.startsWith('/*', i)) {
            d++;
            out[i] = out[i + 1] = ' ';
            i += 2;
          } else if (s.startsWith('*/', i)) {
            d--;
            out[i] = out[i + 1] = ' ';
            i += 2;
          } else {
            if (s[i] != '\n') out[i] = ' ';
            i++;
          }
        } while (d > 0 && i < s.length);
        continue;
      }
      if (c == "'" || c == '"') {
        final bool brute =
            i > 0 && s[i - 1] == 'r' && (i < 2 || !_mot.hasMatch(s[i - 2]));
        i = _chaine(i, brute: brute);
        continue;
      }
      if (interpolation) {
        if (c == '{') {
          profondeur++;
        } else if (c == '}') {
          if (profondeur == 0) return i;
          profondeur--;
        }
      }
      i++;
    }
    return i;
  }

  int _chaine(int i, {required bool brute}) {
    final String q = s[i];
    final String fin = s.startsWith('$q$q$q', i) ? '$q$q$q' : q;
    i += fin.length;
    while (i < s.length) {
      if (s.startsWith(fin, i)) return i + fin.length;
      final String c = s[i];
      if (!brute && c == r'\') {
        out[i] = '_';
        if (i + 1 < s.length) out[i + 1] = '_';
        i += 2;
        continue;
      }
      if (!brute && c == r'$') {
        if (i + 1 < s.length && s[i + 1] == '{') {
          i = _code(i + 2, interpolation: true) + 1;
          continue;
        }
        i++;
        while (i < s.length && _mot.hasMatch(s[i])) {
          i++;
        }
        continue;
      }
      if (c == '\n' && fin.length == 1) return i;
      if (c != '\n') out[i] = '_';
      i++;
    }
    return i;
  }
}

/// Un source masque, avec ses paires de crochets.
class _Source {
  _Source(this.fichier, String brut) : m = masquer(brut) {
    final List<int> pile = <int>[];
    parent = List<int>.filled(m.length + 1, -1);
    paire = <int, int>{};
    for (int i = 0; i < m.length; i++) {
      parent[i] = pile.isEmpty ? -1 : pile.last;
      final String c = m[i];
      if (c == '(' || c == '[' || c == '{') {
        pile.add(i);
      } else if ((c == ')' || c == ']' || c == '}') && pile.isNotEmpty) {
        final int o = pile.removeLast();
        paire[o] = i;
        paire[i] = o;
        parent[i] = pile.isEmpty ? -1 : pile.last;
      }
    }
    parent[m.length] = -1;
    for (final RegExpMatch a in _aliasT.allMatches(m)) {
      alias.add(a[1]!);
    }
  }

  final String fichier;
  final String m;
  late final List<int> parent;
  late final Map<int, int> paire;
  final Set<String> alias = <String>{};

  static final RegExp _aliasT = RegExp(
    r'final\s+(?:[\w<>?]+\s+)?(\w+)\s*=\s*t(?:\.\w+)+\s*;',
  );

  int ligne(int i) => '\n'.allMatches(m.substring(0, i)).length + 1;

  /// Le crochet ouvrant qui contient [i] (exclu), ou -1.
  int ouvrant(int i) {
    // `parent[i]` est le crochet ouvert au moment de lire [i] ; si [i] est
    // lui-meme un ouvrant, son parent est le crochet du dessus.
    return parent[i];
  }

  /// Le dernier caractere non blanc avant [i], ou -1.
  int avant(int i) {
    int j = i - 1;
    while (j >= 0 && m[j].trim().isEmpty) {
      j--;
    }
    return j;
  }

  /// La chaine d'identifiants pointee qui finit juste avant [i]
  /// (`LibellesGroupe.insecable`, `t.a.b`, `Text`), et sa position.
  ({String nom, int debut}) appelant(int i) {
    int fin = i;
    while (fin > 0 && (m[fin - 1] == ' ' || m[fin - 1] == '\n')) {
      fin--;
    }
    int k = fin - 1;
    while (k >= 0 && RegExp(r'[\w.?!]').hasMatch(m[k])) {
      k--;
    }
    return (nom: m.substring(k + 1, fin), debut: k + 1);
  }

  /// La fin du segment de meme niveau qui precede [p] dans le crochet [o] :
  /// la position qui suit le dernier `;`, `}` ou (si [virgule]) `,` de niveau
  /// zero.
  int debutSegment(int o, int p, {required bool virgule}) {
    int j = p - 1;
    while (j > o) {
      final String c = m[j];
      if (c == ')' || c == ']') {
        j = paire[j]! - 1;
        continue;
      }
      if (c == '}') {
        // Fin d'un bloc precedent : frontiere d'instruction.
        return j + 1;
      }
      if (c == ';' || (virgule && c == ',')) return j + 1;
      j--;
    }
    return o + 1;
  }

  /// Vrai si le crochet `{` en [o] ouvre le corps d'un `switch`.
  bool corpsDeSwitch(int o) {
    final int j = avant(o);
    if (j < 0 || m[j] != ')') return false;
    final int ouv = paire[j]!;
    return appelant(ouv).nom == 'switch';
  }

  /// La fonction (ou l'accesseur) qui contient [i] : nom, statique, classe.
  ({String nom, bool statique, String? classe})? fonctionAutour(int i) {
    int o = ouvrant(i);
    while (o >= 0) {
      if (m[o] == '{') {
        int j = avant(o);
        if (j >= 4 && m.substring(j - 4, j + 1) == 'async') j = avant(j - 4);
        String? nom;
        int debutEntete = -1;
        if (j >= 0 && m[j] == ')') {
          final ({String nom, int debut}) a = appelant(paire[j]!);
          final String n = a.nom.split('.').last;
          if (!_motsDeControle.contains(n) && n.isNotEmpty) {
            nom = n;
            debutEntete = a.debut;
          }
        } else if (j >= 0) {
          final ({String nom, int debut}) a = appelant(j + 1);
          final int k = avant(a.debut);
          if (k >= 2 && m.substring(k - 2, k + 1) == 'get') {
            nom = a.nom;
            debutEntete = a.debut;
          }
        }
        if (nom != null) {
          final int d = debutSegment(ouvrant(o), debutEntete, virgule: false);
          return (
            nom: nom,
            statique: m.substring(d, debutEntete).contains('static'),
            classe: classeAutour(o),
          );
        }
      }
      o = ouvrant(o);
    }
    return null;
  }

  /// Le nom de la classe (ou de l'extension) dont le corps contient [i].
  String? classeAutour(int i) {
    int o = ouvrant(i);
    while (o >= 0) {
      if (m[o] == '{') {
        final int d = debutSegment(ouvrant(o), o, virgule: false);
        final RegExpMatch? c = RegExp(r'\b(?:class|extension|mixin)\s+(\w+)')
            .firstMatch(m.substring(d, o));
        if (c != null) return c[1];
      }
      o = ouvrant(o);
    }
    return null;
  }
}

/// Ou finit une valeur.
sealed class _Destination {
  const _Destination();
}

class _Affichee extends _Destination {
  const _Affichee();
}

class _Faute extends _Destination {
  const _Faute(this.raison);
  final String raison;
}

class _Variable extends _Destination {
  const _Variable(this.nom, this.declaration, this.portee);
  final String nom;
  final int declaration;
  final int portee;
}

class _Fonction extends _Destination {
  const _Fonction(this.nom, this.statique, this.classe, this.declaration);
  final String nom;
  final bool statique;
  final String? classe;
  final int declaration;
}

final RegExp _affectation = RegExp(r'(?<![=!<>])\b(\w+)\s*(?:\?\?)?=(?![=>])');
final RegExp _flecheFonction = RegExp(
  r'(?:\bget\s+(\w+)|(\w+)\s*(?:<[^>]*>)?\s*\([^]*\))\s*(?:async\s*)?=>\s*$',
);

/// Les noms d'appels qui laissent la valeur telle quelle (elle reste en tete).
const Set<String> _transparents = <String>{
  'insecable',
  'valeurSeule',
  'ancreSens',
  'dureeSeule',
};

_Destination _classer(_Source s, int p, Set<ChampJoint> joints) {
  // Concatenation derriere autre chose.
  final int a = s.avant(p);
  if (a >= 0 && s.m[a] == '+' && (a == 0 || s.m[a - 1] != '+')) {
    return const _Faute('concatenee derriere un texte');
  }
  final int o = s.ouvrant(p);
  if (o < 0) return _instruction(s, -1, p);
  final String c = s.m[o];
  if (c == '(') {
    // Argument nomme d'un constructeur dont le champ est joint ailleurs.
    final int d = s.debutSegment(o, p, virgule: true);
    final RegExpMatch? nomme = RegExp(r'^\s*(\w+)\s*:')
        .firstMatch(s.m.substring(d, p));
    if (nomme != null) {
      final String classe = _constructeur(s, o).split('.').last;
      if (joints.contains((classe: classe, champ: nomme[1]!))) {
        return _Faute(
          'champ ${nomme[1]} de $classe, joint a d\'autres colonnes',
        );
      }
    }
    final ({String nom, int debut}) app = s.appelant(o);
    final String nom = app.nom;
    if (nom.isEmpty) return _classer(s, o, joints);
    final String tete = nom.split('.').first;
    if (nom.startsWith('t.') || s.alias.contains(tete)) {
      return _Faute('argument du libelle $nom');
    }
    if (_transparents.contains(nom.split('.').last)) {
      return _classer(s, app.debut, joints);
    }
    return const _Affichee();
  }
  if (c == '[') {
    final int? fin = s.paire[o];
    if (fin != null && s.m.startsWith('.join(', fin + 1)) {
      return const _Faute('element d\'une liste jointe');
    }
    return const _Affichee();
  }
  // `{`
  if (o > 0 && s.m[o - 1] == r'$') {
    final int q = o - 2;
    if (q >= 0 && (s.m[q] == "'" || s.m[q] == '"')) {
      int debut = q;
      while (debut > 0 && s.m[debut - 1] == s.m[q]) {
        debut--;
      }
      return _classer(s, debut, joints);
    }
    return const _Faute('interpolee au milieu d\'une chaine');
  }
  if (s.corpsDeSwitch(o)) {
    final int d = s.debutSegment(o, p, virgule: true);
    if (s.m.substring(d, p).contains('=>')) {
      final int fermante = s.avant(o);
      return _classer(s, s.appelant(s.paire[fermante]!).debut, joints);
    }
  }
  return _instruction(s, o, p);
}

_Destination _instruction(_Source s, int o, int p) {
  final int d = s.debutSegment(o, p, virgule: false);
  final String segment = s.m.substring(d, p);
  if (RegExp(r'\breturn\s*$').hasMatch(segment)) {
    final ({String nom, bool statique, String? classe})? f = s.fonctionAutour(
      p,
    );
    if (f == null) return const _Affichee();
    return _Fonction(f.nom, f.statique, f.classe, p);
  }
  final RegExpMatch? fleche = _flecheFonction.firstMatch(segment);
  if (fleche != null) {
    final String nom = fleche[1] ?? fleche[2]!;
    return _Fonction(
      nom,
      segment.contains('static'),
      s.classeAutour(p),
      d + fleche.start,
    );
  }
  final RegExpMatch? aff = _affectation.firstMatch(segment);
  if (aff != null) {
    final int fin = o < 0 ? s.m.length : (s.paire[o] ?? s.m.length);
    return _Variable(aff[1]!, d + aff.start, fin);
  }
  return const _Affichee();
}

/// Un champ d'objet que du code joint a d'autres textes : `(classe, champ)`.
typedef ChampJoint = ({String classe, String champ});

/// `.map((C c) => c.champ` : le parametre type, son nom, le champ lu.
final RegExp _mapChamp = RegExp(
  r'\.map\(\s*\(\s*(\w+)(?:<[\w<>?, ]*>)?\s+(\w+)\s*\)\s*=>\s*(\w+)\.(\w+)',
);

/// Les champs que [sources] joignent par `.join(` (et non par `enchainer`).
Set<ChampJoint> champsJoints(Iterable<String> sourcesMasquees) => <ChampJoint>{
  for (final String m in sourcesMasquees)
    for (final RegExpMatch x in _mapChamp.allMatches(m))
      if (x[2] == x[3] && _suiviDeJoin(m, x.end)) (classe: x[1]!, champ: x[4]!),
};

/// Vrai si l'instruction qui contient [i] se poursuit par `.join(`.
bool _suiviDeJoin(String m, int i) {
  int fin = m.indexOf(';', i);
  if (fin < 0) fin = m.length;
  return m.substring(i, fin).contains('.join(');
}

/// Le nom du constructeur appele par la parenthese [o], arguments de type
/// omis (`ColonneDonnees<CompteAdmin>(` donne `ColonneDonnees`).
String _constructeur(_Source s, int o) {
  int j = s.avant(o);
  if (j < 0 || s.m[j] != '>') return s.appelant(o).nom;
  int profondeur = 0;
  while (j >= 0) {
    if (s.m[j] == '>') profondeur++;
    if (s.m[j] == '<') {
      profondeur--;
      if (profondeur == 0) break;
    }
    j--;
  }
  return j < 0 ? '' : s.appelant(j).nom;
}

/// Toutes les valeurs ancrees de [sources] qui finissent au milieu d'un
/// libelle.
List<AncreGlissee> ancresGlissees([Iterable<File>? sources]) {
  final List<_Source> fichiers = <_Source>[
    for (final File f in sources ?? sourcesDart())
      _Source(f.path, f.readAsStringSync()),
  ];
  final List<AncreGlissee> fautes = <AncreGlissee>[];
  final Set<String> vus = <String>{};
  final Set<ChampJoint> joints = champsJoints(<String>[
    for (final _Source s in fichiers) s.m,
  ]);
  final List<({_Source s, int p, String chemin})> aSuivre =
      <({_Source s, int p, String chemin})>[];

  for (final _Source s in fichiers) {
    for (final RegExpMatch m in _appelAncre.allMatches(s.m)) {
      // Une declaration (`static String valeurSeule(String texte)`) n'est pas
      // un appel.
      final int a = s.avant(m.start);
      if (a >= 0 && RegExp(r'[\w?>]').hasMatch(s.m[a])) {
        final ({String nom, int debut}) mot = s.appelant(a + 1);
        if (mot.nom == 'String' || mot.nom == 'String?') continue;
      }
      aSuivre.add((s: s, p: m.start, chemin: m[1]!));
    }
  }

  final Set<String> fonctionsSuivies = <String>{};
  while (aSuivre.isNotEmpty) {
    final ({_Source s, int p, String chemin}) x = aSuivre.removeLast();
    final String cle = '${x.s.fichier}:${x.p}';
    if (!vus.add(cle)) continue;
    switch (_classer(x.s, x.p, joints)) {
      case _Affichee():
        break;
      case _Faute(:final String raison):
        fautes.add((
          fichier: x.s.fichier,
          ligne: x.s.ligne(x.p),
          raison: '${x.chemin} : $raison',
        ));
      case _Variable(
        :final String nom,
        :final int declaration,
        :final int portee,
      ):
        final RegExp usage = RegExp(
          '(?<![\\w.])${RegExp.escape(nom)}(?![\\w:])',
        );
        for (final RegExpMatch u in usage.allMatches(x.s.m, declaration)) {
          if (u.start >= portee) break;
          if (u.start == declaration) continue;
          // `nom = ...` : une nouvelle affectation n'est pas une lecture.
          if (RegExp(r'^\s*=(?![=>])').hasMatch(x.s.m.substring(u.end))) {
            continue;
          }
          final int debut = u.start > 0 && x.s.m[u.start - 1] == r'$'
              ? u.start - 1
              : u.start;
          if (debut != u.start) {
            // `$nom` dans une chaine.
            final int q = debut - 1;
            if (q >= 0 && (x.s.m[q] == "'" || x.s.m[q] == '"')) {
              aSuivre.add((s: x.s, p: q, chemin: '${x.chemin} > $nom'));
            } else {
              fautes.add((
                fichier: x.s.fichier,
                ligne: x.s.ligne(u.start),
                raison: '${x.chemin} > $nom : interpolee au milieu',
              ));
            }
            continue;
          }
          aSuivre.add((s: x.s, p: u.start, chemin: '${x.chemin} > $nom'));
        }
      case _Fonction(
        :final String nom,
        :final bool statique,
        :final String? classe,
      ):
        final String id = '${x.s.fichier}#$classe.$nom';
        if (!fonctionsSuivies.add(id)) break;
        final bool privee = nom.startsWith('_');
        for (final _Source autre in fichiers) {
          if (privee && autre != x.s) continue;
          final String motif;
          if (autre == x.s) {
            motif = '(?<![\\w])(?:\\w+\\.)?${RegExp.escape(nom)}(?![\\w:])';
          } else if (classe == null) {
            motif = '(?<![\\w.])${RegExp.escape(nom)}(?![\\w:])';
          } else if (statique) {
            motif = '(?<![\\w.])$classe\\.${RegExp.escape(nom)}(?![\\w:])';
          } else {
            motif = '(?<=\\w[.?]|\\)\\.)${RegExp.escape(nom)}(?![\\w:])';
          }
          for (final RegExpMatch u in RegExp(motif).allMatches(autre.m)) {
            // La declaration elle-meme.
            final String apres = autre.m.substring(u.end);
            final int a = autre.avant(u.start);
            final bool declaration =
                a >= 0 &&
                RegExp(r'[\w?>]').hasMatch(autre.m[a]) &&
                // `=> f(` est un appel, pas un type de retour generique.
                !(autre.m[a] == '>' && a > 0 && autre.m[a - 1] == '=') &&
                !RegExp(r'\b(return|await|case|else)$')
                    .hasMatch(autre.m.substring(0, a + 1)) &&
                RegExp(r'^\s*(\(|=>|\{)').hasMatch(apres) &&
                !autre.m.substring(0, u.start).endsWith('.');
            if (declaration) continue;
            // `t.x.contexte(` : un libelle du meme nom, pas la fonction.
            final ({String nom, int debut}) chaine = autre.appelant(u.end);
            if (chaine.nom.startsWith('t.') ||
                autre.alias.contains(chaine.nom.split('.').first)) {
              continue;
            }
            aSuivre.add((
              s: autre,
              p: chaine.debut,
              chemin: '${x.chemin} > $nom',
            ));
          }
        }
    }
  }
  fautes.sort(
    (AncreGlissee a, AncreGlissee b) =>
        '${a.fichier}:${a.ligne.toString().padLeft(5)}'.compareTo(
          '${b.fichier}:${b.ligne.toString().padLeft(5)}',
        ),
  );
  return fautes;
}
