import '../domain/enums.dart';

/// Les chemins de l'application.
///
/// **Une seule arborescence, pour toutes les plateformes et pour les deux modes
/// d'interface.** Le mode enfant ne cree pas de routes distinctes : il change ce
/// qu'un meme ecran affiche. Deux arborescences dupliquees finissent toujours
/// par diverger silencieusement
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 3).
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

  /// Le scanner du QR d'appairage, sur l'appareil de l'eleve. Public comme
  /// tout le sous-arbre de la connexion (contrainte R3) ; le code lu ne passe
  /// jamais par l'URL (R7).
  static const String connexionEleveScanner = '/connexion/eleve/scanner';

  /// La saisie du code d'appairage, retour du scanner compris.
  static const String connexionEleveCode = '/connexion/eleve/code';

  /// La recuperation d'acces : un nouveau lien, jamais un mot de passe.
  static const String connexionRecuperation = '/connexion/recuperation';

  /// L'accueil public avant connexion.
  static const String bienvenue = '/bienvenue';

  /// Inscription : le compte existe, le profil reste a creer.
  ///
  /// Atteignable uniquement depuis [PorteAcces.inscription], donc avec une
  /// session valide et aucune ligne `profiles`. Un compte deja profile ne peut
  /// pas y revenir.
  static const String inscription = '/inscription';

  /// Les quatre etapes de l'inscription, sous le sous-arbre de la porte
  /// `inscription` (contrainte R4 : aucun prefixe `/onboarding`).
  static const String inscriptionUsage = '/inscription/usage';

  /// Identite.
  static const String inscriptionIdentite = '/inscription/identite';

  /// Genre.
  static const String inscriptionGenre = '/inscription/genre';

  /// Recapitulatif, avant la creation du profil.
  static const String inscriptionRecapitulatif = '/inscription/recapitulatif';

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

  // --- DASH-MA-PROD : l'aide de l'eleve -------------------------------------
  //
  // Bloc separe : une autre etape ajoute aussi une route dans ce fichier.

  /// L'aide de l'eleve (« Besoin d'aide ? », dernier bloc de chaque ecran
  /// du Mode Accessibilite, MA14). Sous le prefixe de l'eleve : la garde de
  /// role s'y applique sans rien ajouter.
  static const String eleveAide = '/eleve/aide';

  // --- DASH-EA-PROD : Accueil de l'eleve adulte (bloc propre a l'etape) ----
  //
  // Sous le prefixe `/eleve` : l'eleve adulte est un compte eleve
  // (`AppRole.student`), la garde de role l'y laisse donc entrer. Atteint
  // par `/eleve` quand la capacite « accueil adulte » est servie
  // (`capaciteAccueilAdulteProvider`), jamais d'apres le role. Sans source
  // serveur avant BR-1 (EA-BR-04) : la page dit « indisponible ».

  /// L'Accueil de l'eleve adulte (EA-2, DASH_STRATEGIE.md §3.7).
  static const String eleveAdulte = '/eleve/adulte';

  /// L'historique de ses seances passees, « Voir tout » des dernieres
  /// seances de l'Accueil adulte (D6).
  static const String eleveAdulteSeances = '/eleve/adulte/seances';

  // --- fin du bloc DASH-EA-PROD ---------------------------------------------

  // --- Tuteur -------------------------------------------------------------

  /// Accueil famille : l'etat en direct de chaque enfant.
  ///
  /// **Seule route ajoutee a l'etape 4 hors de `ADM-06`**, et elle repare un
  /// manque de l'etape 2 : `TUT-01` etait le tableau de bord du tuteur dans
  /// toutes les specs, et aucun chemin ne menait a lui. La racine du role
  /// tombait donc sur `TUT-02`, l'ecran de gestion des appareils, c'est-a-dire
  /// sur un ecran d'administration du foyer plutot que sur son suivi.
  static const String tuteurAccueil = '/tuteur';

  /// Alias de l'Accueil (arbre du mandat) : redirige vers [tuteurAccueil].
  ///
  /// **La racine reste `/tuteur`** : `prefixePour(guardian)` en depend, et
  /// changer sa valeur reduirait le prefixe de garde de tout `/tuteur/*`
  /// (contrainte R2).
  static const String tuteurAccueilAlias = '/tuteur/accueil';

  /// Le Foyer, deuxieme destination du tuteur.
  static const String tuteurFoyer = '/tuteur/foyer';

  /// L'ajout d'un profil eleve, depuis l'Accueil, le Foyer ou le Compte.
  ///
  /// Le chemin est `/tuteur/foyer/ajouter` depuis le 24/09/2026 : l'ancien
  /// `ajouter-enfant` portait une regle devenue fausse (un profil eleve peut
  /// etre celui d'un adulte), et redirige ici. Le nom de la constante est
  /// garde pour ses appelants.
  static const String tuteurAjouterEnfant = '/tuteur/foyer/ajouter';

  /// L'ancien chemin d'ajout, garde en redirection vers [tuteurAjouterEnfant].
  static const String tuteurAjouterEnfantAncien =
      '/tuteur/foyer/ajouter-enfant';

  /// L'ajout du profil eleve du titulaire lui-meme (`?pour=moi`, parametre
  /// non sensible) : ecran d'indisponibilite du lot B tant que DB-FOY-01
  /// manque.
  static const String tuteurAjouterPourMoi = '$tuteurAjouterEnfant?pour=moi';

  /// Les appareils du foyer (ecran `AppareilsPage`), sur un chemin statique
  /// declare avant `:eleveId` (contrainte R5).
  static const String tuteurFoyerAppareils = '/tuteur/foyer/appareils';

  /// La fiche d'un profil eleve du foyer.
  static String ficheElevePour(String eleveId) => '$tuteurFoyer/$eleveId';

  /// Une sous-page de la fiche : `informations`, `inscription`, `interface`,
  /// `camera`, `acces` ou `appareils`.
  static String ficheEleveSousPage(String eleveId, String segment) =>
      '${ficheElevePour(eleveId)}/$segment';

  /// Les segments des sous-pages de la fiche, dans l'ordre de la fiche.
  static const List<String> segmentsFicheEleve = <String>[
    'informations',
    'inscription',
    'interface',
    'camera',
    'acces',
    'appareils',
  ];

  /// Appairage d'un appareil pour un eleve donne.
  ///
  /// L'identifiant est dans le chemin et non dans `extra` : contrairement a la
  /// salle, cet ecran n'a rien d'ephemere et doit survivre a un rechargement.
  static const String tuteurAppairer = '/tuteur/foyer/appairer';

  /// Le chemin d'appairage d'un eleve.
  static String appairerPour(String eleveId) => '$tuteurAppairer/$eleveId';

  /// Racine du parcours de personnalisation et de choix d'horaire.
  ///
  /// Sous le prefixe `/tuteur` et non sous `/attente` : le parcours se traverse
  /// avec un dossier valide, et il se reprend -- une famille revient changer
  /// d'horaire longtemps apres son inscription. `deciderRedirection` renvoie
  /// chez lui tout chemin hors prefixe de role ; une page posee a `/parcours`
  /// aurait ete refusee au tuteur par sa propre garde.
  static const String tuteurParcours = '/tuteur/parcours';

  /// Le parcours d'un apprenant donne.
  ///
  /// L'identifiant est dans le chemin et non dans `extra` : cet ecran n'a rien
  /// d'ephemere et doit survivre a un rechargement, comme l'appairage.
  static String parcoursPour(String eleveId) => '$tuteurParcours/$eleveId';

  /// Disponibilites du foyer.
  static const String tuteurDisponibilites = '/tuteur/disponibilites';

  /// Reglages par enfant.
  static const String tuteurReglages = '/tuteur/reglages';

  /// L'Historique du tuteur (destination « Historique ») : l'identifiant
  /// `suivi` est garde, avec ses tests et son ecran (mapping des routes,
  /// section 2).
  static const String tuteurSuivi = '/tuteur/suivi';

  /// Le segment Observations de l'Historique.
  static const String tuteurSuiviObservations = '/tuteur/suivi/observations';

  /// Alias de l'Historique (arbre du mandat) : redirige vers [tuteurSuivi].
  static const String tuteurHistoriqueAlias = '/tuteur/historique';

  /// Racine du detail des seances, deuxieme racine de la branche Historique.
  static const String tuteurSeances = '/tuteur/seances';

  /// Le detail d'une seance passee.
  static String seancePour(String seanceId) => '$tuteurSeances/$seanceId';

  /// Le detail des visites d'observation d'une seance, pour un eleve donne.
  static String observationsSeancePour(String seanceId, {String? eleveId}) =>
      Uri(
        path: '${seancePour(seanceId)}/observations',
        queryParameters: eleveId == null
            ? null
            : <String, String>{'eleve': eleveId},
      ).toString();

  /// Racine des classes du tuteur, dans la branche Accueil. Pas de page a
  /// cette adresse : une classe se choisit depuis l'Accueil.
  static const String tuteurClasses = '/tuteur/classes';

  /// Le choix d'une classe, statique et declare avant `:classeId` (R5).
  static const String tuteurClassesCatalogue = '/tuteur/classes/catalogue';

  /// La classe d'un eleve du foyer.
  static String classePour(String classeId, {String? eleveId}) => Uri(
    path: '$tuteurClasses/$classeId',
    queryParameters: eleveId == null
        ? null
        : <String, String>{'eleve': eleveId},
  ).toString();

  /// Une sous-page de la classe : `planning`, `travail`, `ressources`,
  /// `progression` ou `observer`.
  static String classeSousPage(String classeId, String segment) =>
      '$tuteurClasses/$classeId/$segment';

  /// Les segments des sous-pages de la classe.
  static const List<String> segmentsClasse = <String>[
    'planning',
    'travail',
    'ressources',
    'progression',
  ];

  /// Le compte du tuteur, quatrieme destination de sa coquille.
  static const String tuteurCompte = '/tuteur/compte';

  /// Une sous-page du compte : `informations`, `securite`, `acces`,
  /// `paiements`, `preferences`, `aide`, `informations-legales`,
  /// `consentements`.
  static String compteTuteurSousPage(String segment) =>
      '$tuteurCompte/$segment';

  /// Les segments des sous-pages du compte du tuteur.
  static const List<String> segmentsCompteTuteur = <String>[
    'informations',
    'securite',
    'acces',
    'paiements',
    'preferences',
    'aide',
    'informations-legales',
    'consentements',
  ];

  /// Les preferences du titulaire.
  static const String tuteurComptePreferences = '/tuteur/compte/preferences';

  /// L'apparence (Systeme, Clair, Sombre), sous-page des preferences.
  static const String tuteurCompteApparence =
      '/tuteur/compte/preferences/apparence';

  /// Le consentement aux visites d'observation des comptes existants.
  static const String tuteurCompteConsentements =
      '/tuteur/compte/consentements';

  /// Les notifications du tuteur, ouvertes par la cloche de l'en-tete.
  static const String tuteurNotifications = '/tuteur/notifications';

  /// Vrai quand [chemin] est une **tache focalisee** : sur telephone, la
  /// barre basse s'efface et l'ecran porte son disque retour (manifeste
  /// visuel Tuteur V1 section 4.2 point 5 ; mapping des routes, section 5).
  ///
  /// Une tache focalisee se termine ou s'abandonne : ajout de profil,
  /// emetteur QR d'appairage, questionnaire du parcours, preferences et leur
  /// sous-page, consentement.
  static bool estTacheFocalisee(String chemin) =>
      chemin == tuteurAjouterEnfant ||
      chemin.startsWith('$tuteurAppairer/') ||
      chemin.startsWith('$tuteurParcours/') ||
      chemin == tuteurComptePreferences ||
      chemin.startsWith('$tuteurComptePreferences/') ||
      chemin == tuteurCompteConsentements;

  // --- Enseignant ---------------------------------------------------------

  /// La journee de cours.
  static const String enseignantJournee = '/enseignant/journee';

  /// La liste complete « A terminer » de la Journee (DASH-ENS-ROUTE) : une
  /// adresse, que le rechargement Web garde.
  static const String enseignantATerminer = '$enseignantJournee/a-terminer';

  /// La liste complete des remplacements confirmes de la Journee
  /// (DASH-ENS-LISTES, ligne DASH-ENS-REMPL) : la Journee en montre trois.
  static const String enseignantRemplacements =
      '$enseignantJournee/remplacements';

  /// Toutes les « Alertes utiles » de la Journee (DASH-ENS-LISTES, ligne
  /// DASH-ENS-ALERTES) : la Journee montre deux alertes de presence.
  static const String enseignantAlertes = '$enseignantJournee/alertes';

  /// Mes Classes (ENS-09), deuxieme destination de la barre enseignant (E10,
  /// decision du directeur du 26/09/2026). Page provisoire jusqu'a EN-3.
  static const String enseignantClasses = '/enseignant/classes';

  /// Disponibilites et feed de matching.
  static const String enseignantCreneaux = '/enseignant/creneaux';

  /// Profil de l'enseignant.
  static const String enseignantProfil = '/enseignant/profil';

  // Les quatre routes suivantes ne sont **pas** des destinations de premier
  // niveau : la barre de l'enseignant en tient quatre, Aujourd'hui, Classes,
  // Disponibilites et Profil (E10, decision du directeur du 26/09/2026, qui
  // remplace ADR-027 et ses trois destinations).
  // Ce sont des poses, atteintes depuis un ecran puis quittees
  // (`03-architecture-information.md` section 5).
  //
  // Toutes vivent sous le prefixe `/enseignant`, et ce n'est pas un detail :
  // `prefixePour(AppRole.teacher)` vaut `'/enseignant'`, et `deciderRedirection`
  // renvoie chez lui tout chemin hors prefixe. Un cahier pose a `/cahier`
  // serait refuse a l'enseignant par sa propre garde.

  /// Bienvenue (`ENS-01`) : le premier pas, une fois le dossier valide.
  ///
  /// Se traverse une seule fois et mene a la premiere declaration de
  /// disponibilites, qui vit dans `ENS-06` et non ici : deux grilles de semaine
  /// finiraient par diverger.
  static const String enseignantBienvenue = '/enseignant/bienvenue';

  /// Racine des ecrans contextuels d'une seance.
  static const String enseignantSeance = '/enseignant/seance';

  /// Le cahier de transmission (`ENS-04`) d'une seance.
  ///
  /// **Ecran de sortie obligatoire de seance**, pas un onglet : on y arrive en
  /// quittant la salle, et la Journee le rappelle tant qu'il manque.
  static String cahierPour(String seanceId) =>
      '$enseignantSeance/$seanceId/cahier';

  /// Racine des ecrans contextuels d'un groupe.
  static const String enseignantGroupe = '/enseignant/groupe';

  /// La fiche d'un groupe (`ENS-07`), ouverte depuis la Journee.
  static String groupePour(String groupeId) => '$enseignantGroupe/$groupeId';

  /// La revue courte d'un groupe (`ENS-08`), ouverte depuis sa fiche ou depuis
  /// une anomalie de la Journee.
  static String revuePour(String groupeId) =>
      '$enseignantGroupe/$groupeId/revue';

  // --- Controleur ---------------------------------------------------------

  /// Controle (CTR-01), premiere des quatre destinations du controleur (C13,
  /// document 08 du 27/09/2026, qui remplace « une seule destination, sans
  /// barre »). Une seule carte de mission, jamais de planning (CT-2, C3).
  static const String controleur = '/controleur';

  /// Historique (CTR-05), deuxieme destination. Page provisoire jusqu'a CT-7.
  static const String controleurHistorique = '/controleur/historique';

  /// Echanges (CTR-04), troisieme destination : fils par mission (CT-6).
  /// La quatrieme, Compte, est `/compte`, partage par tous les roles.
  static const String controleurEchanges = '/controleur/echanges';

  /// Le fil de la mission [missionId] dans les Echanges (« Ecrire a
  /// l'administration », P-CTR-06) : le meme ecran, ouvert sur ce fil.
  static String controleurEchangesMission(String missionId) => Uri(
    path: controleurEchanges,
    queryParameters: <String, String>{'mission': missionId},
  ).toString();

  /// Ou mene « Ecrire a l'administration » : le fil de la mission quand son
  /// identifiant est connu, la liste des Echanges sinon.
  static String controleurEcrireAdmin(String? missionId) => missionId == null
      ? controleurEchanges
      : controleurEchangesMission(missionId);

  /// Compte rendu (CTR-03), la sortie de la salle d'observation (P-CTR-03
  /// point 12). Tache focalisee, hors coquille (CT-4).
  static const String controleurCompteRendu = '/controleur/compte-rendu';

  /// Observation (CTR-03A), depuis « Ajouter une observation » ou « Signaler
  /// un point important » du compte rendu. Page provisoire jusqu'a CT-5.
  static const String controleurObservation =
      '/controleur/compte-rendu/observation';

  // --- Admin, huit domaines (gel d'architecture,
  // docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md) ------------------------------------
  //
  // Racine imposee par domaine, jamais par ecran : les routes ci-dessous sont
  // NESTED sous leur domaine, et les anciennes routes plates deviennent des
  // redirections dans `app_router.dart`, jamais une seconde page. Un domaine
  // sans fonction livree (Finance, Configuration, Direction) ne recoit ni
  // route ni page : `AdminDomaine.chemin` y est nul, et la sidebar le montre
  // inerte, jamais avec un ecran vide construit pour l'occasion. Pedagogie
  // a recu ses cinq fonctions (Diagnostics, Progression, Evaluations,
  // Programmes, Qualite) par la mission du 19 septembre 2026 qui a peuple ce
  // domaine reserve.

  /// Domaine Accueil : le centre de commande (`ADM-01`).
  static const String admin = '/admin';

  /// Toutes les alertes ouvertes (`ADM-ALERTES`, ALERTE-1), sous l'Accueil :
  /// ouverte par la cloche, le bandeau d'alerte urgente et « Voir toutes les
  /// alertes » du Centre de commande.
  static const String adminAlertes = '/admin/alertes';

  /// Domaine Operations.
  static const String adminOperations = '/admin/operations';

  /// Les groupes pedagogiques, fonction primaire d'Operations depuis le
  /// pivot du 19 septembre 2026 (migration `0017`).
  static const String adminOperationsGroupes = '/admin/operations/groupes';

  /// Attribution manuelle (`ADM-05`), sous Operations.
  static const String adminOperationsAttributions =
      '/admin/operations/attributions';

  /// Demandes et regles (`ADM-06`), sous Operations.
  static const String adminOperationsDemandes = '/admin/operations/demandes';

  /// Domaine Personnes.
  static const String adminPersonnes = '/admin/personnes';

  /// Validation des dossiers d'identite (`ADM-02`), sous Personnes.
  static const String adminPersonnesDossiers = '/admin/personnes/dossiers';

  /// Les comptes du produit (`ADM-08`), sous Personnes.
  static const String adminPersonnesComptes = '/admin/personnes/comptes';

  /// Les comptes dont l'acces provisoire est echu (DASH-ADM-ECHUS) : la meme
  /// page, ouverte filtree, cible de « Acces echus » du Centre de commande.
  static const String adminPersonnesComptesEchus =
      '$adminPersonnesComptes?filtre=echus';

  /// Domaine Pedagogie.
  static const String adminPedagogie = '/admin/pedagogie';

  /// Diagnostics de placement (`ADM-10`), fonction primaire de Pedagogie.
  static const String adminPedagogieDiagnostics =
      '/admin/pedagogie/diagnostics';

  /// Suivi de progression (`ADM-11`), sous Pedagogie.
  static const String adminPedagogieProgression =
      '/admin/pedagogie/progression';

  /// Evaluations (`ADM-12`), sous Pedagogie.
  static const String adminPedagogieEvaluations =
      '/admin/pedagogie/evaluations';

  /// Le programme pedagogique versionne (`ADM-13`), sous Pedagogie.
  static const String adminPedagogieProgrammes = '/admin/pedagogie/programmes';

  /// Controle qualite pedagogique (`ADM-14`), sous Pedagogie.
  static const String adminPedagogieQualite = '/admin/pedagogie/qualite';

  /// Domaine Configuration -- regles globales du systeme, contrat metier du
  /// 19 septembre 2026 (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`).
  static const String adminConfiguration = '/admin/configuration';

  /// Regles (`ADM-15`), fonction primaire de Configuration : les defauts de
  /// plateforme, jamais les surcharges par profil (`ADM-06`).
  static const String adminConfigurationRegles = '/admin/configuration/regles';

  /// Fonctionnalites (`ADM-16`), sous Configuration.
  static const String adminConfigurationFonctionnalites =
      '/admin/configuration/fonctionnalites';

  /// Conservation des donnees (`ADM-17`), sous Configuration.
  static const String adminConfigurationConservationDonnees =
      '/admin/configuration/conservation-donnees';

  /// Politique de genre pour la revue KYC (AD-9), sous Configuration.
  /// Onglet et contenu reserves a la capacite Super Admin lue par le port.
  static const String adminConfigurationPolitiqueRevueKyc =
      '/admin/configuration/politique-revue-kyc';

  /// Domaine Securite et audit.
  static const String adminSecuriteAudit = '/admin/securite-audit';

  /// Journal d'audit (`ADM-04`), sous Securite et audit.
  static const String adminSecuriteAuditJournal =
      '/admin/securite-audit/journal';

  /// Acces des agents IA (`ADM-07`, ADR-025), sous Securite et audit.
  static const String adminSecuriteAuditAccesAgents =
      '/admin/securite-audit/acces-agents';

  /// L'historique des visites d'observation, onglet pair du Journal
  /// (complement observation du mandat Tuteur V1, section 8).
  static const String adminSecuriteAuditObservations =
      '/admin/securite-audit/observations';

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

  /// La salle de seance en demonstration (roles x etats, donnees fictives).
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoSalle = '/demo/salle';

  /// L'entree en classe en demonstration (roles x etats, CL-4.2).
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoClasse = '/demo/classe';

  /// La coquille enseignant en demonstration (EN-1b) : `?ecran=...&etat=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoEnseignant = '/demo/enseignant';

  /// La coquille controleur en demonstration (CT-1b) : `?ecran=...&etat=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoControleur = '/demo/controleur';

  /// Le Mode Accessibilite en demonstration (MA-1b) : `?eleve=...&moment=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoAccessibilite = '/demo/accessibilite';

  /// La coquille de l'eleve adulte en demonstration (EA-1b) :
  /// `?ecran=...&etat=...&titulaire=femme&vue=conjoint`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoAdulte = '/demo/adulte';

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

  // --- Teaching Core, sous le prefixe reserve `/tc/` -----------------------
  //
  // Promues depuis les cinq fichiers de chemins des lots A, B, C, E, G
  // (plan d'integration Teaching Core, etape 7). Les constantes d'origine
  // (`CheminsTcA`, `RoutesTcB`, `RoutesCoran`, `RoutesTcE`, `RoutesTcG`)
  // restent la source geometrique (segments, parametres) ; celles-ci ne
  // duplquent que les chemins qu'un ecran hors Teaching Core a besoin de
  // nommer (navigation, redirection).

  /// Mes groupes (A). Roles autorises : eleve, tuteur.
  static const String tcGroupes = '/tc/groupes';

  /// L'Espace Groupe d'un groupe donne (A).
  static String tcEspaceGroupe(String groupeId) => '$tcGroupes/$groupeId';

  /// La Bibliotheque (B). Roles autorises : eleve, tuteur.
  static const String tcBibliotheque = '/tc/bibliotheque';

  /// Le moteur Coran hors classe (C). Route interne : la destination
  /// `/eleve/coran` pointe directement sur ce moteur, voir `app_router.dart`.
  static const String tcMushaf = '/tc/mushaf';

  /// La Classe Live (E). Roles autorises : enseignant, eleve. Atteinte par le
  /// bouton « Rejoindre » et la barre « Cours en cours », jamais par URL
  /// tapee (ADR-005).
  static const String tcClasse = '/tc/classe';

  /// La porte d'observation d'une seance (G). Roles autorises : tuteur,
  /// admin, controleur.
  static String tcObservation(String seanceId) => '/tc/observation/$seanceId';

  /// La page « acces refuse » : une route connue d'un autre role, demandee
  /// par URL. Ouverte a tout compte actif ; elle ramene a la racine du role.
  static const String accesRefuse = '/acces-refuse';

  /// La page « hors ligne » du demarrage : la session existe, mais le serveur
  /// n'a pas repondu a la lecture du profil. Elle n'ouvre rien.
  static const String horsLigne = '/hors-ligne';

  /// Les sous-arbres atteignables sans session : **la liste unique que lit la
  /// garde** d'un visiteur deconnecte (`deciderRedirection`, G-PUB). La
  /// galerie de developpement a sa propre porte, compilee seulement sous
  /// `GALERIE`.
  static const Set<String> publiques = <String>{
    connexion,
    bienvenue,
    agentEntree,
  };

  /// La racine de chaque role, ou une redirection renvoie toujours.
  static String racinePour(AppRole role) => switch (role) {
    AppRole.student => eleve,
    AppRole.guardian => tuteurAccueil,
    AppRole.teacher => enseignantJournee,
    AppRole.controller => controleur,
    AppRole.admin => admin,
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
