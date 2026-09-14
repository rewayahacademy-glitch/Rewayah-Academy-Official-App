import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/_dev/galerie/galerie_page.dart';
import '../../features/accueil_eleve/accueil_eleve_page.dart';
import '../../features/accueil_famille/accueil_famille_page.dart';
import '../../features/admin_attribution/attribution_page.dart';
import '../../features/admin_demandes/demandes_page.dart';
import '../../features/admin_dossiers/dossiers_page.dart';
import '../../features/admin_journal/journal_page.dart';
import '../../features/admin_tableau/tableau_de_bord_page.dart';
import '../../features/appareils/ajouter_enfant_page.dart';
import '../../features/appareils/appairage_page.dart';
import '../../features/appareils/appareils_page.dart';
import '../../features/connexion/connexion_page.dart';
import '../../features/controleur/planning_page.dart';
import '../../features/coran/coran_page.dart';
import '../../features/creneaux/creneaux_page.dart';
import '../../features/disponibilites/disponibilites_page.dart';
import '../../features/dossier/attente_page.dart';
import '../../features/dossier/depot_piece_page.dart';
import '../../features/dossier/signature_page.dart';
import '../../features/eleve_connexion/eleve_connexion_page.dart';
import '../../features/inscription/inscription_page.dart';
import '../../features/journee/journee_page.dart';
import '../../features/profil_enseignant/profil_enseignant_page.dart';
import '../../features/reglages_enfant/reglages_enfant_page.dart';
import '../../features/salle/salle_page.dart';
import '../../features/suivi_foyer/suivi_foyer_page.dart';
import '../config/env.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
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
/// (`docs/architecture/etape-2-core-flutter.md` section 3).
///
/// `tool/verifier_jetons.dart` echoue si un second fichier du depot construit
/// un `GoRouter`.
final Provider<GoRouter> routeurProvider = Provider<GoRouter>((Ref ref) {
  final _RafraichisseurRoutage rafraichisseur = _RafraichisseurRoutage();

  ref.listen<SessionState>(sessionProvider, (SessionState? _, SessionState _) {
    rafraichisseur.declencher();
  });
  ref.onDispose(rafraichisseur.dispose);

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
                builder: (BuildContext _, GoRouterState _) =>
                    const CoranPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleveSuivi,
                builder: (BuildContext _, GoRouterState _) =>
                    EcranAConstruire(destination: t.nav.eleve.suivi),
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

      // Controleur : une seule destination, pas de barre de navigation.
      // `CTR-01` est sa racine et son seul ecran ; `CTR-02`, la salle, se
      // rejoint depuis une ligne en cours et vit hors de l'arbre (ADR-005).
      GoRoute(
        path: Routes.controleur,
        builder: (BuildContext _, GoRouterState _) =>
            const PlanningControleurPage(),
      ),

      // Admin. Quatre barres : les demandes (ADM-06) restent derriere leur
      // compteur, une cinquieme entree ferait une barre-menu.
      StatefulShellRoute.indexedStack(
        builder: (BuildContext _, GoRouterState _, StatefulNavigationShell n) =>
            _CoquilleNavigation(role: AppRole.admin, navigationShell: n),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.adminTableauDeBord,
                builder: (BuildContext _, GoRouterState _) =>
                    const TableauDeBordPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.adminDossiers,
                builder: (BuildContext _, GoRouterState _) =>
                    const DossiersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.adminAttribution,
                builder: (BuildContext _, GoRouterState _) =>
                    const AttributionPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.adminJournal,
                builder: (BuildContext _, GoRouterState _) =>
                    const JournalPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.adminDemandes,
        builder: (BuildContext _, GoRouterState _) => const DemandesPage(),
      ),

      // Comptable : le role existe, son interface arrive en V1 (ADR-003).
      GoRoute(
        path: Routes.comptable,
        builder: (BuildContext _, GoRouterState _) =>
            const EcranAConstruire(destination: 'Espace comptable'),
      ),

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

/// La coquille de navigation d'un role, autour des branches qui sont ses
/// destinations.
///
/// Le role est connu par construction de la route : chaque coquille est câblée
/// a un seul role. Le mode d'interface, lui, est lu dans la session : un eleve
/// en mode enfant obtient zero destination, `NavShell` rend alors l'ecran sans
/// le moindre chrome, sur les memes branches (ADR-009).
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
      child: navigationShell,
    );
  }
}
