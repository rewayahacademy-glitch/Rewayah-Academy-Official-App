// Les routes du lot N2 (foyer et eleve adulte, 03/11/2026). Le routeur
// unique (`lib/core/router/app_router.dart`) ne recoit qu'une ligne
// d'inclusion par endroit (G8) :
//   - `routesN2Apprendre()` dans la branche Apprendre de la coquille eleve :
//     Ma classe de l'eleve adulte (E1), la barre allume Apprendre ;
//   - `routesN2Foyer()` sous `/tuteur/foyer` : l'invitation recue (FA2),
//     inviter un second adulte (FA1), la reprise du foyer, cote second adulte
//     et cote titulaire (FA3).
// **Cette fonction ne construit jamais un `GoRouter`.**

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../ma_classe_adulte/ma_classe_adulte_page.dart';
import '../tc_catalogue/routes_tc_b.dart' show RoutesTcB;
import '../tc_mes_groupes/routes_tc_a.dart' show preparerSalleEleve;
import 'invitation_conjoint.dart';
import 'role_foyer.dart';

/// Les adresses du lot N2.
abstract final class RoutesN2 {
  /// Ma classe de l'eleve adulte (E1).
  static const String eleveAdulteClasse = '/eleve/adulte/classe';

  /// L'invitation recue par le second adulte (FA2).
  static const String foyerInvitation = '${Routes.tuteurFoyer}/invitation';

  /// Inviter un second adulte (FA1).
  static const String foyerInviter = '${Routes.tuteurFoyer}/inviter';

  /// La demande de reprise, cote second adulte (FA3).
  static const String foyerReprise = '${Routes.tuteurFoyer}/reprise';

  /// La demande de reprise, cote titulaire (FA3).
  static const String foyerRepriseTitulaire =
      '${Routes.tuteurFoyer}/reprise/titulaire';
}

/// E1 : Ma classe, dans la branche Apprendre.
List<GoRoute> routesN2Apprendre() => <GoRoute>[
  GoRoute(
    path: RoutesN2.eleveAdulteClasse,
    builder: (BuildContext contexte, GoRouterState _) => MaClasseAdultePage(
      onRejoindre: (GroupSummaryVM groupe) =>
          preparerSalleEleve(contexte, groupe),
      onVoirRessources: (String groupeId) =>
          GoRouter.of(contexte).go(RoutesTcB.avecGroupe(groupeId)),
    ),
  ),
];

/// FA1 a FA3 : les sous-routes du Foyer (chemins relatifs a `/tuteur/foyer`).
List<GoRoute> routesN2Foyer() => <GoRoute>[
  GoRoute(
    path: 'invitation',
    builder: (BuildContext contexte, GoRouterState _) {
      void foyer() => GoRouter.of(contexte).go(Routes.tuteurFoyer);
      return InvitationRecuePage(
        onRetour: foyer,
        onMonEspace: (EtatInvitationRecue _) => foyer(),
        onRetourApresReponse: (EtatInvitationRecue _) => foyer(),
      );
    },
  ),
  GoRoute(
    path: 'inviter',
    builder: (BuildContext _, GoRouterState _) => const _InviterDepuisFoyer(),
  ),
  GoRoute(
    path: 'reprise',
    builder: (BuildContext contexte, GoRouterState _) => RepriseFoyerPage(
      onRetour: () => GoRouter.of(contexte).go(Routes.tuteurFoyer),
      // L'etat se relit sur la page meme : la demande deposee s'y lit.
      onDeposee: () {},
    ),
    routes: <GoRoute>[
      GoRoute(
        path: 'titulaire',
        builder: (BuildContext contexte, GoRouterState _) =>
            RepriseTitulairePage(
              onRetour: () => GoRouter.of(contexte).go(Routes.tuteurFoyer),
              // Le refus se relit sur la page meme.
              onRefusee: () {},
            ),
      ),
    ],
  ),
];

/// « Inviter un second adulte » depuis le Foyer : la place offerte suit le
/// genre enregistre du titulaire (`mon_role_foyer()`), forme neutre sinon.
class _InviterDepuisFoyer extends ConsumerWidget {
  const _InviterDepuisFoyer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoleFoyerLu? lu = ref.watch(roleFoyerProvider).value;
    void foyer() => GoRouter.of(context).go(Routes.tuteurFoyer);
    return InviterConjointPage(
      placeFeminine: lu?.placeFeminine,
      depuisFoyer: true,
      onAbandon: foyer,
      onTerminee: foyer,
    );
  }
}
