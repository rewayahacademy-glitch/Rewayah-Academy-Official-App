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
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_B.md`.
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
  static String versRessource(String resourceId) => '$bibliotheque/$resourceId';

  /// L'adresse de la Bibliotheque vue depuis l'Espace d'un groupe.
  ///
  /// Ecrite ici pour que l'adresse ne soit jamais composee a la main ailleurs.
  /// Elle passe par [Uri] plutot que par une concatenation : l'encodage du
  /// parametre est alors celui de la bibliotheque standard.
  ///
  /// L'adresse est partageable et survit a un rechargement de page sur le Web,
  /// ce qu'aucune autre forme de passage ne fait.
  ///
  /// Ce qu'elle n'ouvre pas, et rien de plus : un NON-MEMBRE n'obtient rien.
  /// `ressources_du_groupe` (migration `0033`) refuse l'appelant qui n'est ni
  /// membre, ni tuteur du foyer, ni enseignant, ni admin du groupe demande.
  ///
  /// Elle ne garantit PAS la visibilite ressource par ressource pour celui qui
  /// passe cette porte. Cette fonction est `security definer`, aucune migration
  /// du depot ne pose `force row level security` : elle s'execute en
  /// proprietaire et contourne donc la RLS de `library_resource`. Son corps ne
  /// filtre que l'appartenance au groupe, jamais `access_policy`, jamais
  /// `app_account_valid()` -- la ou la policy `library_resource_lecture`
  /// (migration `0032`) exige les deux et n'ouvre `enseignant_seul` qu'au
  /// `teacher_id` du groupe. Une migration de correction est ecrite dans un lot
  /// voisin ; tant qu'elle n'est pas appliquee, l'ecart reste ouvert.
  static String avecGroupe(String groupeId) => Uri(
    path: bibliotheque,
    queryParameters: <String, String>{parametreGroupe: groupeId},
  ).toString();
}

/// Les routes de la Bibliotheque.
///
/// Le groupe de contexte vient de l'adresse, par le parametre de requete
/// `?groupe=` (voir [RoutesTcB.avecGroupe]) : c'est la seule forme qui survive
/// a un rechargement de page sur le Web, et elle suffit. Aucun parametre de
/// construction ne la double : il ne serait appele par personne.
///
/// Avec groupe ou sans, c'est la meme Bibliotheque : seule la section
/// « Pour ce groupe » change.
List<RouteBase> routesTcB() => <RouteBase>[
  GoRoute(
    path: RoutesTcB.bibliotheque,
    builder: (BuildContext context, GoRouterState state) =>
        BibliothequePage(groupeId: _groupeDe(state)),
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
