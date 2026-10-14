/// Le dessin d'une variante du logo, tel que livre par le directeur.
///
/// Dart pur (lu aussi par `tool/generer_logo.dart`). Les instances vivent dans
/// `logo_traces.g.dart`, **genere** depuis `assets/brand/logo/violet/*.svg` :
/// les chaines [traces] sont les attributs `d` recopies octet pour octet, la
/// boite [largeur] x [hauteur] est le `viewBox` du fichier. Aucune couleur ici
/// : un SVG livre n'a qu'un seul `fill`, que le composant `BrandLogo` choisit
/// d'apres le fond.
library;

/// Une variante du logo : sa source, son `viewBox`, sa regle de remplissage
/// et ses traces.
class DessinLogo {
  /// Cree un dessin.
  const DessinLogo({
    required this.source,
    required this.largeur,
    required this.hauteur,
    required this.pairImpair,
    required this.traces,
  });

  /// Le fichier SVG d'ou le dessin est tire, relatif a la racine du depot.
  final String source;

  /// La largeur du `viewBox` (son origine est 0 0 dans les fichiers livres).
  final double largeur;

  /// La hauteur du `viewBox`.
  final double hauteur;

  /// Vrai quand le SVG declare `fill-rule="evenodd"` ; faux pour la regle
  /// par defaut du SVG, `nonzero`.
  final bool pairImpair;

  /// Les attributs `d` des traces, dans l'ordre du fichier, mot pour mot.
  final List<String> traces;

  /// Largeur sur hauteur : la proportion verrouillee de la variante.
  double get proportion => largeur / hauteur;
}
