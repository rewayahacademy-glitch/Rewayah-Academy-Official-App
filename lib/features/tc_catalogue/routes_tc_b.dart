import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'bibliotheque_page.dart';
import 'detail_ressource_page.dart';

/// Les chemins de la Bibliotheque, sous le prefixe reserve `/tc/`.
///
/// **Aucun `GoRouter` n'est construit ici.** `tool/verifier_jetons.dart` fait
/// echouer la CI des qu'un second fichier de `lib/` en construit un : le
/// produit n'a qu'un routeur, `lib/core/router/app_router.dart`, et il est
/// PROTECTED. Ce fichier **rend des routes**, Agent Z les monte
/// (decision D-04).
///
/// **Une route ne suffit pas.** `redirection.dart` renvoie toute route hors du
/// prefixe de role vers la racine du role : sans ajustement, ces deux routes
/// seront inatteignables. Et une route sans entree de navigation n'existe pas,
/// or `nav_shell.dart` est plafonne a quatre destinations par assertion. Les
/// deux points sont formules dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
abstract final class RoutesTcB {
  /// La Bibliotheque.
  static const String bibliotheque = '/tc/bibliotheque';

  /// La fiche d'une ressource.
  static const String ressource = '/tc/bibliotheque/:resourceId';

  /// Le nom du parametre de chemin de [ressource].
  static const String parametreRessource = 'resourceId';

  /// Le chemin de la fiche d'une ressource donnee.
  static String versRessource(String resourceId) =>
      '$bibliotheque/$resourceId';
}

/// Les routes de la Bibliotheque.
///
/// [groupeId] permet a Agent Z de monter la meme page depuis l'Espace Groupe :
/// c'est la meme Bibliotheque, avec une section « Pour ce groupe » remplie.
List<RouteBase> routesTcB({String? groupeId}) => <RouteBase>[
  GoRoute(
    path: RoutesTcB.bibliotheque,
    builder: (BuildContext context, GoRouterState state) =>
        BibliothequePage(groupeId: groupeId),
    routes: <RouteBase>[
      GoRoute(
        path: ':${RoutesTcB.parametreRessource}',
        builder: (BuildContext context, GoRouterState state) =>
            DetailRessourcePage(
              resourceId:
                  state.pathParameters[RoutesTcB.parametreRessource] ?? '',
            ),
      ),
    ],
  ),
];
