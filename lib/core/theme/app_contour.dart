/// Jetons d'epaisseur de contour et de seuil d'echelle de texte (ETATS-BTN-1).
///
/// Source : l'anneau de focus de `Pressable` (WCAG 2.4.11, 2 points minimum
/// visibles) ; le seuil de 130 % est celui deja applique par `nav_shell` et le
/// Teaching Dock (doc 04 §28 et §33 n. 13). Une valeur de ce fichier se change
/// ici, jamais dans un widget.
abstract final class AppContour {
  /// Le contour fort : deux points. Contour d'une bascule inactive, d'un outil
  /// inactif, anneau de focus.
  static const double fort = 2;

  /// L'echelle de texte au-dela de laquelle un mot d'etat de rangee compacte
  /// cede la place a l'infobulle.
  static const double seuilTexteAgrandi = 1.3;
}
