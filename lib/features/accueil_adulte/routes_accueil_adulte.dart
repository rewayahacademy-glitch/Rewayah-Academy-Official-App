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
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../tc_catalogue/routes_tc_b.dart' show RoutesTcB;
import '../tc_mes_groupes/routes_tc_a.dart' show preparerSalleEleve;
import 'accueil_adulte_page.dart';
import 'historique_seances_adulte_page.dart';

/// Ou mene `/eleve` : l'Accueil adulte quand la capacite est servie, sinon
/// rien (l'accueil de l'eleve reste). Fonction pure.
String? redirectionAccueilEleve({required bool capaciteAccueilAdulte}) =>
    capaciteAccueilAdulte ? Routes.eleveAdulte : null;

/// Les deux routes : l'Accueil adulte et l'historique de ses seances.
///
/// Pas de cloche : l'eleve n'a pas encore de centre de notifications reel
/// (EA-8) ; une cloche sans destination serait inerte (D9).
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
    ),
  ),
  GoRoute(
    path: Routes.eleveAdulteSeances,
    builder: (BuildContext contexte, GoRouterState _) =>
        HistoriqueSeancesAdultePage(
          onRetour: () => GoRouter.of(contexte).go(Routes.eleveAdulte),
        ),
  ),
];
