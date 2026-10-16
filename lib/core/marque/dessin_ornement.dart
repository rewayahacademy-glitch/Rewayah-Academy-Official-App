/// Le dessin d'un ornement de la marque, tel que livre par le directeur.
///
/// Dart pur (lu aussi par `tool/generer_ornement.dart`). Les instances vivent
/// dans `ornement_traces.g.dart`, **genere** depuis
/// `assets/brand/logo/violet/ornement-*.svg` : [trace] est l'attribut `d`
/// recopie mot pour mot, la boite [largeur] x [hauteur] est le `viewBox`.
///
/// Le contour (`ornement-contour.svg`) est livre « en contour exterieur » : un
/// trace epais, masque par la forme pleine. [masque] porte cette forme ; le
/// rendu ne peint que la part du trace qui reste hors d'elle, exactement ce
/// que fait le `<mask>` du fichier.
library;

/// Un ornement : sa source, son `viewBox`, son trace et son masque eventuel.
class DessinOrnement {
  /// Cree un dessin.
  const DessinOrnement({
    required this.source,
    required this.largeur,
    required this.hauteur,
    required this.trace,
    this.masque,
  });

  /// Le fichier SVG d'ou le dessin est tire, relatif a la racine du depot.
  final String source;

  /// La largeur du `viewBox`.
  final double largeur;

  /// La hauteur du `viewBox`.
  final double hauteur;

  /// L'attribut `d` du trace, mot pour mot.
  final String trace;

  /// L'attribut `d` de la forme qui masque le trace (le contour), ou `null`
  /// pour un ornement plein.
  final String? masque;

  /// Largeur sur hauteur.
  double get proportion => largeur / hauteur;
}
