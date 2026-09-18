import '../domain/enums.dart';

/// Les chemins de l'application.
///
/// **Une seule arborescence, pour toutes les plateformes et pour les deux modes
/// d'interface.** Le mode enfant ne cree pas de routes distinctes : il change ce
/// qu'un meme ecran affiche. Deux arborescences dupliquees finissent toujours
/// par diverger silencieusement
/// (`docs/architecture/etape-2-core-flutter.md` section 3).
abstract final class Routes {
  /// Racine. Redirige selon le role.
  static const String racine = '/';

  /// Connexion. Google ou courriel.
  static const String connexion = '/connexion';

  /// Connexion de l'eleve : un code d'appairage, puis le choix de profil.
  ///
  /// Sous-arbre de la connexion, donc public : l'appareil d'un enfant qui
  /// arrive avec un code n'a par construction aucune session.
  static const String connexionEleve = '/connexion/eleve';

  /// Inscription : le compte existe, le profil reste a creer.
  ///
  /// Atteignable uniquement depuis [PorteAcces.inscription], donc avec une
  /// session valide et aucune ligne `profiles`. Un compte deja profile ne peut
  /// pas y revenir.
  static const String inscription = '/inscription';

  /// Portail d'attente : dossier en verification, refuse, ou compte suspendu.
  static const String attente = '/attente';

  /// La carte a accuser une fois : enregistrement audio et visite de controle.
  ///
  /// Premiere des trois etapes du portail, avant le contrat : elle dit en
  /// langage clair ce que le contrat formalisera ensuite (ADR-011).
  static const String attenteAccuse = '/attente/accuse';

  /// Lecture et signature du contrat propre au role.
  static const String attenteContrat = '/attente/contrat';

  /// Depot de la piece d'identite.
  static const String attentePiece = '/attente/piece';

  // --- Eleve, meme arborescence en mode enfant et en mode standard --------

  /// Accueil eleve.
  static const String eleve = '/eleve';

  /// Le Coran.
  static const String eleveCoran = '/eleve/coran';

  /// Suivi et historique de l'eleve.
  static const String eleveSuivi = '/eleve/suivi';

  // --- Tuteur -------------------------------------------------------------

  /// Accueil famille : l'etat en direct de chaque enfant.
  ///
  /// **Seule route ajoutee a l'etape 4 hors de `ADM-06`**, et elle repare un
  /// manque de l'etape 2 : `TUT-01` etait le tableau de bord du tuteur dans
  /// toutes les specs, et aucun chemin ne menait a lui. La racine du role
  /// tombait donc sur `TUT-02`, l'ecran de gestion des appareils, c'est-a-dire
  /// sur un ecran d'administration du foyer plutot que sur son suivi.
  static const String tuteurAccueil = '/tuteur';

  /// Foyer et appareils.
  static const String tuteurFoyer = '/tuteur/foyer';

  /// Ajout d'un enfant au foyer.
  static const String tuteurAjouterEnfant = '/tuteur/foyer/ajouter-enfant';

  /// Appairage d'un appareil pour un eleve donne.
  ///
  /// L'identifiant est dans le chemin et non dans `extra` : contrairement a la
  /// salle, cet ecran n'a rien d'ephemere et doit survivre a un rechargement.
  static const String tuteurAppairer = '/tuteur/foyer/appairer';

  /// Le chemin d'appairage d'un eleve.
  static String appairerPour(String eleveId) => '$tuteurAppairer/$eleveId';

  /// Disponibilites du foyer.
  static const String tuteurDisponibilites = '/tuteur/disponibilites';

  /// Reglages par enfant.
  static const String tuteurReglages = '/tuteur/reglages';

  /// Suivi des cahiers de transmission.
  static const String tuteurSuivi = '/tuteur/suivi';

  // --- Enseignant ---------------------------------------------------------

  /// La journee de cours.
  static const String enseignantJournee = '/enseignant/journee';

  /// Disponibilites et feed de matching.
  static const String enseignantCreneaux = '/enseignant/creneaux';

  /// Profil de l'enseignant.
  static const String enseignantProfil = '/enseignant/profil';

  // --- Controleur ---------------------------------------------------------

  /// Planning global. Une seule destination, pas de barre de navigation.
  static const String controleur = '/controleur';

  // --- Admin --------------------------------------------------------------

  /// Centre de commande.
  static const String adminTableauDeBord = '/admin/tableau-de-bord';

  /// Validation des dossiers d'identite.
  static const String adminDossiers = '/admin/dossiers';

  /// Demandes des quatre parties, et feuille de regles de l'eleve concerne.
  ///
  /// **La seule route que l'etape 4 avait annoncee**, `ADM-06` etant le seul
  /// ecran vraiment nouveau de l'etape : la notion de regle par eleve n'existait
  /// dans aucune spec d'origine, elle nait de l'ADR-017.
  static const String adminDemandes = '/admin/demandes';

  /// Attribution manuelle.
  static const String adminAttribution = '/admin/attribution';

  /// Journal d'audit, lecture seule.
  static const String adminJournal = '/admin/journal';

  /// Acces des agents IA : emission et revocation des jetons d'observation
  /// (`ADM-07`, ADR-025).
  static const String adminAccesAgents = '/admin/acces-agents';

  // --- Observation par un agent IA -----------------------------------------

  /// Entree d'un agent IA (`AGT-00`, ADR-025).
  ///
  /// **Publique par construction** : un agent qui arrive avec un jeton n'a, par
  /// definition, aucune session. Le jeton voyage en parametre d'URL et n'est
  /// jamais range : fermer l'onglet met fin a l'observation.
  ///
  /// Ce n'est pas une porte derobee. Sans jeton vivant, cette route ne rend
  /// qu'un formulaire ; avec un jeton, elle n'ouvre que ce que la base accorde
  /// deja au role `agent_ro`, c'est-a-dire de la lecture, et seulement celle de
  /// la personne observee.
  static const String agentEntree = '/agent';

  /// Le lien a remettre a un agent pour ce jeton.
  static String entreePour(String jeton) => '$agentEntree?jeton=$jeton';

  // --- Comptable ----------------------------------------------------------

  /// Le role existe dans le modele de donnees, son interface arrive en V1
  /// avec le module finance (ADR-003).
  static const String comptable = '/comptable';

  // --- Salle ---------------------------------------------------------------

  /// Salle de cours.
  ///
  /// Jamais partageable, jamais memorisable en favori (ADR-005). Le billet
  /// d'entree transite par `extra`, qui n'apparait pas dans l'URL et disparait
  /// au rechargement : une adresse copiee ne rouvre donc rien.
  static const String salle = '/salle';

  // --- Developpement --------------------------------------------------------

  /// Galerie des composants. Compilee seulement avec `--dart-define=GALERIE=true`.
  static const String galerie = '/_galerie';

  /// Galerie des surfaces Compte, compilee seulement en developpement.
  static const String galerieCompte = '/_galerie/compte';

  // --- Compte -------------------------------------------------------------

  /// Portail commun aux comptes actifs, hors des arbres metier.
  static const String compte = '/compte';

  /// Profil de la personne connectee.
  static const String compteProfil = '/compte/profil';

  /// Preferences locales de l'application.
  static const String compteReglages = '/compte/reglages';

  /// Profils d'enfants du foyer.
  static const String compteProfils = '/compte/profils';

  /// Detail d'un profil enfant.
  static const String compteProfilEnfant = '/compte/profils';

  /// Chemin d'un profil enfant.
  static String compteProfilEnfantPour(String profilId) =>
      '$compteProfilEnfant/$profilId';

  /// Routes atteignables sans session resolue.
  static const Set<String> publiques = <String>{connexion, galerie, agentEntree};

  /// La racine de chaque role, ou une redirection renvoie toujours.
  static String racinePour(AppRole role) => switch (role) {
    AppRole.student => eleve,
    AppRole.guardian => tuteurAccueil,
    AppRole.teacher => enseignantJournee,
    AppRole.controller => controleur,
    AppRole.admin => adminTableauDeBord,
    AppRole.accountant => comptable,
  };

  /// Le prefixe de chemin reserve a un role. Sert a refuser une route d'un
  /// autre role demandee directement par URL, y compris sur le Web.
  static String prefixePour(AppRole role) => switch (role) {
    AppRole.student => eleve,
    AppRole.guardian => tuteurAccueil,
    AppRole.teacher => '/enseignant',
    AppRole.controller => controleur,
    AppRole.admin => '/admin',
    AppRole.accountant => comptable,
  };
}
