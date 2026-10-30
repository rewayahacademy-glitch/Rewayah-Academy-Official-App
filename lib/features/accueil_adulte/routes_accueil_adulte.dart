// Les routes reelles de l'Accueil de l'eleve adulte (DASH-EA-PROD).
//
// **Cette fonction ne construit jamais un `GoRouter`** : elle en rend les
// routes, que `app_router.dart` pose dans la branche Accueil de la coquille
// eleve (la destination « Accueil » reste allumee).
//
// L'eleve adulte est un compte eleve : `/eleve` s'ouvre sur l'Accueil adulte
// quand la capacite [capaciteAccueilAdulteProvider] est servie
// ([redirectionAccueilEleve]), jamais d'apres le role. Avant BR-1, aucune
// source serveur (EA-BR-04) : la capacite reste fausse, `/eleve` ne change
// pas, et `/eleve/adulte` demandee par adresse dit « indisponible » sans rien
// inventer (D10).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../foyer/nos_prix_page.dart';
import '../mon_espace_adulte/mes_finances_page.dart';
import '../suivi_famille/suivi_famille_page.dart';
import '../tc_catalogue/routes_tc_b.dart' show RoutesTcB;
import '../tc_mes_groupes/routes_tc_a.dart' show preparerSalleEleve;
import 'accueil_adulte_page.dart';
import 'historique_seances_adulte_page.dart';

/// Ou mene `/eleve` : l'Accueil adulte quand la capacite est servie, sinon
/// rien (l'accueil de l'eleve reste). Fonction pure.
String? redirectionAccueilEleve({required bool capaciteAccueilAdulte}) =>
    capaciteAccueilAdulte ? Routes.eleveAdulte : null;

/// Ou mene une adresse de ses finances (`/eleve/finances`, lot F1) : nulle
/// part ailleurs pour le compte « eleve autonome » (C-24, EA-ROLE-1), a
/// l'accueil de l'eleve pour tout autre compte. La capacite decide, jamais le
/// role : un compte eleve sans elle (un enfant) n'y entre pas. Fonction pure.
String? redirectionFinancesAdulte({required bool eleveAutonome}) =>
    eleveAutonome ? null : Routes.eleve;

/// Les routes : l'Accueil adulte, l'historique de ses seances, le suivi de
/// ses demandes et ses finances.
///
/// La cloche n'est pas ici : depuis le lot B2 (29/10/2026), la coquille de
/// l'eleve la pose sur toutes les pages de l'eleve adulte et elle mene a
/// `Routes.eleveNotifications`.
List<GoRoute> routesAccueilAdulte() => <GoRoute>[
  GoRoute(
    path: Routes.eleveAdulte,
    builder: (BuildContext contexte, GoRouterState _) => AccueilAdultePage(
      onRejoindre: (GroupSummaryVM groupe) =>
          preparerSalleEleve(contexte, groupe),
      onVoirRessources: (String groupeId) =>
          GoRouter.of(contexte).go(RoutesTcB.avecGroupe(groupeId)),
      onVoirDernieresSeances: () =>
          GoRouter.of(contexte).go(Routes.eleveAdulteSeances),
      onMesFinances: () => GoRouter.of(contexte).go(Routes.eleveFinances),
    ),
  ),
  GoRoute(
    path: Routes.eleveAdulteSeances,
    builder: (BuildContext contexte, GoRouterState _) =>
        HistoriqueSeancesAdultePage(
          onRetour: () => GoRouter.of(contexte).go(Routes.eleveAdulte),
        ),
  ),
  // BACK-FRONT-SUIVI-1 : l'eleve adulte autonome suit lui-meme ses demandes.
  GoRoute(
    path: Routes.eleveAdulteDemandes,
    builder: (BuildContext _, GoRouterState _) =>
        const SuiviFamillePage(chemins: CheminsSuivi.adulte),
  ),
  GoRoute(
    path: '${Routes.eleveAdulteDemandes}/:demandeId',
    builder: (BuildContext _, GoRouterState etat) => FriseDemandePage(
      demandeId: etat.pathParameters['demandeId'] ?? '',
      chemins: CheminsSuivi.adulte,
    ),
  ),
  // Lot F1 : ses finances, dans la branche Accueil (la destination reste
  // allumee). La page d'arrivee porte le nom de la carte tapee (EA-4c) ; sans
  // source serveur (FI-BR-17), elle dit que rien n'est encore publie.
  GoRoute(
    path: Routes.eleveFinances,
    redirect: (BuildContext contexte, GoRouterState _) =>
        redirectionFinancesAdulte(
          eleveAutonome: ProviderScope.containerOf(
            contexte,
            listen: false,
          ).read(sessionProvider).eleveAutonome,
        ),
    builder: (BuildContext contexte, GoRouterState _) => MesFinancesPage(
      onRetour: () => GoRouter.of(contexte).go(Routes.eleveAdulte),
      // LE moteur de recharge du foyer, son seul profil coche (guide, section 4) :
      // jamais un second centre de paiement.
      onRecharger: (String profilId) =>
          GoRouter.of(contexte).go(Routes.rechargePour(<String>[profilId])),
      onMouvements: () =>
          GoRouter.of(contexte).go(Routes.eleveFinancesMouvements),
      onNosPrix: () => GoRouter.of(contexte).go(Routes.eleveFinancesPrix),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: 'mouvements',
        builder: (BuildContext contexte, GoRouterState _) => MesMouvementsPage(
          onRetour: () => GoRouter.of(contexte).go(Routes.eleveFinances),
        ),
      ),
      GoRoute(
        path: 'prix',
        builder: (BuildContext contexte, GoRouterState _) => NosPrixPage(
          onRetour: () => GoRouter.of(contexte).go(Routes.eleveFinances),
        ),
      ),
    ],
  ),
];
