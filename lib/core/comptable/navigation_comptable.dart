// La navigation de second niveau du Comptable (CPT-F) : les onglets DANS la
// page des destinations Paiements et Tresorerie
// (`20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` §3). Meme patron que
// `ongletsFinance()` de la direction, consomme par `SousNavigationDomaine`
// dans `PageShell.entete`.
//
// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../router/routes.dart';

/// Les trois onglets de la destination Paiements, dans l'ordre d'affichage :
/// A effectuer (W02), Contractuels (W06), Beneficiaires (W07).
List<({String libelle, String chemin})> ongletsPaiementsComptable() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.comptable.onglets.aEffectuer,
        chemin: Routes.comptablePaiements,
      ),
      (
        libelle: t.comptable.onglets.contractuels,
        chemin: Routes.comptableContractuels,
      ),
      (
        libelle: t.comptable.onglets.beneficiaires,
        chemin: Routes.comptableBeneficiaires,
      ),
    ];

/// Les trois onglets de la destination Tresorerie : Coffres (W04),
/// Encaissements (W05), Rapprochement.
List<({String libelle, String chemin})> ongletsTresorerieComptable() =>
    <({String libelle, String chemin})>[
      (
        libelle: t.comptable.onglets.coffres,
        chemin: Routes.comptableTresorerie,
      ),
      (
        libelle: t.comptable.onglets.encaissements,
        chemin: Routes.comptableEncaissements,
      ),
      (
        libelle: t.comptable.onglets.rapprochement,
        chemin: Routes.comptableRapprochement,
      ),
    ];

/// L'index de l'onglet Paiements actif pour [chemin] : A effectuer pour la
/// liste et le detail d'une obligation, Contractuels et Beneficiaires pour
/// leurs pages et leurs details.
int indexOngletPaiements(String chemin) {
  if (chemin == Routes.comptableContractuels ||
      chemin.startsWith('${Routes.comptableContractuels}/')) {
    return 1;
  }
  if (chemin == Routes.comptableBeneficiaires ||
      chemin.startsWith('${Routes.comptableBeneficiaires}/')) {
    return 2;
  }
  return 0;
}

/// L'index de l'onglet Tresorerie actif pour [chemin].
int indexOngletTresorerie(String chemin) {
  if (chemin == Routes.comptableEncaissements ||
      chemin.startsWith('${Routes.comptableEncaissements}/')) {
    return 1;
  }
  if (chemin == Routes.comptableRapprochement) {
    return 2;
  }
  return 0;
}

/// Le retour d'une page de niveau 2 du Comptable : la page du dessous quand
/// la pile en a une, sinon [parent] (adresse tapee directement, ou arrivee
/// par un lien d'Aujourd'hui).
void retourComptable(BuildContext context, String parent) {
  final GoRouter routeur = GoRouter.of(context);
  if (routeur.canPop()) {
    routeur.pop();
  } else {
    routeur.go(parent);
  }
}
