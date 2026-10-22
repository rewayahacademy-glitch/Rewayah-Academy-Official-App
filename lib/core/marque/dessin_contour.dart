/// Le dessin du symbole en contour, tel que livre par le directeur.
///
/// Dart pur (lu aussi par `tool/generer_contour.dart`). L'instance vit dans
/// `contour_traces.g.dart`, **genere** depuis
/// `assets/brand/logo/violet/symbole-contour.svg` : les chaines [traces] sont
/// les attributs `d` recopies octet pour octet, la boite [largeur] x [hauteur]
/// est le `viewBox`, [epaisseur] le `stroke-width` du fichier. Le fichier est un
/// **trait** (pas un aplat) : les traces se peignent en `stroke`, jamais en
/// `fill`. Aucune couleur ici : un SVG livre n'en a qu'une, que le support
/// choisit d'apres son fond (`peinture_contour.dart`).
library;

/// Le symbole en contour : sa source, son `viewBox`, l'epaisseur et la jointure
/// de son trait, et ses traces.
class DessinContour {
  /// Cree un dessin.
  const DessinContour({
    required this.source,
    required this.largeur,
    required this.hauteur,
    required this.epaisseur,
    required this.traces,
  });

  /// Le fichier SVG d'ou le dessin est tire, relatif a la racine du depot.
  final String source;

  /// La largeur du `viewBox` (son origine est 0 0 dans le fichier livre).
  final double largeur;

  /// La hauteur du `viewBox`.
  final double hauteur;

  /// Le `stroke-width` du fichier, dans les unites du `viewBox`. La jointure
  /// du fichier (`stroke-linejoin="round"`) est reproduite par le rendu.
  final double epaisseur;

  /// Les attributs `d` des traces, dans l'ordre du fichier, mot pour mot.
  final List<String> traces;

  /// Largeur sur hauteur : la proportion verrouillee du symbole.
  double get proportion => largeur / hauteur;
}
