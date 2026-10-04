// Detail beneficiaire / paiement (FIN-CPT-W03, M01 ecran 3 ; spec §13.3,
// §31, §40). Posee « en preparation » par CPT-F avec son constructeur
// definitif ; **propriete de la voie CPT-PAY ensuite**
// (`20_comptable/02_DECOUPAGE.md`).
//
// Lignes de calcul avec leur source ; « Signaler un ecart » sans champ de
// correction (R-FIN-17) ; encart permanent §31 ; un seul bouton plein
// « Payer maintenant », absent quand le beneficiaire est la personne
// connectee (R-FIN-15). La confirmation montre toujours le montant exact
// (R-FIN-04). Lit `portObligationsPayablesProvider` et `portPayoutProvider`.

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Le detail d'une obligation payable, sous l'onglet « A effectuer ».
class DetailPaiementPage extends StatelessWidget {
  /// Cree la page pour l'obligation [obligationId] (segment d'adresse).
  const DetailPaiementPage({required this.obligationId, super.key});

  /// L'obligation.
  final String obligationId;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.paiements;
    return PageShell(
      titre: p.detailTitre,
      sousTitre: p.detailSousTitre,
      onRetour: () => retourComptable(context, Routes.comptablePaiements),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
