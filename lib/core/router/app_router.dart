import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/_dev/galerie/compte_galerie.dart';
import '../../features/_dev/galerie/galerie_page.dart';
import '../../features/accueil_eleve/accueil_eleve_page.dart';
import '../../features/accueil_famille/accueil_famille_page.dart';
import '../../features/admin_acces_agents/acces_agents_page.dart';
import '../../features/admin_attribution/attribution_page.dart';
import '../../features/admin_comptes/comptes_page.dart';
import '../../features/admin_configuration_conservation_donnees/conservation_donnees_page.dart';
import '../../features/admin_configuration_fonctionnalites/fonctionnalites_page.dart';
import '../../features/admin_configuration_regles/regles_page.dart';
import '../../features/admin_demandes/demandes_page.dart';
import '../../features/admin_dossiers/dossiers_page.dart';
import '../../features/admin_groupes/groupes_page.dart';
import '../../features/admin_journal/journal_page.dart';
import '../../features/admin_pedagogie_diagnostics/diagnostics_page.dart';
import '../../features/admin_pedagogie_evaluations/evaluations_page.dart';
import '../../features/admin_pedagogie_programmes/programmes_page.dart';
import '../../features/admin_pedagogie_progression/progression_page.dart';
import '../../features/admin_pedagogie_qualite/qualite_page.dart';
import '../../features/admin_tableau/tableau_de_bord_page.dart';
import '../../features/agent_entree/agent_entree_page.dart';
import '../../features/appareils/ajouter_enfant_page.dart';
import '../../features/appareils/appairage_page.dart';
import '../../features/appareils/appareils_page.dart';
import '../../features/bienvenue_enseignant/bienvenue_page.dart';
import '../../features/cahier/cahier_page.dart';
import '../../features/compte/compte_page.dart';
import '../../features/connexion/connexion_page.dart';
import '../../features/controleur/planning_page.dart';
import '../../features/creneaux/creneaux_page.dart';
import '../../features/disponibilites/disponibilites_page.dart';
import '../../features/dossier/attente_page.dart';
import '../../features/dossier/depot_piece_page.dart';
import '../../features/dossier/signature_page.dart';
import '../../features/eleve_connexion/eleve_connexion_page.dart';
import '../../features/fiche_groupe/fiche_groupe_page.dart';
import '../../features/inscription/inscription_page.dart';
import '../../features/journee/journee_page.dart';
import '../../features/parcours_offres/parcours_offres_page.dart';
import '../../features/profil_enseignant/profil_enseignant_page.dart';
import '../../features/reglages_enfant/reglages_enfant_page.dart';
import '../../features/revue_groupe/revue_groupe_page.dart';
import '../../features/salle/salle_page.dart';
import '../../features/suivi_eleve/suivi_eleve_page.dart';
import '../../features/suivi_foyer/suivi_foyer_page.dart';
import '../../features/tc_catalogue/routes_tc_b.dart';
import '../../features/tc_classe_live/routes_tc_e.dart';
import '../../features/tc_mes_groupes/routes_tc_a.dart';
import '../../features/tc_mushaf/mushaf_page.dart';
import '../../features/tc_mushaf/routes_tc_c.dart';
import '../../features/tc_observation_ui/routes_tc_g.dart';
import '../admin/admin_domaine.dart';
import '../config/env.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../tc_groupe/group_home_vm.dart' show RoleEspaceGroupe;
import '../widgets/admin_shell.dart';
import '../widgets/nav_shell.dart';
import 'billet_salle.dart';
import 'ecran_a_construire.dart';
import 'redirection.dart';
import 'routes.dart';

/// Le routeur de l'application.
///
/// **Un seul routeur, pour toutes les plateformes**, puisque le Web est ouvert
/// a tous les roles (ADR-008). Aucune branche de navigation par plateforme,
/// aucune arborescence dupliquee entre le mode enfant et le mode standard
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 3).
///
/// `tool/verifier_jetons.dart` echoue si un second fichier du depot construit
/// un `GoRouter`.
final Provider<GoRouter> routeurProvider = Provider<GoRouter>((Ref ref) {
  final _RafraichisseurRoutage rafraichisseur = _RafraichisseurRoutage();

  ref.listen<SessionState>(sessionProvider, (SessionState? _, SessionState _) {
    rafraichisseur.declencher();
  });
  ref.onDispose(rafraichisseur.dispose);

  // Lu une fois, a la construction du routeur : un role ne change pas sans
  // reconnexion, qui recree ce provider. `routesTcA` n'en a besoin que pour
  // distinguer l'affichage eleve/tuteur au sein de l'Espace Groupe -- la
  // redirection, elle, s'appuie sur le role frais lu a chaque decision.
  final RoleEspaceGroupe sessionRole = _roleEspaceGroupePour(
    ref.read(sessionProvider).role,
  );

  return GoRouter(
    initialLocation: Routes.racine,
    refreshListenable: rafraichisseur,
    redirect: (BuildContext _, GoRouterState etat) {
      return deciderRedirection(
        session: ref.read(sessionProvider),
        cheminDemande: etat.matchedLocation,
        billet: etat.extra is BilletSalle ? etat.extra! as BilletSalle : null,
        maintenant: DateTime.now(),
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.racine,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.commun.chargement),
      ),
      GoRoute(
        path: Routes.connexion,
        builder: (BuildContext _, GoRouterState _) => const ConnexionPage(),
      ),
      GoRoute(
        path: Routes.connexionEleve,
        builder: (BuildContext _, GoRouterState _) =>
            const EleveConnexionPage(),
      ),
      GoRoute(
        path: Routes.inscription,
        builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
      ),
      // `AGT-00` : l'entree d'un agent IA (ADR-025). Publique, puisqu'un
      // porteur de jeton n'a par definition aucune session ; elle n'ouvre rien
      // par elle-meme, l'observation se decide dans `main()`.
      GoRoute(
        path: Routes.agentEntree,
        builder: (BuildContext _, GoRouterState _) => const AgentEntreePage(),
      ),
      // Le portail d'attente et ses trois pages. Le sous-arbre entier est
      // ouvert a un compte en attente, la racine seule ne suffirait pas.
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) => const AttentePage(),
      ),
      GoRoute(
        path: Routes.attenteAccuse,
        builder: (BuildContext _, GoRouterState _) => const AccusePage(),
      ),
      GoRoute(
        path: Routes.attenteContrat,
        builder: (BuildContext _, GoRouterState _) => const ContratPage(),
      ),
      GoRoute(
        path: Routes.attentePiece,
        builder: (BuildContext _, GoRouterState _) => const DepotPiecePage(),
      ),

      // Compte. Cet espace est partage par les roles actifs, mais ses
      // capacites restent celles projetees par la session et le serveur.
      //
      // Le chrome du role l'entoure, **role lu dans la session** : c'est ici
      // que vit « Se deconnecter », donc l'ecran que tout role finit par
      // ouvrir, et il se rendait sans aucune navigation. On y entrait par le
      // pied du tiroir et on n'en ressortait qu'avec le bouton precedent du
      // navigateur.
      GoRoute(
        path: Routes.compte,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ComptePage()),
      ),
      GoRoute(
        path: Routes.compteProfil,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ProfilPersonnelPage()),
      ),
      GoRoute(
        path: Routes.compteReglages,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ReglagesComptePage()),
      ),
      GoRoute(
        path: Routes.compteProfils,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ProfilsComptePage()),
      ),
      GoRoute(
        path: '${Routes.compteProfilEnfant}/:profilId',
        builder: (BuildContext _, GoRouterState etat) => _CoquilleSecondaire(
          child: ProfilEnfantPage(
            profilId: etat.pathParameters['profilId'] ?? '',
          ),
        ),
      ),

      // Eleve. Meme arborescence en mode enfant et en mode standard : c'est ce
      // que chaque ecran AFFICHE qui change, jamais la structure (ADR-009). La
      // barre a trois destinations en mode standard, zero en mode enfant :
      // `destinationsPour` decide ce qui est rendu, les branches existent dans
      // les deux modes.
      StatefulShellRoute.indexedStack(
        builder: (BuildContext _, GoRouterState _, StatefulNavigationShell n) =>
            _CoquilleNavigation(role: AppRole.student, navigationShell: n),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleve,
                builder: (BuildContext _, GoRouterState _) =>
                    const AccueilElevePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleveCoran,
                // Pointe sur le nouveau moteur Mushaf (Teaching Core, lot C) :
                // arbitrage entérine au plan d'integration section 3.1 point
                // 1, « la destination /eleve/coran existante pointe sur le
                // nouveau moteur ». `sessionId` reste nul : hors classe.
                builder: (BuildContext _, GoRouterState _) =>
                    const MushafPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleveSuivi,
                builder: (BuildContext _, GoRouterState _) =>
                    const SuiviElevePage(),
              ),
            ],
          ),
        ],
      ),

      // Tuteur. `TUT-01` est la racine du role : c'est le suivi du foyer, et
      // non l'ecran de gestion des appareils, qui accueille le parent. Les
      // routes foyer, ajout d'enfant et appairage restent hors de la barre,
      // atteintes depuis l'ecran puis quittees : ce sont des poses, pas des
      // etages (`03-architecture-information.md` section 5).
      StatefulShellRoute.indexedStack(
        builder: (BuildContext _, GoRouterState _, StatefulNavigationShell n) =>
            _CoquilleNavigation(role: AppRole.guardian, navigationShell: n),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurAccueil,
                builder: (BuildContext _, GoRouterState _) =>
                    const AccueilFamillePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurDisponibilites,
                builder: (BuildContext _, GoRouterState _) =>
                    const DisponibilitesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurReglages,
                builder: (BuildContext _, GoRouterState _) =>
                    const ReglagesEnfantPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurSuivi,
                builder: (BuildContext _, GoRouterState _) =>
                    const SuiviFoyerPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.tuteurFoyer,
        builder: (BuildContext _, GoRouterState _) => const AppareilsPage(),
      ),
      GoRoute(
        path: Routes.tuteurAjouterEnfant,
        builder: (BuildContext _, GoRouterState _) => const AjouterEnfantPage(),
      ),
      GoRoute(
        path: '${Routes.tuteurAppairer}/:eleveId',
        builder: (BuildContext _, GoRouterState etat) =>
            AppairagePage(eleveId: etat.pathParameters['eleveId'] ?? ''),
      ),
      // Le parcours de personnalisation et de choix d'horaire. Une pose, pas
      // une destination de la barre : on y entre depuis l'accueil famille et on
      // en ressort (`03-architecture-information.md` section 5).
      GoRoute(
        path: '${Routes.tuteurParcours}/:eleveId',
        builder: (BuildContext _, GoRouterState etat) =>
            ParcoursOffresPage(eleveId: etat.pathParameters['eleveId'] ?? ''),
      ),

      // Enseignant.
      StatefulShellRoute.indexedStack(
        builder: (BuildContext _, GoRouterState _, StatefulNavigationShell n) =>
            _CoquilleNavigation(role: AppRole.teacher, navigationShell: n),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantJournee,
                builder: (BuildContext _, GoRouterState _) =>
                    const JourneePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantCreneaux,
                builder: (BuildContext _, GoRouterState _) =>
                    const CreneauxPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantProfil,
                builder: (BuildContext _, GoRouterState _) =>
                    const ProfilEnseignantPage(),
              ),
            ],
          ),
        ],
      ),

      // Les quatre poses de l'enseignant, HORS de la coquille et c'est le
      // point : une `GoRoute` posee dans une `StatefulShellBranch` devient une
      // destination de la barre, et la barre de l'enseignant en tient
      // exactement trois (`TEACHER_PARALLEL_BASELINE.md` §3.1, ADR-027). Une
      // pose s'atteint depuis un ecran puis se quitte, comme les trois poses du
      // tuteur juste au-dessus.
      //
      // La forme des chemins est ecrite ici avec ses parametres, et calculee
      // ailleurs par `Routes.cahierPour`, `groupePour` et `revuePour` : les deux
      // doivent rester d'accord, et `test/router/redirection_test.dart` mesure
      // les deux cotes -- que chaque constructeur produise bien un chemin sous
      // `/enseignant`, et qu'un tuteur qui le demande reparte chez lui.
      GoRoute(
        path: Routes.enseignantBienvenue,
        builder: (BuildContext _, GoRouterState _) =>
            const BienvenueEnseignantPage(),
      ),
      GoRoute(
        path: '${Routes.enseignantSeance}/:seanceId/cahier',
        builder: (BuildContext _, GoRouterState etat) =>
            CahierPage(seanceId: etat.pathParameters['seanceId'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId',
        builder: (BuildContext _, GoRouterState etat) =>
            FicheGroupePage(groupeId: etat.pathParameters['groupeId'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId/revue',
        builder: (BuildContext _, GoRouterState etat) =>
            RevueGroupePage(groupeId: etat.pathParameters['groupeId'] ?? ''),
      ),

      // Controleur : une seule destination, pas de barre de navigation.
      // `CTR-01` est sa racine et son seul ecran ; `CTR-02`, la salle, se
      // rejoint depuis une ligne en cours et vit hors de l'arbre (ADR-005).
      GoRoute(
        path: Routes.controleur,
        builder: (BuildContext _, GoRouterState _) =>
            const PlanningControleurPage(),
      ),

      // Admin. Huit domaines (gel d'architecture,
      // `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`), routes NESTED par domaine.
      // Chaque route porte son domaine explicitement, comme
      // `_CoquilleSecondaire` portait deja son role -- ni l'un ni l'autre ne
      // devine depuis le chemin courant. Pedagogie, Finance, Configuration et
      // Direction n'ont **aucune route ici** : l'audit interdit une page
      // construite pour un domaine sans fonction reelle
      // (`AdminDomaine.chemin` y est nul, `AdminShell` les rend inertes).
      GoRoute(
        path: Routes.admin,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.accueil,
          child: TableauDeBordPage(),
        ),
      ),
      // La racine du domaine Operations n'est pas une page : elle renvoie a
      // sa fonction primaire, jamais une seconde implementation. Groupes en
      // est la fonction primaire depuis le pivot du 19 septembre 2026
      // (migration `0017`) : c'est le noyau du produit, l'Attribution et les
      // Demandes restent des fonctions secondaires atteignables depuis
      // l'Accueil.
      GoRoute(
        path: Routes.adminOperations,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsGroupes,
      ),
      GoRoute(
        path: Routes.adminOperationsGroupes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: GroupesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminOperationsAttributions,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: AttributionPage(),
        ),
      ),
      // La reaffectation (demandes) reste atteinte depuis l'Accueil, jamais
      // depuis un second niveau de la sidebar
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md).
      GoRoute(
        path: Routes.adminOperationsDemandes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: DemandesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPersonnes,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesDossiers,
      ),
      GoRoute(
        path: Routes.adminPersonnesDossiers,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          child: DossiersPage(),
        ),
      ),
      // `ADM-08` : les comptes, atteints depuis l'Accueil
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md).
      // Sans cet ecran, l'administration n'avait aucun moyen de voir une
      // personne inscrite qui n'a pas encore depose sa piece : c'est le
      // defaut mesure le 18 septembre 2026.
      GoRoute(
        path: Routes.adminPersonnesComptes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          child: ComptesPage(),
        ),
      ),
      // Domaine Pedagogie : cinq fonctions pairs, jamais une secondaire
      // atteinte seulement depuis l'Accueil comme Operations/Personnes --
      // voir `SousNavigationDomaine`. Diagnostics est la fonction primaire,
      // meme pattern que Groupes pour Operations : la file la plus
      // actionnable du domaine.
      GoRoute(
        path: Routes.adminPedagogie,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPedagogieDiagnostics,
      ),
      GoRoute(
        path: Routes.adminPedagogieDiagnostics,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: DiagnosticsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieProgression,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: ProgressionPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieEvaluations,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: EvaluationsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieProgrammes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: ProgrammesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieQualite,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: QualitePage(),
        ),
      ),
      // Domaine Configuration : la racine redirige vers Regles, sa fonction
      // primaire -- meme mecanique que Pedagogie plus haut. Academie, Classe
      // en ligne, Notifications et Localisation n'ont pas de route : aucune
      // fonction reelle derriere elles, voir `ongletsConfiguration()`.
      GoRoute(
        path: Routes.adminConfiguration,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminConfigurationRegles,
      ),
      GoRoute(
        path: Routes.adminConfigurationRegles,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: ReglesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminConfigurationFonctionnalites,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: FonctionnalitesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminConfigurationConservationDonnees,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: ConservationDonneesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminSecuriteAudit,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditJournal,
      ),
      GoRoute(
        path: Routes.adminSecuriteAuditJournal,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: JournalPage(),
        ),
      ),
      // `ADM-07` : l'acces des agents IA (ADR-025), atteint depuis l'Accueil.
      GoRoute(
        path: Routes.adminSecuriteAuditAccesAgents,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: AccesAgentsPage(),
        ),
      ),

      // Anciennes routes plates : des redirections, jamais une seconde page
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md, table de compatibilite).
      GoRoute(
        path: '/admin/tableau-de-bord',
        redirect: (BuildContext _, GoRouterState _) => Routes.admin,
      ),
      GoRoute(
        path: '/admin/dossiers',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesDossiers,
      ),
      GoRoute(
        path: '/admin/comptes',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesComptes,
      ),
      GoRoute(
        path: '/admin/attribution',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsAttributions,
      ),
      GoRoute(
        path: '/admin/demandes',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsDemandes,
      ),
      GoRoute(
        path: '/admin/journal',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditJournal,
      ),
      GoRoute(
        path: '/admin/acces-agents',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditAccesAgents,
      ),

      // Comptable : le role existe, son interface arrive en V1 (ADR-003).
      GoRoute(
        path: Routes.comptable,
        builder: (BuildContext _, GoRouterState _) => const ComptePage(),
      ),

      // Teaching Core (plan d'integration, etape 7). Cinq lots, cinq
      // fonctions qui RETOURNENT des routes sans jamais construire de
      // `GoRouter` (decision D-04) : `routesTcA`, `routesTcB`, `routesTcC`,
      // `routesTcE`, `routesTcG`. Chaque chemin porte son autorisation de
      // role dans `redirection.dart` (`_teachingCoreAutorise`), sans quoi
      // `/tc/` serait inatteignable pour tous les roles.
      ...routesTcA(role: sessionRole),
      ...routesTcB(),
      ...routesTcC(),
      ...routesTcE(),
      ...routesTcG(),

      // Salle. Le billet passe par `extra`, jamais par l'URL (ADR-005).
      //
      // `deciderRedirection` a deja refuse l'entree sans billet presentable :
      // arriver ici avec `extra` vide est donc impossible par le routeur. Le
      // repli sur une seance vide existe quand meme, et il est sur -- le
      // backend refusera le jeton, et l'ecran affichera son impasse d'acces
      // plutot que de lever.
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState etat) => SallePage(
          seanceId: etat.extra is BilletSalle
              ? (etat.extra! as BilletSalle).sessionId
              : '',
        ),
      ),

      // Galerie de developpement, absente des versions de production.
      if (Env.galerieActive)
        GoRoute(
          path: Routes.galerie,
          builder: (BuildContext _, GoRouterState _) => const GaleriePage(),
        ),
      if (Env.galerieActive)
        GoRoute(
          path: Routes.galerieCompte,
          builder: (BuildContext _, GoRouterState _) =>
              const CompteGaleriePage(),
        ),
    ],
  );
});

/// Reveille go_router quand la session change.
///
/// go_router attend un [Listenable] ; Riverpod fournit un flux d'etats. Ce pont
/// existe uniquement pour relier les deux, il ne porte aucune logique.
class _RafraichisseurRoutage extends ChangeNotifier {
  void declencher() => notifyListeners();
}

/// Racine de l'application, branchee sur le routeur.
class AppRouterDelegateHote extends ConsumerWidget {
  /// Cree l'hote du routeur.
  const AppRouterDelegateHote({required this.constructeur, super.key});

  /// Construit l'application a partir de la configuration de routage.
  final Widget Function(BuildContext context, GoRouter routeur) constructeur;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      constructeur(context, ref.watch(routeurProvider));
}

/// Les routes atteignables, exposees pour les tests d'arborescence.
@visibleForTesting
List<String> cheminsDeclares(GoRouter routeur) {
  final List<String> chemins = <String>[];
  void parcourir(List<RouteBase> routes, String prefixe) {
    for (final RouteBase route in routes) {
      if (route is GoRoute) {
        final String complet = route.path.startsWith('/')
            ? route.path
            : '$prefixe/${route.path}';
        chemins.add(complet);
        parcourir(route.routes, complet);
      }
    }
  }

  parcourir(routeur.configuration.routes, '');
  return chemins;
}

/// Redirige vers la racine du role, sans passer par une route intermediaire.
@visibleForTesting
String racineDe(AppRole? role) =>
    role == null ? Routes.connexion : Routes.racinePour(role);

/// Traduit le role de session en role d'Espace Groupe (Teaching Core, lot A).
///
/// **Un role different, pas un doublon** : `AppRole` vient du JWT et porte
/// six valeurs, `RoleEspaceGroupe` n'en porte que quatre et decide
/// uniquement de ce que l'Espace Groupe affiche. Le controleur et le
/// comptable n'atteignent jamais `/tc/groupes` (`_teachingCoreAutorise` dans
/// `redirection.dart` le refuse), le repli `eleve` ici ne sert donc qu'a
/// satisfaire le type : aucun de ces deux roles ne le lit jamais.
@visibleForTesting
RoleEspaceGroupe roleEspaceGroupePour(AppRole? role) =>
    _roleEspaceGroupePour(role);

RoleEspaceGroupe _roleEspaceGroupePour(AppRole? role) => switch (role) {
  AppRole.guardian => RoleEspaceGroupe.tuteur,
  AppRole.teacher => RoleEspaceGroupe.enseignant,
  AppRole.admin => RoleEspaceGroupe.admin,
  AppRole.student ||
  AppRole.controller ||
  AppRole.accountant ||
  null => RoleEspaceGroupe.eleve,
};

/// La coquille de navigation d'un role, autour des branches qui sont ses
/// destinations.
///
/// Le role est connu par construction de la route : chaque coquille est câblée
/// a un seul role. Le mode d'interface, lui, est lu dans la session : un eleve
/// en mode enfant obtient zero destination, `NavShell` rend alors l'ecran sans
/// le moindre chrome, sur les memes branches (ADR-009).
/// Le chrome d'un role autour d'un ecran **hors** de sa barre.
///
/// `ADM-06`, `ADM-07` et `ADM-08` ne sont pas des destinations de premier
/// niveau, la barre etant plafonnee a quatre entrees (et gelee a trois pour
/// l'enseignant, `TEACHER_PARALLEL_BASELINE.md` §3.1), mais ils ont besoin de
/// son chrome pour qu'on puisse en **sortir**. Sans lui, on y entre et on n'en
/// revient qu'avec le bouton precedent du navigateur : c'est precisement le
/// reproche fait a l'interface le 18 septembre 2026, et `ADM-08` venait de le
/// reproduire le jour meme de sa creation.
///
/// **L'espace « Mon compte » est le meme cas, et il avait ete oublie** : c'est
/// l'ecran ou vit « Se deconnecter », donc celui que tout role finit par
/// ouvrir, et il se rendait sans le moindre chrome. On y arrivait par le pied
/// du tiroir et on n'en ressortait plus. Il est partage par tous les roles, le
/// role s'y lit donc toujours dans la session, jamais câble par la route.
///
/// Aucune destination n'est active ici : `indexActif` est nul, et le chrome
/// rend alors ses entrees sans en surligner aucune.
class _CoquilleSecondaire extends ConsumerWidget {
  const _CoquilleSecondaire({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);

    final SessionState session = ref.watch(sessionProvider);
    final AppRole? effectif = session.role;

    // Sans role connu, il n'y a pas de chrome a rendre : l'ecran se suffit.
    if (effectif == null) {
      return child;
    }

    // L'admin n'a plus de coquille `NavShell` depuis le lot IA-01 : « Mon
    // compte » reste transverse aux huit domaines
    // (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`), donc aucun domaine n'y est actif.
    // Sans ce branchement, un admin qui ouvrait `/compte` retombait sur
    // `destinationsPour(role: AppRole.admin)`, videe par ce meme lot, et
    // perdait tout chrome -- exactement le defaut mesure le 18 septembre
    // 2026 sur ce meme ecran.
    if (effectif == AppRole.admin) {
      return AdminShell(
        domaines: domainesAdmin(voitDirection: session.peutVoirDirection),
        domaineActif: null,
        onAller: aller,
        onCompte: () => aller(Routes.compte),
        child: child,
      );
    }

    return NavShell(
      destinations: destinationsPour(
        role: effectif,
        // Seul l'eleve a deux formes de destinations (ADR-009) ; pour les
        // autres roles le mode ne change rien.
        mode: session.interfaceMode,
      ),
      indexActif: null,
      onAller: aller,
      secondaires: secondairesPour(role: effectif),
      onAllerSecondaire: aller,
      child: child,
    );
  }
}

class _CoquilleNavigation extends ConsumerWidget {
  /// Cree la coquille d'un role.
  const _CoquilleNavigation({
    required this.role,
    required this.navigationShell,
  });

  /// Le role dont cette coquille tient les destinations.
  final AppRole role;

  /// Les branches de la coquille, pilotées par `go_router`.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InterfaceMode mode = ref.watch(
      sessionProvider.select((SessionState s) => s.interfaceMode),
    );
    final List<Destination> destinations = destinationsPour(
      role: role,
      mode: mode,
    );

    return NavShell(
      destinations: destinations,
      indexActif: navigationShell.currentIndex,
      onAller: (String chemin) {
        final int index = destinations.indexWhere(
          (Destination d) => d.chemin == chemin,
        );
        if (index == -1) {
          return;
        }
        navigationShell.goBranch(
          index,
          // Retaper la destination courante la reprend a sa racine.
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      secondaires: secondairesPour(role: role),
      // Les entrees secondaires sont des routes de premier niveau **hors** de
      // la coquille : elles se rejoignent par `go`, jamais par `goBranch`, qui
      // ne connait que les branches.
      onAllerSecondaire: (String chemin) => GoRouter.of(context).go(chemin),
      child: navigationShell,
    );
  }
}

/// Le chrome du panneau admin, huit domaines (lot IA-01, 19 septembre 2026).
///
/// Remplace `_CoquilleNavigation`/`_CoquilleSecondaire` pour le role admin :
/// `AdminShell` ne partage pas la limite de quatre destinations de
/// `NavShell`, l'operateur a tranche que le panneau grandira avec un RBAC a
/// plusieurs roles (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`). Chaque route porte explicitement
/// son domaine, exactement comme `_CoquilleSecondaire` porte deja son role :
/// ni l'un ni l'autre ne devine depuis le chemin courant.
///
/// **Perd l'IndexedStack** que les quatre premiers ecrans avaient hier : huit
/// domaines ne se rangent plus dans quatre branches d'onglets, la plupart des
/// ecrans admin redemarrent donc leur etat a chaque navigation, comme le
/// faisaient deja `ADM-06`, `ADM-07` et `ADM-08` avant ce lot. C'est le prix
/// assume de la restructuration, pas un oubli.
class _CoquilleAdmin extends ConsumerWidget {
  const _CoquilleAdmin({required this.domaine, required this.child});

  /// Le domaine que revendique cette route.
  final AdminDomaine domaine;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);

    final bool voitDirection = ref.watch(
      sessionProvider.select((SessionState s) => s.peutVoirDirection),
    );

    return AdminShell(
      domaines: domainesAdmin(voitDirection: voitDirection),
      domaineActif: domaine,
      onAller: aller,
      onCompte: () => aller(Routes.compte),
      child: child,
    );
  }
}
