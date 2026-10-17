import '../domain/enums.dart';
import '../finance/montant.dart';

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

  /// RECRUT-ECRANS : le code d'invitation du candidat enseignant, sous la
  /// porte `inscription`. Le parametre `code` d'un lien d'invitation est
  /// verifie des l'ouverture.
  static const String inscriptionInvitation = '/inscription/invitation';

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
  // Sous le prefixe `/eleve` : l'eleve adulte est un compte tuteur
  // (`AppRole.guardian`) dont le serveur sert la capacite « eleve autonome »
  // (`SessionState.eleveAutonome`, C-24) ; la redirection le laisse entrer
  // sur ce seul sous-arbre (EA-ROLE-1). Atteint par `/eleve` quand la
  // capacite « accueil adulte » est servie
  // (`capaciteAccueilAdulteProvider`), jamais d'apres le role. Sans source
  // serveur avant BR-1 (EA-BR-04) : la page dit « indisponible ».

  /// L'Accueil de l'eleve adulte (EA-2, DASH_STRATEGIE.md §3.7).
  static const String eleveAdulte = '/eleve/adulte';

  /// L'historique de ses seances passees, « Voir tout » des dernieres
  /// seances de l'Accueil adulte (D6).
  static const String eleveAdulteSeances = '/eleve/adulte/seances';

  /// Le suivi de ses demandes de creneau (BACK-FRONT-SUIVI-1) : l'eleve
  /// adulte autonome voit lui-meme sa frise.
  static const String eleveAdulteDemandes = '/eleve/adulte/demandes';

  /// La frise d'une de ses demandes.
  static String eleveAdulteDemande(String demandeId) =>
      '$eleveAdulteDemandes/$demandeId';

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

  /// La recharge d'un ou plusieurs profils (guide Finance V4 §4, FI-4), sur
  /// un chemin statique declare avant `:eleveId` (contrainte R5). Un seul
  /// moteur de recharge (`RechargeFoyerPage`).
  static const String tuteurFoyerRecharge = '/tuteur/foyer/recharge';

  /// La recharge avec [profils] deja coches (`?profils=a,b`).
  static String rechargePour(Iterable<String> profils) => Uri(
    path: tuteurFoyerRecharge,
    queryParameters: <String, String>{'profils': profils.join(',')},
  ).toString();

  /// La recharge ouverte depuis Compte > Paiements (`?depuis=compte`) :
  /// l'abandon y ramene, jamais au Foyer (revue FI-7).
  static final String rechargeDepuisCompte = Uri(
    path: tuteurFoyerRecharge,
    queryParameters: <String, String>{'depuis': origineCompte},
  ).toString();

  /// La valeur de `?depuis=` d'une recharge ouverte depuis le Compte.
  static const String origineCompte = 'compte';

  /// La recharge reprise apres un echec (FI-8, guide §5.4 : « ne pas perdre
  /// la selection ») : les profils coches et le montant de chacun
  /// (`?profils=a,b&montants=a:1000:USD,b:4000:USD`). Le montant n'est
  /// qu'un rappel : l'ecran ne le retient que s'il fait partie des montants
  /// que la source propose. [commande] : la commande d'ou l'on reprend
  /// (`&reprise=`), pour qu'une reprise ouvre toujours une recharge neuve.
  /// La recharge est une seule page (R3-01) : le recapitulatif et le moyen
  /// de paiement s'y lisent des que la selection rappelee est complete.
  static String rechargeReprise(
    Map<String, Montant> montants, {
    String? commande,
  }) => Uri(
    path: tuteurFoyerRecharge,
    queryParameters: <String, String>{
      'profils': montants.keys.join(','),
      'montants': <String>[
        for (final MapEntry<String, Montant> e in montants.entries)
          '${e.key}:${e.value.mineur}:${e.value.devise}',
      ].join(','),
      if (commande != null && commande.isNotEmpty) 'reprise': commande,
    },
  ).toString();

  /// Relit `?montants=` ([rechargeReprise]) ; une entree illisible est
  /// ignoree, jamais devinee.
  static Map<String, Montant> montantsDe(String? brut) => <String, Montant>{
    for (final String entree in (brut ?? '').split(','))
      if (entree.split(':')
          case [final String id, final String mineur, final String devise]
          when id.isNotEmpty && devise.isNotEmpty)
        if (int.tryParse(mineur) case final int m) id: Montant(m, devise),
  };

  /// Le resultat d'une recharge (FI-8, guide §1.6 et §5.4) : l'etat de la
  /// commande tel que la source le rend, sur un chemin statique declare sous
  /// la recharge, avant `:eleveId` (contrainte R5).
  static const String tuteurFoyerRechargeResultat =
      '$tuteurFoyerRecharge/result';

  /// Le resultat de la commande [commandeId] (`?commande=`) : une adresse
  /// rouverte relit l'etat, elle ne rejoue jamais le paiement. [recharge] :
  /// les parametres de la recharge qui a paye, gardes dans l'adresse pour
  /// que la recharge sous le resultat reste la meme page (sa commande, son
  /// « Suivre le paiement »), y compris au retour du navigateur.
  static String resultatRechargePour(
    String commandeId, {
    Map<String, String> recharge = const <String, String>{},
  }) => Uri(
    path: tuteurFoyerRechargeResultat,
    queryParameters: <String, String>{
      for (final MapEntry<String, String> e in recharge.entries)
        if (!_horsIdentite.contains(e.key)) e.key: e.value,
      'commande': commandeId,
    },
  ).toString();

  /// L'identite d'une recharge, lue de son adresse ou de celle de son
  /// resultat : tous les parametres sauf `commande` et `etape`, tries. La
  /// meme identite garde la meme page (et sa commande) ; une autre en ouvre
  /// une neuve.
  static String identiteRecharge(Map<String, String> parametres) => (<String>[
    for (final MapEntry<String, String> e in parametres.entries)
      if (!_horsIdentite.contains(e.key)) '${e.key}=${e.value}',
  ]..sort()).join('&');

  /// Les parametres qui ne font pas l'identite d'une recharge.
  static const Set<String> _horsIdentite = <String>{'commande', 'etape'};

  /// La fiche d'un profil eleve du foyer.
  static String ficheElevePour(String eleveId) => '$tuteurFoyer/$eleveId';

  /// Une sous-page de la fiche : `informations`, `inscription`, `interface`,
  /// `camera`, `acces`, `finances`, `mouvements` ou `appareils`.
  static String ficheEleveSousPage(String eleveId, String segment) =>
      '${ficheElevePour(eleveId)}/$segment';

  /// Les segments des sous-pages de la fiche, dans l'ordre de la fiche.
  static const List<String> segmentsFicheEleve = <String>[
    'informations',
    'inscription',
    'interface',
    'couleur',
    'camera',
    'acces',
    'finances',
    'mouvements',
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

  // --- Communications V1 (COM-F) -------------------------------------------
  //
  // Les routes des Communications sont posees une fois par le socle (COM-F,
  // `UX_REVIEW_COMMUNICATIONS_L0` section 3) ; chaque voie remplace ensuite
  // l'ecran provisoire dans son propre dossier. Toutes vivent sous le
  // prefixe du role (`prefixePour`) : aucune garde nouvelle, aucune
  // destination ajoutee aux barres (4 sur 4, `nav_shell.dart`).

  /// Les Messages metier du tuteur (COM-M01, COM-W01), une pose de l'Accueil :
  /// aucune cinquieme destination, l'entree vient de l'Espace Classe et des
  /// notifications.
  static const String tuteurMessages = '/tuteur/messages';

  /// Un fil des Messages du tuteur.
  static String tuteurFilPour(String filId) => '$tuteurMessages/$filId';

  /// Le suivi des demandes de creneau du foyer (OFFRES-FAM-1).
  static const String tuteurDemandes = '/tuteur/demandes';

  /// Les demandes de presentation standard de ses enfants (MA-9).
  static const String tuteurPresentation = '/tuteur/presentation';

  /// La frise d'une demande (SUIVI-FAMILLE, R20).
  static String tuteurDemande(String demandeId) => '$tuteurDemandes/$demandeId';

  /// ECHELLE-FAM-ETATS-1 : le resultat d'une fusion ou d'un transfert pour une
  /// demande : la nouvelle classe, le titre de l'enseignant, l'horaire.
  static String tuteurChangementPour(String demandeId) =>
      '$tuteurDemandes/$demandeId/changement';

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

  /// L'ecran commun des remplacements (REMPL-1) : offres urgentes, vos
  /// remplacements confirmes (la Journee en montre trois), offres prises.
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

  /// Mes revenus (FI-10, guide Finance V4 §4 et §5.5) : l'estimation du mois,
  /// atteinte depuis le Profil (le Compte de l'enseignant), dans sa branche.
  static const String enseignantRevenus = '/enseignant/revenus';

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

  /// Le contrat a signer de nouveau (Q-2 = a, 05/10/2026) : un enseignant
  /// actif qui a signe la version 2026-09 y est mene quand la politique de
  /// controle est publiee (`resignatureContratEnseignantProvider`). Fermee
  /// le reste du temps (`deciderRedirection`).
  static const String enseignantContrat = '/enseignant/contrat';

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

  /// La publication d'une annonce pour la Classe [groupeId] (COM-ANN,
  /// spec section 14) : une tache focalisee ouverte depuis l'Espace Classe
  /// enseignant (`FicheGroupePage`).
  static String publierAnnoncePour(String groupeId) =>
      '$enseignantGroupe/$groupeId/annonce';

  /// Les Messages metier de l'enseignant (COM-M01, COM-W01) : une pose,
  /// Classes reste la destination active.
  static const String enseignantMessages = '/enseignant/messages';

  /// Un fil des Messages de l'enseignant.
  static String enseignantFilPour(String filId) => '$enseignantMessages/$filId';

  /// La Communaute enseignants (COM-M02, COM-W02) : un raccourci depuis
  /// Aujourd'hui (QUESTIONS Q2), jamais une destination.
  static const String enseignantCommunaute = '/enseignant/communaute';

  /// Une publication de la Communaute.
  static String enseignantPublicationPour(String publicationId) =>
      '$enseignantCommunaute/$publicationId';

  /// Les notifications de l'enseignant, ouvertes par la cloche de sa
  /// coquille : la `NotificationsPage` existante, jamais un second centre.
  static const String enseignantNotifications = '/enseignant/notifications';

  // --- Controleur ---------------------------------------------------------

  /// Controle (CTR-01), premiere des quatre destinations du controleur (C13,
  /// document 08 du 27/09/2026, qui remplace « une seule destination, sans
  /// barre »). Une seule carte de mission, jamais de planning (CT-2, C3).
  static const String controleur = '/controleur';

  /// La seconde etape de connexion du controleur (L1-10) : enrolement d'un
  /// facteur TOTP, ou verification a chaque connexion. Hors coquille, sans
  /// barre : tant que la capacite `mfaRequise` est vraie, c'est la seule page
  /// atteignable.
  static const String mfaControleur = '/controleur/mfa';

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

  /// Les notifications du controleur, ouvertes par la cloche de sa coquille.
  /// Les Echanges restent son seul fil (C13) : aucune route Messages ici.
  static const String controleurNotifications = '/controleur/notifications';

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

  /// `ADM-18` : l'Espace de traitement (AD-X, image ADMIN-SHELL-02), file
  /// reunie des dossiers et des demandes en attente. Racine du domaine
  /// Operations.
  static const String adminOperationsTraitement =
      '/admin/operations/traitement';

  /// Attribution manuelle (`ADM-05`), sous Operations.
  static const String adminOperationsAttributions =
      '/admin/operations/attributions';

  /// Demandes et regles (`ADM-06`), sous Operations.
  static const String adminOperationsDemandes = '/admin/operations/demandes';

  /// L'Administration des communications (COM-W04), sous Operations
  /// (QUESTIONS Q4) : jamais un neuvieme domaine. La racine renvoie a son
  /// premier onglet, Annonces.
  static const String adminOperationsCommunications =
      '/admin/operations/communications';

  /// Onglet Annonces de l'Administration des communications.
  static const String adminCommunicationsAnnonces =
      '$adminOperationsCommunications/annonces';

  /// Onglet Moderation de l'Administration des communications.
  static const String adminCommunicationsModeration =
      '$adminOperationsCommunications/moderation';

  /// Onglet Messages de l'Administration des communications.
  static const String adminCommunicationsMessages =
      '$adminOperationsCommunications/messages';

  /// Un fil des Messages, cote administration.
  static String adminFilPour(String filId) =>
      '$adminCommunicationsMessages/$filId';

  /// Le Studio (COM-W00, COM-M04) : l'espace de travail interne, reserve a
  /// l'admin en V1 (QUESTIONS Q1). Ouvert par l'action « Le Studio » de
  /// l'en-tete de l'`AdminShell`, hors de la coquille admin (sa propre
  /// navigation, sortie vers [admin]).
  static const String adminStudio = '/admin/studio';

  /// Racine des canaux du Studio : pas de page a cette adresse.
  static const String adminStudioCanaux = '$adminStudio/canaux';

  /// Un canal du Studio (COM-W03, COM-M03).
  static String canalStudioPour(String canalId) =>
      '$adminStudioCanaux/$canalId';

  /// Les notifications de l'admin, ouvertes par la cloche de l'en-tete de
  /// l'`AdminShell`.
  static const String adminNotifications = '/admin/notifications';

  /// OFFRES-ADM-1 : « Classes a ouvrir », les demandes semblables reunies et
  /// la creation de leur classe, sous Operations.
  static const String adminOperationsRegroupements =
      '/admin/operations/regroupements';

  /// L2-05 : l'administration des offres vitrine (creer, publier, retirer),
  /// sous Operations.
  static const String adminOperationsOffres = '/admin/operations/offres';

  /// ECHELLE-ADM-PILOTAGE-1 : le tableau de pilotage par horaire (classes,
  /// remplissage, demandes, enseignants libres et manquants), sous
  /// Operations.
  static const String adminOperationsPilotage = '/admin/operations/pilotage';

  /// DASH-ADM-PLANNING : le planning de la direction, les seances de la
  /// semaine toutes classes confondues. Atteint depuis l'Accueil.
  static const String adminOperationsPlanning = '/admin/operations/planning';

  /// RECRUT-ECRANS : inviter un enseignant (code a usage unique), sous
  /// Personnes.
  static const String adminPersonnesInvitations =
      '/admin/personnes/invitations';

  /// BACK-FRONT-REPRISE-1 : la file des reprises de foyer, sous Personnes.
  static const String adminPersonnesReprises = '/admin/personnes/reprises';

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

  /// CAP29-0 : le catalogue de la bibliotheque, sous Pedagogie.
  static const String adminPedagogieBibliotheque =
      '/admin/pedagogie/bibliotheque';

  /// CAP29-C : ajouter un support (import), avant `:supportId` dans le routeur.
  static const String adminPedagogieBibliothequeNouveau =
      '/admin/pedagogie/bibliotheque/nouveau';

  /// CAP29-D : verifier et publier la derniere version d'un support.
  static String adminPedagogieSupportPublication(String supportId) =>
      '$adminPedagogieBibliotheque/$supportId/publication';

  /// CAP29-E : attribuer un support aux classes, ou le retirer.
  static String adminPedagogieSupportAttribution(String supportId) =>
      '$adminPedagogieBibliotheque/$supportId/attribution';

  /// CAP29-C : deposer un fichier pour le brouillon d'un support existant.
  static String adminPedagogieSupportFichier(String supportId) =>
      '$adminPedagogieBibliothequeNouveau?support=$supportId';

  /// CAP29-0 : la fiche d'un support de la bibliotheque.
  static String adminPedagogieSupport(String supportId) =>
      '$adminPedagogieBibliotheque/$supportId';

  /// Domaine Finance (FI-1b) : racine et onglet « Vue globale » (route
  /// canonique « Vue d'ensemble » du contrat metier,
  /// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md:68`).
  static const String adminFinance = '/admin/finance';

  /// Politiques commerciales, onglet de Finance (FI-1b ; revue FI-1a,
  /// `17_finance/UX_REVIEW_08_FINANCE.md:91`).
  static const String adminFinancePolitiques = '/admin/finance/politiques';

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

  /// DASH-ADM-INC : les incidents des 24 dernieres heures, ce que compte la
  /// tuile « Incidents (24 h) » de l'Accueil (D9).
  static const String adminSecuriteAuditIncidents =
      '/admin/securite-audit/incidents';

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

  /// ECHELLE-CTRL-DIRECT-1 : les regles du tirage des missions de controle et
  /// l'historique audite des tirages, lisibles par la direction seule, sous
  /// Securite et audit.
  static const String adminSecuriteAuditTirages =
      '/admin/securite-audit/tirages';

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
  //
  // Comptable V1 (CPT-F, spec `REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1`,
  // `20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` §3) : quatre
  // destinations, Aujourd'hui, Paiements, Tresorerie, Compte (`/compte`,
  // partage), et des onglets DANS la page pour le second niveau. Toutes les
  // routes du role vivent sous `/comptable` (`prefixePour`) ; « Recevoir mes
  // paiements » vit sous `/compte`, ouvert a tout beneficiaire avec compte ;
  // le delta Direction vit sous `/admin/finance`. Ces constantes sont posees
  // UNE FOIS par CPT-F et gelees : une voie qui en veut une autre ecrit une
  // ligne pour CPT-FUS (`20_comptable/02_DECOUPAGE.md`, regle de propriete).

  /// La racine du role : Aujourd'hui (FIN-CPT-W01, M01 ecran 1).
  static const String comptable = '/comptable';

  /// Destination Paiements, onglet « A effectuer » (W02, M01 ecran 2).
  static const String comptablePaiements = '/comptable/paiements';

  /// Le segment fixe du detail d'une obligation payable (W03) : `obligation`
  /// pour ne jamais entrer en collision avec `contractuels` et
  /// `beneficiaires`, qui vivent sous le meme prefixe.
  static const String comptablePaiementsObligation =
      '/comptable/paiements/obligation';

  /// Le detail d'une obligation payable (W03, M01 ecran 3).
  static String comptablePaiementObligationPour(String obligationId) =>
      '$comptablePaiementsObligation/$obligationId';

  /// Onglet « Contractuels » de Paiements (W06).
  static const String comptableContractuels =
      '/comptable/paiements/contractuels';

  /// « Nouvelle obligation » (W06), seulement si la capacite
  /// `creerObligation` est rendue par la source. Une tache focalisee.
  static const String comptableContractuelsNouvelle =
      '/comptable/paiements/contractuels/nouvelle';

  /// Le segment fixe du detail d'une obligation de contractuel.
  static const String comptableContractuelsObligation =
      '/comptable/paiements/contractuels/obligation';

  /// Le detail d'une obligation de contractuel (W06). « Payer » y ouvre le
  /// W03 de l'obligation payable, jamais un second tunnel (DR-12).
  static String comptableContractuelObligationPour(String obligationId) =>
      '$comptableContractuelsObligation/$obligationId';

  /// Onglet « Beneficiaires » de Paiements (W07, liste).
  static const String comptableBeneficiaires =
      '/comptable/paiements/beneficiaires';

  /// Le profil de paiement d'un beneficiaire, vu par le Comptable (W07).
  static String comptableBeneficiairePour(String beneficiaireId) =>
      '$comptableBeneficiaires/$beneficiaireId';

  /// Le fil metier « Profil de paiement » d'un beneficiaire, ouvert par
  /// « Relancer » (CPT-COM, CPT-BR-11) : un fil contextuel des Messages
  /// metier, jamais une messagerie Finance (R-FIN-21).
  static String comptableFilProfilPaiementPour(String beneficiaireId) =>
      '${comptableBeneficiairePour(beneficiaireId)}/fil';

  /// Destination Tresorerie, onglet « Coffres » (W04, M02 ecran 1).
  static const String comptableTresorerie = '/comptable/tresorerie';

  /// Onglet « Encaissements » de Tresorerie (W05, M02 ecran 2).
  static const String comptableEncaissements =
      '/comptable/tresorerie/encaissements';

  /// Le detail d'un encaissement (panneau a 1440, page sous 1200).
  static String comptableEncaissementPour(String encaissementId) =>
      '$comptableEncaissements/$encaissementId';

  /// Onglet « Rapprochement » de Tresorerie (`ReconciliationWorkspace`).
  static const String comptableRapprochement =
      '/comptable/tresorerie/rapprochement';

  /// Onglet « Rapports » de Tresorerie (COMPTA-GRAPH-1) : entrees et sorties
  /// sur 6 mois, flux sur 30 jours, export du rapport.
  static const String comptableRapports = '/comptable/tresorerie/rapports';

  /// « Recevoir mes paiements » (spec §17, §38) : la surface personnelle de
  /// tout beneficiaire avec compte (enseignant, Comptable), sous `/compte`
  /// comme `/compte/profil`, dans la coquille du role connecte.
  static const String comptePaiementsRecus = '/compte/paiements-recus';

  /// Le troisieme onglet du domaine Finance de la direction : « Reserve et
  /// delegation » (spec §37, delta Direction).
  static const String adminFinanceReserveDelegation =
      '/admin/finance/reserve-delegation';

  /// Le quatrieme onglet du domaine Finance de la direction : « A valider »
  /// (decision Q-8 = (a) du 05/10, CPT-VAL-1) : les demandes du Comptable
  /// qu'une autre personne habilitee valide ou refuse.
  static const String adminFinanceAValider = '/admin/finance/a-valider';

  /// La coquille du Comptable en demonstration : `?ecran=...&montants=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoComptable = '/demo/comptable';

  /// Parametre de requete : le filtre d'une liste du Comptable (`?filtre=`),
  /// valeurs de [filtresPaiementsComptable] pour les paiements.
  static const String parametreFiltreComptable = 'filtre';

  /// Parametre de requete : le type de beneficiaire (`?type=enseignant` ou
  /// `?type=contractuel`, [typesBeneficiaireComptable]).
  static const String parametreTypeComptable = 'type';

  /// Parametre de requete : la Classe, qui reste un filtre et un detail
  /// analytique, jamais un payout separe (`?classe=`, spec §14.5).
  static const String parametreClasseComptable = 'classe';

  /// Parametre de requete : l'action ouverte a l'arrivee (`?action=`).
  static const String parametreActionComptable = 'action';

  /// Parametre de requete : la vue d'Aujourd'hui (`?vue=`).
  static const String parametreVueComptable = 'vue';

  /// Valeur de `?action=` : ouvrir « Alimenter la Reserve strategique » sur
  /// la Tresorerie (W04), depuis les Acces rapides d'Aujourd'hui.
  static const String actionAlimenterReserve = 'alimenter';

  /// Valeur de `?vue=` : la file complete « A traiter » et « Alertes »
  /// d'Aujourd'hui (le « Voir tout » de M01, DR-10), meme route.
  static const String vueAttentionComptable = 'attention';

  /// Les filtres de la liste « Paiements a effectuer » (`?filtre=`) : les
  /// liens d'Aujourd'hui ouvrent la liste deja filtree (spec §5.1, « un
  /// raccourci ouvre toujours l'ecran canonique »).
  static const List<String> filtresPaiementsComptable = <String>[
    'prets',
    'infos',
    'verification',
    'validation',
    'retard',
  ];

  /// Les valeurs de `?type=` de la liste des paiements.
  static const List<String> typesBeneficiaireComptable = <String>[
    'enseignant',
    'contractuel',
  ];

  /// L'adresse de la liste des paiements, filtree : aucun parametre vide.
  static String comptablePaiementsFiltres({
    String? filtre,
    String? type,
    String? classe,
  }) => _avecRequete(comptablePaiements, <String, String?>{
    parametreFiltreComptable: filtre,
    parametreTypeComptable: type,
    parametreClasseComptable: classe,
  });

  /// L'adresse de la liste des encaissements, filtree.
  static String comptableEncaissementsFiltres({String? filtre}) => _avecRequete(
    comptableEncaissements,
    <String, String?>{parametreFiltreComptable: filtre},
  );

  /// L'adresse des beneficiaires, filtree (`?filtre=infos`, par exemple).
  static String comptableBeneficiairesFiltres({String? filtre}) => _avecRequete(
    comptableBeneficiaires,
    <String, String?>{parametreFiltreComptable: filtre},
  );

  /// La Tresorerie ouverte sur « Alimenter la Reserve strategique ».
  static String get comptableTresorerieAlimenter => _avecRequete(
    comptableTresorerie,
    <String, String?>{parametreActionComptable: actionAlimenterReserve},
  );

  /// Aujourd'hui ouvert sur la file complete.
  static String get comptableAttention => _avecRequete(
    comptable,
    <String, String?>{parametreVueComptable: vueAttentionComptable},
  );

  /// Vrai quand [chemin] est une page de la destination Paiements du
  /// Comptable (onglet actif, retour des pages de detail).
  static bool estPaiementsComptable(String chemin) =>
      chemin == comptablePaiements || chemin.startsWith('$comptablePaiements/');

  /// Vrai quand [chemin] est une page de la destination Tresorerie.
  static bool estTresorerieComptable(String chemin) =>
      chemin == comptableTresorerie ||
      chemin.startsWith('$comptableTresorerie/');

  /// Vrai quand [chemin] est une tache focalisee du Comptable : sur
  /// telephone, la barre basse s'efface et l'ecran porte son disque retour.
  /// Seul le formulaire « Nouvelle obligation » en est une : les pages de
  /// detail (obligation, encaissement, profil de paiement) gardent la barre,
  /// comme les fiches du tuteur.
  static bool estTacheFocaliseeComptable(String chemin) =>
      chemin == comptableContractuelsNouvelle;

  /// [chemin] avec les parametres de [requete] qui ont une valeur non vide ;
  /// sans aucun, le chemin nu (jamais un `?` orphelin).
  static String _avecRequete(String chemin, Map<String, String?> requete) {
    final Map<String, String> pleins = <String, String>{
      for (final MapEntry<String, String?> e in requete.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    if (pleins.isEmpty) return chemin;
    return Uri(path: chemin, queryParameters: pleins).toString();
  }

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

  /// Le domaine Finance en demonstration (FI-1b) : `?ecran=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoFinance = '/demo/finance';

  /// Les Communications en demonstration (COM-F) : `?voie=...&role=...`.
  /// Enregistree seulement hors production (`environnementAutoriseDemo`).
  static const String demoCommunications = '/demo/communications';

  // --- Developpement --------------------------------------------------------

  /// Galerie des composants. Compilee seulement avec `--dart-define=GALERIE=true`.
  static const String galerie = '/_galerie';

  /// Galerie des surfaces Compte, compilee seulement en developpement.
  static const String galerieCompte = '/_galerie/compte';

  // --- RECH-1 : la recherche transversale (spec RECH-03 §1, §4.1) ---------
  //
  // Bloc propre a l'etape. **Une seule route pour tous les espaces** : la
  // surface de recherche est transverse, ni un tableau de bord ni un
  // cinquieme onglet. L'espace actif et le domaine d'ouverture sont des
  // choix d'interface en parametres, sans aucun texte cherche dans l'adresse :
  // la requete ne passe jamais par l'URL (SEC-R20).

  /// La recherche commune, hors des arbres de role (comme `/compte`).
  static const String recherche = '/recherche';

  /// L'adresse de la recherche avec son contexte : [espace] est le nom d'un
  /// `EspaceRecherche`, [domaine] celui d'un `DomaineRecherche` (recherche
  /// contextuelle d'un module). Jamais le texte cherche.
  static String rechercheAvec({String? espace, String? domaine}) => Uri(
    path: recherche,
    queryParameters: <String, String>{'espace': ?espace, 'domaine': ?domaine},
  ).toString();

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

  /// Ou mene la cloche des notifications de la coquille d'un role : la
  /// `NotificationsPage` existante, sous le prefixe du role. Nul pour un
  /// role sans cloche (l'eleve, le comptable).
  static String? notificationsPour(AppRole role) => switch (role) {
    AppRole.guardian => tuteurNotifications,
    AppRole.teacher => enseignantNotifications,
    AppRole.controller => controleurNotifications,
    AppRole.admin => adminNotifications,
    AppRole.student || AppRole.accountant => null,
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
