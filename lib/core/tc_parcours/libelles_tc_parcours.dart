import 'ports_externes/intention_pedagogique.dart';
import 'student_concern.dart';

/// La facade de libelles du lot H, en attendant slang.
///
/// **Mecanisme impose par la decision D-03.** Neuf agents paralleles et un seul
/// `assets/i18n/fr.i18n.json` de 68 Ko, dont la sortie generee de 244 Ko est
/// versionnee : neuf agents qui y ecriraient produiraient neuf conflits non
/// fusionnables a la main. Chaque libelle vit donc ici, annote de la clef qu'il
/// prendra, et la meme liste est deposee dans
/// `docs/teaching-core/i18n/tc_i18n_H.json`.
///
/// **Agent Z** fusionne les neuf JSON, regenere slang, remplace ces constantes
/// par `t.tc.parcours.*` et supprime ce fichier.
///
/// Les libelles portent leurs accents : ce sont des textes lus par des
/// utilisateurs, pas des commentaires de code. Zero emoji, zero M-dash, comme
/// partout ailleurs dans le depot -- et c'est pour cela que les trois visages de
/// la maquette de la spec section 12.1 ne sont pas ici : ils sont rendus par des
/// mots, que l'Interface guidee sait aussi lire a voix haute.
abstract final class LibellesParcours {
  // --- Avant le prochain cours -------------------------------------------

  /// TC-I18N: cle=tc.parcours.avant.titre
  static const String avantTitre = 'Avant le prochain cours';

  /// TC-I18N: cle=tc.parcours.avant.rien
  static const String avantRien = 'Rien à préparer pour le prochain cours.';

  /// TC-I18N: cle=tc.parcours.avant.rienDetail
  static const String avantRienDetail =
      'Votre enseignant proposera le travail à la fin de la prochaine séance.';

  /// TC-I18N: cle=tc.parcours.avant.nonBranche
  ///
  /// **Jamais confondu avec `avantRien`.** Celui-ci dit que la source du travail
  /// n'est pas encore lue ; l'autre affirme qu'il n'y a rien a preparer. Dire le
  /// second a la place du premier serait affirmer une absence que personne n'a
  /// mesuree.
  static const String avantNonBranche =
      "Le travail à préparer n'est pas encore relié à cet espace.";

  /// TC-I18N: cle=tc.parcours.avant.nonBrancheDetail
  static const String avantNonBrancheDetail =
      "Cela ne veut pas dire qu'il n'y a rien à préparer : cet écran ne sait "
      'pas encore le lire.';

  /// TC-I18N: cle=tc.parcours.avant.reprendre
  static const String avantReprendre = 'Reprendre le cours';

  /// TC-I18N: cle=tc.parcours.avant.reprendreDepuis
  static String avantReprendreDepuis(String position) =>
      'Reprendre le cours à $position';

  // --- Les cinq intentions, reprises d'Agent D ----------------------------

  /// TC-I18N: cle=tc.parcours.intention.apprendre
  static const String intentionApprendre = 'À apprendre';

  /// TC-I18N: cle=tc.parcours.intention.revoir
  static const String intentionRevoir = 'À revoir';

  /// TC-I18N: cle=tc.parcours.intention.renforcer
  static const String intentionRenforcer = 'À renforcer';

  /// TC-I18N: cle=tc.parcours.intention.entretenir
  static const String intentionEntretenir = 'À entretenir';

  /// TC-I18N: cle=tc.parcours.intention.evaluation
  static const String intentionEvaluation = "Pour l'évaluation";

  /// Le libelle d'une intention pedagogique.
  ///
  /// **Le meme vocabulaire que les marqueurs d'Agent D**, jamais un second : le
  /// lot H traduit l'enum, il n'en invente pas les valeurs.
  static String intention(IntentionPedagogique intention) =>
      switch (intention) {
        IntentionPedagogique.aApprendre => intentionApprendre,
        IntentionPedagogique.aRevoir => intentionRevoir,
        IntentionPedagogique.aRenforcer => intentionRenforcer,
        IntentionPedagogique.aEntretenir => intentionEntretenir,
        IntentionPedagogique.pourEvaluation => intentionEvaluation,
      };

  // --- Comment se dit une plage de travail --------------------------------

  /// TC-I18N: cle=tc.parcours.plage.versets
  static String plageVersets({
    required int sourate,
    required int premier,
    required int dernier,
  }) => premier == dernier
      ? 'Sourate $sourate, verset $premier'
      : 'Sourate $sourate, versets $premier à $dernier';

  /// TC-I18N: cle=tc.parcours.plage.versetsCroisee
  static String plageVersetsCroisee({
    required int sourateDebut,
    required int versetDebut,
    required int sourateFin,
    required int versetFin,
  }) =>
      'Sourate $sourateDebut, verset $versetDebut '
      "jusqu'à sourate $sourateFin, verset $versetFin";

  /// TC-I18N: cle=tc.parcours.plage.pages
  static String plagePages({required int premiere, required int derniere}) =>
      premiere == derniere
      ? 'Page $premiere'
      : 'Pages $premiere à $derniere';

  /// TC-I18N: cle=tc.parcours.plage.section
  static String plageSection(String section) => 'Section $section';

  /// TC-I18N: cle=tc.parcours.plage.ressource
  static const String plageRessource = 'Tout le support';

  // --- Micro-feedback : cinq questions, en rotation -----------------------

  /// TC-I18N: cle=tc.parcours.feedback.cours.intitule
  static const String feedbackCoursIntitule =
      "Comment était le cours aujourd'hui ?";

  /// TC-I18N: cle=tc.parcours.feedback.cours.difficile
  static const String feedbackCoursDifficile = 'Difficile';

  /// TC-I18N: cle=tc.parcours.feedback.cours.bien
  static const String feedbackCoursBien = 'Bien';

  /// TC-I18N: cle=tc.parcours.feedback.cours.tresBien
  static const String feedbackCoursTresBien = 'Très bien';

  /// TC-I18N: cle=tc.parcours.feedback.comprehension.intitule
  static const String feedbackComprehensionIntitule =
      'Avez-vous compris ce qui a été travaillé ?';

  /// TC-I18N: cle=tc.parcours.feedback.comprehension.difficile
  static const String feedbackComprehensionDifficile = 'Pas vraiment';

  /// TC-I18N: cle=tc.parcours.feedback.comprehension.bien
  static const String feedbackComprehensionBien = 'Plutôt oui';

  /// TC-I18N: cle=tc.parcours.feedback.comprehension.tresBien
  static const String feedbackComprehensionTresBien = 'Tout à fait';

  /// TC-I18N: cle=tc.parcours.feedback.rythme.intitule
  static const String feedbackRythmeIntitule =
      'Le rythme du cours vous a-t-il convenu ?';

  /// TC-I18N: cle=tc.parcours.feedback.rythme.difficile
  static const String feedbackRythmeDifficile = 'Trop rapide';

  /// TC-I18N: cle=tc.parcours.feedback.rythme.bien
  static const String feedbackRythmeBien = 'Convenable';

  /// TC-I18N: cle=tc.parcours.feedback.rythme.tresBien
  static const String feedbackRythmeTresBien = 'Très confortable';

  /// TC-I18N: cle=tc.parcours.feedback.technique.intitule
  static const String feedbackTechniqueIntitule =
      "Le son et l'image étaient-ils confortables ?";

  /// TC-I18N: cle=tc.parcours.feedback.technique.difficile
  static const String feedbackTechniqueDifficile = 'Gênants';

  /// TC-I18N: cle=tc.parcours.feedback.technique.bien
  static const String feedbackTechniqueBien = 'Corrects';

  /// TC-I18N: cle=tc.parcours.feedback.technique.tresBien
  static const String feedbackTechniqueTresBien = 'Très bons';

  /// TC-I18N: cle=tc.parcours.feedback.confiance.intitule
  static const String feedbackConfianceIntitule =
      'Vous sentez-vous prêt pour le prochain cours ?';

  /// TC-I18N: cle=tc.parcours.feedback.confiance.difficile
  static const String feedbackConfianceDifficile = 'Pas encore';

  /// TC-I18N: cle=tc.parcours.feedback.confiance.bien
  static const String feedbackConfianceBien = 'Plutôt';

  /// TC-I18N: cle=tc.parcours.feedback.confiance.tresBien
  static const String feedbackConfianceTresBien = 'Tout à fait';

  /// TC-I18N: cle=tc.parcours.feedback.merci
  static const String feedbackMerci = 'Merci.';

  /// TC-I18N: cle=tc.parcours.feedback.tendance.titre
  static const String feedbackTendanceTitre = 'Retour des élèves';

  /// TC-I18N: cle=tc.parcours.feedback.tendance.sousSeuil
  static const String feedbackTendanceSousSeuil =
      'Pas encore assez de retours pour dégager une tendance.';

  /// TC-I18N: cle=tc.parcours.feedback.tendance.anonyme
  static const String feedbackTendanceAnonyme =
      'Les retours sont anonymes et agrégés. Ils ne suffisent jamais, seuls, '
      'à une décision.';

  // --- Signalement --------------------------------------------------------

  /// TC-I18N: cle=tc.parcours.signalement.titre
  static const String signalementTitre = 'Signaler un besoin';

  /// TC-I18N: cle=tc.parcours.signalement.categorie
  static const String signalementCategorie = "De quoi s'agit-il ?";

  /// TC-I18N: cle=tc.parcours.signalement.categorie.pedagogique
  static const String categoriePedagogique = 'Pédagogique';

  /// TC-I18N: cle=tc.parcours.signalement.categorie.presence
  static const String categoriePresence = 'Présence';

  /// TC-I18N: cle=tc.parcours.signalement.categorie.technique
  static const String categorieTechnique = 'Technique';

  /// TC-I18N: cle=tc.parcours.signalement.categorie.changement
  static const String categorieChangement = 'Changement';

  /// TC-I18N: cle=tc.parcours.signalement.categorie.autre
  static const String categorieAutre = 'Autre';

  /// Le libelle d'une categorie de signalement.
  static String categorie(CategorieSignalement categorie) =>
      switch (categorie) {
        CategorieSignalement.pedagogique => categoriePedagogique,
        CategorieSignalement.presence => categoriePresence,
        CategorieSignalement.technique => categorieTechnique,
        CategorieSignalement.changement => categorieChangement,
        CategorieSignalement.autre => categorieAutre,
      };

  /// TC-I18N: cle=tc.parcours.signalement.interne
  static const String signalementInterne = 'Note interne';

  /// TC-I18N: cle=tc.parcours.signalement.interneAide
  static const String signalementInterneAide =
      "Lue par l'administration seulement. Elle ne part jamais automatiquement "
      'à la famille.';

  /// TC-I18N: cle=tc.parcours.signalement.famille
  static const String signalementFamille = 'Message pour la famille';

  /// TC-I18N: cle=tc.parcours.signalement.familleAide
  static const String signalementFamilleAide =
      "Facultatif. L'administration décide seule de le transmettre, en un clic.";

  /// TC-I18N: cle=tc.parcours.signalement.contexte
  static String signalementContexte({required String eleve}) =>
      'Élève $eleve. La séance, le groupe et votre nom sont déjà joints.';

  /// TC-I18N: cle=tc.parcours.signalement.envoyer
  static const String signalementEnvoyer = 'Envoyer le signalement';

  /// TC-I18N: cle=tc.parcours.signalement.envoye
  static const String signalementEnvoye =
      "Signalement transmis à l'administration.";

  /// TC-I18N: cle=tc.parcours.signalement.interneRequis
  static const String signalementInterneRequis =
      "Écrivez au moins ce que l'administration doit savoir.";

  /// TC-I18N: cle=tc.parcours.signalement.echec
  static const String signalementEchec =
      "Le signalement n'a pas pu être transmis. Réessayez.";

  // --- Apres le cours -----------------------------------------------------

  /// TC-I18N: cle=tc.parcours.postCours.titre
  static const String postCoursTitre = 'Après le cours';

  /// TC-I18N: cle=tc.parcours.postCours.duree
  static String postCoursDuree(int minutes) => 'Durée réelle $minutes min';

  /// TC-I18N: cle=tc.parcours.postCours.exceptions
  static const String postCoursExceptions = 'À confirmer';

  /// TC-I18N: cle=tc.parcours.postCours.toutEstNominal
  static const String postCoursToutEstNominal =
      'Rien ne demande votre attention.';

  /// TC-I18N: cle=tc.parcours.postCours.reprise
  static const String postCoursReprise = 'Reprise proposée';

  /// TC-I18N: cle=tc.parcours.postCours.repriseInconnue
  static const String postCoursRepriseInconnue =
      'Aucune position de reprise connue pour cette séance.';

  /// TC-I18N: cle=tc.parcours.postCours.travail
  static const String postCoursTravail = 'Travail proposé';

  /// TC-I18N: cle=tc.parcours.postCours.travailAucun
  static const String postCoursTravailAucun =
      "Aucun travail proposé pour l'instant.";

  /// TC-I18N: cle=tc.parcours.postCours.valider
  static const String postCoursValider = 'Valider';

  /// TC-I18N: cle=tc.parcours.postCours.enFile
  static const String postCoursEnFile =
      'Enregistré. Il partira dès le retour du réseau.';

  /// TC-I18N: cle=tc.parcours.postCours.envoye
  static const String postCoursEnvoye = 'Cours clôturé.';
}
