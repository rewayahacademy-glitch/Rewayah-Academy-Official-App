import 'package:go_router/go_router.dart';

import '../../core/tc_groupe/group_home_vm.dart';
import '../tc_espace_groupe/espace_groupe_page.dart';
import '../tc_espace_groupe/roster_enseignant_slot.dart';
import 'chemins_tc_a.dart';
import 'mes_groupes_page.dart';

/// Les routes d'Agent A.
///
/// **Cette fonction ne construit jamais un `GoRouter`.** Elle en **retourne**
/// les routes. `tool/verifier_jetons.dart` fait echouer la CI si un second
/// fichier de `lib/` construit un routeur, et `app_router.dart` est protege :
/// c'est Agent Z qui appelle cette fonction depuis lui, promeut les constantes
/// de [CheminsTcA] dans `routes.dart` et ajuste `redirection.dart`.
///
/// Trois points a traiter a l'integration, detailles en section 7 de
/// `docs/teaching-core/TC_CONTRACT_REQUEST_A.md` :
///
/// 1. `redirection.dart` renvoie toute route hors prefixe de role vers la
///    racine du role : sans ajustement, `/tc/groupes` est **inatteignable** ;
/// 2. une route sans entree de navigation n'existe pas, et `nav_shell.dart` est
///    plafonne a quatre destinations par assertion, les quatre de l'enseignant
///    etant deja prises. Ajouter « Mes groupes » est un **arbitrage produit** ;
/// 3. [role] est ici une valeur par defaut. Agent Z la derive de la session
///    applicative, ou un widget lit une capacite et non un role brut.
List<RouteBase> routesTcA({RoleEspaceGroupe role = RoleEspaceGroupe.eleve}) =>
    <RouteBase>[
      GoRoute(
        path: CheminsTcA.mesGroupes,
        builder: (_, _) => const MesGroupesPage(),
        routes: <RouteBase>[
          GoRoute(
            path: CheminsTcA.segmentEspaceGroupe,
            builder: (_, GoRouterState etat) {
              final String groupeId =
                  etat.pathParameters[CheminsTcA.parametreGroupe] ?? '';
              return EspaceGroupePage(
                groupeId: groupeId,
                role: role,
                contenuRoster: RosterEnseignantSlot(groupeId: groupeId),
              );
            },
          ),
        ],
      ),
    ];
