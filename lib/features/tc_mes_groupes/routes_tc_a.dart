import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
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
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md` :
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
        // « Rejoindre » des cartes ouvre la salle comme celui de l'Espace
        // Groupe (BOUTONS-GRISES-1) : non branche, il etait rendu inerte.
        builder: (BuildContext contexte, GoRouterState _) => MesGroupesPage(
          onRejoindre: (GroupSummaryVM groupe) =>
              preparerSalleEleve(contexte, groupe),
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
                    preparerSalleEleve(contexte, groupe),
              );
            },
          ),
        ],
      ),
    ];

/// « Rejoindre » ouvre la salle canonique `/salle` avec sa preparation, pour
/// tout role (eleve, enseignant, adulte) : la preparation est celle de la
/// seance du groupe, et `/salle` la montre selon le role de la session.
/// Aucune nouvelle route : le billet passe par `extra`, jamais par l'URL
/// (ADR-005). Aussi le « Rejoindre » de l'Accueil adulte (DASH-EA-PROD).
/// Le nom est reste (usage dans `routes_accueil_adulte.dart`).
void preparerSalleEleve(BuildContext contexte, GroupSummaryVM groupe) {
  final String? sessionId = groupe.prochaineSeance?.sessionId;
  if (sessionId == null) {
    return;
  }
  GoRouter.of(contexte).go(
    Routes.salle,
    extra: BilletSalle(
      sessionId: sessionId,
      emisA: DateTime.now(),
      preparation: true,
      groupeId: groupe.groupeId,
    ),
  );
}
