// Aujourd'hui du Comptable (FIN-CPT-W01, M01 ecran 1 ; spec §29, §12, §28,
// §11). Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT (CPT-JOUR) ensuite**, qui ecrit dans
// `lib/features/comptable/aujourdhui/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Repond a « Que dois-je faire maintenant ? » : neuf zones (§29), aucun
// graphique en surnombre (DR-09), aucun bouton Payer (DR-11) ; chaque ligne
// ouvre l'ecran canonique par sa route de `Routes` (§5.1). Lit
// `portAujourdhuiComptableProvider` (CPT-BR-03).

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Aujourd'hui du Comptable, dans la coquille du role (branche 0).
class AujourdhuiComptablePage extends StatelessWidget {
  /// Cree la page. [vue] vient de `?vue=` : `attention` ouvre la file
  /// complete « A traiter » et « Alertes » (le « Voir tout » de M01, meme
  /// route, DR-10).
  const AujourdhuiComptablePage({super.key, this.vue});

  /// La vue demandee par l'adresse, ou nulle pour l'ecran complet.
  final String? vue;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
