// « Nouvelle obligation » (FIN-CPT-W06 ; spec §22.3 ; K-57). Posee « en
// preparation » par CPT-F avec son constructeur definitif ; **propriete de la
// voie CPT-CTR ensuite** (`20_comptable/02_DECOUPAGE.md`).
//
// Une tache focalisee (`Routes.estTacheFocaliseeComptable`) : sans barre
// basse sur telephone, sans actions de coquille. Formulaire semi-automatique
// (K-57) : beneficiaire, devise, echeance et centre de cout preremplis ou
// choisis ; seuls l'objet et le montant se saisissent, parce qu'une facture
// externe n'est connue que de celui qui la recoit. Atteinte seulement si la
// capacite `creerObligation` est rendue. Ecrit par
// `portObligationsContractuelsProvider.creer` (CPT-BR-08).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Le formulaire d'une nouvelle obligation ponctuelle.
class NouvelleObligationPage extends StatelessWidget {
  /// Cree la page.
  const NouvelleObligationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.comptable.contractuels.nouvelle,
      onRetour: () => retourComptable(context, Routes.comptableContractuels),
      actionsCoquille: false,
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
