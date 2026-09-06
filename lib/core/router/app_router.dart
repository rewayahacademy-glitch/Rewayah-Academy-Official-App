import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/_dev/galerie/galerie_page.dart';
import '../../features/admin_dossiers/dossiers_page.dart';
import '../../features/appareils/ajouter_enfant_page.dart';
import '../../features/appareils/appairage_page.dart';
import '../../features/appareils/appareils_page.dart';
import '../../features/connexion/connexion_page.dart';
import '../../features/creneaux/creneaux_page.dart';
import '../../features/disponibilites/disponibilites_page.dart';
import '../../features/dossier/attente_page.dart';
import '../../features/dossier/depot_piece_page.dart';
import '../../features/dossier/signature_page.dart';
import '../../features/eleve_connexion/eleve_connexion_page.dart';
import '../../features/inscription/inscription_page.dart';
import '../config/env.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
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

  ref.listen<SessionState>(sessionProvider, (
    SessionState? _,
    SessionState _,
  ) {
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
      // que chaque ecran AFFICHE qui change, jamais la structure.
      GoRoute(
        path: Routes.eleve,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.eleve.accueil),
        routes: <RouteBase>[
          GoRoute(
            path: 'coran',
            builder: (BuildContext _, GoRouterState _) =>
                EcranAConstruire(destination: t.nav.eleve.coran),
          ),
          GoRoute(
            path: 'suivi',
            builder: (BuildContext _, GoRouterState _) =>
                EcranAConstruire(destination: t.nav.eleve.suivi),
          ),
        ],
      ),

      // Tuteur.
      GoRoute(
        path: Routes.tuteurFoyer,
        builder: (BuildContext _, GoRouterState _) => const AppareilsPage(),
      ),
      GoRoute(
        path: Routes.tuteurAjouterEnfant,
        builder: (BuildContext _, GoRouterState _) =>
            const AjouterEnfantPage(),
      ),
      GoRoute(
        path: '${Routes.tuteurAppairer}/:eleveId',
        builder: (BuildContext _, GoRouterState etat) =>
            AppairagePage(eleveId: etat.pathParameters['eleveId'] ?? ''),
      ),
      GoRoute(
        path: Routes.tuteurDisponibilites,
        builder: (BuildContext _, GoRouterState _) =>
            const DisponibilitesPage(),
      ),
      GoRoute(
        path: Routes.tuteurReglages,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.tuteur.reglages),
      ),
      GoRoute(
        path: Routes.tuteurSuivi,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.tuteur.suivi),
      ),

      // Enseignant.
      GoRoute(
        path: Routes.enseignantJournee,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.enseignant.journee),
      ),
      GoRoute(
        path: Routes.enseignantCreneaux,
        builder: (BuildContext _, GoRouterState _) => const CreneauxPage(),
      ),
      GoRoute(
        path: Routes.enseignantProfil,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.enseignant.profil),
      ),

      // Controleur : une seule destination, pas de barre de navigation.
      GoRoute(
        path: Routes.controleur,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.controleur.planning),
      ),

      // Admin.
      GoRoute(
        path: Routes.adminTableauDeBord,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.admin.tableauDeBord),
      ),
      GoRoute(
        path: Routes.adminDossiers,
        builder: (BuildContext _, GoRouterState _) => const DossiersPage(),
      ),
      GoRoute(
        path: Routes.adminAttribution,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.admin.attribution),
      ),
      GoRoute(
        path: Routes.adminJournal,
        builder: (BuildContext _, GoRouterState _) =>
            EcranAConstruire(destination: t.nav.admin.journal),
      ),

      // Comptable : le role existe, son interface arrive en V1 (ADR-003).
      GoRoute(
        path: Routes.comptable,
        builder: (BuildContext _, GoRouterState _) =>
            const EcranAConstruire(destination: 'Espace comptable'),
      ),

      // Salle. Le billet passe par `extra`, jamais par l'URL (ADR-005).
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState _) =>
            const EcranAConstruire(destination: 'ELV-03 / ENS-03'),
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
