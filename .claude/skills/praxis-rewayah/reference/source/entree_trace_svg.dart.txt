/// Lecture des donnees `d` d'un trace SVG, en Dart pur.
///
/// **Aucune dependance a Flutter** : ce fichier est lu par le generateur
/// `tool/generer_logo.dart` (lance par `dart run`, sans `dart:ui`) autant que
/// par le composant `BrandLogo`. Il rend une liste de commandes **absolues et
/// normalisees** (deplacer, ligne, cubique, quadratique, fermer) ; c'est le
/// composant qui les transforme en `Path`.
///
/// Commandes couvertes : `M L H V C S Q T Z`, absolues et relatives, avec
/// repetitions implicites (`M 0 0 10 10` trace une ligne apres le premier
/// point) et toutes les ecritures de nombre du SVG (`-.5`, `1.5e-3`,
/// `0-1.56-.14`, `1.5.5`). **Les arcs (`A`) levent** : aucun trace du logo
/// n'en contient, et dessiner faux en silence serait pire qu'echouer.
library;

/// La nature d'une commande normalisee.
enum NatureCommande {
  /// Deplacer le crayon sans tracer (un point).
  deplacer,

  /// Une ligne droite jusqu'au point.
  ligne,

  /// Une courbe de Bezier cubique (deux points de controle, un point).
  cubique,

  /// Une courbe de Bezier quadratique (un point de controle, un point).
  quadratique,

  /// Fermer le sous-trace courant.
  fermer,
}

/// Une commande absolue : sa nature et ses coordonnees, a plat
/// (`x1, y1, x2, y2, x, y` pour une cubique).
class CommandeTrace {
  /// Cree une commande.
  const CommandeTrace(this.nature, this.coordonnees);

  /// La nature de la commande.
  final NatureCommande nature;

  /// Les coordonnees absolues, dans l'ordre du SVG.
  final List<double> coordonnees;

  @override
  bool operator ==(Object other) {
    if (other is! CommandeTrace || other.nature != nature) return false;
    if (other.coordonnees.length != coordonnees.length) return false;
    for (int i = 0; i < coordonnees.length; i++) {
      if (other.coordonnees[i] != coordonnees[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(nature, Object.hashAll(coordonnees));

  @override
  String toString() => '${nature.name}$coordonnees';
}

/// Un jeton : une lettre de commande, ou un nombre SVG complet.
final RegExp _jeton = RegExp(
  r'[A-Za-z]|[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?',
);

final RegExp _lettre = RegExp(r'^[A-Za-z]$');

/// Le nombre de coordonnees que consomme chaque commande, par repetition.
const Map<String, int> _arite = <String, int>{
  'M': 2,
  'L': 2,
  'H': 1,
  'V': 1,
  'C': 6,
  'S': 4,
  'Q': 4,
  'T': 2,
  'Z': 0,
};

/// Lit les donnees `d` d'un trace SVG en commandes absolues.
///
/// Leve une [FormatException] sur une commande inconnue (dont les arcs), un
/// nombre avant toute commande ou une commande a qui il manque des nombres.
List<CommandeTrace> lireTraceSvg(String donnees) {
  final List<String> jetons = <String>[
    for (final RegExpMatch m in _jeton.allMatches(donnees)) m.group(0)!,
  ];
  final List<CommandeTrace> sortie = <CommandeTrace>[];

  double x = 0;
  double y = 0;
  double xDepart = 0;
  double yDepart = 0;
  // Le dernier point de controle, pour la reflexion de `S` (cubique) et de
  // `T` (quadratique). Nul quand la commande precedente n'en a pas.
  double? xCubique;
  double? yCubique;
  double? xQuad;
  double? yQuad;
  String? commande;
  int i = 0;

  double suivant() {
    if (i >= jetons.length || _lettre.hasMatch(jetons[i])) {
      throw FormatException('nombre attendu apres $commande', donnees);
    }
    return double.parse(jetons[i++]);
  }

  while (i < jetons.length) {
    if (_lettre.hasMatch(jetons[i])) {
      commande = jetons[i];
      i++;
      if (!_arite.containsKey(commande.toUpperCase())) {
        throw FormatException('commande de trace inconnue', commande);
      }
      if (commande.toUpperCase() == 'Z') {
        sortie.add(const CommandeTrace(NatureCommande.fermer, <double>[]));
        x = xDepart;
        y = yDepart;
        xCubique = yCubique = xQuad = yQuad = null;
        continue;
      }
    } else if (commande == null) {
      throw FormatException('nombre avant toute commande', donnees);
    } else if (commande.toUpperCase() == 'Z') {
      throw FormatException('nombre apres Z', donnees);
    }

    final String c = commande;
    final bool relatif = c == c.toLowerCase();
    final double ox = relatif ? x : 0;
    final double oy = relatif ? y : 0;

    switch (c.toUpperCase()) {
      case 'M':
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(CommandeTrace(NatureCommande.deplacer, <double>[x, y]));
        xDepart = x;
        yDepart = y;
        xCubique = yCubique = xQuad = yQuad = null;
        // Les paires suivantes d'un `M` sont des lignes.
        commande = relatif ? 'l' : 'L';
      case 'L':
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(CommandeTrace(NatureCommande.ligne, <double>[x, y]));
        xCubique = yCubique = xQuad = yQuad = null;
      case 'H':
        x = ox + suivant();
        sortie.add(CommandeTrace(NatureCommande.ligne, <double>[x, y]));
        xCubique = yCubique = xQuad = yQuad = null;
      case 'V':
        y = oy + suivant();
        sortie.add(CommandeTrace(NatureCommande.ligne, <double>[x, y]));
        xCubique = yCubique = xQuad = yQuad = null;
      case 'C':
        final double x1 = ox + suivant();
        final double y1 = oy + suivant();
        final double x2 = ox + suivant();
        final double y2 = oy + suivant();
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(
          CommandeTrace(NatureCommande.cubique, <double>[x1, y1, x2, y2, x, y]),
        );
        xCubique = x2;
        yCubique = y2;
        xQuad = yQuad = null;
      case 'S':
        final double x1 = xCubique == null ? x : 2 * x - xCubique;
        final double y1 = yCubique == null ? y : 2 * y - yCubique;
        final double x2 = ox + suivant();
        final double y2 = oy + suivant();
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(
          CommandeTrace(NatureCommande.cubique, <double>[x1, y1, x2, y2, x, y]),
        );
        xCubique = x2;
        yCubique = y2;
        xQuad = yQuad = null;
      case 'Q':
        final double x1 = ox + suivant();
        final double y1 = oy + suivant();
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(
          CommandeTrace(NatureCommande.quadratique, <double>[x1, y1, x, y]),
        );
        xQuad = x1;
        yQuad = y1;
        xCubique = yCubique = null;
      case 'T':
        final double x1 = xQuad == null ? x : 2 * x - xQuad;
        final double y1 = yQuad == null ? y : 2 * y - yQuad;
        x = ox + suivant();
        y = oy + suivant();
        sortie.add(
          CommandeTrace(NatureCommande.quadratique, <double>[x1, y1, x, y]),
        );
        xQuad = x1;
        yQuad = y1;
        xCubique = yCubique = null;
    }
  }
  return sortie;
}
