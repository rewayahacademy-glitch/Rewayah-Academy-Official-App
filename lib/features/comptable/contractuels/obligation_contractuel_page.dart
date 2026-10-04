// Detail d'une obligation de contractuel (FIN-CPT-W06 ; spec §22.3, §22.4).
// Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-CTR ensuite** (`20_comptable/02_DECOUPAGE.md`).
//
// « Karim Studio - Facture #024 - 350 USD » → « Payer 350 USD » : le montant
// ne se modifie pas apres approbation ; « Payer » navigue vers
// `Routes.comptablePaiementObligationPour(obligationPayableId)` (DR-12).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Le detail d'une obligation de contractuel, sous l'onglet « Contractuels ».
class ObligationContractuelPage extends StatelessWidget {
  /// Cree la page pour l'obligation [obligationId] (segment d'adresse).
  const ObligationContractuelPage({required this.obligationId, super.key});

  /// L'obligation.
  final String obligationId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.comptable.contractuels.detailTitre,
      onRetour: () => retourComptable(context, Routes.comptableContractuels),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
