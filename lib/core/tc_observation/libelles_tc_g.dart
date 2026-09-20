import 'guardian_session_visit.dart';
import 'port_politique_observation.dart';

/// Les libelles du domaine Observation, en attendant la fusion slang.
///
/// **Facade temporaire, imposee par la decision D-03.** Le pipeline slang est
/// mono-fichier : `slang.yaml` n'active pas `namespaces`, il y a une seule
/// source `assets/i18n/fr.i18n.json` et une seule sortie generee et versionnee.
/// Neuf agents paralleles y produiraient neuf conflits, dont certains sur
/// 244 Ko de code genere qu'on ne fusionne pas a la main.
///
/// Chaque constante porte, en commentaire, la cle exacte sous laquelle elle est
/// deposee dans `docs/teaching-core/i18n/tc_i18n_G.json`. C'est ce couple qui
/// rend le travail d'Agent Z mecanique : il fusionne, regenere, remplace chaque
/// constante par son `t.tc.observation...`, puis supprime ce fichier.
///
/// **Aucune chaine visible ne se pose ailleurs que dans ce fichier.** Une
/// chaine noyee dans un widget serait introuvable pour Agent Z.
abstract final class LibellesTcG {
  // --- Entree ---------------------------------------------------------------

  // TC-I18N: tc.observation.entree.titre
  /// Titre de l'ecran d'entree en observation.
  static const String entreeTitre = 'Observer la séance';

  // TC-I18N: tc.observation.entree.tuteurIntro
  /// Ce que le tuteur lit avant d'entrer.
  static const String entreeTuteurIntro =
      'Vous pouvez regarder un court moment le cours de votre enfant. Votre '
      'micro et votre caméra restent fermés.';

  // TC-I18N: tc.observation.entree.adminIntro
  /// Ce que l'administration lit avant de choisir son mode.
  static const String entreeAdminIntro =
      'Choisissez votre mode avant d\'entrer. Il ne change plus ensuite.';

  // TC-I18N: tc.observation.entree.controleurIntro
  /// Ce que le controle qualite lit avant d'entrer.
  static const String entreeControleurIntro =
      'Vous entrez en observation invisible. Aucun micro, aucune caméra.';

  // TC-I18N: tc.observation.entree.entrer
  /// Action d'entree.
  static const String entreeAction = 'Entrer';

  // TC-I18N: tc.observation.entree.modeDiscret
  /// Premier mode administrateur.
  static const String modeDiscret = 'Observer discrètement';

  // TC-I18N: tc.observation.entree.modeDiscretDetail
  /// Ce que le mode discret implique.
  static const String modeDiscretDetail =
      'Invisible pour les participants. Sans micro ni caméra, sans annonce.';

  // TC-I18N: tc.observation.entree.modeVisible
  /// Second mode administrateur.
  static const String modeVisible = 'Rejoindre la classe';

  // TC-I18N: tc.observation.entree.modeVisibleDetail
  /// Ce que le mode visible implique.
  static const String modeVisibleDetail =
      'Visible par tous sous le nom Administration Rewayah. Micro et caméra '
      'permis, annonce faite.';

  // TC-I18N: tc.observation.entree.nomInstitutionnel
  /// Le nom sous lequel une intervention administrative apparait.
  static const String nomInstitutionnel = 'Administration Rewayah';

  // TC-I18N: tc.observation.entree.visiteJournalisee
  /// Rappel permanent, affiche a tout observateur incognito.
  static const String visiteJournalisee =
      'Visite journalisée : identité, séance, entrée, sortie et durée.';

  // TC-I18N: tc.observation.entree.roleSansObservation
  /// Etat pour un compte qui n'observe aucune seance.
  static const String roleSansObservation =
      'Votre compte n\'observe pas les séances.';

  // --- Refus ----------------------------------------------------------------

  // TC-I18N: tc.observation.refus.politiqueDesactivee
  /// Refus : l'administration a ferme l'observation pour ce groupe.
  static const String refusPolitiqueDesactivee =
      'L\'observation est désactivée pour ce groupe.';

  // TC-I18N: tc.observation.refus.quotaVisites
  /// Refus : toutes les visites de la seance sont consommees.
  static const String refusQuotaVisites =
      'Vous avez déjà utilisé vos visites pour cette séance.';

  // TC-I18N: tc.observation.refus.tempsEpuise
  /// Refus : le temps total est consomme.
  static const String refusTempsEpuise =
      'Votre temps d\'observation est épuisé pour cette séance.';

  // TC-I18N: tc.observation.refus.lienTuteur
  /// Refus : aucun lien entre l'appelant et un eleve de la seance.
  static const String refusLienTuteur =
      'Vous n\'êtes rattaché à aucun élève de cette séance.';

  // TC-I18N: tc.observation.refus.seanceNonActive
  /// Refus : la seance n'a pas lieu.
  static const String refusSeanceNonActive = 'La séance n\'est pas en cours.';

  // TC-I18N: tc.observation.refus.horsFenetre
  /// Refus : la salle n'est pas ouverte a cette heure.
  static const String refusHorsFenetre =
      'La salle n\'est pas ouverte à cette heure.';

  // TC-I18N: tc.observation.refus.indisponible
  /// La question n'a pas pu etre posee au serveur.
  static const String refusIndisponible =
      'L\'observation n\'est pas disponible pour le moment.';

  // TC-I18N: tc.observation.refus.capaciteAbsente
  /// La capacite serveur n'est pas installee sur ce deploiement.
  static const String refusCapaciteAbsente =
      'L\'observation n\'est pas encore activée sur cette installation.';

  // --- Visite ---------------------------------------------------------------

  // TC-I18N: tc.observation.visite.titre
  /// Titre pendant la visite.
  static const String visiteTitre = 'Observation en cours';

  // TC-I18N: tc.observation.visite.quitter
  /// Action de sortie volontaire.
  static const String visiteQuitter = 'Quitter';

  // TC-I18N: tc.observation.visite.mediaFerme
  /// Rappel discret des interdictions de media.
  static const String visiteMediaFerme =
      'Micro et caméra fermés pendant l\'observation.';

  // TC-I18N: tc.observation.visite.supportIndisponible
  /// Etat du support partage tant qu'il n'est pas fourni par la Classe Live.
  static const String visiteSupportIndisponible =
      'Le support partagé par l\'enseignant s\'affiche ici.';

  // TC-I18N: tc.observation.visite.enseignant
  /// Etiquette de la vignette enseignant.
  static const String visiteEnseignant = 'Enseignant';

  // TC-I18N: tc.observation.visite.monEnfant
  /// Etiquette de la vignette de l'enfant observe.
  static const String visiteMonEnfant = 'Votre enfant';

  // TC-I18N: tc.observation.visite.enfantAbsent
  /// Etat quand l'enfant n'a pas encore rejoint, ou que son media est ferme.
  static const String visiteEnfantAbsent =
      'Votre enfant n\'a pas d\'image ouverte.';

  // TC-I18N: tc.observation.visite.budgetIncertain
  /// Etat explicite : le temps restant n'est plus confirme par le serveur.
  static const String visiteBudgetIncertain =
      'Temps restant non confirmé par le serveur.';

  // TC-I18N: tc.observation.visite.sortieNonConfirmee
  /// Etat explicite : le serveur n'a pas confirme la fermeture.
  static const String visiteSortieNonConfirmee =
      'La fin de votre visite n\'a pas pu être confirmée. Elle sera fermée '
      'par le serveur.';

  // --- Fin ------------------------------------------------------------------

  // TC-I18N: tc.observation.fin.sortieVolontaire
  /// Fin : sortie volontaire.
  static const String finSortieVolontaire = 'Vous avez quitté l\'observation.';

  // TC-I18N: tc.observation.fin.quotaAtteint
  /// Fin : budget epuise.
  static const String finQuotaAtteint = 'Votre temps d\'observation est écoulé.';

  // TC-I18N: tc.observation.fin.seanceTerminee
  /// Fin : la seance s'est terminee.
  static const String finSeanceTerminee = 'La séance est terminée.';

  // TC-I18N: tc.observation.fin.revocationServeur
  /// Fin : le serveur a coupe l'acces.
  static const String finRevocationServeur =
      'Votre observation a été interrompue.';

  // TC-I18N: tc.observation.fin.deconnexion
  /// Fin : lien perdu.
  static const String finDeconnexion = 'La connexion a été perdue.';

  // --- Annonce cote enseignant et cote enfant -------------------------------

  // TC-I18N: tc.observation.annonce.enfantIndicateur
  /// Indicateur discret, cote enfant observe.
  static const String annonceEnfantIndicateur = 'Ton tuteur regarde le cours';

  // --- Module de reglages ---------------------------------------------------

  // TC-I18N: tc.observation.reglages.titre
  /// Titre du module de reglages.
  static const String reglagesTitre = 'Observation par les tuteurs';

  // TC-I18N: tc.observation.reglages.intro
  /// Ce que le module explique.
  static const String reglagesIntro =
      'Un tuteur peut regarder un court moment le cours de son enfant, sans '
      'micro ni caméra. Ce réglage décide de ce qui s\'applique à ce groupe.';

  // TC-I18N: tc.observation.reglages.heriter
  /// Premier choix.
  static const String reglagesHeriter = 'Hériter de l\'Académie';

  // TC-I18N: tc.observation.reglages.personnaliser
  /// Deuxieme choix.
  static const String reglagesPersonnaliser = 'Personnaliser pour ce groupe';

  // TC-I18N: tc.observation.reglages.desactiver
  /// Troisieme choix.
  static const String reglagesDesactiver = 'Désactiver pour ce groupe';

  // TC-I18N: tc.observation.reglages.maxVisites
  /// Libelle du premier quota.
  static const String reglagesMaxVisites = 'Visites par séance';

  // TC-I18N: tc.observation.reglages.tempsTotal
  /// Libelle du second quota.
  static const String reglagesTempsTotal = 'Temps total par séance';

  // TC-I18N: tc.observation.reglages.diminuer
  /// Libelle semantique du pas negatif.
  static const String reglagesDiminuer = 'Diminuer';

  // TC-I18N: tc.observation.reglages.augmenter
  /// Libelle semantique du pas positif.
  static const String reglagesAugmenter = 'Augmenter';

  // TC-I18N: tc.observation.reglages.enregistrer
  /// Action d'enregistrement.
  static const String reglagesEnregistrer = 'Enregistrer';

  // TC-I18N: tc.observation.reglages.invalideVisites
  /// Message de validation du premier quota.
  static const String reglagesInvalideVisites =
      'Au moins une visite par séance.';

  // TC-I18N: tc.observation.reglages.invalideTemps
  /// Message de validation du second quota.
  static const String reglagesInvalideTemps =
      'Au moins trente secondes par séance.';

  // --- Interpolations -------------------------------------------------------

  // TC-I18N: tc.observation.visite.restant
  /// Le compte a rebours du budget restant.
  static String tempsRestant(int secondes) => '$secondes s restantes';

  // TC-I18N: tc.observation.visite.visites
  /// Le rang de la visite dans la seance.
  static String rangVisite(int rang, int total) => 'Visite $rang sur $total';

  // TC-I18N: tc.observation.annonce.tuteurObserve
  /// L'annonce lue par l'enseignant.
  ///
  /// **Le tuteur n'est jamais nomme.** L'enseignant apprend qu'un tuteur
  /// observe, pas lequel : son identite ne lui apporte rien et n'a pas a
  /// circuler. Le prenom de l'enfant, lui, est deja celui que `teacher_roster_v`
  /// lui livre.
  static String tuteurObserve(String prenomEnfant) =>
      'Tuteur de $prenomEnfant observe';

  // TC-I18N: tc.observation.annonce.restant
  /// L'indicateur discret de temps restant, cote enseignant.
  static String annonceRestant(int secondes) => '$secondes s';

  // TC-I18N: tc.observation.reglages.valeurHeritee
  /// Rappel de la valeur de l'Academie sous un champ personnalise.
  static String valeurHeritee(String valeur) => 'Académie : $valeur';

  // TC-I18N: tc.observation.reglages.uniteVisiteUne
  /// Une seule visite.
  static String uniteVisiteUne(int n) => '$n visite';

  // TC-I18N: tc.observation.reglages.uniteVisites
  /// Plusieurs visites.
  static String uniteVisitesPlusieurs(int n) => '$n visites';

  /// Un nombre de visites, avec son unite.
  ///
  /// Deux cles plutot qu'un pluriel slang : `fr.i18n.json` n'utilise aucune
  /// forme `(plural)` aujourd'hui, et introduire la premiere pendant la phase
  /// parallele ferait porter a Agent Z un changement de pipeline en plus d'une
  /// fusion.
  static String uniteVisites(int n) =>
      n > 1 ? uniteVisitesPlusieurs(n) : uniteVisiteUne(n);

  // TC-I18N: tc.observation.reglages.uniteSecondes
  /// Un nombre de secondes, avec son unite.
  static String uniteSecondes(int n) => '$n s';

  // TC-I18N: tc.observation.reglages.versionPolitique
  /// La version de politique sous laquelle les visites sont journalisees.
  static String versionPolitique(String version) => 'Version $version';

  /// Le message qui correspond a un refus serveur.
  static String refus(MotifRefusObservation motif) => switch (motif) {
    MotifRefusObservation.policyDesactivee => refusPolitiqueDesactivee,
    MotifRefusObservation.quotaVisitesAtteint => refusQuotaVisites,
    MotifRefusObservation.tempsEpuise => refusTempsEpuise,
    MotifRefusObservation.lienTuteurAbsent => refusLienTuteur,
    MotifRefusObservation.seanceNonActive => refusSeanceNonActive,
    MotifRefusObservation.horsFenetre => refusHorsFenetre,
  };

  /// Le message qui correspond a une fin de visite.
  static String messageFin(FinDeVisite fin) => switch (fin) {
    FinDeVisite.sortieVolontaire => finSortieVolontaire,
    FinDeVisite.quotaAtteint => finQuotaAtteint,
    FinDeVisite.seanceTerminee => finSeanceTerminee,
    FinDeVisite.revocationServeur => finRevocationServeur,
    FinDeVisite.deconnexion => finDeconnexion,
  };
}
