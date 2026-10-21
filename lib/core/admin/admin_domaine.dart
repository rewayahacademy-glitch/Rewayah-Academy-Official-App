import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../router/routes.dart';

/// Un domaine de premier niveau du panneau admin (gel d'architecture,
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`).
///
/// Huit domaines fixes : la sidebar admin ne contient jamais rien de plus
/// granulaire que cette liste, quel que soit le nombre d'ecrans qu'elle
/// recouvre. C'est une regle absolue, pas une preference -- voir
/// [domainesAdmin].
enum AdminDomaine {
  /// Le centre de commande (`ADM-01`). Racine `/admin`.
  accueil,

  /// Groupes pedagogiques (fonction primaire depuis le pivot du 19 septembre
  /// 2026, migration `0017`), regroupements des demandes et demandes
  /// (reaffectation, regles).
  operations,

  /// Dossiers d'identite et registre des comptes.
  personnes,

  /// Diagnostics de placement, progression, evaluations, programme
  /// pedagogique versionne et controle qualite -- cinq fonctions livrees le
  /// 19 septembre 2026. Les regles individuelles operationnelles (ADM-06)
  /// restent sous Operations, distinctes des exceptions pedagogiques de ce
  /// domaine.
  pedagogie,

  /// Vue globale et politiques commerciales (FI-1b, guide Finance V4 du
  /// directeur, 02/10/2026), routes du contrat metier
  /// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`.
  /// Sans port branche, chaque onglet dit « Pas encore disponible ».
  finance,

  /// Regles globales du systeme -- distinctes de Finance par nature, jamais
  /// par ecran d'origine (contrat metier du 19 septembre 2026,
  /// `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`). Trois fonctions
  /// livrees le 19 septembre 2026 : Regles, Fonctionnalites, Conservation
  /// des donnees. Academie, Classe en ligne, Notifications et Localisation
  /// restent a construire (schema absent ou RPC d'ecriture manquante).
  configuration,

  /// Journal d'audit et acces des agents IA.
  securite,

  /// Reserve. Visible seulement selon permissions -- qui n'existent pas
  /// encore, voir `SessionState.peutVoirDirection`.
  direction,
}

/// Ce qu'un domaine porte pour se rendre dans la sidebar et le routeur.
extension AdminDomaineX on AdminDomaine {
  /// Le libelle affiche.
  String get libelle => switch (this) {
    AdminDomaine.accueil => t.nav.admin.accueil,
    AdminDomaine.operations => t.nav.admin.operations,
    AdminDomaine.personnes => t.nav.admin.personnes,
    AdminDomaine.pedagogie => t.nav.admin.pedagogie,
    AdminDomaine.finance => t.nav.admin.finance,
    AdminDomaine.configuration => t.nav.admin.configuration,
    AdminDomaine.securite => t.nav.admin.securite,
    AdminDomaine.direction => t.nav.admin.direction,
  };

  /// L'icone du domaine.
  AppIcon get icone => switch (this) {
    AdminDomaine.accueil => AppIcons.tableauDeBord,
    AdminDomaine.operations => AppIcons.attribution,
    AdminDomaine.personnes => AppIcons.profil,
    AdminDomaine.pedagogie => AppIcons.pedagogie,
    AdminDomaine.finance => AppIcons.finance,
    AdminDomaine.configuration => AppIcons.reglages,
    AdminDomaine.securite => AppIcons.controleQualite,
    AdminDomaine.direction => AppIcons.direction,
  };

  /// La route de domaine cible, ou `null` quand aucune fonction n'est encore
  /// livree.
  ///
  /// **Nul, jamais un ecran vide** : l'audit interdit explicitement de
  /// construire une page pour remplir le chrome d'un domaine sans fonction
  /// reelle. La sidebar montre le libelle, inerte, jusqu'a ce qu'un ecran
  /// existe -- voir `AdminShell`.
  ///
  /// Pour Operations, Personnes, Pedagogie, Configuration et Securite et
  /// audit, cette route est la racine du domaine : elle redirige vers sa
  /// fonction primaire (jamais une seconde page) -- voir les redirections
  /// d'`app_router.dart`. Pour Operations, Personnes et Securite et audit,
  /// la fonction secondaire reste atteinte depuis l'Accueil ; Pedagogie et
  /// Configuration, elles, montrent leurs fonctions pairs via
  /// `SousNavigationDomaine`, jamais depuis un second niveau de la sidebar.
  String? get chemin => switch (this) {
    AdminDomaine.accueil => Routes.admin,
    AdminDomaine.operations => Routes.adminOperations,
    AdminDomaine.personnes => Routes.adminPersonnes,
    AdminDomaine.pedagogie => Routes.adminPedagogie,
    AdminDomaine.configuration => Routes.adminConfiguration,
    AdminDomaine.securite => Routes.adminSecuriteAudit,
    AdminDomaine.finance => Routes.adminFinance,
    AdminDomaine.direction => null,
  };

  /// Vrai quand le domaine a une fonction reelle, livree et atteignable.
  bool get actif => chemin != null;
}

/// Les domaines visibles dans la sidebar admin, dans l'ordre impose.
///
/// **Jamais plus granulaire, jamais reordonne** : c'est la regle absolue du
/// gel d'architecture. Direction ne parait meme pas dans cette liste tant que
/// [voitDirection] ne l'accorde pas -- « ni la route ni le libelle ne sont
/// exposes » (regle 6 de l'audit) -- fixe a `false` aujourd'hui, faute de
/// toute fondation de permission (`SessionState.peutVoirDirection`).
/// Pedagogie a quitte les domaines reserves le 19 septembre 2026, ses cinq
/// fonctions livrees ; Configuration l'a quittee le meme jour (soir), ses
/// trois premieres fonctions livrees ; Finance le 3 octobre 2026 (FI-1b).
List<AdminDomaine> domainesAdmin({required bool voitDirection}) =>
    <AdminDomaine>[
      AdminDomaine.accueil,
      AdminDomaine.operations,
      AdminDomaine.personnes,
      AdminDomaine.pedagogie,
      AdminDomaine.finance,
      AdminDomaine.configuration,
      AdminDomaine.securite,
      if (voitDirection) AdminDomaine.direction,
    ];

/// Les cibles de la recherche rapide de la barre superieure admin : les
/// domaines qui ont une route reelle.
///
/// **Une recherche de navigation, pas une recherche metier** : aucune donnee
/// n'est interrogee, seulement des libelles fixes et leurs routes -- ce
/// qu'une coquille a le droit de faire, rien de plus. Un domaine sans
/// fonction (Direction) n'y figure pas : il n'a pas de route a trouver.
///
/// Les Communications (sous Operations, QUESTIONS Q4) et Le Studio (action de
/// l'en-tete, Q1) s'y ajoutent apres les domaines : ce ne sont pas des
/// domaines, mais des ecrans qu'aucun libelle de domaine ne nomme (COM-F).
List<({String libelle, String chemin})> ciblesRechercheAdmin({
  required bool voitDirection,
}) => <({String libelle, String chemin})>[
  for (final AdminDomaine domaine in domainesAdmin(
    voitDirection: voitDirection,
  ))
    if (domaine.chemin case final String chemin)
      (libelle: domaine.libelle, chemin: chemin),
  (
    libelle: t.com.socle.navigation.communications,
    chemin: Routes.adminOperationsCommunications,
  ),
  (libelle: t.com.socle.navigation.studio, chemin: Routes.adminStudio),
];

/// Les cinq fonctions pairs du domaine Pedagogie, dans l'ordre d'affichage
/// impose par la mission -- Diagnostics, Progression, Evaluations,
/// Programmes, Qualite -- jamais l'ordre de construction technique (qui a
/// suivi la dependance au programme : Programmes d'abord, Qualite en
/// dernier). Consommee par `SousNavigationDomaine` dans chacun des cinq
/// ecrans.
List<({String libelle, String chemin})> ongletsPedagogie() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.admin.diagnostics.titre,
        chemin: Routes.adminPedagogieDiagnostics,
      ),
      (
        libelle: t.admin.progression.titre,
        chemin: Routes.adminPedagogieProgression,
      ),
      (
        libelle: t.admin.evaluations.titre,
        chemin: Routes.adminPedagogieEvaluations,
      ),
      (
        libelle: t.admin.programmes.titre,
        chemin: Routes.adminPedagogieProgrammes,
      ),
      // CAP29-0 : la bibliotheque est la 6e fonction de Pedagogie, apres
      // Programmes et avant Qualite (aucun neuvieme domaine).
      (
        libelle: t.admin.bibliotheque.titre,
        chemin: Routes.adminPedagogieBibliotheque,
      ),
      (libelle: t.admin.qualite.titre, chemin: Routes.adminPedagogieQualite),
    ];

/// Les quatre fonctions pairs du domaine Finance, dans l'ordre du guide
/// Finance V4 §2 et des maquettes 09 et 10 : Vue globale, puis Politiques
/// commerciales (revue FI-1a, `17_finance/UX_REVIEW_08_FINANCE.md:91`, :297),
/// puis **Reserve et delegation** (Comptable V1, CPT-F : la politique de la
/// Reserve strategique et la delegation financiere, spec Finance
/// operationnelle §37 ; `UX_REVIEW_FINANCE_COMPTABLE_L0.md` §5.9), puis
/// **A valider** (CPT-VAL-1, decision Q-8 = (a) du 05/10 : les demandes du
/// Comptable, valider ou refuser avec motif).
/// Les politiques vivent sous Finance, pas sous Configuration : une
/// politique commerciale est financiere par nature (contrat metier) ; la
/// Reserve et la delegation sont de la gouvernance de tresorerie, un onglet
/// de plus dans le meme domaine, jamais un second systeme Finance.
/// Consommee par `SousNavigationDomaine` dans l'en-tete de `FinancePage`.
List<({String libelle, String chemin})>
ongletsFinance() => <({String libelle, String chemin})>[
  (libelle: t.admin.finance.vueGlobale, chemin: Routes.adminFinance),
  (libelle: t.admin.finance.politiques, chemin: Routes.adminFinancePolitiques),
  (
    libelle: t.admin.finance.reserveDelegation,
    chemin: Routes.adminFinanceReserveDelegation,
  ),
  // CPT-VAL-1 (decision Q-8 = (a) du 05/10) : les demandes du Comptable.
  (libelle: t.admin.finance.aValider, chemin: Routes.adminFinanceAValider),
  // FAC-C-01 (passation du 17/10, point 3) : les paiements recus.
  (libelle: t.admin.finance.paiements, chemin: Routes.adminFinancePaiements),
];

/// Les fonctions livrees du domaine Configuration, dans l'ordre du contrat
/// metier (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_FINANCE_CONFIGURATION.md`) parmi les
/// sept qu'il liste. **Seules celles construites y figurent** : Academie,
/// Classe en ligne, Notifications et Localisation n'ont ni route ni ecran --
/// les y lister ferait echouer la navigation au clic, exactement ce que
/// l'audit interdit pour un domaine sans fonction reelle. Cette liste
/// grandit lot par lot (`CFG-02`, `CFG-03`), jamais d'un coup comme
/// Pedagogie.
///
/// [politiqueRevueKyc] ajoute l'onglet de la politique de genre (AD-9) ; il
/// ne vaut vrai que pour la capacite Super Admin lue par le port.
List<({String libelle, String chemin})> ongletsConfiguration({
  bool politiqueRevueKyc = false,
}) => <({String libelle, String chemin})>[
  (libelle: t.admin.regles.titre, chemin: Routes.adminConfigurationRegles),
  (
    libelle: t.admin.fonctionnalites.titre,
    chemin: Routes.adminConfigurationFonctionnalites,
  ),
  (
    libelle: t.admin.conservationDonnees.titre,
    chemin: Routes.adminConfigurationConservationDonnees,
  ),
  if (politiqueRevueKyc)
    (
      libelle: t.admin.politiqueRevueKyc.titre,
      chemin: Routes.adminConfigurationPolitiqueRevueKyc,
    ),
  // PE : toujours le dernier onglet (apres la politique KYC quand elle existe).
  (
    libelle: t.admin.protectionEnfants.titre,
    chemin: Routes.adminConfigurationProtectionEnfants,
  ),
];

/// Les deux fonctions pairs du domaine Operations (AD-X) : l'Espace de
/// traitement (`ADM-18`, image ADMIN-SHELL-02), racine du domaine, et les
/// Classes (`ADM-09`, image ADMIN-SHELL-03). Regroupements et Demandes restent
/// des fonctions secondaires, atteintes depuis l'Accueil et depuis la file.
/// Consommee par `SousNavigationDomaine` dans l'en-tete des deux ecrans.
List<({String libelle, String chemin})> ongletsOperations() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.admin.traitement.titre,
        chemin: Routes.adminOperationsTraitement,
      ),
      (libelle: t.admin.groupes.titre, chemin: Routes.adminOperationsGroupes),
    ];

/// Les deux fonctions pairs du domaine Personnes : Dossiers a valider
/// (`ADM-02`) et Comptes (`ADM-08`), modification UX n°1. Consommee par
/// `SousNavigationDomaine` dans l'en-tete des deux ecrans.
List<({String libelle, String chemin})> ongletsPersonnes() =>
    <({String libelle, String chemin})>[
      (libelle: t.dossiers.titre, chemin: Routes.adminPersonnesDossiers),
      (libelle: t.admin.comptes.titre, chemin: Routes.adminPersonnesComptes),
      // RECRUT-ECRANS : l'invitation des enseignants, avant leur dossier.
      (
        libelle: t.recrutement.invitations.onglet,
        chemin: Routes.adminPersonnesInvitations,
      ),
      // BACK-FRONT-REPRISE-1 : la file des reprises de foyer.
      (
        libelle: t.reprisesAdmin.onglet,
        chemin: Routes.adminPersonnesReprises,
      ),
      // IMM-ACCUEIL-FRONT : l'import des inscriptions actuelles.
      (
        libelle: t.admin.importInscriptions.onglet,
        chemin: Routes.adminPersonnesImport,
      ),
      // CPT-SUPPR-EXPORT : les demandes de suppression de compte.
      (
        libelle: t.admin.suppressions.onglet,
        chemin: Routes.adminPersonnesSuppressions,
      ),
    ];

/// Les deux fonctions pairs du domaine Securite et audit : le Journal et
/// l'historique des observations (complement observation du mandat Tuteur
/// V1, section 8 ; mapping des routes, ligne C4). Les acces des agents IA
/// restent une fonction secondaire atteinte depuis l'Accueil.
///
/// Consommee par `SousNavigationDomaine` dans l'en-tete des deux ecrans : le
/// Journal (lot E, `journal_page.dart`) et l'historique des observations (lot
/// E, `observations_admin_page.dart`).
List<({String libelle, String chemin})> ongletsSecurite() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.admin.journal.titre,
        chemin: Routes.adminSecuriteAuditJournal,
      ),
      (
        libelle: t.admin.observations.titre,
        chemin: Routes.adminSecuriteAuditObservations,
      ),
      // ECHELLE-CTRL-DIRECT-1 : le tirage des controles (regles et
      // historique), la direction seule.
      (
        libelle: t.admin.tirage.titre,
        chemin: Routes.adminSecuriteAuditTirages,
      ),
    ];

/// Les trois onglets pairs de l'Administration des communications, sous
/// Operations (QUESTIONS Q4) : Annonces, Moderation, Messages, dans cet
/// ordre. Consommee par `SousNavigationDomaine` dans l'en-tete de l'ecran ;
/// aucun neuvieme domaine, aucun second niveau de barre (COM-F).
List<({String libelle, String chemin})> ongletsCommunications() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.com.socle.navigation.ongletAnnonces,
        chemin: Routes.adminCommunicationsAnnonces,
      ),
      (
        libelle: t.com.socle.navigation.ongletModeration,
        chemin: Routes.adminCommunicationsModeration,
      ),
      (
        libelle: t.com.socle.navigation.ongletMessages,
        chemin: Routes.adminCommunicationsMessages,
      ),
    ];
