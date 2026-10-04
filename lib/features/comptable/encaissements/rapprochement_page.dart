// Rapprochement et remboursements (`ReconciliationWorkspace` ; spec §25,
// §26, §48). Posee « en preparation » par CPT-F avec son constructeur
// definitif ; **propriete de la voie CPT-ENC ensuite**, qui ecrit dans
// `lib/features/comptable/encaissements/rapprochement/**`
// (`20_comptable/02_DECOUPAGE.md`).
//
// Etats : automatique, a verifier, rapproche, conflit, sans correspondance,
// doublon potentiel. Journal par operation (§48) sans inventer d'audit. Lit
// `portRapprochementProvider` (CPT-BR-14) et les remboursements de
// `portEncaissementsProvider` (CPT-BR-15).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// L'espace de rapprochement, onglet « Rapprochement » de Tresorerie.
class RapprochementPage extends StatelessWidget {
  /// Cree la page.
  const RapprochementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final e = t.comptable.encaissements;
    return PageShell(
      titre: e.rapprochementTitre,
      sousTitre: e.rapprochementSousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
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
