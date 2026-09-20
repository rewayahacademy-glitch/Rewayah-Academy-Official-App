import 'annotation_layer.dart';
import 'etat_outils.dart';
import 'intention_pedagogique.dart';
import 'port_dock_hote.dart';

/// La facade de libelles du lot D, en attendant slang.
///
/// **Mecanisme impose par la decision D-03.** Neuf agents paralleles et un seul
/// `assets/i18n/fr.i18n.json` de 68 Ko, dont la sortie generee de 244 Ko est
/// versionnee : neuf agents qui y ecriraient produiraient neuf conflits
/// non fusionnables a la main. Chaque libelle vit donc ici, annote de la clef
/// qu'il prendra, et la meme liste est deposee dans
/// `docs/teaching-core/i18n/tc_i18n_D.json`.
///
/// **Agent Z** fusionne les neuf JSON, regenere slang, remplace ces constantes
/// par `t.tc.outils.*` et supprime ce fichier. Aucun autre agent ne le lit.
///
/// Les libelles portent leurs accents : ce sont des textes lus par des
/// utilisateurs, pas des commentaires de code. Zero emoji, zero M-dash, comme
/// partout ailleurs dans le depot.
abstract final class LibellesOutils {
  // --- Le dock ------------------------------------------------------------

  /// TC-I18N: cle=tc.outils.dock.titre
  static const String dockTitre = 'Outils';

  /// TC-I18N: cle=tc.outils.dock.deplacer
  static const String dockDeplacer = 'Déplacer les outils';

  /// TC-I18N: cle=tc.outils.dock.position.bas
  static const String positionBas = 'En bas';

  /// TC-I18N: cle=tc.outils.dock.position.gauche
  static const String positionGauche = 'À gauche';

  /// TC-I18N: cle=tc.outils.dock.position.droite
  static const String positionDroite = 'À droite';

  /// Le libelle d'une position du dock.
  static String position(PositionDock position) => switch (position) {
    PositionDock.bas => positionBas,
    PositionDock.gauche => positionGauche,
    PositionDock.droite => positionDroite,
  };

  // --- Les sept outils ----------------------------------------------------

  /// TC-I18N: cle=tc.outils.dock.bibliotheque
  static const String outilBibliotheque = 'Bibliothèque';

  /// TC-I18N: cle=tc.outils.dock.focus
  static const String outilFocus = 'Focus';

  /// TC-I18N: cle=tc.outils.dock.marquer
  static const String outilMarquer = 'Marquer';

  /// TC-I18N: cle=tc.outils.dock.masquer
  static const String outilMasquer = 'Masquer';

  /// TC-I18N: cle=tc.outils.dock.stylet
  static const String outilStylet = 'Stylet';

  /// TC-I18N: cle=tc.outils.dock.pointeur
  static const String outilPointeur = 'Pointeur';

  /// TC-I18N: cle=tc.outils.dock.revision
  static const String outilRevision = 'Révision';

  /// Le libelle d'un outil du dock.
  static String outil(OutilDock outil) => switch (outil) {
    OutilDock.bibliotheque => outilBibliotheque,
    OutilDock.focus => outilFocus,
    OutilDock.marquer => outilMarquer,
    OutilDock.masquer => outilMasquer,
    OutilDock.stylet => outilStylet,
    OutilDock.pointeur => outilPointeur,
    OutilDock.revision => outilRevision,
  };

  // --- Les cinq intentions, libelles exacts de la spec 8.2 ----------------

  /// TC-I18N: cle=tc.outils.intention.aApprendre
  static const String intentionAApprendre = 'À apprendre';

  /// TC-I18N: cle=tc.outils.intention.aRevoir
  static const String intentionARevoir = 'À revoir';

  /// TC-I18N: cle=tc.outils.intention.aRenforcer
  static const String intentionARenforcer = 'À renforcer';

  /// TC-I18N: cle=tc.outils.intention.aEntretenir
  static const String intentionAEntretenir = 'À entretenir';

  /// TC-I18N: cle=tc.outils.intention.pourEvaluation
  static const String intentionPourEvaluation = "Pour l'évaluation";

  /// Le libelle utilisateur d'une intention.
  ///
  /// **Les cinq libelles sont fixes par la spec (section 8.2)** : ils ne se
  /// reformulent pas au fil des ecrans. Un marqueur porte toujours ce mot, et
  /// jamais sa seule couleur.
  static String intention(IntentionPedagogique intention) =>
      switch (intention) {
        IntentionPedagogique.aApprendre => intentionAApprendre,
        IntentionPedagogique.aRevoir => intentionARevoir,
        IntentionPedagogique.aRenforcer => intentionARenforcer,
        IntentionPedagogique.aEntretenir => intentionAEntretenir,
        IntentionPedagogique.pourEvaluation => intentionPourEvaluation,
      };

  // --- La barre du stylet -------------------------------------------------

  /// TC-I18N: cle=tc.outils.trait.stylet
  static const String traitStylet = 'Stylet';

  /// TC-I18N: cle=tc.outils.trait.surligneur
  static const String traitSurligneur = 'Surligner';

  /// TC-I18N: cle=tc.outils.trait.gomme
  static const String traitGomme = 'Gomme';

  /// TC-I18N: cle=tc.outils.trait.annuler
  static const String traitAnnuler = 'Annuler';

  /// TC-I18N: cle=tc.outils.trait.plus
  static const String traitPlus = 'Plus';

  /// Le libelle d'un outil de trace.
  static String outilTrait(OutilTrait outil) => switch (outil) {
    OutilTrait.stylet => traitStylet,
    OutilTrait.surligneur => traitSurligneur,
    OutilTrait.gomme => traitGomme,
  };

  // --- Les trois portees --------------------------------------------------

  /// TC-I18N: cle=tc.outils.portee.temporaire
  static const String porteeTemporaire = "Le temps d'expliquer";

  /// TC-I18N: cle=tc.outils.portee.seance
  static const String porteeSeance = "Jusqu'à la fin du cours";

  /// TC-I18N: cle=tc.outils.portee.enregistree
  static const String porteeEnregistree = 'Enregistrer';

  /// TC-I18N: cle=tc.outils.portee.aide
  static const String porteeAide = 'Combien de temps garder ces annotations ?';

  /// Le libelle d'une portee.
  ///
  /// Trois libelles qui disent **ce qui va se passer**, et non le nom technique
  /// de la portee : « temporaire » ne dit rien a personne, « le temps
  /// d'expliquer » dit tout.
  static String portee(PorteeAnnotation portee) => switch (portee) {
    PorteeAnnotation.temporaire => porteeTemporaire,
    PorteeAnnotation.seance => porteeSeance,
    PorteeAnnotation.enregistree => porteeEnregistree,
  };

  // --- Les feuilles -------------------------------------------------------

  /// TC-I18N: cle=tc.outils.marquer.titre
  static const String marquerTitre = 'Marquer ce passage';

  /// TC-I18N: cle=tc.outils.marquer.aide
  static const String marquerAide = 'Choisissez ce que ce passage demande.';

  /// TC-I18N: cle=tc.outils.marquer.retirer
  static const String marquerRetirer = 'Retirer le marqueur';

  /// TC-I18N: cle=tc.outils.revision.titre
  static const String revisionTitre = 'À préparer';

  /// TC-I18N: cle=tc.outils.revision.aide
  static const String revisionAide =
      'Le passage sélectionné devient un travail à préparer.';

  /// TC-I18N: cle=tc.outils.revision.groupeEntier
  static const String revisionGroupeEntier = 'Tout le groupe';

  /// TC-I18N: cle=tc.outils.revision.consigne
  static const String revisionConsigne = 'Consigne courte (facultatif)';

  /// TC-I18N: cle=tc.outils.revision.creer
  static const String revisionCreer = 'Poser le travail';

  /// TC-I18N: cle=tc.outils.revision.posee
  static const String revisionPosee = 'Travail à préparer posé';

  /// TC-I18N: cle=tc.outils.masquer.reveler
  static const String masquerReveler = 'Révéler';

  /// TC-I18N: cle=tc.outils.masquer.refermer
  static const String masquerRefermer = 'Masquer de nouveau';

  /// TC-I18N: cle=tc.outils.masquer.tout
  static const String masquerToutRetirer = 'Tout démasquer';

  /// TC-I18N: cle=tc.outils.focus.quitter
  static const String focusQuitter = 'Quitter le focus';

  // --- Ce que l'on avertit ------------------------------------------------

  /// TC-I18N: cle=tc.outils.annotation.ancrageDegrade
  static const String ancrageDegrade =
      "Ce passage n'a pas de repère de texte : "
      "l'annotation suivra la page, pas les mots.";

  /// TC-I18N: cle=tc.outils.annotation.horsPage
  static const String annotationHorsPage =
      "Annotations masquées : leur passage n'est pas à l'écran.";

  /// TC-I18N: cle=tc.outils.annotation.aucuneSelection
  static const String aucuneSelection = "Sélectionnez d'abord un passage.";
}
