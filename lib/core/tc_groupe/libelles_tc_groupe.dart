import '../i18n/strings.g.dart';
import '../tc_horloge/session_clock_vm.dart';
import 'group_summary_vm.dart';

/// Les libelles et la mise en forme du domaine Groupe.
///
/// **Module permanent, pas une facade.** A la difference des huit autres
/// facades `// TC-I18N:` du chantier Teaching Core, ce fichier porte de la
/// logique de presentation reelle -- `ligneEtat`, `compteARebours`,
/// `dureeLisible` -- que plusieurs ecrans partagent explicitement (« Un seul
/// endroit decide de cette phrase »). Le supprimer et repeter cette logique a
/// chaque site d'appel referait diverger ce que la carte de « Mes groupes »
/// et la Session Card de l'Espace Groupe affichent pour le meme instant.
/// Seule sa source change : les libelles viennent desormais de
/// `t.tc.groupe.*`, fusionnes depuis `docs/archive/2026-09-pre-remise-a-plat/teaching-core/i18n/tc_i18n_A.json`.
abstract final class LibellesGroupe {
  /// Le titre de l'ecran « Mes groupes ».
  static String get mesGroupesTitre => t.tc.groupe.mesGroupes.titre;

  /// Aucun groupe.
  static String get aucunGroupe => t.tc.groupe.mesGroupes.aucun;

  /// Ce que cela veut dire.
  static String get aucunGroupeDetail => t.tc.groupe.mesGroupes.aucunDetail;

  /// L'echec de lecture.
  static String get erreur => t.tc.groupe.commun.erreur;

  /// Reessayer.
  static String get reessayer => t.tc.groupe.commun.reessayer;

  /// Le libelle d'accessibilite de la carte entiere.
  static String ouvrirGroupe(String libelle) =>
      t.tc.groupe.carte.ouvrir(libelle: libelle);

  /// La capacite reelle, toujours lue de la donnee serveur.
  static String capacite({required int membres, required int seuil}) =>
      t.tc.groupe.carte.capacite(membres: membres, seuil: seuil);

  /// La capacite, dite en toutes lettres pour les technologies d'assistance.
  static String capacitePhrase({required int membres, required int seuil}) =>
      t.tc.groupe.carte.capacitePhrase(membres: membres, seuil: seuil);

  /// Le groupe est au plafond.
  static String get complet => t.tc.groupe.carte.complet;

  /// L'intitule du bloc de prochaine seance.
  static String get prochainCours => t.tc.groupe.carte.prochainCours;

  /// Aucune occurrence connue.
  static String get aucuneSeance => t.tc.groupe.carte.aucuneSeance;

  /// Pourquoi, sans accuser l'utilisateur.
  static String get aucuneSeanceDetail => t.tc.groupe.carte.aucuneSeanceDetail;

  /// La duree prevue.
  static String duree(String valeur) => t.tc.groupe.carte.duree(valeur: valeur);

  /// L'intitule seul, pour une ligne libelle/valeur.
  static String get dureeLibelle => t.tc.groupe.carte.dureeLibelle;

  /// Le bouton d'entree en classe.
  static String get rejoindre => t.tc.groupe.carte.rejoindre;

  /// Titre masculin.
  static String get sayyid => t.tc.groupe.enseignant.sayyid;

  /// Titre feminin.
  static String get sayyida => t.tc.groupe.enseignant.sayyida;

  /// Le nom de l'enseignant, precede de son titre.
  static String enseignantNomme(EnseignantVM enseignant) {
    final String titre = switch (enseignant.titre) {
      TitreEnseignant.sayyid => sayyid,
      TitreEnseignant.sayyida => sayyida,
    };
    return '$titre ${enseignant.nomAffichage}';
  }

  /// La photo obligatoire manque.
  static String get photoManquante => t.tc.groupe.enseignant.photoManquante;

  /// Ce que cela signifie, sans accuser l'enseignant devant les familles.
  static String get photoManquanteDetail =>
      t.tc.groupe.enseignant.photoManquanteDetail;

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

  /// Le cours et le niveau, en langage humain.
  static String coursEtNiveau({String? cours, String? niveau}) =>
      joindre(cours, niveau);

  /// Compte a rebours court.
  static String dansMinutes(int minutes) =>
      t.tc.groupe.temps.dansMinutes(minutes: minutes);

  /// Compte a rebours long.
  static String dansHeures({required int heures, required int minutes}) => t
      .tc
      .groupe
      .temps
      .dansHeures(heures: heures, minutes: minutes.toString().padLeft(2, '0'));

  /// Moins d'une minute.
  static String get imminent => t.tc.groupe.temps.imminent;

  /// La salle est ouverte, le cours n'a pas commence.
  static String salleOuverte(String reste) =>
      t.tc.groupe.temps.salleOuverte(reste: reste);

  /// Connecte avant l'heure.
  static String get attenteAvantDebut => t.tc.groupe.temps.attente;

  /// L'invariant de presence, dit simplement.
  static String get attenteAvantDebutDetail => t.tc.groupe.temps.attenteDetail;

  /// Le temps restant, court.
  static String resteMinutes(int minutes) =>
      t.tc.groupe.temps.resteMinutes(minutes: minutes);

  /// Le temps restant, long.
  static String resteHeures({required int heures, required int minutes}) => t
      .tc
      .groupe
      .temps
      .resteHeures(heures: heures, minutes: minutes.toString().padLeft(2, '0'));

  /// Le cours se tient.
  static String enCours(String reste) =>
      t.tc.groupe.temps.enCours(reste: reste);

  /// La seance deborde. **Jamais un nombre negatif.**
  static String get prolongee => t.tc.groupe.temps.prolongee;

  /// La seance est finie.
  static String get terminee => t.tc.groupe.temps.terminee;

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

  /// Forme courte pour une pastille : la seance deborde.
  static String get depassement => t.tc.groupe.temps.depassement;

  /// Forme courte pour une pastille.
  static String get salleOuverteCourt => t.tc.groupe.temps.salleOuverteCourt;

  /// Forme courte pour une pastille.
  static String get enSalle => t.tc.groupe.temps.enSalle;

  /// Forme courte pour une pastille.
  static String get enDirect => t.tc.groupe.temps.enDirect;

  /// L'heure de la personne qui regarde.
  static String get votreHeure => t.tc.groupe.horloges.votreHeure;

  /// L'heure de l'enseignant, cote eleve et tuteur.
  static String chezEnseignant(String nomme) =>
      t.tc.groupe.horloges.chezEnseignant(nomme: nomme);

  /// L'heure de reference du groupe, cote enseignant.
  static String get heureGroupe => t.tc.groupe.horloges.heureGroupe;

  /// Une heure et sa ville, par exemple « 18:00 Riyad ».
  static String heureEtVille({required String heure, required String ville}) =>
      t.tc.groupe.horloges.heureEtVille(heure: heure, ville: ville);

  /// Anticipation a trente jours.
  static String get dstJ30 => t.tc.groupe.dst.j30;

  /// Anticipation a sept jours.
  static String get dstJ7 => t.tc.groupe.dst.j7;

  /// Anticipation a la veille.
  static String get dstJ1 => t.tc.groupe.dst.j1;

  /// L'intitule d'une notice de changement d'heure.
  static String dstEcheance(EcheanceDst echeance) => switch (echeance) {
    EcheanceDst.j30 => dstJ30,
    EcheanceDst.j7 => dstJ7,
    EcheanceDst.j1 => dstJ1,
  };

  /// Le detail du deplacement, avec deux heures deja rendues.
  static String dstDetail({required String avant, required String apres}) =>
      t.tc.groupe.dst.detail(avant: avant, apres: apres);

  /// Le conseil d'appareil, discret et sans jugement.
  static String get conseilAppareil => t.tc.groupe.session.conseilAppareil;

  /// L'intitule du bloc de travail a venir.
  static String get avantProchainCours => t.tc.groupe.espace.avantProchainCours;

  /// Rien a preparer.
  static String get aucuneAction => t.tc.groupe.espace.aucuneAction;

  /// L'intitule de la bibliotheque du groupe.
  static String get bibliotheque => t.tc.groupe.espace.bibliotheque;

  /// L'acces au catalogue complet.
  static String get bibliothequeVoirTout =>
      t.tc.groupe.espace.bibliothequeVoirTout;

  /// L'intitule du bloc de progression.
  static String get progression => t.tc.groupe.espace.progression;

  /// L'intitule de la liste pedagogique.
  static String get roster => t.tc.groupe.espace.roster;

  /// L'action contextuelle de reprise, jamais une section permanente.
  static String get reprendreLeCours => t.tc.groupe.espace.reprendreLeCours;

  /// Le chemin de sortie vers « Mes groupes ».
  static String get retour => t.tc.groupe.espace.retour;

  /// Le groupe n'est pas visible par l'appelant.
  static String get groupeIntrouvable => t.tc.groupe.espace.introuvable;

  /// Pourquoi.
  static String get groupeIntrouvableDetail =>
      t.tc.groupe.espace.introuvableDetail;

  /// Un emplacement dont le port n'est pas encore branche.
  static String get emplacementNonBranche => t.tc.groupe.emplacement.nonBranche;

  /// Ce qui manque, dit sans jargon.
  static String get emplacementNonBrancheDetail =>
      t.tc.groupe.emplacement.nonBrancheDetail;

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
  ///
  /// Les unites passent par les libelles (`tc.groupe.duree`), plus par des
  /// chaines en dur (defaut D11 de la cartographie C06).
  static String dureeLisible(Duration duree) {
    final int minutes = duree.inMinutes;
    if (minutes < Duration.minutesPerHour) {
      return t.tc.groupe.duree.minutes(minutes: minutes);
    }
    final int heures = minutes ~/ Duration.minutesPerHour;
    final int reste = minutes % Duration.minutesPerHour;
    return reste == 0
        ? t.tc.groupe.duree.heures(heures: heures)
        : t.tc.groupe.duree.heuresMinutes(
            heures: heures,
            minutes: reste.toString().padLeft(2, '0'),
          );
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
