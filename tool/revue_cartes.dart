// Detecteur de cartes collees (K-55), partage par `verifier_revue.dart` et son
// test (`test/tool/revue_cartes_test.dart`).
//
// Le defaut vise : deux surfaces de contenu qui se touchent, ou presque, sans
// l'ecart des jetons entre elles. Le minimum entre deux cartes est
// [ecartMinimumCartes] (16, `Ecart.vLg`, l'ecart des ecrans du tuteur) ; entre
// deux boites peintes a la main, [ecartMinimumBoites] (le contact seul).
// Il se voit dans une liste `children:` de `Column`, `Row`, `Wrap`, `Flex` ou
// `ListView`, ou chaque element est une carte, un espace (`Ecart`,
// `SizedBox`, `Padding`) ou autre chose (un titre, un filet : qui separe) :
//
// 1. deux cartes qui se suivent, l'espace entre elles inferieur au minimum ;
// 2. une boucle (`for`, `...x.map`) dont chaque tour rend une carte, l'espace
//    entre deux tours inferieur au minimum ;
// 3. un `ListView.builder` ou `GridView.builder` sans separateur dont
//    l'element est une carte ;
// 4. une carte « derivee » : un widget d'ecran dont `build` rend une carte
//    (`_CarteFoyer`), une variable locale ou une methode qui en rend une.
//
// Une « carte » est un composant du core (`AppCard`, `BentoTile`, `StatTile`,
// `ChildCard`, `GroupeReglages`, `SettingRow`, `CarteGroupee`), un widget
// derive, ou une boite peinte a la main (`DecoratedBox` / `Container` avec
// fond ou filet ET rayon). `PileCartes` impose l'ecart lui-meme : il n'est
// jamais le parent fautif.
import 'dart:io';

/// Un cas de cartes collees.
class CasCollage {
  /// Cree un cas.
  const CasCollage(this.chemin, this.ligne, this.extrait);

  /// Le fichier.
  final String chemin;

  /// La ligne du premier element fautif.
  final int ligne;

  /// Le nom de la carte, son rang dans le fichier et l'ecart mesure.
  final String extrait;
}

/// L'ecart minimum entre deux cartes : `Ecart.vLg`, celui des ecrans du tuteur.
const double ecartMinimumCartes = 16;

/// L'ecart minimum entre deux pastilles de choix (`AppCard` a marge reduite).
const double ecartMinimumPastilles = 8;

/// L'ecart minimum entre deux boites peintes a la main : le contact seul (une
/// pastille ou un segment peut etre serre, une carte non).
const double ecartMinimumBoites = 1;

/// Les tailles des jetons d'espacement (`AppSpacing`, `Ecart`).
const Map<String, double> _jetons = <String, double>{
  'xs': 4,
  'sm': 8,
  'md': 12,
  'lg': 16,
  'xl': 20,
  'xxl': 24,
  'xxxl': 32,
  'section': 40,
  'titreEcran': 48,
  'respiration': 64,
};

/// Les cartes du core.
const Set<String> cartesDuCore = <String>{
  'AppCard',
  'BentoTile',
  'ChildCard',
  'StatTile',
  'GroupeReglages',
  'CarteGroupee',
  'SettingRow',
  'ScheduleOption',
  'CarteLignes',
  'ConfigLigneBooleenne',
};

/// Les enveloppes qui ne changent rien a l'espace entre deux cartes.
const Set<String> _enveloppes = <String>{
  'Expanded',
  'Flexible',
  'SizedBox',
  'ConstrainedBox',
  'Semantics',
  'Align',
  'Center',
  'KeyedSubtree',
  'ExcludeSemantics',
  'MergeSemantics',
  'IntrinsicHeight',
  'IntrinsicWidth',
  'FractionallySizedBox',
  'Hero',
  'RepaintBoundary',
  'Focus',
  'FocusTraversalGroup',
};

/// Les parents ou deux cartes voisines se touchent.
const Set<String> _parents = <String>{
  'Column',
  'Row',
  'Wrap',
  'Flex',
  'ListView',
  'SliverList',
};

final RegExp _listeEnfants = RegExp(
  r'\b(?:children|slivers)\s*:\s*(?:const\s*)?(?:<\s*Widget\s*>\s*)?\[',
);

final RegExp _constructeurBuilder = RegExp(
  r'(?<![\w.])(ListView|GridView|SliverList)\.(builder|separated)\s*\(',
);

/// Une liste de widgets nommee : `final lignes = <Widget>[...]`.
final RegExp _listeVariable = RegExp(
  r'\b(?:List<Widget>\s+|final\s+(?:List<Widget>\s+)?|var\s+)(\w+)\s*=\s*(?:const\s*)?(?:<\s*Widget\s*>\s*)?\[',
);

/// L'axe d'une liste : l'espace pose dans l'autre sens ne separe rien.
enum _Axe { vertical, horizontal, les2 }

/// Le parent d'une liste : son axe et l'espace qu'il pose entre enfants.
class _Parent {
  const _Parent(this.axe, this.ecart);

  final _Axe axe;
  final double ecart;
}

/// Un element d'une liste, apres mise a plat.
class _Element {
  const _Element({
    this.carte = false,
    this.nom = '',
    this.index = 0,
    this.avant = 0,
    this.apres = 0,
    this.espace,
    this.minimum = ecartMinimumCartes,
  });

  /// Vrai quand l'element est une carte.
  final bool carte;

  /// Le nom de la carte, pour le message.
  final String nom;

  /// Le debut dans le texte, pour la ligne.
  final int index;

  /// L'espace pose par un `Padding` autour de la carte.
  final double avant;

  /// Voir [avant].
  final double apres;

  /// La taille quand l'element n'est qu'un espace ; `null` quand c'est un vrai
  /// element (titre, filet, texte) : il separe les cartes.
  final double? espace;

  /// L'ecart minimum que cette carte exige de sa voisine.
  final double minimum;
}

/// Une carte reconnue, et l'espace que son `Padding` pose autour.
class _Carte {
  const _Carte(this.nom, this.avant, this.apres, this.minimum);

  final String nom;
  final double avant;
  final double apres;
  final double minimum;
}

/// Le debut du corps d'une methode : `=> expression` ou `{ ... return`.
final RegExp _corpsRendu = RegExp(
  r'^\s*(?:async\s*)?(?:=>|\{[\s\S]*?\breturn)\s+',
);

/// Les 700 caracteres qui suivent [index] : assez pour trouver la premiere
/// expression rendue, sans lire tout le fichier.
String _debut(String t, int index) =>
    t.substring(index, index + 700 > t.length ? t.length : index + 700);

/// Les noms des widgets d'ecran dont `build` rend une carte, deduits de
/// [textes] (le texte de tous les fichiers du dossier concerne).
Set<String> cartesDerivees(Iterable<String> textes) {
  final Set<String> cartes = <String>{...cartesDuCore};
  final RegExp classe = RegExp(
    r'class\s+(\w+)\s+extends\s+\w+(?:<[^>{]*>)?\s*\{',
  );
  final List<(String, String)> corps = <(String, String)>[];
  for (final String t in textes) {
    for (final RegExpMatch m in classe.allMatches(t)) {
      final RegExpMatch? build = RegExp(r'Widget\s+build\s*\(')
          .firstMatch(t.substring(m.end));
      final int suivante = t.indexOf(RegExp(r'\nclass\s'), m.end);
      if (build == null || (suivante >= 0 && m.end + build.start > suivante)) {
        continue;
      }
      final int ferme = _fermante(t, m.end + build.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String suite = _debut(t, ferme + 1);
      final RegExpMatch? retour = _corpsRendu.firstMatch(suite);
      if (retour == null) {
        continue;
      }
      corps.add((m.group(1)!, suite.substring(retour.end)));
    }
  }
  bool change = true;
  while (change) {
    change = false;
    for (final (String, String) c in corps) {
      if (cartes.contains(c.$1)) {
        continue;
      }
      final _Carte? rendue = _carte(c.$2.trimLeft(), cartes, _Axe.les2);
      if (rendue != null && rendue.minimum > ecartMinimumBoites) {
        cartes.add(c.$1);
        change = true;
      }
    }
  }
  return cartes;
}

/// Les cartes que le fichier [t] nomme lui-meme : une variable locale qui
/// vaut une carte (`final Widget carte = AppCard(...)`), une methode qui en
/// rend une (`Widget _carte(...) => AppCard(...)`), une variable de boucle
/// typee par une carte (`for (final StatTile tuile in tuiles)`).
Set<String> _avecLocales(String t, Set<String> cartes) {
  final Set<String> sortie = <String>{...cartes};
  final RegExp variable = RegExp(
    r'(?:\bfinal|\bvar|\bWidget)\s+(?:Widget\s+)?(\w+)\s*=\s*',
  );
  final RegExp methode = RegExp(r'\bWidget\s+(\w+)\s*\(');
  final RegExp boucle = RegExp(
    r'\bfor\s*\(\s*(?:final\s+)?(\w+)\s+(\w+)\s+in\b',
  );
  bool change = true;
  while (change) {
    change = false;
    for (final RegExpMatch m in variable.allMatches(t)) {
      if (!sortie.contains(m.group(1)) &&
          _carte(t.substring(m.end).trimLeft(), sortie, _Axe.les2) != null) {
        sortie.add(m.group(1)!);
        change = true;
      }
    }
    for (final RegExpMatch m in methode.allMatches(t)) {
      if (sortie.contains(m.group(1))) {
        continue;
      }
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String suite = _debut(t, ferme + 1);
      final RegExpMatch? corps = _corpsRendu.firstMatch(suite);
      final _Carte? rendue = corps == null
          ? null
          : _carte(suite.substring(corps.end), sortie, _Axe.les2);
      // Une boite peinte (barre de squelette, pastille) n'est pas une carte.
      if (rendue != null && rendue.minimum > ecartMinimumBoites) {
        sortie.add(m.group(1)!);
        change = true;
      }
    }
    for (final RegExpMatch m in boucle.allMatches(t)) {
      if (sortie.contains(m.group(1)) && !sortie.contains(m.group(2))) {
        sortie.add(m.group(2)!);
        change = true;
      }
    }
  }
  return sortie;
}

/// Les cas de cartes collees du texte [t] du fichier [chemin].
List<CasCollage> cartesColleesDans(
  String chemin,
  String t, {
  Set<String> cartes = cartesDuCore,
}) {
  final Set<String> connues = _avecLocales(t, cartes);
  final List<CasCollage> cas = <CasCollage>[];
  final Map<String, int> rangs = <String, int>{};
  final Set<int> deja = <int>{};
  void signaler(int index, String nom, double ecart) {
    if (!deja.add(index)) {
      return;
    }
    final int rang = rangs[nom] = (rangs[nom] ?? 0) + 1;
    final String mesure = ecart <= 0 ? 'collees' : 'ecart ${_nombre(ecart)}';
    cas.add(CasCollage(chemin, _ligneDe(t, index), '$nom n°$rang ($mesure)'));
  }

  void verifier(List<_Element> suite, _Parent p) {
    for (int j = 0; j < suite.length; j++) {
      if (!suite[j].carte) {
        continue;
      }
      // La carte precedente, avec seulement des espaces entre elles.
      double somme = 0;
      int i = j - 1;
      while (i >= 0 && !suite[i].carte && suite[i].espace != null) {
        somme += suite[i].espace!;
        i--;
      }
      if (i < 0 || !suite[i].carte) {
        continue;
      }
      final double ecart =
          somme + suite[i].apres + suite[j].avant + p.ecart * (j - i);
      final double minimum = suite[i].minimum < suite[j].minimum
          ? suite[i].minimum
          : suite[j].minimum;
      if (ecart < minimum) {
        signaler(suite[j].index, suite[j].nom, ecart);
      }
    }
  }

  for (final RegExpMatch m in _listeEnfants.allMatches(t)) {
    final int ouvre = m.end - 1;
    final int parent = _appelParent(t, ouvre);
    final int ferme = _fermante(t, ouvre);
    final _Parent? p = parent < 0 ? null : _parent(t, parent);
    if (p != null && ferme > 0) {
      verifier(_aplatir(t, ouvre + 1, ferme, connues, p.axe), p);
    }
  }

  // Une liste construite a part, puis posee dans `children: liste`.
  for (final RegExpMatch m in _listeVariable.allMatches(t)) {
    final RegExpMatch? usage = RegExp(
      r'\bchildren\s*:\s*' + m.group(1)! + r'\b',
    ).firstMatch(t);
    if (usage == null) {
      continue;
    }
    final int parent = _appelParent(t, usage.start);
    final _Parent? p = parent < 0 ? null : _parent(t, parent);
    final int ouvre = m.end - 1;
    final int ferme = _fermante(t, ouvre);
    if (p != null && ferme > 0) {
      verifier(_aplatir(t, ouvre + 1, ferme, connues, p.axe), p);
    }
  }

  for (final RegExpMatch m in _constructeurBuilder.allMatches(t)) {
    final int ouvre = m.end - 1;
    final int ferme = _fermante(t, ouvre);
    if (ferme < 0) {
      continue;
    }
    final String appel = t.substring(ouvre, ferme);
    final int builder = appel.indexOf(RegExp(r'itemBuilder\s*:'));
    if (builder < 0) {
      continue;
    }
    final String corps = appel.substring(builder);
    final int retour = corps.indexOf(RegExp(r'(?:=>|return)\s*'));
    if (retour < 0) {
      continue;
    }
    final String expression = corps
        .substring(retour)
        .replaceFirst(RegExp(r'^(?:=>|return)\s*'), '');
    final _Carte? c = _carte(expression, connues, _Axe.les2);
    if (c == null) {
      continue;
    }
    double ecart = c.avant + c.apres;
    double minimum = c.minimum;
    if (m.group(1) == 'GridView') {
      final double a = _valeurNommee(appel, 'mainAxisSpacing') ?? 0;
      final double b = _valeurNommee(appel, 'crossAxisSpacing') ?? 0;
      ecart = a < b ? a : b;
    }
    if (m.group(2) == 'separated') {
      // Une liste dense a separateur : 8 au moins entre deux lignes.
      final RegExpMatch? s = RegExp(
        r'separatorBuilder\s*:[^=]*=>\s*([^;]*?)(?:,\s*itemBuilder|,\s*itemCount|\)\s*,?\s*$)',
        dotAll: true,
      ).firstMatch(appel);
      final double? e = s == null
          ? null
          : _espace(
              s.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' '),
              _Axe.vertical,
            );
      if (e == null) {
        continue;
      }
      ecart = e + c.avant + c.apres;
      minimum = minimum < ecartMinimumPastilles
          ? minimum
          : ecartMinimumPastilles;
    }
    if (ecart < minimum) {
      signaler(ouvre + builder + retour, c.nom, ecart);
    }
  }
  return cas;
}

String _nombre(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

/// Le parent de la liste dont l'appel s'ouvre en [ouvre] : `null` quand ce
/// n'est pas une `Column`, `Row`, `Wrap`, `Flex` ou `ListView`. Un `spacing:`
/// non numerique compte pour l'ecart minimum (on ne sait pas, on ne signale
/// pas).
_Parent? _parent(String t, int ouvre) {
  final RegExpMatch? nom = RegExp(r'([A-Z]\w*)(?:\.\w+)?\s*$')
      .firstMatch(t.substring(0, ouvre));
  if (nom == null || !_parents.contains(nom.group(1))) {
    return null;
  }
  final int ferme = _fermante(t, ouvre);
  if (ferme < 0) {
    return null;
  }
  // Les arguments du premier niveau seulement : un `spacing:` d'un enfant
  // n'est pas celui du parent.
  final String arguments = _premierNiveau(t.substring(ouvre + 1, ferme));
  final List<double> espaces = RegExp(r'\b(?:spacing|runSpacing)\s*:\s*([^,]+)')
      .allMatches(arguments)
      .map((RegExpMatch x) => _valeur(x.group(1)!.trim()) ?? ecartMinimumCartes)
      .toList();
  double ecart = 0;
  if (nom.group(1) == 'Wrap') {
    // Une grille a besoin des deux : le plus petit gouverne.
    ecart = espaces.length < 2
        ? 0
        : espaces.reduce((double a, double b) => a < b ? a : b);
  } else if (espaces.isNotEmpty) {
    ecart = espaces.first;
  }
  final _Axe axe = switch (nom.group(1)) {
    'Column' || 'ListView' || 'SliverList' => _Axe.vertical,
    'Row' => _Axe.horizontal,
    _ => _Axe.les2,
  };
  return _Parent(axe, ecart);
}

/// La valeur d'un espace : un nombre, `AppSpacing.md`, `Ecart.vLg`.
double? _valeur(String e) {
  final String x = e.replaceAll(RegExp(r'^const\s+'), '').trim();
  final double? n = double.tryParse(x);
  if (n != null) {
    return n;
  }
  final RegExpMatch? j = RegExp(r'^(?:AppSpacing\.(\w+)|Ecart\.[vh](\w+))$')
      .firstMatch(x);
  if (j == null) {
    return null;
  }
  return _jetons[j.group(1) ?? _minuscule(j.group(2)!)];
}

String _minuscule(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// La valeur de l'argument nomme [nom] dans [appel], ou `null`.
double? _valeurNommee(String appel, String nom) {
  final RegExpMatch? m = RegExp('\\b$nom\\s*:\\s*([^,)]+)').firstMatch(appel);
  return m == null ? null : _valeur(m.group(1)!.trim());
}

/// Le texte [s] sans ce qui est entre parentheses, crochets ou accolades.
String _premierNiveau(String s) {
  final StringBuffer sortie = StringBuffer();
  int profondeur = 0;
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c == "'" || c == '"') {
      final int fin = _finChaine(s, i);
      if (fin < 0) {
        break;
      }
      i = fin;
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (profondeur == 0) {
      sortie.write(c);
    }
  }
  return sortie.toString();
}

/// Met a plat les elements de la liste entre [debut] et [fin] : un `if` est
/// garde, un `...[a, b]` est deplie, une boucle compte deux tours de suite
/// (c'est la jonction des tours qui colle).
List<_Element> _aplatir(
  String t,
  int debut,
  int fin,
  Set<String> cartes,
  _Axe axe,
) {
  final List<_Element> sortie = <_Element>[];
  for (final (int, int) borne in _decouper(t, debut, fin)) {
    sortie.addAll(_element(t, borne.$1, borne.$2, cartes, axe));
  }
  return sortie;
}

List<_Element> _element(
  String t,
  int debut,
  int fin,
  Set<String> cartes,
  _Axe axe,
) {
  int d = debut;
  while (d < fin && RegExp(r'\s').hasMatch(t[d])) {
    d++;
  }
  String texte = t.substring(d, fin);
  if (texte.isEmpty) {
    return const <_Element>[];
  }
  // `if (cond) element` : on garde l'element, la condition seule ne change
  // pas la mise en page quand elle est vraie.
  final RegExpMatch? si = RegExp(r'^(?:if|else\s+if)\s*\(').firstMatch(texte);
  if (si != null) {
    final int fermeCondition = _fermante(t, d + si.end - 1);
    if (fermeCondition < 0 || fermeCondition >= fin) {
      return const <_Element>[];
    }
    // `if (c) a else b` : deux branches qui ne se suivent pas, separees par
    // une barriere ; chacune est examinee pour elle-meme.
    final String reste = t.substring(fermeCondition + 1, fin);
    final int sinon = _indexSinon(reste);
    if (sinon < 0) {
      return _element(t, fermeCondition + 1, fin, cartes, axe);
    }
    final int finA = fermeCondition + 1 + sinon;
    return <_Element>[
      ..._element(t, fermeCondition + 1, finA, cartes, axe),
      _Element(index: d),
      ..._element(t, finA + 4, fin, cartes, axe),
    ];
  }
  final RegExpMatch? boucle = RegExp(r'^for\s*\(').firstMatch(texte);
  if (boucle != null) {
    final int fermeBoucle = _fermante(t, d + boucle.end - 1);
    if (fermeBoucle < 0 || fermeBoucle >= fin) {
      return const <_Element>[];
    }
    final List<_Element> tour = _element(t, fermeBoucle + 1, fin, cartes, axe);
    return <_Element>[...tour, ...tour];
  }
  if (texte.startsWith('...')) {
    texte = texte.substring(3).trimLeft();
    final int decalage = fin - texte.length;
    final RegExpMatch? liste = RegExp(r'^(?:const\s*)?(?:<\s*Widget\s*>\s*)?\[')
        .firstMatch(texte);
    if (liste != null) {
      final int ouvre = decalage + liste.end - 1;
      final int ferme = _fermante(t, ouvre);
      if (ferme < 0) {
        return const <_Element>[];
      }
      return _aplatir(t, ouvre + 1, ferme, cartes, axe);
    }
    // `...x.map((e) => Carte(...))` : un tour par element.
    final RegExpMatch? carte = RegExp(r'\.map\s*(?:<[^>(]*>)?\s*\(')
        .firstMatch(texte);
    if (carte != null) {
      final int ouvre = decalage + carte.end - 1;
      final int ferme = _fermante(t, ouvre);
      if (ferme < 0) {
        return const <_Element>[];
      }
      final String lambda = t.substring(ouvre + 1, ferme);
      final int fleche = lambda.indexOf('=>');
      final int origine;
      if (fleche >= 0) {
        origine = ouvre + 1 + fleche + 2;
      } else {
        final int retour = lambda.indexOf(RegExp(r'return\s'));
        if (retour < 0) {
          return const <_Element>[];
        }
        origine = ouvre + 1 + retour + 7;
      }
      final List<_Element> tour = _element(t, origine, ferme, cartes, axe);
      return <_Element>[...tour, ...tour];
    }
    return const <_Element>[];
  }
  // Une liste litterale rendue par une fermeture : `[Carte(), Ecart.vLg]`.
  if (texte.startsWith('[')) {
    final int ferme = _fermante(t, d);
    if (ferme > 0 && ferme < fin) {
      return _aplatir(t, d + 1, ferme, cartes, axe);
    }
  }
  final _Carte? c = _carte(texte, cartes, axe);
  if (c != null) {
    return <_Element>[
      _Element(
        carte: true,
        nom: c.nom,
        index: d,
        avant: c.avant,
        apres: c.apres,
        minimum: c.minimum,
      ),
    ];
  }
  return <_Element>[_Element(index: d, espace: _espace(texte.trim(), axe))];
}

/// La taille d'un element qui n'est qu'un espace (`Ecart.vLg`,
/// `SizedBox(height: 16)`), 0 quand il est pose dans l'autre sens, `null`
/// quand c'est un vrai element qui separe les cartes (titre, filet).
double? _espace(String texte, _Axe axe) {
  final RegExpMatch? e = RegExp(r'^(?:const\s+)?Ecart\.([vh])(\w+)\s*$')
      .firstMatch(texte);
  if (e != null) {
    final double? v = _jetons[_minuscule(e.group(2)!)];
    if (v == null) {
      return null;
    }
    final bool vertical = e.group(1) == 'v';
    return (vertical && axe == _Axe.horizontal) ||
            (!vertical && axe == _Axe.vertical)
        ? 0
        : v;
  }
  final RegExpMatch? s = RegExp(r'^(?:const\s+)?SizedBox\s*\(')
      .firstMatch(texte);
  if (s != null) {
    final int ferme = _fermante(texte, s.end - 1);
    if (ferme < 0) {
      return null;
    }
    final String arguments = texte.substring(s.end, ferme);
    if (arguments.contains('child:')) {
      return null;
    }
    final double? h = _valeurNommee(arguments, 'height');
    final double? w = _valeurNommee(arguments, 'width');
    if (h == null && w == null) {
      return null;
    }
    return switch (axe) {
      _Axe.vertical => h ?? 0,
      _Axe.horizontal => w ?? 0,
      _Axe.les2 => h ?? w ?? 0,
    };
  }
  return null;
}

int _indexSinon(String reste) {
  int profondeur = 0;
  for (int i = 0; i < reste.length; i++) {
    final String c = reste[i];
    if (c == "'" || c == '"') {
      final int fin = _finChaine(reste, i);
      if (fin < 0) {
        return -1;
      }
      i = fin;
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (profondeur == 0 &&
        RegExp(r'\belse\b').matchAsPrefix(reste, i) != null &&
        (i == 0 || !RegExp(r'\w').hasMatch(reste[i - 1]))) {
      return i;
    }
  }
  return -1;
}

/// La carte que rend l'expression [e], ou `null` : une carte du jeu [cartes],
/// une enveloppe neutre ou un `Padding` autour d'une carte, ou une boite
/// peinte a la main avec fond ou filet et rayon.
_Carte? _carte(String e, Set<String> cartes, _Axe axe) {
  final String nu = e.trim();
  if (RegExp(r'^\w+$').hasMatch(nu) && cartes.contains(nu)) {
    return _Carte(nu, 0, 0, ecartMinimumCartes);
  }
  final RegExpMatch? m = RegExp(
    r'^(?:const\s+|new\s+)?([A-Za-z_]\w*)(?:\.\w+)?\s*(?:<[^>(]*>)?\s*\(',
  ).firstMatch(e);
  if (m == null) {
    return null;
  }
  final String nom = m.group(1)!;
  final int ouvre = m.end - 1;
  if (cartes.contains(nom)) {
    return _Carte(nom, 0, 0, _minimumDe(e, nom, ouvre));
  }
  if (_enveloppes.contains(nom) || nom == 'Padding') {
    final int ferme = _fermante(e, ouvre);
    if (ferme < 0) {
      return null;
    }
    final String arguments = e.substring(ouvre + 1, ferme);
    final RegExpMatch? enfant = RegExp(r'(?<![\w])child\s*:\s*')
        .firstMatch(_masquerNiveaux(arguments));
    if (enfant == null) {
      return null;
    }
    final List<(int, int)> bornes = _decouper(
      arguments,
      enfant.end,
      arguments.length,
    );
    if (bornes.isEmpty) {
      return null;
    }
    final _Carte? dedans = _carte(
      arguments.substring(bornes.first.$1, bornes.first.$2),
      cartes,
      axe,
    );
    if (dedans == null || nom != 'Padding') {
      return dedans;
    }
    final (double, double) marge = _marge(arguments, axe);
    return _Carte(
      dedans.nom,
      dedans.avant + marge.$1,
      dedans.apres + marge.$2,
      dedans.minimum,
    );
  }
  if (nom == 'DecoratedBox' || nom == 'Container') {
    final int ferme = _fermante(e, ouvre);
    if (ferme < 0) {
      return null;
    }
    final String arguments = e.substring(ouvre + 1, ferme);
    final int deco = arguments.indexOf('BoxDecoration(');
    if (deco < 0) {
      return null;
    }
    final int finDeco = _fermante(arguments, deco + 13);
    if (finDeco < 0) {
      return null;
    }
    final String peinture = arguments.substring(deco, finDeco);
    if (!peinture.contains('BoxShape.circle') &&
        peinture.contains('borderRadius') &&
        RegExp(r'\b(?:color|border)\s*:').hasMatch(peinture)) {
      return _Carte(nom, 0, 0, ecartMinimumBoites);
    }
  }
  return null;
}

/// L'ecart que [nom] exige : une `AppCard` a marge reduite (moins de 16) est
/// une pastille de choix, pas une carte de contenu : 8 lui suffisent.
double _minimumDe(String e, String nom, int ouvre) {
  if (nom != 'AppCard') {
    return ecartMinimumCartes;
  }
  final int ferme = _fermante(e, ouvre);
  if (ferme < 0) {
    return ecartMinimumCartes;
  }
  final double? marge = _valeurNommee(
    _premierNiveau(e.substring(ouvre + 1, ferme)),
    'marge',
  );
  return marge != null && marge < ecartMinimumCartes
      ? ecartMinimumPastilles
      : ecartMinimumCartes;
}

/// L'espace (avant, apres) que pose l'argument `padding:` d'un `Padding`.
(double, double) _marge(String arguments, _Axe axe) {
  final RegExpMatch? m = RegExp(
    r'padding\s*:\s*(?:const\s+)?EdgeInsets(?:Directional)?\.(\w+)\s*\(',
  ).firstMatch(arguments);
  if (m == null) {
    return (0, 0);
  }
  final int ferme = _fermante(arguments, m.end - 1);
  if (ferme < 0) {
    return (0, 0);
  }
  final String interieur = arguments.substring(m.end, ferme);
  double nom(String n) => _valeurNommee(interieur, n) ?? 0;
  double haut = 0;
  double bas = 0;
  double debut = 0;
  double fin = 0;
  switch (m.group(1)) {
    case 'all':
      haut = bas = debut = fin = _valeur(interieur.trim()) ?? 0;
    case 'symmetric':
      haut = bas = nom('vertical');
      debut = fin = nom('horizontal');
    default:
      haut = nom('top');
      bas = nom('bottom');
      debut = nom('start') > nom('left') ? nom('start') : nom('left');
      fin = nom('end') > nom('right') ? nom('end') : nom('right');
  }
  return switch (axe) {
    _Axe.vertical => (haut, bas),
    _Axe.horizontal => (debut, fin),
    _Axe.les2 => (haut > debut ? haut : debut, bas > fin ? bas : fin),
  };
}

/// Le texte avec ses parentheses, crochets et accolades internes remplaces
/// par des espaces : on y cherche un argument du premier niveau.
String _masquerNiveaux(String s) {
  final StringBuffer sortie = StringBuffer();
  int profondeur = 0;
  for (int i = 0; i < s.length; i++) {
    final String c = s[i];
    if (c == "'" || c == '"') {
      final int fin = _finChaine(s, i);
      if (fin < 0) {
        sortie.write(' ' * (s.length - i));
        break;
      }
      sortie.write(' ' * (fin - i + 1));
      i = fin;
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
      sortie.write(' ');
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
      sortie.write(' ');
    } else {
      sortie.write(profondeur == 0 ? c : ' ');
    }
  }
  return sortie.toString();
}

/// Les bornes des elements du premier niveau entre [debut] et [fin].
List<(int, int)> _decouper(String t, int debut, int fin) {
  final List<(int, int)> bornes = <(int, int)>[];
  int profondeur = 0;
  int depart = debut;
  for (int i = debut; i < fin; i++) {
    final String c = t[i];
    if (c == "'" || c == '"') {
      final int f = _finChaine(t, i);
      if (f < 0) {
        break;
      }
      i = f;
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (c == ',' && profondeur == 0) {
      bornes.add((depart, i));
      depart = i + 1;
    }
  }
  if (t.substring(depart, fin).trim().isNotEmpty) {
    bornes.add((depart, fin));
  }
  return bornes;
}

int _ligneDe(String texte, int index) =>
    '\n'.allMatches(texte.substring(0, index)).length + 1;

/// L'index de la fermante qui correspond a l'ouvrante a [debut].
int _fermante(String t, int debut) {
  int profondeur = 0;
  for (int i = debut; i < t.length; i++) {
    final String c = t[i];
    if (c == "'" || c == '"') {
      i = _finChaine(t, i);
      if (i < 0) {
        return -1;
      }
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
      if (profondeur == 0) {
        return i;
      }
    }
  }
  return -1;
}

int _finChaine(String t, int debut) {
  final String q = t[debut];
  for (int i = debut + 1; i < t.length; i++) {
    if (t[i] == r'\') {
      i++;
    } else if (t[i] == q || t[i] == '\n') {
      return i;
    }
  }
  return -1;
}

/// L'index de la parenthese ouvrante de l'appel qui contient [index].
int _appelParent(String t, int index) {
  int profondeur = 0;
  for (int i = index - 1; i >= 0; i--) {
    final String c = t[i];
    if (c == ')' || c == ']' || c == '}') {
      profondeur++;
    } else if (c == '(' || c == '[' || c == '{') {
      if (profondeur > 0) {
        profondeur--;
      } else if (c == '(') {
        return i;
      }
    }
  }
  return -1;
}

/// Les sources Dart des ecrans (hors `_dev` et fichiers generes).
Iterable<File> sourcesDesEcrans() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.endsWith('.g.dart'))
        .where((File f) => !f.path.contains('_dev'));

/// Les commentaires de ligne retires (les `//` d'une URL sont gardes).
String sansCommentaires(String source) => source
    .replaceAll('\r', '')
    .split('\n')
    .map((String l) => l.replaceFirst(RegExp(r'(?<![:\w])//.*$'), ''))
    .join('\n');

/// Tous les cas des sources de `lib/`, `core` compris.
List<CasCollage> tousLesCas() {
  final List<File> fichiers = sourcesDesEcrans().toList();
  final Map<String, String> textes = <String, String>{
    for (final File f in fichiers)
      f.path: sansCommentaires(f.readAsStringSync()),
  };
  final Set<String> cartes = cartesDerivees(textes.values);
  final List<CasCollage> cas = <CasCollage>[];
  for (final MapEntry<String, String> e in textes.entries) {
    cas.addAll(cartesColleesDans(e.key, e.value, cartes: cartes));
  }
  return cas;
}
