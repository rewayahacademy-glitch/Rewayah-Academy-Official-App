import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../router/routes.dart';

/// Un domaine de premier niveau du panneau admin (gel d'architecture,
/// `docs/architecture/ADMIN_IA_AUDIT.md`).
///
/// Huit domaines fixes : la sidebar admin ne contient jamais rien de plus
/// granulaire que cette liste, quel que soit le nombre d'ecrans qu'elle
/// recouvre. C'est une regle absolue, pas une preference -- voir
/// [domainesAdmin].
enum AdminDomaine {
  /// Le centre de commande (`ADM-01`). Racine `/admin`.
  accueil,

  /// Groupes pedagogiques (fonction primaire depuis le pivot du 19 septembre
  /// 2026, migration `0017`), attribution manuelle et demandes
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

  /// Reserve. Hors MVP-0, module finance (ADR-003), voir
  /// `docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`.
  finance,

  /// Regles globales du systeme -- distinctes de Finance par nature, jamais
  /// par ecran d'origine (contrat metier du 19 septembre 2026,
  /// `docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`). Trois fonctions
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
    AdminDomaine.finance || AdminDomaine.direction => null,
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
/// toute fondation de permission (`SessionState.peutVoirDirection`). Les
/// domaine reserve restant (Finance), lui, **reste visible** mais inerte :
/// l'audit ne demande pas de le masquer, seulement de ne rien construire
/// derriere. Pedagogie a quitte cette liste le 19 septembre 2026, ses cinq
/// fonctions livrees ; Configuration l'a quittee le meme jour (soir), ses
/// trois premieres fonctions livrees.
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
/// fonction (Finance, Configuration) n'y figure pas : il n'a pas de route a
/// trouver.
List<({String libelle, String chemin})> ciblesRechercheAdmin({
  required bool voitDirection,
}) => <({String libelle, String chemin})>[
  for (final AdminDomaine domaine in domainesAdmin(voitDirection: voitDirection))
    if (domaine.chemin case final String chemin)
      (libelle: domaine.libelle, chemin: chemin),
];

/// Les cinq fonctions pairs du domaine Pedagogie, dans l'ordre d'affichage
/// impose par la mission -- Diagnostics, Progression, Evaluations,
/// Programmes, Qualite -- jamais l'ordre de construction technique (qui a
/// suivi la dependance au programme : Programmes d'abord, Qualite en
/// dernier). Consommee par `SousNavigationDomaine` dans chacun des cinq
/// ecrans.
List<({String libelle, String chemin})> ongletsPedagogie() =>
    <({String libelle, String chemin})>[
      (libelle: t.admin.diagnostics.titre, chemin: Routes.adminPedagogieDiagnostics),
      (libelle: t.admin.progression.titre, chemin: Routes.adminPedagogieProgression),
      (libelle: t.admin.evaluations.titre, chemin: Routes.adminPedagogieEvaluations),
      (libelle: t.admin.programmes.titre, chemin: Routes.adminPedagogieProgrammes),
      (libelle: t.admin.qualite.titre, chemin: Routes.adminPedagogieQualite),
    ];

/// Les fonctions livrees du domaine Configuration, dans l'ordre du contrat
/// metier (`docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`) parmi les
/// sept qu'il liste. **Seules celles construites y figurent** : Academie,
/// Classe en ligne, Notifications et Localisation n'ont ni route ni ecran --
/// les y lister ferait echouer la navigation au clic, exactement ce que
/// l'audit interdit pour un domaine sans fonction reelle. Cette liste
/// grandit lot par lot (`CFG-02`, `CFG-03`), jamais d'un coup comme
/// Pedagogie.
List<({String libelle, String chemin})> ongletsConfiguration() =>
    <({String libelle, String chemin})>[
      (libelle: t.admin.regles.titre, chemin: Routes.adminConfigurationRegles),
      (
        libelle: t.admin.fonctionnalites.titre,
        chemin: Routes.adminConfigurationFonctionnalites,
      ),
      (
        libelle: t.admin.conservationDonnees.titre,
        chemin: Routes.adminConfigurationConservationDonnees,
      ),
    ];
