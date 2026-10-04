// Encaissements (FIN-CPT-W05, M02 ecran 2 ; spec §24, §33). Posee « en
// preparation » par CPT-F avec son constructeur definitif ; **propriete de la
// voie CPT-ENC ensuite**, qui ecrit dans
// `lib/features/comptable/encaissements/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Etats §24.1 ; « Confirme » seulement sur retour du port (§24.3) ; panneau
// detail a 1440 (brut, frais, net, reference, prestataire, foyer,
// affectation, rapprochement), page sous 1200. Lit
// `portEncaissementsProvider` (CPT-BR-07, 15).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';

/// La liste des encaissements, onglet « Encaissements » de Tresorerie.
class EncaissementsPage extends StatelessWidget {
  /// Cree la page. [filtre] vient de `?filtre=`, brut.
  const EncaissementsPage({super.key, this.filtre});

  /// Le filtre d'etat, brut.
  final String? filtre;

  @override
  Widget build(BuildContext context) {
    final e = t.comptable.encaissements;
    return PageShell(
      titre: e.titre,
      sousTitre: e.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
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
