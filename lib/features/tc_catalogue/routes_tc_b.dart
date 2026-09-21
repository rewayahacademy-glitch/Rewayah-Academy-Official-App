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

  /// Le nom du parametre de REQUETE qui porte le groupe de contexte.
  ///
  /// Une requete, et non un segment de chemin : [ressource] occupe deja le
  /// segment suivant, et un second segment entrerait en collision avec elle.
  static const String parametreGroupe = 'groupe';

  /// Le chemin de la fiche d'une ressource donnee.
  static String versRessource(String resourceId) =>
      '$bibliotheque/$resourceId';

  /// L'adresse de la Bibliotheque vue depuis l'Espace d'un groupe.
  ///
  /// Ecrite ici pour que l'adresse ne soit jamais composee a la main ailleurs.
  /// Elle passe par [Uri] plutot que par une concatenation : l'encodage du
  /// parametre est alors celui de la bibliotheque standard.
  ///
  /// L'adresse est partageable et survit a un rechargement de page sur le Web,
  /// ce qu'aucune autre forme de passage ne fait. Elle n'ouvre rien de plus a
  /// celui qui la recoit : `ressources_du_groupe` (migration `0033`) refuse
  /// l'appelant qui n'est ni membre, ni tuteur du foyer, ni enseignant, ni
  /// admin du groupe demande.
  static String avecGroupe(String groupeId) => Uri(
    path: bibliotheque,
    queryParameters: <String, String>{parametreGroupe: groupeId},
  ).toString();
}

/// Les routes de la Bibliotheque.
///
/// Le groupe de contexte vient d'abord de l'adresse, par le parametre de
/// requete `?groupe=` (voir [RoutesTcB.avecGroupe]) : c'est la seule forme qui
/// survive a un rechargement de page sur le Web. [groupeId] reste le repli
/// quand l'adresse n'en porte pas, et garde la symetrie avec `routesTcA`.
///
/// Dans les deux cas c'est la meme Bibliotheque : seule la section
/// « Pour ce groupe » change.
List<RouteBase> routesTcB({String? groupeId}) => <RouteBase>[
  GoRoute(
    path: RoutesTcB.bibliotheque,
    builder: (BuildContext context, GoRouterState state) =>
        BibliothequePage(groupeId: _groupeDe(state) ?? groupeId),
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

/// Le groupe porte par l'adresse, ou `null` quand elle n'en porte pas.
///
/// Une valeur vide ou blanche vaut absence : une adresse tapee a moitie
/// (`?groupe=`) doit ouvrir la Bibliotheque generale, jamais demander au
/// serveur les ressources d'un groupe dont l'identifiant est la chaine vide.
String? _groupeDe(GoRouterState etat) {
  final String? brut = etat.uri.queryParameters[RoutesTcB.parametreGroupe];
  final String? propre = brut?.trim();
  return (propre == null || propre.isEmpty) ? null : propre;
}
