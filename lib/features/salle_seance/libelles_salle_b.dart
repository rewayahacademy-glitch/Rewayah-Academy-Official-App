// Les libelles nouveaux de la salle B (EN-10), en francais seulement.
//
// Sources : 04_ENSEIGNANT §19.1 (ordre du selecteur), 02_DECOUPAGE ligne EN-10
// et maquettes enseignant planche 3 (barre compacte). Les autres libelles du
// dock et du selecteur viennent des traductions existantes (`t.salle`,
// `t.tc.bibliotheque`). A porter dans les traductions a LG-1.

/// Les libelles nouveaux de la salle B.
abstract final class LibellesSalleB {
  /// 04_ENSEIGNANT §19.1, deuxieme onglet : « Cette Classe ».
  static const String cetteClasse = 'Cette Classe';

  /// EN-KB, memoire ENSEIGNANT-2026-09-26 regle E19 (titre de la regle) :
  /// la ligne de `/compte/reglages`.
  static const String raccourcisTitre =
      'Raccourcis clavier en salle sur ordinateur';

  /// EN-KB, regle E19, premier et troisieme points ; « roster » (mot de la
  /// regle E19) est remplace par « Élèves », le nom que porte le panneau a
  /// l'ecran (EN-9, EN-11, E17 : aucun terme qui n'est pas affiche ailleurs).
  static const String raccourcisDetail =
      'M micro, V caméra, R Élèves, B bibliothèque, Échap ferme le panneau. '
      "La caméra ne s'allume jamais par un raccourci.";
}
