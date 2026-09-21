import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../tc_classe_live/classe_live_page.dart';
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
        // Le tuteur ajoute la photo d'un membre depuis ses reglages ; un eleve
        // sur son appareil ne le peut pas, et la porte le lui dit.
        builder: (BuildContext contexte, _) => MesGroupesPage(
          onAjouterPhoto: role == RoleEspaceGroupe.tuteur
              ? () => GoRouter.of(contexte).go(Routes.tuteurReglages)
              : null,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: CheminsTcA.segmentEspaceGroupe,
            builder: (BuildContext contexte, GoRouterState etat) {
              final String groupeId =
                  etat.pathParameters[CheminsTcA.parametreGroupe] ?? '';
              return EspaceGroupePage(
                groupeId: groupeId,
                role: role,
                contenuRoster: RosterEnseignantSlot(groupeId: groupeId),
                onRejoindre: (GroupSummaryVM groupe) =>
                    _rejoindre(contexte, groupe),
              );
            },
          ),
        ],
      ),
    ];

/// Ouvre la Classe Live du groupe, avec son contexte.
///
/// **Silencieux sans seance materialisee.** Le bouton « Rejoindre » de
/// `CarteSession` ne se rend deja que fenetre ouverte -- horloge, jamais
/// l'ecran -- donc `prochaineSeance?.sessionId` est nul seulement si
/// l'occurrence n'a pas ete materialisee cote serveur : `ContexteClasseLive`
/// exige un `sessionId`, on ne navigue pas plutot que d'en inventer un.
void _rejoindre(BuildContext contexte, GroupSummaryVM groupe) {
  final String? sessionId = groupe.prochaineSeance?.sessionId;
  if (sessionId == null) {
    return;
  }
  GoRouter.of(contexte).go(
    Routes.tcClasse,
    extra: ContexteClasseLive(
      sessionId: sessionId,
      groupeId: groupe.groupeId,
      libelleGroupe: groupe.libelle,
      enseignant: EnseignantDeClasse(
        nomAffichage: groupe.enseignant.nomAffichage,
        titre: groupe.enseignant.titre,
        photoCleOuUrl: groupe.enseignant.photoUrlOuCle,
      ),
      horloge: groupe.horloge,
      seuilMax: groupe.seuilMax,
    ),
  );
}
