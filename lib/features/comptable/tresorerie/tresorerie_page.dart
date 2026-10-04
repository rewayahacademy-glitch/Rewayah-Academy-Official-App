// Tresorerie et coffres (FIN-CPT-W04, M02 ecran 1 ; spec §8, §9, §10, §11,
// §32). Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-TRES ensuite**, qui ecrit dans
// `lib/features/comptable/tresorerie/**`, `resume_tresorerie.dart` et
// `carte_reserve_strategique.dart` (`20_comptable/02_DECOUPAGE.md`).
//
// Titre toujours « Reserve strategique » (R-FIN-05) ; objectif en mois ou
// montant fixe (R-FIN-06, 07) ; aucune valeur commerciale codee (R-FIN-08,
// 09) ; retrait sans capacite bloque (R-FIN-10) ; prevision en lignes datees
// (DR-09). Lit `portTresorerieProvider` (CPT-BR-04, 05) et
// `portPolitiqueReserveProvider` (CPT-BR-12, lecture).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// La tresorerie et ses sept coffres, onglet « Coffres » de Tresorerie.
class TresoreriePage extends StatelessWidget {
  /// Cree la page. [action] vient de `?action=` : `alimenter` ouvre
  /// « Alimenter la Reserve strategique » a l'arrivee (depuis Aujourd'hui).
  const TresoreriePage({super.key, this.action});

  /// L'action demandee par l'adresse, brute.
  final String? action;

  @override
  Widget build(BuildContext context) {
    final tr = t.comptable.tresorerie;
    return PageShell(
      titre: tr.titre,
      sousTitre: tr.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
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
