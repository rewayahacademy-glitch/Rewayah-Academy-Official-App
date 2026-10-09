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
//
// Reprise 2 (DUREE-INSECABLE-5) : un champ est suivi a ses lectures
// `objet.champ` quel que soit le NOM de l'objet. Son type est cherche :
// ecrit, ou deduit de ce qui donne l'objet (initialisation, collection
// parcourue par `for`, recepteur d'un `.map(` qui recoit une lambda, type
// rendu d'une fonction, champ d'un autre objet). Un type deduit qui ne nomme
// pas la classe ecarte la lecture ; un type introuvable la garde si le
// fichier nomme la classe. Une valeur rangee par affectation
// (`s.duree = valeur`, `this.duree = valeur`, `duree = valeur` dans la
// classe) est suivie de meme.
//
// Reprise 3 (DUREE-INSECABLE-5, seconde relecture adverse) : un litteral
// colle derriere un autre (`'Duree : ' '${valeur}'`, sur une ou plusieurs
// lignes) n'est pas une tete de libelle, Dart concatene les deux : la valeur
// interpolee au debut du second est au milieu. Un champ lu par `this.champ`
// (dans une classe qui le porte) ou `this.objet.champ` est suivi comme
// `champ` et `objet.champ`.

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

  /// La fin de l'instruction qui commence a [i] : le premier `;` de niveau
  /// zero, ou le crochet fermant qui contient [i].
  int finInstruction(int i) {
    int j = i;
    while (j < m.length) {
      final String c = m[j];
      if (c == '(' || c == '[' || c == '{') {
        final int? f = paire[j];
        if (f == null) return m.length;
        j = f + 1;
        continue;
      }
      if (c == ';' || c == ')' || c == ']' || c == '}') return j;
      j++;
    }
    return m.length;
  }

  /// La fin du terme qui commence a [i] : un nom, ou un crochet et sa paire.
  int finTerme(int i) {
    if (i < m.length && '([{'.contains(m[i])) {
      return (paire[i] ?? i) + 1;
    }
    int j = i;
    while (j < m.length && RegExp(r'\w').hasMatch(m[j])) {
      j++;
    }
    return j;
  }

  /// Les membres appeles a la suite de [i] (`.where(...).join(...)` donne
  /// `where`, `join`), arguments de type et `!` compris.
  List<String> chaineApres(int i) {
    final List<String> noms = <String>[];
    final RegExp membre = RegExp(r'^\s*!?\s*\??\.\.?(\w+)\s*');
    int j = i;
    while (true) {
      final RegExpMatch? x = membre.firstMatch(m.substring(j));
      if (x == null) return noms;
      noms.add(x[1]!);
      j += x.end;
      if (j < m.length && m[j] == '<') {
        int profondeur = 0;
        while (j < m.length) {
          if (m[j] == '<') profondeur++;
          if (m[j] == '>' && --profondeur == 0) break;
          j++;
        }
        // Un `<` de comparaison, sans `>` : fin du source.
        if (j >= m.length) return noms;
        j++;
        while (j < m.length && m[j].trim().isEmpty) {
          j++;
        }
      }
      if (j < m.length && (m[j] == '(' || m[j] == '[')) {
        j = (paire[j] ?? j) + 1;
      }
    }
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
  const _Variable(
    this.nom,
    this.declaration,
    this.portee, {
    this.collection = false,
  });
  final String nom;
  final int declaration;
  final int portee;

  /// Vrai si la variable tient une collection (liste, table, record) qui
  /// contient la valeur, et non la valeur elle-meme.
  final bool collection;
}

class _Fonction extends _Destination {
  const _Fonction(this.nom, this.statique, this.classe, this.declaration);
  final String nom;
  final bool statique;
  final String? classe;
  final int declaration;
}

/// Un champ d'objet ou la valeur est rangee par affectation :
/// `objet.champ = valeur`, `this.champ = valeur`, ou `champ = valeur` dans
/// une classe qui declare ce champ. [classe] est null quand l'objet n'est
/// pas `this` : son type n'est pas lisible dans le source.
class _Champ extends _Destination {
  const _Champ(this.classe, this.champ, {this.recepteur});
  final String? classe;
  final String champ;

  /// La fin de l'objet qui recoit la valeur (`s` dans `s.duree = `), dont
  /// le type est cherche quand [classe] est null.
  final int? recepteur;
}

/// DUREE-INSECABLE-5 : la valeur est un argument de l'appel [nom], nomme
/// ([nomme]) ou au rang [position] parmi les arguments positionnels. On la
/// suit dans le parametre qui la recoit : champ `this.x` d'un constructeur,
/// ou variable dans le corps de la fonction, de la methode ou du
/// `copyWith`.
class _Appel extends _Destination {
  const _Appel(this.nom, this.nomme, this.position);
  final String nom;
  final String? nomme;
  final int position;
}

/// DUREE-INSECABLE-5 : la valeur est ajoutee (`add`, `insert`) a la
/// collection [recepteur], qu'il faut suivre jusqu'a un `.join(`.
class _AjouteeA extends _Destination {
  const _AjouteeA(this.recepteur);
  final String recepteur;
}

/// La classe construite par l'appel [nom] (`AffichageSeance._`,
/// `Col`, `_Colonne`), ou null pour un appel de fonction ou de methode.
String? _classeConstruite(String nom) {
  for (final String segment in nom.split('.')) {
    if (RegExp(r'^_?[A-Z]').hasMatch(segment)) return segment;
  }
  return null;
}

final RegExp _affectation = RegExp(r'(?<![=!<>])\b(\w+)\s*(?:\?\?)?=(?![=>])');

/// `table[cle] = valeur` : la valeur entre dans la collection `table`.
final RegExp _affectationIndexee = RegExp(
  r'(?<![\w.$])(\w+)\s*\[[^\]]*\]\s*(?:\?\?)?=(?![=>])',
);
final RegExp _flecheFonction = RegExp(
  r'(?:\bget\s+(\w+)|(\w+)\s*(?:<[^>]*>)?\s*\([^]*\))\s*(?:async\s*)?=>\s*$',
);

/// Les noms d'appels qui laissent la valeur telle quelle (elle reste en tete,
/// au besoin dans un isolat de sens qui commence par elle).
const Set<String> _transparents = <String>{
  'insecable',
  'valeurSeule',
  'ancreSens',
  'dureeSeule',
  'isolerSens',
  'isolerDansInterface',
  'isolerSiAutreSens',
};

/// Les appels qui retirent l'ancre d'une valeur inseree derriere un autre
/// texte (lib/core/i18n/isolat_bidi.dart).
const Set<String> _neutralisants = <String>{'enchainer', 'sansAncre'};

/// Ecrire dans un tampon, c'est ecrire derriere ce qu'il contient deja.
const Set<String> _tampons = <String>{'write', 'writeln', 'writeAll'};

/// Remplacer un repere par la valeur, c'est l'inserer dans un autre texte.
const Set<String> _remplacements = <String>{
  'replaceAll',
  'replaceFirst',
  'replaceRange',
  'replaceAllMapped',
  'replaceFirstMapped',
};

/// Ajouter a une collection : la valeur n'en est pas forcement la tete.
const Set<String> _ajouts = <String>{'add', 'addAll', 'insert', 'insertAll'};

/// Les mots qui precedent une expression (et non un type).
const Set<String> _motsExpression = <String>{
  'return',
  'await',
  'else',
  'case',
  'new',
  'throw',
  'yield',
  'in',
  'is',
  'as',
  'default',
  'assert',
  'if',
  'while',
  'const',
  'final',
  'var',
};

/// Le mot (identifiant) qui finit en [j], ou ''.
String _motFinissantEn(_Source s, int j) {
  int k = j;
  while (k >= 0 && RegExp(r'\w').hasMatch(s.m[k])) {
    k--;
  }
  return s.m.substring(k + 1, j + 1);
}

_Destination _classer(
  _Source s,
  int p,
  Set<ChampJoint> joints, {
  bool collection = false,
}) {
  // Une collection qui contient la valeur, puis jointe : la valeur finit au
  // milieu de la ligne jointe.
  if (collection && s.chaineApres(s.finTerme(p)).contains('join')) {
    return const _Faute('element d\'une collection jointe');
  }
  // Reprise 2 (DUREE-INSECABLE-5) : un litteral colle a un litteral qui le
  // precede (`'Duree : ' '$valeur'`, la forme que `dart format` donne a une
  // ligne longue) n'est pas la tete du libelle : Dart les concatene.
  final int a = s.avant(p);
  if (_guillemet(s, p) && a >= 0 && _guillemet(s, a)) {
    return const _Faute('litteral colle derriere un autre litteral');
  }
  // Concatenation derriere autre chose.
  if (a >= 0 && s.m[a] == '+' && (a == 0 || s.m[a - 1] != '+')) {
    return const _Faute('concatenee derriere un texte');
  }
  final int o = s.ouvrant(p);
  if (o < 0) return _instruction(s, -1, p, collection: collection);
  final String c = s.m[o];
  if (c == '(') return _argument(s, o, p, joints, collection);
  if (c == '[') {
    final int av = s.avant(o);
    // `liste[valeur]` : un indice, pas un element.
    if (av >= 0 &&
        RegExp(r'[\w)\]!]').hasMatch(s.m[av]) &&
        !_motsExpression.contains(_motFinissantEn(s, av))) {
      return const _Affichee();
    }
    final int? fin = s.paire[o];
    // Le premier element commence la ligne jointe : son ancre y est en tete.
    if (_premierElement(s, o, p)) return const _Affichee();
    if (fin != null && s.chaineApres(fin + 1).contains('join')) {
      return const _Faute('element d\'une liste jointe');
    }
    // DUREE-INSECABLE-5 : la liste est suivie (variable, champ, argument)
    // jusqu'a un eventuel `.join(`.
    return _classer(s, o, joints, collection: true);
  }
  // `{`
  if (o > 0 && s.m[o - 1] == r'$') {
    final int q = o - 2;
    if (q >= 0 && _guillemet(s, q)) {
      return _classer(s, _debutLitteral(s, q), joints, collection: collection);
    }
    return const _Faute('interpolee au milieu d\'une chaine');
  }
  if (s.corpsDeSwitch(o)) {
    final int d = s.debutSegment(o, p, virgule: true);
    if (s.m.substring(d, p).contains('=>')) {
      final int fermante = s.avant(o);
      return _classer(
        s,
        s.appelant(s.paire[fermante]!).debut,
        joints,
        collection: collection,
      );
    }
  }
  // DUREE-INSECABLE-5 : table ou ensemble litteral (`{'duree': valeur}`) :
  // la valeur y est rangee ; la table est suivie comme une collection.
  if (_litteral(s, o)) return _classer(s, o, joints, collection: true);
  return _instruction(s, o, p, collection: collection);
}

/// Vrai si le caractere [i] du source masque est un guillemet.
bool _guillemet(_Source s, int i) => s.m[i] == "'" || s.m[i] == '"';

/// Le debut du litteral ouvert par le guillemet [q] (juste avant une
/// interpolation en tete). Trois guillemets ouvrent un litteral long ; deux,
/// ou quatre et plus, ferment un litteral et en ouvrent un autre, colle : le
/// guillemet qui precede le debut rendu signale alors le litteral adjacent.
int _debutLitteral(_Source s, int q) {
  int n = 1;
  while (q - n >= 0 && s.m[q - n] == s.m[q]) {
    n++;
  }
  return n >= 3 ? q - 2 : q;
}

/// Vrai si [p] est le premier element de la liste [o] : rien avant lui,
/// sinon une condition d'element (`if (premier != null) premier`) ou un
/// `?` d'element facultatif.
bool _premierElement(_Source s, int o, int p) {
  int j = o + 1;
  final RegExp blanc = RegExp(r'[\s?]');
  while (j < p) {
    if (blanc.hasMatch(s.m[j])) {
      j++;
      continue;
    }
    if (s.m.startsWith('if', j)) {
      int k = j + 2;
      while (k < p && s.m[k].trim().isEmpty) {
        k++;
      }
      if (k < p && s.m[k] == '(') {
        j = (s.paire[k] ?? p) + 1;
        continue;
      }
    }
    return false;
  }
  return true;
}

/// Vrai si l'accolade [o] ouvre une table ou un ensemble litteral, et non un
/// bloc.
bool _litteral(_Source s, int o) {
  int j = s.avant(o);
  if (j < 0) return false;
  if (s.m[j] == '>') {
    if (j > 0 && s.m[j - 1] == '=') return true; // `=> {`
    // `<String, int>{` (litteral) contre `State<Carte> {` (corps de classe).
    int profondeur = 0;
    while (j >= 0) {
      if (s.m[j] == '>') profondeur++;
      if (s.m[j] == '<' && --profondeur == 0) break;
      j--;
    }
    j = s.avant(j);
    if (j < 0) return true;
    if (!RegExp(r'\w').hasMatch(s.m[j])) return true;
    return _motsExpression.contains(_motFinissantEn(s, j));
  }
  if ('=([,:?'.contains(s.m[j])) return true;
  if (RegExp(r'\w').hasMatch(s.m[j])) {
    return const <String>{
      'return',
      'const',
      'yield',
    }.contains(_motFinissantEn(s, j));
  }
  return false;
}

/// La valeur est dans les parentheses [o] : argument d'un appel, element
/// d'un record, ou simple parenthesage.
_Destination _argument(
  _Source s,
  int o,
  int p,
  Set<ChampJoint> joints,
  bool collection,
) {
  final int d = s.debutSegment(o, p, virgule: true);
  final RegExpMatch? nomme = RegExp(r'^\s*(\w+)\s*:')
      .firstMatch(s.m.substring(d, p));
  final ({String nom, int debut}) app = _constructeur(s, o);
  final String nom = app.nom;
  if (nomme != null) {
    // Argument nomme d'un constructeur dont le champ est joint ailleurs.
    final String classe = _classeConstruite(nom) ?? nom.split('.').last;
    if (joints.contains((classe: classe, champ: nomme[1]!))) {
      return _Faute('champ ${nomme[1]} de $classe, joint a d\'autres colonnes');
    }
  }
  if (nom.isEmpty || nom == 'return') {
    // Un record (`(duree: d, heure: h)`, `(h, d)`) range la valeur : il est
    // suivi comme une collection. Une simple parenthese laisse la valeur.
    final bool record = nomme != null || _virgulesDeNiveauZero(s, o) > 0;
    return _classer(s, o, joints, collection: collection || record);
  }
  if (_motsDeControle.contains(nom)) return const _Affichee();
  final String tete = nom.split('.').first;
  if (nom.startsWith('t.') || s.alias.contains(tete)) {
    return _Faute('argument du libelle $nom');
  }
  final String dernier = nom.split('.').last;
  if (_transparents.contains(dernier)) {
    return _classer(s, app.debut, joints, collection: collection);
  }
  if (_neutralisants.contains(dernier)) return const _Affichee();
  if (_tampons.contains(dernier)) {
    return const _Faute('ecrite dans un tampon, derriere son contenu');
  }
  if (_remplacements.contains(dernier)) {
    return const _Faute('inseree dans un texte par remplacement');
  }
  if (dernier == 'map' || dernier == 'expand') {
    // `xs.map((x) => valeur)` : la valeur devient un element de la
    // collection rendue, suivie jusqu'a un eventuel `.join(`.
    return _classer(s, app.debut, joints, collection: true);
  }
  if (_ajouts.contains(dernier)) {
    if (nom.startsWith('.')) {
      // Cascade (`<String>[]..add(valeur)`) : l'instruction entiere.
      final int debut = s.debutSegment(
        s.ouvrant(app.debut),
        app.debut,
        virgule: true,
      );
      final int fin = s.finInstruction(app.debut);
      if (s.m.substring(debut, fin).contains('.join(')) {
        return const _Faute('ajoutee a une liste jointe');
      }
      return _instruction(s, s.ouvrant(app.debut), app.debut, collection: true);
    }
    return _AjouteeA(nom.substring(0, nom.length - dernier.length - 1));
  }
  return _Appel(nom, nomme?[1], nomme == null ? _rang(s, o, p) : -1);
}

/// Le nombre de virgules de niveau zero entre les parentheses [o].
int _virgulesDeNiveauZero(_Source s, int o) {
  final int? fin = s.paire[o];
  if (fin == null) return 0;
  int n = 0;
  int j = o + 1;
  while (j < fin) {
    final String c = s.m[j];
    if ('([{'.contains(c)) {
      j = (s.paire[j] ?? j) + 1;
      continue;
    }
    if (c == ',' && s.m.substring(j + 1, fin).trim().isNotEmpty) n++;
    j++;
  }
  return n;
}

/// Le rang de l'argument positionnel qui contient [p] dans l'appel [o]
/// (les arguments nommes ne comptent pas).
int _rang(_Source s, int o, int p) {
  int rang = 0;
  int debut = o + 1;
  int j = o + 1;
  while (j < p) {
    final String c = s.m[j];
    if ('([{'.contains(c)) {
      j = (s.paire[j] ?? j) + 1;
      continue;
    }
    if (c == ',') {
      if (!RegExp(r'^\s*\w+\s*:').hasMatch(s.m.substring(debut, j))) rang++;
      debut = j + 1;
    }
    j++;
  }
  return rang;
}

_Destination _instruction(_Source s, int o, int p, {bool collection = false}) {
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
  final int fin = o < 0 ? s.m.length : (s.paire[o] ?? s.m.length);
  final RegExpMatch? indexee = _affectationIndexee.firstMatch(segment);
  if (indexee != null) {
    // La table existe deja : on la suit dans tout le bloc.
    return _Variable(indexee[1]!, o < 0 ? 0 : o, fin, collection: true);
  }
  // DUREE-INSECABLE-5 (reprise) : `objet.champ = valeur` range la valeur
  // dans un champ d'objet, relu ensuite par `autre.champ` n'importe ou.
  final RegExpMatch? membre = _affectationMembre.firstMatch(segment);
  if (membre != null) {
    final String recepteur = membre[1]!;
    return _Champ(
      recepteur == 'this' ? s.classeAutour(p) : null,
      membre[2]!,
      recepteur: d + membre.start + recepteur.length,
    );
  }
  final RegExpMatch? aff = _affectation.firstMatch(segment);
  if (aff != null) {
    final String nom = aff[1]!;
    // `champ = valeur` sans declaration locale, dans une classe qui declare
    // ce champ : la valeur est rangee dans l'objet.
    final String? classe = s.classeAutour(p);
    if (classe != null &&
        segment.substring(0, aff.start).trim().isEmpty &&
        !_declareeLocalement(s, nom, p) &&
        _champDeclare(s, classe, nom)) {
      return _Champ(classe, nom);
    }
    return _Variable(nom, d + aff.start, fin, collection: collection);
  }
  return const _Affichee();
}

/// `objet.champ = `, `objet?.champ ??= `, `liste[0].champ = ` : le
/// recepteur (dernier maillon avant le point) et le champ.
final RegExp _affectationMembre = RegExp(
  r'(\w+|\)|\])\s*[?!]?\.(\w+)\s*(?:\?\?)?=(?![=>])\s*$',
);

/// Vrai si [nom] est declare (variable ou parametre) dans le membre de
/// classe qui contient [p], avant [p].
bool _declareeLocalement(_Source s, String nom, int p) {
  int bloc = s.ouvrant(p);
  int membre = -1;
  while (bloc >= 0) {
    final int o = s.ouvrant(bloc);
    if (o >= 0 && _corpsDeClasse(s, o)) {
      membre = bloc;
      break;
    }
    bloc = o;
  }
  if (membre < 0) return true;
  final int debut = s.debutSegment(s.ouvrant(membre), membre, virgule: false);
  return RegExp(
    '(?:[\\w>?]\\s+|\\bfor\\s*\\(\\s*)${RegExp.escape(nom)}\\s*[=;,)]',
  ).hasMatch(s.m.substring(debut, p));
}

/// Vrai si une classe [classe] des sources declare le champ [champ].
bool _champDeclareDans(List<_Source> fichiers, String classe, String champ) =>
    fichiers.any((_Source s) => _champDeclare(s, classe, champ));

/// Vrai si la classe [classe] du source [s] declare le champ [champ].
bool _champDeclare(_Source s, String classe, String champ) {
  final RegExpMatch? c = RegExp(
    '\\b(?:class|mixin)\\s+${RegExp.escape(classe)}\\b',
  ).firstMatch(s.m);
  if (c == null) return false;
  final int ouvre = s.m.indexOf('{', c.end);
  final int? ferme = ouvre < 0 ? null : s.paire[ouvre];
  if (ferme == null) return false;
  return _declarationDeChamp(champ).hasMatch(s.m.substring(ouvre, ferme));
}

/// Une declaration de champ `Type champ;`, `Type champ = ...;`, ou un
/// parametre `this.champ`.
RegExp _declarationDeChamp(String champ) {
  final String c = RegExp.escape(champ);
  return RegExp('(?:[\\w>?]\\s+$c\\s*[;=](?!=)|\\bthis\\.$c\\b)');
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

/// Le nom du constructeur (ou de la fonction) appele par la parenthese [o],
/// arguments de type omis (`ColonneDonnees<CompteAdmin>(` donne
/// `ColonneDonnees`), et le debut de ce nom.
({String nom, int debut}) _constructeur(_Source s, int o) {
  int j = s.avant(o);
  if (j < 0 || s.m[j] != '>') return s.appelant(o);
  int profondeur = 0;
  while (j >= 0) {
    if (s.m[j] == '>') profondeur++;
    if (s.m[j] == '<') {
      profondeur--;
      if (profondeur == 0) break;
    }
    j--;
  }
  return j < 0 ? (nom: '', debut: o) : s.appelant(j);
}

/// Un parametre de declaration : son nom et sa position, ou le champ
/// `this.x` qu'il remplit.
typedef _Parametre = ({String? nom, int position, String? champ});

/// Une declaration de fonction, de methode ou de constructeur.
class _Declaration {
  _Declaration(
    this.s,
    this.classe,
    this.parametres,
    this.finCorps, {
    required this.locale,
    required this.membre,
  });

  final _Source s;
  final String? classe;

  /// Le bloc `(debut, fin)` d'une fonction locale, seul endroit ou elle est
  /// appelable ; null pour une fonction de premier niveau ou un membre.
  final ({int debut, int fin})? locale;

  /// Vrai pour un membre de classe, d'extension ou de mixin.
  final bool membre;
  final List<({_Parametre p, bool nomme})> parametres;

  /// La fin du corps (ou de la liste d'initialisation), -1 sans corps.
  final int finCorps;

  _Parametre? parametre(String? nomme, int rang) {
    if (nomme != null) {
      for (final ({_Parametre p, bool nomme}) x in parametres) {
        if (x.nomme && (x.p.nom == nomme || x.p.champ == nomme)) return x.p;
      }
      return null;
    }
    int i = 0;
    for (final ({_Parametre p, bool nomme}) x in parametres) {
      if (x.nomme) continue;
      if (i++ == rang) return x.p;
    }
    return null;
  }
}

/// Les segments de niveau zero (separes par des virgules) entre [debut] et
/// [fin].
List<({int debut, int fin})> _segments(_Source s, int debut, int fin) {
  final List<({int debut, int fin})> segments = <({int debut, int fin})>[];
  int d = debut;
  int j = debut;
  while (j < fin) {
    final String c = s.m[j];
    if ('([{'.contains(c)) {
      j = (s.paire[j] ?? j) + 1;
      continue;
    }
    if (c == ',') {
      segments.add((debut: d, fin: j));
      d = j + 1;
    }
    j++;
  }
  if (s.m.substring(d, fin).trim().isNotEmpty) {
    segments.add((debut: d, fin: fin));
  }
  return segments;
}

List<({_Parametre p, bool nomme})> _parametres(
  _Source s,
  int ouvrante,
  int fermante,
) {
  final List<({_Parametre p, bool nomme})> liste =
      <({_Parametre p, bool nomme})>[];
  void lire(int debut, int fin, bool nomme) {
    for (final ({int debut, int fin}) g in _segments(s, debut, fin)) {
      final String brut = s.m.substring(g.debut, g.fin);
      final int decalage = brut.length - brut.trimLeft().length;
      final int d = g.debut + decalage;
      if (d < g.fin && (s.m[d] == '{' || s.m[d] == '[')) {
        final int? f = s.paire[d];
        if (f != null) {
          lire(d + 1, f, s.m[d] == '{');
          continue;
        }
      }
      String texte = s.m.substring(d, g.fin);
      final int egal = texte.indexOf('=');
      if (egal >= 0) texte = texte.substring(0, egal);
      final RegExpMatch? champ = RegExp(r'\bthis\.(\w+)\s*$')
          .firstMatch(texte.trimRight());
      if (champ != null) {
        liste.add((
          p: (nom: null, position: d + champ.start, champ: champ[1]),
          nomme: nomme,
        ));
        continue;
      }
      if (RegExp(r'\bsuper\.\w+\s*$').hasMatch(texte.trimRight())) {
        liste.add((p: (nom: null, position: d, champ: null), nomme: nomme));
        continue;
      }
      final RegExpMatch? dernier = RegExp(r'(\w+)\s*$')
          .firstMatch(texte.trimRight());
      liste.add((
        p: (
          nom: dernier?[1],
          position: dernier == null ? d : d + dernier.start,
          champ: null,
        ),
        nomme: nomme,
      ));
    }
  }

  lire(ouvrante + 1, fermante, false);
  return liste;
}

/// La fin du corps d'une declaration dont les parametres finissent en
/// [fermante], ou -1 (constructeur sans corps).
int _finCorps(_Source s, int fermante) {
  int j = fermante + 1;
  final RegExp blanc = RegExp(r'\s');
  while (j < s.m.length && blanc.hasMatch(s.m[j])) {
    j++;
  }
  for (final String mot in <String>['async*', 'async', 'sync*']) {
    if (s.m.startsWith(mot, j)) {
      j += mot.length;
      while (j < s.m.length && blanc.hasMatch(s.m[j])) {
        j++;
      }
      break;
    }
  }
  if (s.m.startsWith('=>', j)) return s.finInstruction(j + 2);
  if (j < s.m.length && s.m[j] == '{') return s.paire[j] ?? -1;
  if (j < s.m.length && s.m[j] == ':') {
    // Liste d'initialisation, puis corps eventuel.
    int k = j + 1;
    while (k < s.m.length) {
      final String c = s.m[k];
      if (c == '{') return s.paire[k] ?? -1;
      if (c == '(' || c == '[') {
        k = (s.paire[k] ?? k) + 1;
        continue;
      }
      if (c == ';') return k;
      k++;
    }
  }
  return -1;
}

/// Vrai si le nom qui commence en [debut] et dont les parametres s'ouvrent
/// en [ouvrante] est une declaration (et non un appel).
bool _estDeclaration(_Source s, int debut, int ouvrante, String? classe) {
  final int? fermante = s.paire[ouvrante];
  if (fermante == null) return false;
  final String apres = s.m.substring(fermante + 1).trimLeft();
  final bool corps =
      apres.startsWith('{') ||
      apres.startsWith('=>') ||
      apres.startsWith('async') ||
      apres.startsWith('sync');
  final bool sansCorps = apres.startsWith(';') || apres.startsWith(':');
  if (!corps && !sansCorps) return false;
  int j = s.avant(debut);
  while (j >= 0 &&
      const <String>{
        'const',
        'factory',
        'external',
        'static',
      }.contains(_motFinissantEn(s, j))) {
    j = s.avant(j - _motFinissantEn(s, j).length + 1);
  }
  final bool constructeur =
      classe != null &&
      s.m.startsWith(classe, debut) &&
      s.classeAutour(debut) == classe;
  if (j < 0) return corps || constructeur;
  final String c = s.m[j];
  if (';{}'.contains(c)) return constructeur || corps;
  if (constructeur) {
    // `factory`, `const` deja sautes : un constructeur suit un membre.
    return false;
  }
  if (!corps) return false;
  if (RegExp(r'\w').hasMatch(c)) {
    return !_motsExpression.contains(_motFinissantEn(s, j));
  }
  if (c == '>') return j > 0 && s.m[j - 1] != '=';
  if (c == '?') return j > 0 && RegExp(r'[\w>]').hasMatch(s.m[j - 1]);
  return false;
}

/// Vrai si l'accolade [o] ouvre le corps d'une classe, d'une extension,
/// d'un mixin ou d'une enumeration.
bool _corpsDeClasse(_Source s, int o) {
  if (s.m[o] != '{') return false;
  final int d = s.debutSegment(s.ouvrant(o), o, virgule: false);
  return RegExp(r'\b(?:class|extension|mixin|enum)\b')
      .hasMatch(s.m.substring(d, o));
}

/// Les declarations que l'appel [nom], fait en [position] de [origine],
/// peut viser : une fonction locale visible a cet endroit, un membre de la
/// classe ou une fonction de premier niveau pour un appel nu ; un membre
/// pour un appel `objet.methode(` ; un constructeur ou un membre statique
/// pour `Classe(` et `Classe.x(`.
Iterable<_Declaration> _cibles(
  List<_Source> fichiers,
  _Source origine,
  int position,
  String nom,
) {
  final List<String> segments = nom
      .split('.')
      .where((String x) => x.isNotEmpty)
      .toList();
  final bool classe = segments.any(
    (String x) => RegExp(r'^_?[A-Z]').hasMatch(x),
  );
  final bool nu = segments.length == 1 && !nom.startsWith('.');
  final String? classeIci = origine.classeAutour(position);
  return _declarations(fichiers, origine, nom).where((_Declaration d) {
    if (classe) return true;
    final ({int debut, int fin})? locale = d.locale;
    if (locale != null) {
      return nu &&
          d.s == origine &&
          position > locale.debut &&
          position < locale.fin;
    }
    if (d.membre) return !nu || d.classe == classeIci;
    return nu;
  });
}

final Map<String, List<_Declaration>> _cacheDeclarations =
    <String, List<_Declaration>>{};

/// Les declarations que peut viser l'appel [nom] fait dans [origine].
List<_Declaration> _declarations(
  List<_Source> fichiers,
  _Source origine,
  String nom,
) {
  final List<String> segments = nom
      .split('.')
      .map((String x) => x.replaceAll(RegExp(r'[?!]'), ''))
      .where((String x) => x.isNotEmpty)
      .toList();
  if (segments.isEmpty) return const <_Declaration>[];
  final String dernier = segments.last;
  int rangClasse = -1;
  for (int i = 0; i < segments.length; i++) {
    if (RegExp(r'^_?[A-Z]').hasMatch(segments[i])) rangClasse = i;
  }
  String? classe;
  String motif;
  if (rangClasse >= 0 && rangClasse == segments.length - 1) {
    classe = dernier;
    motif = '(?<![\\w\$.])${RegExp.escape(classe)}';
  } else if (rangClasse >= 0 && rangClasse == segments.length - 2) {
    classe = segments[rangClasse];
    motif =
        '(?<![\\w\$.])(?:${RegExp.escape(classe)}\\.)?${RegExp.escape(dernier)}';
  } else {
    motif = '(?<![\\w\$.])${RegExp.escape(dernier)}';
  }
  final bool privee = (classe ?? dernier).startsWith('_');
  final String cle = '${privee ? origine.fichier : ''}|$motif|$classe';
  final List<_Declaration>? connues = _cacheDeclarations[cle];
  if (connues != null) return connues;
  final RegExp re = RegExp('$motif\\s*(?:<[^()]*?>)?\\s*\\(');
  final List<_Declaration> trouvees = <_Declaration>[];
  for (final _Source s in fichiers) {
    if (privee && s != origine) continue;
    if (!s.m.contains(dernier)) continue;
    for (final RegExpMatch u in re.allMatches(s.m)) {
      final int ouvrante = u.end - 1;
      if (!_estDeclaration(s, u.start, ouvrante, classe)) continue;
      if (classe != null && s.classeAutour(u.start) != classe) continue;
      final int fermante = s.paire[ouvrante]!;
      final int bloc = s.ouvrant(u.start);
      final bool membre = bloc >= 0 && _corpsDeClasse(s, bloc);
      trouvees.add(
        _Declaration(
          s,
          s.classeAutour(u.start),
          _parametres(s, ouvrante, fermante),
          _finCorps(s, fermante),
          membre: membre,
          locale: bloc < 0 || membre
              ? null
              : (debut: bloc, fin: s.paire[bloc] ?? s.m.length),
        ),
      );
    }
  }
  return _cacheDeclarations[cle] = trouvees;
}

/// Suit le champ [champ] jusqu'a ses lectures. [classe] est la classe qui le
/// porte quand elle est connue (constructeur `this.champ`, `this.champ =`),
/// sinon toute classe qui declare un champ de ce nom.
///
/// DUREE-INSECABLE-5 (reprise) : les lectures `objet.champ` sont relevees
/// par le NOM DU CHAMP, quel que soit l'objet, dans tous les fichiers. Le
/// type de l'objet n'est pas lisible dans le source quand il est infere
/// (`final col = colonne;`, `final c = colonnes().first;`), parametre d'une
/// lambda non typee (`.map((col) => col.texte(ligne))`) ou variable d'une
/// boucle (`for (final col in colonnes)`) : la garde ne doit pas dependre du
/// nom choisi. Une lecture d'un autre objet qui porte un champ du meme nom
/// est suivie aussi ; c'est le prix d'une garde qui ne laisse rien passer.
/// Les libelles (`t.a.champ`, alias de `t`) ne sont pas des lectures.
///
/// Dans le corps d'une classe qui declare le champ, les lectures nues
/// (`champ`, `'$champ'`) sont suivies aussi.
void _suivreChamp(
  List<_Source> fichiers,
  String? classe,
  String champ,
  String chemin,
  bool collection,
  List<_ASuivre> aSuivre,
  List<AncreGlissee> fautes,
) {
  final RegExp declaration = RegExp(
    classe == null
        ? '\\b(?:class|mixin)\\s+(\\w+)\\b'
        : '\\b(?:class|mixin)\\s+${RegExp.escape(classe)}\\b',
  );
  final RegExp nu = RegExp('(?<![\\w.])${RegExp.escape(champ)}(?![\\w:])');
  final RegExp declare = _declarationDeChamp(champ);
  final String suite = '$chemin > ${classe ?? '*'}.$champ';
  bool champDeclare = false;
  for (final _Source s in fichiers) {
    if (!s.m.contains(champ)) continue;
    for (final RegExpMatch c in declaration.allMatches(s.m)) {
      final int ouvre = s.m.indexOf('{', c.end);
      final int? ferme = ouvre < 0 ? null : s.paire[ouvre];
      if (ferme == null) continue;
      if (!declare.hasMatch(s.m.substring(ouvre, ferme))) continue;
      champDeclare = true;
      for (final RegExpMatch u in nu.allMatches(
        s.m.substring(0, ferme),
        ouvre,
      )) {
        if (_affectee(s, u.end)) continue;
        // `final String champ;`, `this.champ` (parametre) : pas une lecture.
        final int a = s.avant(u.start);
        final bool interpolee = u.start > 0 && s.m[u.start - 1] == r'$';
        if (!interpolee && a >= 0 && RegExp(r'[\w>?]').hasMatch(s.m[a])) {
          final String mot = _motFinissantEn(s, a);
          if (!_motsExpression.contains(mot)) continue;
        }
        _lecture(s, u.start, suite, collection, aSuivre, fautes);
      }
    }
  }
  // Un argument nomme d'une classe hors des sources (un widget de Flutter)
  // n'est pas un champ que le code relit : seul un champ declare, ou range
  // par affectation sur un objet de type inconnu, est suivi.
  if (classe != null && !champDeclare) return;
  // `..champ` (cascade) ne correspond pas : le point y suit un point.
  final RegExp acces = RegExp(
    '(?<=[\\w)\\]!?])\\s*[?!]?\\.${RegExp.escape(champ)}(?![\\w:])',
  );
  for (final _Source s in fichiers) {
    if (!s.m.contains(champ)) continue;
    for (final RegExpMatch u in acces.allMatches(s.m)) {
      if (_affectee(s, u.end)) continue;
      final ({String nom, int debut}) lecture = s.appelant(u.end);
      final List<String> maillons = lecture.nom.split('.');
      final String tete = maillons.first;
      if (tete == 'this' || tete == 'super') {
        // Reprise 2 (DUREE-INSECABLE-5) : `this.champ` (ou `super.champ`)
        // lu dans une classe qui porte le champ ; `this.objet.champ` est lu
        // comme `objet.champ`, plus bas. Un parametre `this.champ` de
        // constructeur n'est pas une lecture.
        if (maillons.length == 2) {
          if (_parametreDeclare(s, lecture.debut)) continue;
          final String? ici = s.classeAutour(u.start);
          if (ici == null) continue;
          final bool porte = classe == null
              ? _champDeclare(s, ici, champ)
              : ici == classe || tete == 'super';
          if (!porte) continue;
          _lecture(s, lecture.debut, suite, collection, aSuivre, fautes);
          continue;
        }
      }
      if (lecture.nom.startsWith('t.') || s.alias.contains(tete)) continue;
      if (classe != null && !_peutEtre(fichiers, s, u.start, classe)) {
        continue;
      }
      _lecture(s, lecture.debut, suite, collection, aSuivre, fautes);
    }
  }
}

/// Vrai si [p] est dans la liste des parametres d'une declaration
/// (`Seance(this.duree)`, `Seance({required this.duree})`).
bool _parametreDeclare(_Source s, int p) {
  int o = s.ouvrant(p);
  if (o >= 0 && (s.m[o] == '{' || s.m[o] == '[')) o = s.ouvrant(o);
  if (o < 0 || s.m[o] != '(') return false;
  final ({String nom, int debut}) app = _constructeur(s, o);
  if (app.nom.isEmpty) return false;
  return _estDeclaration(s, app.debut, o, s.classeAutour(o));
}

/// Les types qui ne disent rien de l'objet.
const Set<String> _typesOuverts = <String>{'dynamic', 'Object', 'T'};

/// Vrai si l'objet lu juste avant [point] (`objet.champ`) peut etre de la
/// classe [classe].
///
/// Son type est cherche dans le source : type ecrit (variable, parametre,
/// champ), sinon deduit de ce qui le donne (`final col = colonne;`,
/// `final c = colonnes().first;`, `for (final col in colonnes)`,
/// `colonnes.map((col) => ...)`, `final s = Seance();`), en remontant
/// jusqu'a une declaration typee, dans ce fichier ou une fonction d'un autre.
/// Le type trouve doit nommer [classe] (`ColonneDonnees<T>`,
/// `List<ColonneDonnees<T>>`), ou etre ouvert (`dynamic`, `Object`, `T`).
/// Un type introuvable est accepte quand le fichier nomme [classe] : un
/// objet de la classe y est vraisemblable, quel que soit le nom choisi.
bool _peutEtre(List<_Source> fichiers, _Source s, int point, String classe) {
  final RegExp nommee = RegExp('(?<![\\w\$])${RegExp.escape(classe)}\\b');
  final String? type = _typeAvant(fichiers, s, point);
  if (type == null) return nommee.hasMatch(s.m);
  final String base = type.replaceAll(RegExp(r'<.*$|\?'), '').trim();
  return _typesOuverts.contains(base) || nommee.hasMatch(type);
}

/// Le type (texte) de l'objet qui finit juste avant [point], ou null.
String? _typeAvant(List<_Source> fichiers, _Source s, int point) {
  int j = point - 1;
  while (j >= 0 && s.m[j].trim().isEmpty) {
    j--;
  }
  if (j >= 0 && (s.m[j] == '?' || s.m[j] == '!')) j--;
  if (j < 0 || !RegExp(r'\w').hasMatch(s.m[j])) return null;
  final String nom = _motFinissantEn(s, j);
  if (nom.isEmpty || RegExp(r'^\d').hasMatch(nom)) return null;
  return _typeDeNom(fichiers, s, nom, j - nom.length + 1, 0);
}

final Map<String, String?> _cacheTypes = <String, String?>{};

/// Le type du nom [nom] lu en [position] de [s] : sa declaration la plus
/// proche avant [position], sinon la premiere du fichier (champ declare plus
/// bas), sinon une fonction ou un accesseur de ce nom dans les sources.
String? _typeDeNom(
  List<_Source> fichiers,
  _Source s,
  String nom,
  int position,
  int profondeur,
) {
  if (profondeur > 4) return null;
  if (nom == 'widget') {
    return RegExp(r'\bState<(\w+)>').firstMatch(s.m)?[1];
  }
  if (RegExp(r'^_?[A-Z]').hasMatch(nom)) return nom;
  if (_motsExpression.contains(nom) || nom == 'this') return null;
  final _Decl? d = _declarationProche(s, nom, position);
  if (d == null) {
    return _typeRendu(fichiers, nom) ?? _typeDeChamp(fichiers, nom);
  }
  final String cle = '${s.fichier}:${d.p}:$nom';
  if (_cacheTypes.containsKey(cle)) return _cacheTypes[cle];
  _cacheTypes[cle] = null; // garde contre les cycles
  final String? type = switch (d) {
    _Decl(:final String type) when type.isNotEmpty => type,
    _Decl(:final int? source) when source != null => _typeExpression(
      fichiers,
      s,
      source,
      profondeur + 1,
    ),
    _ => null,
  };
  return _cacheTypes[cle] = type;
}

/// Une declaration de nom : son [type] ecrit (vide sinon), ou la position
/// [source] de l'expression qui en donne la valeur (initialisation,
/// collection parcourue, recepteur d'un `.map(`).
typedef _Decl = ({int p, String type, int? source});

final Map<String, List<_Decl>> _cacheDecl = <String, List<_Decl>>{};

List<_Decl> _declarationsDe(_Source s, String nom) {
  final String cle = '${s.fichier}|$nom';
  final List<_Decl>? connues = _cacheDecl[cle];
  if (connues != null) return connues;
  final String n = RegExp.escape(nom);
  final List<_Decl> liste = <_Decl>[];
  // `Type nom` suivi de `;`, `=`, `,`, `)`, `}` ou `in`.
  for (final RegExpMatch x in RegExp(
    '(?<![\\w.\$])((?:[A-Z_]\\w*|int|double|num|bool|dynamic)'
    '(?:<[^;{}()=]*?>)?\\??)\\s+$n\\s*(?=[;=,)}]|\\bin\\b)',
  ).allMatches(s.m)) {
    if (_motsExpression.contains(x[1])) continue;
    liste.add((p: x.start, type: x[1]!, source: null));
  }
  // `final nom = expr`, `var nom = expr`.
  for (final RegExpMatch x in RegExp(
    '\\b(?:final|var|const)\\s+$n\\s*=(?![=>])',
  ).allMatches(s.m)) {
    liste.add((p: x.start, type: '', source: x.end));
  }
  // `for (final nom in expr)`.
  for (final RegExpMatch x in RegExp(
    '\\b(?:final|var)\\s+$n\\s+in\\b',
  ).allMatches(s.m)) {
    liste.add((p: x.start, type: '', source: x.end));
  }
  // `(nom) =>`, `(a, nom) {` : parametre de lambda non type ; la valeur
  // vient du recepteur de l'appel qui recoit la lambda (`xs.map(`).
  for (final RegExpMatch x in RegExp(
    '\\((\\s*(?:\\w+\\s*,\\s*)*$n\\s*(?:,\\s*\\w+\\s*)*)\\)\\s*(?:=>|\\{|async)',
  ).allMatches(s.m)) {
    final int o = s.ouvrant(x.start);
    int? source;
    if (o >= 0 && s.m[o] == '(') {
      final ({String nom, int debut}) appel = s.appelant(o);
      if (appel.nom.contains('.')) source = appel.debut;
    }
    liste.add((p: x.start, type: '', source: source));
  }
  return _cacheDecl[cle] = liste;
}

_Decl? _declarationProche(_Source s, String nom, int position) {
  _Decl? proche;
  _Decl? premiere;
  for (final _Decl d in _declarationsDe(s, nom)) {
    if (d.p < position && (proche == null || d.p > proche.p)) proche = d;
    if (premiere == null || d.p < premiere.p) premiere = d;
  }
  return proche ?? premiere;
}

/// Le type de l'expression qui commence en [i] : une collection litterale
/// typee (`<C>[...]`), un constructeur (`C(`, `C.x(`), sinon le type de son
/// premier nom (`colonnes` dans `colonnes().first`, `secondaires.map`).
String? _typeExpression(
  List<_Source> fichiers,
  _Source s,
  int i,
  int profondeur,
) {
  int j = i;
  while (j < s.m.length && s.m[j].trim().isEmpty) {
    j++;
  }
  final String reste = s.m.substring(j, (j + 200).clamp(j, s.m.length));
  final RegExpMatch? litteral = RegExp(r'^(?:const\s+)?<([^\[{;]*)>\s*[\[{]')
      .firstMatch(reste);
  if (litteral != null) return litteral[1];
  final RegExpMatch? construit = RegExp(
    r'^(?:const\s+|new\s+|await\s+)?(_?[A-Z]\w*)',
  ).firstMatch(reste);
  if (construit != null) return construit[1];
  final RegExpMatch? tete = RegExp(r'^(?:await\s+)?(\w+)').firstMatch(reste);
  if (tete == null) return null;
  return _typeDeNom(fichiers, s, tete[1]!, j, profondeur);
}

final Map<String, String?> _cacheChamps = <String, String?>{};

/// Les types ecrits des declarations [nom] des autres sources (un champ
/// `final Membre membre;` lu par `participant.membre`), joints par `|` :
/// l'objet peut etre de l'un d'eux.
String? _typeDeChamp(List<_Source> fichiers, String nom) {
  if (_cacheChamps.containsKey(nom)) return _cacheChamps[nom];
  final Set<String> types = <String>{
    for (final _Source s in fichiers)
      if (s.m.contains(nom))
        for (final _Decl d in _declarationsDe(s, nom))
          if (d.type.isNotEmpty) d.type,
  };
  return _cacheChamps[nom] = types.isEmpty ? null : types.join('|');
}

final Map<String, String?> _cacheRendus = <String, String?>{};

/// Le type rendu par une fonction, une methode ou un accesseur [nom]
/// declare dans les sources (`List<Colonne<int>> colonnes() =>`).
String? _typeRendu(List<_Source> fichiers, String nom) {
  if (_cacheRendus.containsKey(nom)) return _cacheRendus[nom];
  final RegExp re = RegExp(
    '(?<![\\w.\$])((?:[A-Z_]\\w*|int|double|num|bool)'
    '(?:<[^;{}()=]*?>)?\\??)\\s+(?:get\\s+)?${RegExp.escape(nom)}'
    '\\s*(?:<[^>]*>)?\\s*(?:\\(|=>|\\{)',
  );
  for (final _Source s in fichiers) {
    if (!s.m.contains(nom)) continue;
    final RegExpMatch? x = re.firstMatch(s.m);
    if (x != null && !_motsExpression.contains(x[1])) {
      return _cacheRendus[nom] = x[1];
    }
  }
  return _cacheRendus[nom] = null;
}

/// Une lecture du champ en [p] : `$champ` dans une chaine, ou une
/// expression classee comme la valeur elle-meme.
void _lecture(
  _Source s,
  int p,
  String suite,
  bool collection,
  List<_ASuivre> aSuivre,
  List<AncreGlissee> fautes,
) {
  if (p > 0 && s.m[p - 1] == r'$') {
    final int q = p - 2;
    if (q >= 0 && _guillemet(s, q)) {
      aSuivre.add((
        s: s,
        p: _debutLitteral(s, q),
        chemin: suite,
        collection: collection,
      ));
    } else {
      fautes.add((
        fichier: s.fichier,
        ligne: s.ligne(p),
        raison: '$suite : interpolee au milieu',
      ));
    }
    return;
  }
  aSuivre.add((s: s, p: p, chemin: suite, collection: collection));
}

/// Vrai si la position [fin] est suivie d'une affectation (`= ...`).
bool _affectee(_Source s, int fin) =>
    RegExp(r'^\s*(?:\?\?)?=(?![=>])').hasMatch(s.m.substring(fin));

/// Une position a classer : ou la valeur (ou la collection qui la contient,
/// si [collection]) se trouve, et le chemin parcouru depuis l'ancre.
typedef _ASuivre = ({_Source s, int p, String chemin, bool collection});

/// Suit la variable [nom] (declaree en [declaration], visible jusqu'a
/// [portee]) a chacune de ses lectures.
void _suivreVariable(
  _Source s,
  String nom,
  int declaration,
  int portee,
  String chemin,
  bool collection,
  List<_ASuivre> aSuivre,
  List<AncreGlissee> fautes,
) {
  final RegExp usage = RegExp('(?<![\\w.])${RegExp.escape(nom)}(?![\\w:])');
  for (final RegExpMatch u in usage.allMatches(s.m, declaration)) {
    if (u.start >= portee) break;
    if (u.start == declaration) continue;
    // `nom = ...` : une nouvelle affectation n'est pas une lecture.
    if (RegExp(r'^\s*=(?![=>])').hasMatch(s.m.substring(u.end))) {
      continue;
    }
    final int debut = u.start > 0 && s.m[u.start - 1] == r'$'
        ? u.start - 1
        : u.start;
    if (debut != u.start) {
      // `$nom` dans une chaine.
      final int q = debut - 1;
      if (q >= 0 && _guillemet(s, q)) {
        aSuivre.add((
          s: s,
          p: _debutLitteral(s, q),
          chemin: '$chemin > $nom',
          collection: collection,
        ));
      } else {
        fautes.add((
          fichier: s.fichier,
          ligne: s.ligne(u.start),
          raison: '$chemin > $nom : interpolee au milieu',
        ));
      }
      continue;
    }
    aSuivre.add((
      s: s,
      p: u.start,
      chemin: '$chemin > $nom',
      collection: collection,
    ));
  }
}

/// Toutes les valeurs ancrees de [sources] qui finissent au milieu d'un
/// libelle.
List<AncreGlissee> ancresGlissees([Iterable<File>? sources]) {
  _cacheDeclarations.clear();
  _cacheTypes.clear();
  _cacheDecl.clear();
  _cacheRendus.clear();
  _cacheChamps.clear();
  final List<_Source> fichiers = <_Source>[
    for (final File f in sources ?? sourcesDart())
      _Source(f.path, f.readAsStringSync()),
  ];
  final List<AncreGlissee> fautes = <AncreGlissee>[];
  final Set<String> vus = <String>{};
  final Set<ChampJoint> joints = champsJoints(<String>[
    for (final _Source s in fichiers) s.m,
  ]);
  final List<_ASuivre> aSuivre = <_ASuivre>[];

  for (final _Source s in fichiers) {
    for (final RegExpMatch m in _appelAncre.allMatches(s.m)) {
      // Une declaration (`static String valeurSeule(String texte)`) n'est pas
      // un appel.
      final int a = s.avant(m.start);
      if (a >= 0 && RegExp(r'[\w?>]').hasMatch(s.m[a])) {
        final ({String nom, int debut}) mot = s.appelant(a + 1);
        if (mot.nom == 'String' || mot.nom == 'String?') continue;
      }
      aSuivre.add((s: s, p: m.start, chemin: m[1]!, collection: false));
    }
  }

  final Set<String> fonctionsSuivies = <String>{};
  final Set<String> champsSuivis = <String>{};
  final Set<String> appelsSuivis = <String>{};
  void champ(String? classe, String nom, String chemin, bool collection) {
    if (!champsSuivis.add('$classe.$nom/$collection')) return;
    _suivreChamp(fichiers, classe, nom, chemin, collection, aSuivre, fautes);
  }

  while (aSuivre.isNotEmpty) {
    final _ASuivre x = aSuivre.removeLast();
    final String cle = '${x.s.fichier}:${x.p}:${x.collection}';
    if (!vus.add(cle)) continue;
    switch (_classer(x.s, x.p, joints, collection: x.collection)) {
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
        :final bool collection,
      ):
        _suivreVariable(
          x.s,
          nom,
          declaration,
          portee,
          x.chemin,
          collection || x.collection,
          aSuivre,
          fautes,
        );
      case _Champ(
        :final String? classe,
        champ: final String nom,
        :final int? recepteur,
      ):
        String? c = classe;
        if (c == null && recepteur != null) {
          // `s.duree = ` : la classe de `s`, si son type se lit.
          final String? type = _typeAvant(fichiers, x.s, recepteur);
          c = type == null
              ? null
              : RegExp(r'^\s*(_?[A-Z]\w*)').firstMatch(type)?[1];
          if (c != null && !_champDeclareDans(fichiers, c, nom)) c = null;
        }
        if (c == null) {
          // Type illisible : le champ est suivi dans ce fichier, quel que
          // soit l'objet lu.
          _suivreChamp(
            <_Source>[x.s],
            null,
            nom,
            x.chemin,
            x.collection,
            aSuivre,
            fautes,
          );
        } else {
          champ(c, nom, x.chemin, x.collection);
        }
      case _AjouteeA(:final String recepteur):
        // La collection qui recoit la valeur, a chacune de ses lectures dans
        // le fichier.
        final String r = recepteur.split('.').last;
        final RegExp usage = RegExp(
          '(?<![\\w\$])${RegExp.escape(r)}(?![\\w:])',
        );
        // Une variable locale est suivie dans la fonction qui la declare ;
        // un champ, dans tout le fichier.
        int debut = 0;
        int fin = x.s.m.length;
        int bloc = x.s.ouvrant(x.p);
        while (bloc >= 0 &&
            x.s.ouvrant(bloc) >= 0 &&
            !_corpsDeClasse(x.s, x.s.ouvrant(bloc))) {
          bloc = x.s.ouvrant(bloc);
        }
        if (bloc >= 0 && !recepteur.contains('.')) {
          final int f = x.s.paire[bloc] ?? fin;
          if (RegExp('\\b(?:final|var|[\\w<>?, ]+)\\s+${RegExp.escape(r)}\\s*=')
              .hasMatch(x.s.m.substring(bloc, f))) {
            debut = bloc;
            fin = f;
          }
        }
        for (final RegExpMatch u in usage.allMatches(x.s.m, debut)) {
          if (u.start >= fin) break;
          aSuivre.add((
            s: x.s,
            p: x.s.appelant(u.end).debut,
            chemin: '${x.chemin} > $recepteur',
            collection: true,
          ));
        }
      case _Appel(:final String nom, :final String? nomme, :final int position):
        final String id =
            '${x.s.fichier}#$nom/${nomme ?? position}/${x.collection}';
        if (!appelsSuivis.add(id)) break;
        final String suite = '${x.chemin} > $nom(${nomme ?? '#$position'})';
        for (final _Declaration d in _cibles(fichiers, x.s, x.p, nom)) {
          final _Parametre? p = d.parametre(nomme, position);
          if (p == null) continue;
          final String? c = p.champ;
          if (c != null) {
            if (d.classe != null) champ(d.classe!, c, suite, x.collection);
            continue;
          }
          final String? n = p.nom;
          if (n == null || d.finCorps < 0) continue;
          _suivreVariable(
            d.s,
            n,
            p.position,
            d.finCorps,
            suite,
            x.collection,
            aSuivre,
            fautes,
          );
        }
        // Repli : argument nomme d'un constructeur, champ `this.x`.
        final String? construite = _classeConstruite(nom);
        if (nomme != null && construite != null) {
          champ(construite, nomme, x.chemin, x.collection);
        }
      case _Fonction(
        :final String nom,
        :final bool statique,
        :final String? classe,
      ):
        final String id = '${x.s.fichier}#$classe.$nom/${x.collection}';
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
              collection: x.collection,
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
  // Une meme ligne atteinte par deux chemins n'est qu'une faute.
  final Set<String> lignes = <String>{};
  return <AncreGlissee>[
    for (final AncreGlissee f in fautes)
      if (lignes.add('${f.fichier}:${f.ligne}')) f,
  ];
}
