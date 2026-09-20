import '../tc_horloge/session_clock_vm.dart';
import 'group_summary_vm.dart';

/// La facade de libelles du domaine Groupe.
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
/// Le sous-arbre d'Agent A est `tc.groupe.*`, et rien d'autre.
abstract final class LibellesGroupe {
  // TC-I18N: tc.groupe.mesGroupes.titre
  /// Le titre de l'ecran « Mes groupes ».
  static const String mesGroupesTitre = 'Mes groupes';

  // TC-I18N: tc.groupe.mesGroupes.aucun
  /// Aucun groupe.
  static const String aucunGroupe = 'Aucun groupe pour le moment';

  // TC-I18N: tc.groupe.mesGroupes.aucunDetail
  /// Ce que cela veut dire.
  static const String aucunGroupeDetail =
      "L'academie vous placera dans un groupe des qu'un creneau vous "
      'correspond.';

  // TC-I18N: tc.groupe.commun.erreur
  /// L'echec de lecture.
  static const String erreur = 'Vos groupes n ont pas pu etre lus';

  // TC-I18N: tc.groupe.commun.reessayer
  /// Reessayer.
  static const String reessayer = 'Reessayer';

  // TC-I18N: tc.groupe.carte.ouvrir
  /// Le libelle d'accessibilite de la carte entiere.
  static String ouvrirGroupe(String libelle) => 'Ouvrir le groupe $libelle';

  // TC-I18N: tc.groupe.carte.capacite
  /// La capacite reelle, toujours lue de la donnee serveur.
  static String capacite({required int membres, required int seuil}) =>
      '$membres / $seuil';

  // TC-I18N: tc.groupe.carte.capacitePhrase
  /// La capacite, dite en toutes lettres pour les technologies d'assistance.
  static String capacitePhrase({required int membres, required int seuil}) =>
      '$membres eleves sur $seuil places';

  // TC-I18N: tc.groupe.carte.complet
  /// Le groupe est au plafond.
  static const String complet = 'Complet';

  // TC-I18N: tc.groupe.carte.prochainCours
  /// L'intitule du bloc de prochaine seance.
  static const String prochainCours = 'Prochain cours';

  // TC-I18N: tc.groupe.carte.aucuneSeance
  /// Aucune occurrence connue.
  static const String aucuneSeance = 'Aucune seance planifiee';

  // TC-I18N: tc.groupe.carte.aucuneSeanceDetail
  /// Pourquoi, sans accuser l'utilisateur.
  static const String aucuneSeanceDetail =
      "Le planning de ce groupe n'est pas encore pose.";

  // TC-I18N: tc.groupe.carte.duree
  /// La duree prevue.
  static String duree(String valeur) => 'Duree $valeur';

  // TC-I18N: tc.groupe.carte.dureeLibelle
  /// L'intitule seul, pour une ligne libelle/valeur.
  static const String dureeLibelle = 'Duree';

  // TC-I18N: tc.groupe.carte.rejoindre
  /// Le bouton d'entree en classe.
  static const String rejoindre = 'Rejoindre';

  // TC-I18N: tc.groupe.enseignant.sayyid
  /// Titre masculin.
  static const String sayyid = 'Sayyid';

  // TC-I18N: tc.groupe.enseignant.sayyida
  /// Titre feminin.
  static const String sayyida = 'Sayyida';

  /// Le nom de l'enseignant, precede de son titre.
  static String enseignantNomme(EnseignantVM enseignant) {
    final String titre = switch (enseignant.titre) {
      TitreEnseignant.sayyid => sayyid,
      TitreEnseignant.sayyida => sayyida,
    };
    return '$titre ${enseignant.nomAffichage}';
  }

  // TC-I18N: tc.groupe.enseignant.photoManquante
  /// La photo obligatoire manque.
  static const String photoManquante = 'Photo a fournir';

  // TC-I18N: tc.groupe.enseignant.photoManquanteDetail
  /// Ce que cela signifie, sans accuser l'enseignant devant les familles.
  static const String photoManquanteDetail =
      "La photo de l'enseignant n'a pas encore ete enregistree.";

  /// Le separateur du produit entre deux fragments d'une meme ligne.
  ///
  /// Un point median, jamais un tiret : le tiret long est refuse par
  /// `tool/verifier_jetons.dart`, et le tiret court se confond avec un signe
  /// moins dans une ligne qui porte des durees.
  static const String separateur = ' · ';

  /// Joint deux fragments, en supportant l'absence de l'un des deux.
  static String joindre(String? premier, String? second) {
    final List<String> morceaux = <String>[
      if (premier != null && premier.trim().isNotEmpty) premier.trim(),
      if (second != null && second.trim().isNotEmpty) second.trim(),
    ];
    return morceaux.join(separateur);
  }

  // TC-I18N: tc.groupe.cours.coursEtNiveau
  /// Le cours et le niveau, en langage humain.
  static String coursEtNiveau({String? cours, String? niveau}) =>
      joindre(cours, niveau);

  // TC-I18N: tc.groupe.temps.dansMinutes
  /// Compte a rebours court.
  static String dansMinutes(int minutes) => 'Cours dans $minutes min';

  // TC-I18N: tc.groupe.temps.dansHeures
  /// Compte a rebours long.
  static String dansHeures({required int heures, required int minutes}) =>
      'Cours dans $heures h ${minutes.toString().padLeft(2, '0')}';

  // TC-I18N: tc.groupe.temps.imminent
  /// Moins d'une minute.
  static const String imminent = 'Cours imminent';

  // TC-I18N: tc.groupe.temps.salleOuverte
  /// La salle est ouverte, le cours n'a pas commence.
  static String salleOuverte(String reste) => 'Salle ouverte · $reste';

  // TC-I18N: tc.groupe.temps.attente
  /// Connecte avant l'heure.
  static const String attenteAvantDebut =
      "Vous etes dans la salle. Le cours n'a pas encore commence.";

  // TC-I18N: tc.groupe.temps.attenteDetail
  /// L'invariant de presence, dit simplement.
  static const String attenteAvantDebutDetail =
      'Ce temps d attente ne compte pas dans votre presence.';

  // TC-I18N: tc.groupe.temps.resteMinutes
  /// Le temps restant, court.
  static String resteMinutes(int minutes) => 'Reste $minutes min';

  // TC-I18N: tc.groupe.temps.resteHeures
  /// Le temps restant, long.
  static String resteHeures({required int heures, required int minutes}) =>
      'Reste $heures h ${minutes.toString().padLeft(2, '0')}';

  // TC-I18N: tc.groupe.temps.enCours
  /// Le cours se tient.
  static String enCours(String reste) => 'Cours en cours · $reste';

  // TC-I18N: tc.groupe.temps.prolongee
  /// La seance deborde. **Jamais un nombre negatif.**
  static const String prolongee = 'Cours toujours en cours';

  // TC-I18N: tc.groupe.temps.terminee
  /// La seance est finie.
  static const String terminee = 'Cours termine';

  /// Le mot d'etat d'une phase, pour la pastille de la carte.
  static String phase(PhaseSeance phase) => switch (phase) {
    PhaseSeance.avantFenetre => prochainCours,
    PhaseSeance.salleOuverte => salleOuverteCourt,
    PhaseSeance.attenteAvantT0 => enSalle,
    PhaseSeance.enCours => enDirect,
    // La pastille dit autre chose que la ligne d'etat : « Cours toujours en
    // cours » est la phrase de la specification, et la repeter deux fois dans
    // la meme carte ferait lire deux informations la ou il n'y en a qu'une.
    PhaseSeance.prolongee => depassement,
    PhaseSeance.terminee => terminee,
  };

  // TC-I18N: tc.groupe.temps.depassement
  /// Forme courte pour une pastille : la seance deborde.
  static const String depassement = 'En depassement';

  // TC-I18N: tc.groupe.temps.salleOuverteCourt
  /// Forme courte pour une pastille.
  static const String salleOuverteCourt = 'Salle ouverte';

  // TC-I18N: tc.groupe.temps.enSalle
  /// Forme courte pour une pastille.
  static const String enSalle = 'En salle';

  // TC-I18N: tc.groupe.temps.enDirect
  /// Forme courte pour une pastille.
  static const String enDirect = 'En direct';

  // TC-I18N: tc.groupe.horloges.votreHeure
  /// L'heure de la personne qui regarde.
  static const String votreHeure = 'Votre heure';

  // TC-I18N: tc.groupe.horloges.chezEnseignant
  /// L'heure de l'enseignant, cote eleve et tuteur.
  static String chezEnseignant(String nomme) => 'Chez $nomme';

  // TC-I18N: tc.groupe.horloges.heureGroupe
  /// L'heure de reference du groupe, cote enseignant.
  static const String heureGroupe = 'Heure du groupe';

  // TC-I18N: tc.groupe.horloges.heureEtVille
  /// Une heure et sa ville, par exemple « 18:00 Riyad ».
  static String heureEtVille({required String heure, required String ville}) =>
      '$heure $ville';

  // TC-I18N: tc.groupe.dst.j30
  /// Anticipation a trente jours.
  static const String dstJ30 = 'Changement d heure dans un mois';

  // TC-I18N: tc.groupe.dst.j7
  /// Anticipation a sept jours.
  static const String dstJ7 = 'Changement d heure la semaine prochaine';

  // TC-I18N: tc.groupe.dst.j1
  /// Anticipation a la veille.
  static const String dstJ1 = 'Changement d heure demain';

  /// L'intitule d'une notice de changement d'heure.
  static String dstEcheance(EcheanceDst echeance) => switch (echeance) {
    EcheanceDst.j30 => dstJ30,
    EcheanceDst.j7 => dstJ7,
    EcheanceDst.j1 => dstJ1,
  };

  // TC-I18N: tc.groupe.dst.detail
  /// Le detail du deplacement, avec deux heures deja rendues.
  static String dstDetail({required String avant, required String apres}) =>
      'Votre cours passera de $avant a $apres.';

  // TC-I18N: tc.groupe.session.conseilAppareil
  /// Le conseil d'appareil, discret et sans jugement.
  static const String conseilAppareil =
      'Tablette ou ordinateur conseille pour le cours. Le telephone reste '
      'pris en charge.';

  // TC-I18N: tc.groupe.espace.avantProchainCours
  /// L'intitule du bloc de travail a venir.
  static const String avantProchainCours = 'Avant le prochain cours';

  // TC-I18N: tc.groupe.espace.aucuneAction
  /// Rien a preparer.
  static const String aucuneAction = 'Rien a preparer pour l instant';

  // TC-I18N: tc.groupe.espace.bibliotheque
  /// L'intitule de la bibliotheque du groupe.
  static const String bibliotheque = 'Bibliotheque';

  // TC-I18N: tc.groupe.espace.bibliothequeVoirTout
  /// L'acces au catalogue complet.
  static const String bibliothequeVoirTout = 'Voir tout';

  // TC-I18N: tc.groupe.espace.progression
  /// L'intitule du bloc de progression.
  static const String progression = 'Progression';

  // TC-I18N: tc.groupe.espace.roster
  /// L'intitule de la liste pedagogique.
  static const String roster = 'Eleves du groupe';

  // TC-I18N: tc.groupe.espace.reprendreLeCours
  /// L'action contextuelle de reprise, jamais une section permanente.
  static const String reprendreLeCours = 'Reprendre le cours';

  // TC-I18N: tc.groupe.espace.retour
  /// Le chemin de sortie vers « Mes groupes ».
  static const String retour = 'Mes groupes';

  // TC-I18N: tc.groupe.espace.introuvable
  /// Le groupe n'est pas visible par l'appelant.
  static const String groupeIntrouvable = 'Ce groupe ne vous est pas ouvert';

  // TC-I18N: tc.groupe.espace.introuvableDetail
  /// Pourquoi.
  static const String groupeIntrouvableDetail =
      'Il a peut-etre ete cloture, ou il appartient a une autre classe.';

  // TC-I18N: tc.groupe.emplacement.nonBranche
  /// Un emplacement dont le port n'est pas encore branche.
  static const String emplacementNonBranche = 'Bientot disponible';

  // TC-I18N: tc.groupe.emplacement.nonBrancheDetail
  /// Ce qui manque, dit sans jargon.
  static const String emplacementNonBrancheDetail =
      'Ce contenu sera rattache a cet espace prochainement.';

  /// Le compte a rebours avant le debut, en clair.
  ///
  /// La coupure a une heure et le remplissage des minutes suivent
  /// `_compteARebours()` de `accueil_eleve_page.dart` : deux ecrans qui
  /// n'arrondiraient pas pareil feraient douter de l'heure du cours.
  static String compteARebours(Duration reste) {
    final int minutes = reste.inMinutes;
    if (minutes <= 0) {
      return imminent;
    }
    if (minutes < Duration.minutesPerHour) {
      return dansMinutes(minutes);
    }
    return dansHeures(
      heures: minutes ~/ Duration.minutesPerHour,
      minutes: minutes % Duration.minutesPerHour,
    );
  }

  /// Le temps restant avant la fin, en clair.
  static String tempsRestant(Duration reste) {
    final int minutes = reste.inMinutes;
    if (minutes < Duration.minutesPerHour) {
      return resteMinutes(minutes < 0 ? 0 : minutes);
    }
    return resteHeures(
      heures: minutes ~/ Duration.minutesPerHour,
      minutes: minutes % Duration.minutesPerHour,
    );
  }

  /// Une duree prevue, en clair : « 1 h 30 » ou « 45 min ».
  static String dureeLisible(Duration duree) {
    final int minutes = duree.inMinutes;
    if (minutes < Duration.minutesPerHour) {
      return '$minutes min';
    }
    final int heures = minutes ~/ Duration.minutesPerHour;
    final int reste = minutes % Duration.minutesPerHour;
    return reste == 0
        ? '$heures h'
        : '$heures h ${reste.toString().padLeft(2, '0')}';
  }

  /// La ligne d'etat de la Session Card, deduite de l'horloge.
  ///
  /// **Un seul endroit decide de cette phrase.** La carte de « Mes groupes » et
  /// la Session Card de l'Espace Groupe lisent la meme : deux formulations pour
  /// le meme instant feraient douter de laquelle croire.
  static String ligneEtat(SessionClockVM horloge) {
    final Duration? restant = horloge.restant;
    return switch (horloge.phase) {
      PhaseSeance.avantFenetre =>
        restant == null ? prochainCours : compteARebours(restant),
      PhaseSeance.salleOuverte => salleOuverte(
        restant == null ? salleOuverteCourt : compteARebours(restant),
      ),
      PhaseSeance.attenteAvantT0 => attenteAvantDebut,
      PhaseSeance.enCours => enCours(
        restant == null ? enDirect : tempsRestant(restant),
      ),
      // Aucun nombre ici, et c'est le coeur de la regle : un compte a rebours
      // negatif serait un mensonge.
      PhaseSeance.prolongee => prolongee,
      PhaseSeance.terminee => terminee,
    };
  }
}
