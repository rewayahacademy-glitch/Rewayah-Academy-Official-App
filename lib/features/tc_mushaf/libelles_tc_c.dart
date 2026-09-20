/// Les libelles du moteur Coran, en attendant la fusion slang d'Agent Z.
///
/// **Façade temporaire, decidee par D-03.** `assets/i18n/fr.i18n.json` et les
/// deux fichiers generes de `lib/core/i18n/` sont partages par neuf agents et
/// par le chantier enseignant : neuf regenerations de 244 Ko de code versionne
/// ne se fusionnent pas a la main. Chaque constante porte donc sa cle cible en
/// commentaire `// TC-I18N:`, et le meme texte vit dans
/// `docs/teaching-core/i18n/tc_i18n_C.json`. Agent Z fusionne, regenere,
/// remplace les appels et supprime ce fichier.
///
/// **Ce qui existe deja n'est pas recopie ici.** Le sous-arbre `eleve.coran`
/// porte deja le titre, la pagination, le juz, la reprise, les quatre etats du
/// lecteur, l'attribution Tanzil et les commandes de taille : l'ecran les lit
/// par `t.eleve.coran.*`. Seuls les libelles que le moteur ajoute sont ici.
library;

/// Les libelles neufs du moteur Coran.
abstract final class LibellesCoran {
  // --- Les trois rendus ---------------------------------------------------

  /// TC-I18N: cle=tc.coran.modes.mushaf
  static const String modeMushaf = 'Page du mushaf';

  /// TC-I18N: cle=tc.coran.modes.verset
  static const String modeVerset = 'Lecture agrandie';

  /// TC-I18N: cle=tc.coran.modes.focus
  static const String modeFocus = 'Focus';

  /// TC-I18N: cle=tc.coran.modes.choisir
  static const String choisirMode = 'Mode de lecture';

  // --- La page et l'ouverture ---------------------------------------------

  /// TC-I18N: cle=tc.coran.mushaf.coteDroite
  static const String coteDroite = 'Page de droite';

  /// TC-I18N: cle=tc.coran.mushaf.coteGauche
  static const String coteGauche = 'Page de gauche';

  /// TC-I18N: cle=tc.coran.mushaf.ouverture
  static String ouverture(int droite, int gauche) =>
      'Ouverture, pages $droite et $gauche';

  // --- La fidelite de composition -----------------------------------------

  /// TC-I18N: cle=tc.coran.fidelite.approchee
  static const String compositionApprochee = 'Composition approchee';

  /// TC-I18N: cle=tc.coran.fidelite.approcheeDetail
  static const String compositionApprocheeDetail =
      'Les versets de cette page sont exactement ceux de la page du Mushaf '
      'de Medine. Leur repartition sur les lignes, elle, est celle de cet '
      "ecran : le decoupage en lignes de l'edition n'est pas encore importe.";

  /// TC-I18N: cle=tc.coran.fidelite.fidele
  static const String compositionFidele = "Composition de l'edition";

  // --- Zoom ----------------------------------------------------------------

  /// TC-I18N: cle=tc.coran.zoom.bride
  static const String zoomBride =
      'Grossissement limite par la largeur : au dela, un mot serait coupe.';

  /// TC-I18N: cle=tc.coran.zoom.valeur
  static String zoomValeur(int pourcent) => '$pourcent %';

  /// TC-I18N: cle=tc.coran.zoom.renvoiLectureAgrandie
  static const String zoomRenvoiLectureAgrandie =
      'Pour grossir le texte, passez en lecture agrandie : la page du mushaf '
      'garde sa geometrie.';

  // --- Navigation ----------------------------------------------------------

  /// TC-I18N: cle=tc.coran.navigation.titre
  static const String navigationTitre = 'Aller a';

  /// TC-I18N: cle=tc.coran.navigation.ouvrir
  static const String navigationOuvrir = 'Aller a une page';

  /// TC-I18N: cle=tc.coran.navigation.champ
  static const String navigationChamp = 'Page, sourate, juz ou reference';

  /// TC-I18N: cle=tc.coran.navigation.indice
  static const String navigationIndice = 'Par exemple 18, Al-Kahf, juz 15, 2:255';

  /// TC-I18N: cle=tc.coran.navigation.limite
  static const String navigationLimite =
      'La recherche porte sur les numeros de page, les references et les noms '
      "de sourate. La recherche dans le texte du Coran n'est pas encore "
      'disponible.';

  /// TC-I18N: cle=tc.coran.navigation.aucunResultat
  static const String navigationAucunResultat = 'Aucune reference trouvee';

  /// TC-I18N: cle=tc.coran.navigation.pageNumero
  static String pageNumero(int page) => 'Page $page';

  /// TC-I18N: cle=tc.coran.navigation.aucunResultatDetail
  static const String navigationAucunResultatDetail =
      'Essayez un numero de page, un nom de sourate, ou une reference comme '
      '2:255.';

  // --- Reprises ------------------------------------------------------------

  /// TC-I18N: cle=tc.coran.reprise.groupe
  static const String repriseGroupe = 'Reprendre le cours';

  /// TC-I18N: cle=tc.coran.reprise.groupeDetail
  static String repriseGroupeDetail(int page) => 'Le groupe en etait page $page';

  // --- Focus ---------------------------------------------------------------

  /// TC-I18N: cle=tc.coran.focus.aucunePlage
  static const String focusAucunePlage = 'Aucun passage mis en avant';

  /// TC-I18N: cle=tc.coran.focus.aucunePlageDetail
  static const String focusAucunePlageDetail =
      "Le focus suit le passage que l'enseignant designe. Hors classe, il "
      'centre la page ouverte.';

  /// TC-I18N: cle=tc.coran.focus.quitter
  static const String focusQuitter = 'Quitter le focus';
}
