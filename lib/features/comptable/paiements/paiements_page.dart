// Paiements a effectuer (FIN-CPT-W02, M01 ecran 2 ; spec §13, §14, §15, §30).
// Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-PAY ensuite**, qui ecrit dans
// `lib/features/comptable/paiements/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Montant en lecture seule, jamais un champ de saisie (R-FIN-16) ;
// consolidation par beneficiaire, la Classe reste un filtre (§14.4, 14.5) ;
// « Payer » visible seulement si l'obligation le permet (capacite rendue par
// la source). Lit `portObligationsPayablesProvider` (CPT-BR-01).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// La liste des paiements a effectuer, onglet « A effectuer » de Paiements.
class PaiementsAEffectuerPage extends StatelessWidget {
  /// Cree la page. Les trois filtres viennent de l'adresse, bruts
  /// (`?filtre=prets|infos|verification|validation|retard`,
  /// `?type=enseignant|contractuel`, `?classe=`) : les liens d'Aujourd'hui
  /// ouvrent la liste deja filtree (§5.1).
  const PaiementsAEffectuerPage({
    super.key,
    this.filtre,
    this.type,
    this.classe,
  });

  /// Le filtre d'etat, brut.
  final String? filtre;

  /// Le type de beneficiaire, brut.
  final String? type;

  /// La Classe, brute.
  final String? classe;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.paiements;
    return PageShell(
      titre: p.titre,
      sousTitre: p.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPaiementsComptable(),
        indexActif: 0,
      ),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
