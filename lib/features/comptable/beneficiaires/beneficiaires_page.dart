// Beneficiaires vus par le Comptable (FIN-CPT-W07, liste ; spec §16, §27.2,
// §35). Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-BEN ensuite**, qui ecrit dans
// `lib/features/comptable/beneficiaires/**` et `lib/features/paiements_recus/**`
// (`20_comptable/02_DECOUPAGE.md`).
//
// Coordonnees masquees (« Orange Money •••• 4423 »), aucun « Modifier
// coordonnees » (R-FIN-11, 12). Relancer passe par
// `portRelancePaiementProvider` (CPT-BR-11), aucune messagerie Finance
// (R-FIN-21). Lit `portBeneficiairesPaiementProvider` (CPT-BR-06).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// La liste des beneficiaires, onglet « Beneficiaires » de Paiements.
class BeneficiairesPage extends StatelessWidget {
  /// Cree la page. [filtre] vient de `?filtre=` (`infos` pour les
  /// informations manquantes, depuis Aujourd'hui), brut.
  const BeneficiairesPage({super.key, this.filtre});

  /// Le filtre, brut.
  final String? filtre;

  @override
  Widget build(BuildContext context) {
    final b = t.comptable.beneficiaires;
    return PageShell(
      titre: b.titre,
      sousTitre: b.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPaiementsComptable(),
        indexActif: 2,
      ),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
