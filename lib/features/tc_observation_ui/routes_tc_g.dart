import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'entree_observation_page.dart';

/// Les chemins du domaine Observation, sous le prefixe reserve `/tc/`.
///
/// **Des constantes, pas un routeur.** `lib/core/router/routes.dart` et
/// `app_router.dart` sont proteges, et `tool/verifier_jetons.dart` fait echouer
/// la CI si un second fichier de `lib/` construit un `GoRouter`. Agent Z
/// promeut ces constantes dans `routes.dart` a l'integration.
abstract final class RoutesTcG {
  /// Le nom du parametre de chemin, pour que l'appelant et la route ne
  /// divergent pas sur une chaine.
  static const String parametreSeance = 'seanceId';

  /// La porte d'observation d'une seance.
  static const String observation = '/tc/observation/:$parametreSeance';

  /// Le chemin concret d'une seance.
  static String versObservation(String seanceId) => '/tc/observation/$seanceId';
}

/// Les routes du domaine Observation.
///
/// **Cette fonction RETOURNE des routes, elle ne construit pas de routeur.**
/// Agent Z l'appelle depuis `app_router.dart` et ajuste `redirection.dart` :
/// sans cet ajustement, toute route hors prefixe de role est redirigee vers la
/// racine du role, et l'ecran serait inatteignable.
///
/// Attention : une route sans entree de navigation n'existe pas.
/// `nav_shell.dart` est
/// protege et plafonne a quatre destinations par assertion : l'entree du tuteur
/// se greffe donc sur `accueil_famille_page.dart`, qui porte deja `_assister`,
/// et celle du controle qualite sur `planning_page.dart` (CTR-01). Les deux
/// demandes sont dans `TC_CONTRACT_REQUEST_G.md`.
List<RouteBase> routesTcG() => <RouteBase>[
  GoRoute(
    path: RoutesTcG.observation,
    builder: (BuildContext context, GoRouterState etat) =>
        EntreeObservationPage(
          seanceId: etat.pathParameters[RoutesTcG.parametreSeance] ?? '',
        ),
  ),
];
