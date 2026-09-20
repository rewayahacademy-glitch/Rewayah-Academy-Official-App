/// La facade de libelles du domaine Classe.
///
/// **Provisoire, et remplacee par Agent Z.** Le pipeline slang du depot est
/// mono-fichier : une seule source `assets/i18n/fr.i18n.json` et une seule
/// sortie generee et versionnee de 244 Ko. Neuf agents qui y ecriraient en
/// parallele produiraient neuf conflits sur du code genere qu'on ne fusionne
/// pas a la main. La decision `D-03` impose donc ce mecanisme : chaque agent
/// depose ses libelles dans `docs/teaching-core/i18n/tc_i18n_<X>.json` et ecrit
/// son interface contre une facade annotee.
///
/// Chaque constante porte sa cle finale en commentaire `// TC-I18N:`. Agent Z
/// fusionne les JSON, regenere, remplace les appels et supprime ce fichier.
///
/// **Les accents vivent dans le JSON, pas ici.** Aucun fichier Dart du depot
/// n'en porte : la verification l'a confirmee sur `salle_page.dart`,
/// `vue_presence.dart` et `empty_state.dart`. Les libelles definitifs, accentues,
/// sont dans `docs/teaching-core/i18n/tc_i18n_E.json`.
///
/// Le sous-arbre d'Agent E est `tc.classe.*`, et rien d'autre.
abstract final class LibellesClasse {
  // --- En-tete de la Classe Live -----------------------------------------

  // TC-I18N: tc.classe.entete.titreEnseignant.sayyid
  /// Titre masculin. **Jamais Ustaz** (decision D-02).
  static const String titreSayyid = 'Sayyid';

  // TC-I18N: tc.classe.entete.titreEnseignant.sayyida
  /// Titre feminin. **Jamais Ustazah** (decision D-02).
  static const String titreSayyida = 'Sayyida';

  // TC-I18N: tc.classe.entete.resteMinutes
  /// Le temps restant, deja arrondi a la minute par l'horloge.
  static String resteMinutes(int minutes) => 'Reste $minutes min';

  // TC-I18N: tc.classe.entete.resteHeuresMinutes
  /// Le temps restant au-dela de l'heure.
  static String resteHeuresMinutes(int heures, int minutes) =>
      'Reste $heures h ${minutes.toString().padLeft(2, '0')}';

  // TC-I18N: tc.classe.entete.coursEnCours
  /// Le cours se tient, sans compte a rebours : c'est la prolongation.
  static const String coursToujoursEnCours = 'Cours toujours en cours';

  // TC-I18N: tc.classe.entete.photoManquante
  /// La photo enseignant est obligatoire (decision D-01) : son absence se dit.
  static const String photoEnseignantManquante = 'Photo enseignant manquante';

  // --- Roster -------------------------------------------------------------

  // TC-I18N: tc.classe.roster.titre
  /// Le titre de la colonne et de la feuille de roster.
  static const String rosterTitre = 'Eleves';

  // TC-I18N: tc.classe.roster.compteur
  /// Le libelle parle du bouton compact, qui dit ce que « 4/5 » signifie.
  static String rosterCompteurParle(int presents, int attendus) =>
      'Eleves : $presents presents sur $attendus attendus';

  // TC-I18N: tc.classe.roster.indisponible
  /// La lecture n'a rien rendu. **Ce n'est pas « personne ».**
  static const String rosterIndisponible = 'Roster indisponible';

  // TC-I18N: tc.classe.roster.indisponibleDetail
  /// Ce que cela veut dire.
  static const String rosterIndisponibleDetail =
      'Les etats de vos eleves n ont pas pu etre lus. Le cours continue.';

  // TC-I18N: tc.classe.roster.vide
  /// Aucun eleve inscrit a cette seance.
  static const String rosterVide = 'Aucun eleve inscrit';

  // TC-I18N: tc.classe.roster.videDetail
  /// Ce que cela veut dire.
  static const String rosterVideDetail =
      'Cette seance n a aucun eleve inscrit. Verifiez le groupe.';

  // TC-I18N: tc.classe.roster.ouvrirFiche
  /// Le libelle parle d'une ligne de roster : il dit l'acte.
  static String ouvrirFiche(String prenom) => 'Ouvrir la fiche de $prenom';

  // TC-I18N: tc.classe.roster.places
  /// Les places du groupe. **Le plafond vient du serveur, jamais d une
  /// constante.**
  static String rosterPlaces(int inscrits, int plafond) =>
      '$inscrits / $plafond places';

  // --- Etats de presence projetes ----------------------------------------

  // TC-I18N: tc.classe.etat.inconnu
  /// L'etat n'est pas derivable. **Jamais « absent ».**
  static const String etatInconnu = 'Etat inconnu';

  // TC-I18N: tc.classe.etat.attendu
  /// Inscrit, pas encore entre.
  static const String etatAttendu = 'Attendu';

  // TC-I18N: tc.classe.etat.enConnexion
  /// La connexion est en cours.
  static const String etatEnConnexion = 'En connexion';

  // TC-I18N: tc.classe.etat.present
  /// En salle.
  static const String etatPresent = 'Present';

  // TC-I18N: tc.classe.etat.enRetard
  /// Entre apres l'heure.
  static const String etatEnRetard = 'En retard';

  // TC-I18N: tc.classe.etat.deconnecte
  /// Le lien a lache.
  static const String etatDeconnecte = 'Deconnecte';

  // TC-I18N: tc.classe.etat.enReconnexion
  /// Le lien a lache, le retour court encore.
  static const String etatEnReconnexion = 'En reconnexion';

  // TC-I18N: tc.classe.etat.sorti
  /// Parti volontairement.
  static const String etatSorti = 'Sorti';

  // TC-I18N: tc.classe.etat.absent
  /// La seance est finie et cette personne n est jamais entree.
  static const String etatAbsent = 'Absent';

  // --- Fiche pedagogique de seance ---------------------------------------

  // TC-I18N: tc.classe.fiche.niveau
  /// Le niveau humain, jamais un code technique.
  static const String ficheNiveau = 'Niveau';

  // TC-I18N: tc.classe.fiche.objectif
  /// Les objectifs actifs.
  static const String ficheObjectif = 'Objectif actuel';

  // TC-I18N: tc.classe.fiche.derniereSeance
  /// Ce que la seance precedente a laisse.
  static const String ficheDerniereSeance = 'Derniere seance';

  // TC-I18N: tc.classe.fiche.page
  /// Une position de page, telle que la fiche la resume : « Page 31 ».
  static String fichePage(int page) => 'Page $page';

  // TC-I18N: tc.classe.fiche.travailEnCours
  /// Combien de travaux sont en cours pour cet eleve.
  static String ficheTravauxEnCours(int nombre) =>
      nombre <= 1 ? '$nombre element' : '$nombre elements';

  // TC-I18N: tc.classe.fiche.aReprendre
  /// Le point a reprendre.
  static const String ficheAReprendre = 'A reprendre';

  // TC-I18N: tc.classe.fiche.presenceRecente
  /// L'assiduite recente.
  static const String fichePresenceRecente = 'Presence recente';

  // TC-I18N: tc.classe.fiche.assiduite
  /// « 8 / 9 cours ».
  static String ficheAssiduite(int presences, int total) =>
      '$presences / $total cours';

  // TC-I18N: tc.classe.fiche.travailActuel
  /// Le travail en cours.
  static const String ficheTravailActuel = 'Travail actuel';

  // TC-I18N: tc.classe.fiche.interfaceGuidee
  /// **Jamais « mode enfant »** (decision D-07).
  static const String ficheInterfaceGuidee = 'Interface guidee';

  // TC-I18N: tc.classe.fiche.sansPedagogie
  /// La projection pedagogique n est pas encore livree par le serveur.
  static const String ficheSansPedagogie = 'Suivi pedagogique indisponible';

  // TC-I18N: tc.classe.fiche.sansPedagogieDetail
  /// Ce que cela veut dire, sans jargon.
  static const String ficheSansPedagogieDetail =
      'Le parcours, les objectifs et le travail en cours ne sont pas encore '
      'ouverts a l enseignant.';

  // --- Actions frequentes de la fiche ------------------------------------

  // TC-I18N: tc.classe.action.rappel
  /// Le rappel discret.
  static const String actionRappel = 'Rappel discret';

  // TC-I18N: tc.classe.action.reciter
  /// Donner la parole.
  static const String actionReciter = 'Choisir pour reciter';

  // TC-I18N: tc.classe.action.noter
  /// Noter, au cahier.
  static const String actionNoter = 'Noter';

  // TC-I18N: tc.classe.action.signaler
  /// Signaler un besoin.
  static const String actionSignaler = 'Signaler un besoin';

  // TC-I18N: tc.classe.action.contexte
  /// Ouvrir le contexte pedagogique complet.
  static const String actionContexte = 'Ouvrir le contexte';

  // --- Rappel discret -----------------------------------------------------

  // TC-I18N: tc.classe.rappel.recu
  /// Ce que l'eleve lit. **Simple, et rien de plus.**
  static const String rappelRecu = 'Le professeur vous appelle';

  // TC-I18N: tc.classe.rappel.echec
  /// **Le seul message du rappel** : il n apparait que si l envoi echoue.
  static const String rappelEchec = 'Le rappel n a pas pu etre envoye';

  // TC-I18N: tc.classe.rappel.echecDroit
  /// L appelant n a pas le droit d emettre dans cette seance.
  static const String rappelEchecDroit =
      'Votre acces a cette seance ne permet pas d appeler un eleve';

  // TC-I18N: tc.classe.rappel.cooldown
  /// Le cooldown court encore. Sans reproche.
  static String rappelCooldown(int secondes) =>
      'Deja appele. A nouveau dans $secondes s';

  // --- File de recitation -------------------------------------------------

  // TC-I18N: tc.classe.recitation.titre
  /// Le titre du bloc.
  static const String recitationTitre = 'Recitation';

  // TC-I18N: tc.classe.recitation.actif
  /// Qui recite.
  static String reciteEnCeMoment(String prenom) => '$prenom recite';

  // TC-I18N: tc.classe.recitation.pastille
  /// La pastille d une ligne de roster : cet eleve a la parole.
  ///
  /// Court **par necessite mesuree** : la colonne de roster fait 256 points, et
  /// « Amina recite » a cote de l etat de presence depassait de 102 points.
  static const String recite = 'Recite';

  // TC-I18N: tc.classe.recitation.suivants
  /// Les suivants.
  static const String recitationSuivants = 'Ensuite';

  // TC-I18N: tc.classe.recitation.personne
  /// Personne ne recite.
  static const String recitationPersonne = 'Personne ne recite';

  // TC-I18N: tc.classe.recitation.arreter
  /// Rendre la file au repos.
  static const String recitationArreter = 'Arreter la recitation';

  // --- Support et Bibliotheque -------------------------------------------

  // TC-I18N: tc.classe.support.aucun
  /// Aucun support presente : la video reprend de l espace.
  static const String supportAucun = 'Aucun support presente';

  // TC-I18N: tc.classe.support.aucunDetail
  /// Ce que l enseignant peut faire.
  static const String supportAucunDetail =
      'Ouvrez la Bibliotheque pour presenter un support au groupe.';

  // TC-I18N: tc.classe.support.bibliotheque
  /// Ouvrir la Bibliotheque. **La meme, en classe et hors classe** (D-20).
  static const String ouvrirBibliotheque = 'Bibliotheque';

  // TC-I18N: tc.classe.support.bibliothequeAbsente
  /// La surface d Agent B n est pas encore branchee.
  static const String bibliothequeAbsente = 'Bibliotheque non branchee';

  // TC-I18N: tc.classe.support.bibliothequeAbsenteDetail
  /// Ce que cela veut dire.
  static const String bibliothequeAbsenteDetail =
      'Le choix de support sera disponible des l integration du catalogue.';

  // --- Commandes de salle -------------------------------------------------

  // TC-I18N: tc.classe.commandes.micro
  /// Ouvrir le micro. **Aucune commande vocale** (decision D-10).
  static const String microOuvrir = 'Ouvrir le micro';

  // TC-I18N: tc.classe.commandes.microFermer
  /// Fermer le micro.
  static const String microFermer = 'Fermer le micro';

  // TC-I18N: tc.classe.commandes.camera
  /// Ouvrir la camera.
  static const String cameraOuvrir = 'Ouvrir la camera';

  // TC-I18N: tc.classe.commandes.cameraFermer
  /// Fermer la camera.
  static const String cameraFermer = 'Fermer la camera';

  // TC-I18N: tc.classe.commandes.quitter
  /// Quitter le cours. **Le seul geste qui coupe la salle.**
  static const String quitter = 'Quitter';

  // TC-I18N: tc.classe.commandes.quitterQuestion
  /// La question posee avant de couper la salle.
  static const String quitterQuestion = 'Quitter le cours ?';

  // TC-I18N: tc.classe.commandes.quitterConsequence
  /// Ce que la sortie entraine, dit sans dramatiser.
  static const String quitterConsequence =
      'Votre sortie sera enregistree. Vous pourrez revenir tant que la seance '
      'est ouverte.';

  // TC-I18N: tc.classe.commandes.fermerBibliotheque
  /// Refermer le panneau de la Bibliotheque. **Ne quitte pas le cours.**
  static const String fermerBibliotheque = 'Fermer la Bibliotheque';

  // TC-I18N: tc.classe.commandes.microCoupe
  /// Le mot court pose sous une vignette dont le micro est ferme.
  static const String microCoupeCourt = 'Micro ferme';

  // --- Scene video --------------------------------------------------------

  // TC-I18N: tc.classe.scene.vide
  /// Personne d autre n est encore dans la salle.
  static const String sceneVide = 'Vous etes seul dans la salle pour le moment';

  // TC-I18N: tc.classe.scene.sansImage
  /// Un participant sans image publiee. **Ce n est pas une panne.**
  static const String sansImage = 'Sans image';

  // --- Etat reseau --------------------------------------------------------

  // TC-I18N: tc.classe.reseau.bon
  /// Le lien tient.
  static const String reseauBon = 'Reseau bon';

  // TC-I18N: tc.classe.reseau.mediocre
  /// Le lien se degrade. **La seance continue.**
  static const String reseauMediocre = 'Reseau instable';

  // TC-I18N: tc.classe.reseau.perdu
  /// Le lien est perdu.
  static const String reseauPerdu = 'Reseau perdu';

  // --- Attentes d entree --------------------------------------------------

  // TC-I18N: tc.classe.attente.materiel
  /// L inspection du materiel est en cours.
  static const String attenteMateriel = 'Verification de votre micro';

  // TC-I18N: tc.classe.attente.ouverture
  /// Le jeton d entree est demande au serveur.
  static const String attenteOuverture = 'Ouverture du cours';

  // TC-I18N: tc.classe.attente.connexion
  /// La connexion au serveur temps reel est en cours.
  static const String attenteConnexion = 'Connexion au cours';

  // TC-I18N: tc.classe.attente.refus
  /// **Un seul message pour trois refus**, et c est voulu : le serveur ne dit
  /// jamais si la seance existe, si l appelant y est inscrit, ou s il est en
  /// avance. Le lui faire dire par le client reintroduirait la fuite.
  static const String entreeRefusee =
      'Le cours n est pas accessible pour le moment';

  // --- Etat du lien -------------------------------------------------------

  // TC-I18N: tc.classe.lien.instable
  /// Le lien se degrade. **La seance continue.**
  static const String lienInstable = 'Connexion instable';

  // TC-I18N: tc.classe.lien.reconnexion
  /// Le lien est perdu, le moteur le retablit.
  static const String lienReconnexion = 'Reconnexion en cours';

  // TC-I18N: tc.classe.lien.retabli
  /// Le lien vient d etre retabli.
  static const String lienRetabli = 'Connexion retablie';

  // TC-I18N: tc.classe.lien.echec
  /// Le lien n a pas pu etre retabli. **La salle reste a l ecran.**
  static const String lienEchec = 'Connexion perdue';

  // TC-I18N: tc.classe.lien.retourDeSuspension
  /// L application revient d une suspension. **Ne rien promettre.**
  ///
  /// Il ne s affiche pas PENDANT la suspension : une application suspendue ne
  /// rend aucune image, `SchedulerBinding` coupe les frames des l etat
  /// `paused`. C est au RETOUR que la phrase sert, et elle tient tant que le
  /// moteur n a pas redit que le lien est la.
  static const String lienArrierePlan =
      'Le cours a ete mis en pause par le systeme. Verification du lien en '
      'cours.';

  // --- Barre « Cours en cours » -------------------------------------------

  // TC-I18N: tc.classe.barre.titre
  /// Le cours continue derriere l ecran affiche.
  static const String barreCoursEnCours = 'Cours en cours';

  // TC-I18N: tc.classe.barre.revenir
  /// Le libelle parle du retour instantane.
  static String barreRevenir(String groupe) => 'Revenir au cours de $groupe';

  // --- Pre-cours ----------------------------------------------------------

  // TC-I18N: tc.classe.prevol.titre
  /// Le preflight de l enseignant.
  static const String prevolTitre = 'Avant d ouvrir le cours';

  // TC-I18N: tc.classe.prevol.microOk
  /// Le micro repond.
  static const String prevolMicroOk = 'Micro detecte';

  // TC-I18N: tc.classe.prevol.microAbsent
  /// **La seule impasse bloquante** : pour une academie de Coran, l audio prime.
  static const String prevolMicroAbsent = 'Aucun micro utilisable';

  // TC-I18N: tc.classe.prevol.cameraOk
  /// La camera repond.
  static const String prevolCameraOk = 'Camera detectee';

  // TC-I18N: tc.classe.prevol.cameraAbsente
  /// **Non bloquant** : un cours de Coran se suit a la voix.
  static const String prevolCameraAbsente = 'Aucune camera. Le cours reste '
      'possible.';

  // TC-I18N: tc.classe.prevol.permissionRefusee
  /// La cause la plus frequente, et la seule qui se repare ici.
  static const String prevolPermissionRefusee =
      'Acces au micro refuse. Autorisez-le pour ouvrir le cours.';

  // TC-I18N: tc.classe.prevol.reessayer
  /// Remesurer le materiel.
  static const String prevolReessayer = 'Verifier a nouveau';

  // --- Observation --------------------------------------------------------

  // TC-I18N: tc.classe.observation.restant
  /// Le temps d observation restant d un tuteur.
  static String observationRestant(int secondes) => 'Reste $secondes s';
}
