// Contractuels et obligations (FIN-CPT-W06 ; spec §22, §23, §34). Posee « en
// preparation » par CPT-F avec son constructeur definitif ; **propriete de la
// voie CPT-CTR ensuite**, qui ecrit dans
// `lib/features/comptable/contractuels/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Onglets internes Obligations / A approuver / A payer / Historique ; le
// montant manuel n'existe qu'a la creation, fige apres approbation ;
// « Nouvelle obligation » seulement pour la capacite `creerObligation` ;
// « Payer » ouvre le W03 de l'obligation payable, aucun composant de paiement
// ici (DR-12). Lit `portObligationsContractuelsProvider` (CPT-BR-08).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// Les obligations de contractuels, onglet « Contractuels » de Paiements.
class ContractuelsPage extends StatelessWidget {
  /// Cree la page. [onglet] est l'onglet interne demande par l'adresse
  /// (`?onglet=`), brut.
  const ContractuelsPage({super.key, this.onglet});

  /// L'onglet interne, brut.
  final String? onglet;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    return PageShell(
      titre: c.titre,
      sousTitre: c.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPaiementsComptable(),
        indexActif: 1,
      ),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
