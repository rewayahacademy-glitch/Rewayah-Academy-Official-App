// Delta Direction (spec §37, §9.2 a §9.6, §21) : l'onglet « Reserve et
// delegation » du domaine Finance de la direction, troisieme onglet de
// `FinancePage` (`OngletFinance.reserveDelegation`). Pose « en preparation »
// par CPT-F avec son constructeur definitif ; **propriete de la voie CPT-DIR
// ensuite**, qui ecrit dans `lib/features/admin_finance/reserve_delegation/**`
// (`StrategicReservePolicyPanel`, `FinanceDelegationPolicyPanel`) et ici
// (`20_comptable/02_DECOUPAGE.md`). `finance_page.dart`,
// `politiques_commerciales.dart` et `vue_globale_finance.dart` restent geles.
//
// Rendu DANS le `PageShell` de `FinancePage` (comme `VueGlobaleFinanceBloc`),
// jamais une seconde page : pas de second systeme Finance Direction. Modes
// de reserve : montant fixe, couverture en mois ; alimentation : desactivee,
// fixe, pourcentage, jusqu'a l'objectif, proposee ; cadences §9.4 ;
// delegation §21.2. Aucun plafond commercial code (R-FIN-08, 09). Lit et
// ecrit `portPolitiqueReserveProvider` (CPT-BR-12) et
// `portDelegationFinanceProvider` (CPT-BR-13).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/empty_state.dart';

/// Le corps de l'onglet « Reserve et delegation ».
class ReserveDelegationPage extends StatelessWidget {
  /// Cree le corps.
  const ReserveDelegationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: t.comptable.commun.enPreparationTitre,
      invitation: t.comptable.commun.enPreparationPhrase,
    );
  }
}
