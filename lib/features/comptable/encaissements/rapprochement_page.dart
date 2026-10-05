// Rapprochement et remboursements (`ReconciliationWorkspace` ; spec §25,
// §26, §48). Posee « en preparation » par CPT-F avec son constructeur
// definitif ; **propriete de la voie CPT-ENC**, qui ecrit dans
// `lib/features/comptable/encaissements/rapprochement/**`
// (`20_comptable/02_DECOUPAGE.md`).
//
// Etats : automatique, a verifier, rapproche, conflit, sans correspondance,
// doublon potentiel. Journal par operation (§48) sans inventer d'audit. Lit
// `portRapprochementProvider` (CPT-BR-14) et les remboursements de
// `portEncaissementsProvider` (CPT-BR-15) ; sans source
// (`CapaciteIndisponible`), la page reste « en preparation ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_rapprochement.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import 'commun_encaissements.dart';
import 'rapprochement/donnees_rapprochement.dart';
import 'rapprochement/espace_rapprochement.dart';

/// L'espace de rapprochement, onglet « Rapprochement » de Tresorerie.
class RapprochementPage extends ConsumerWidget {
  /// Cree la page.
  const RapprochementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = t.comptable.encaissements;
    final AsyncValue<List<ElementRapprochement>> valeur = ref.watch(
      elementsRapprochementProvider,
    );
    final bool sansSource =
        valeur.hasError && valeur.error is CapaciteIndisponible;
    return PageShell(
      titre: e.rapprochementTitre,
      sousTitre: e.rapprochementSousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
        indexActif: 2,
      ),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: sansSource
          ? const EnPreparationComptable()
          : BlocEncaissements<List<ElementRapprochement>>(
              valeur: valeur,
              onReessayer: () => ref.invalidate(elementsRapprochementProvider),
              // L'espace dit lui-meme « rien a rapprocher » et garde
              // l'acces aux remboursements.
              estVide: (List<ElementRapprochement> _) => false,
              construire: (List<ElementRapprochement> elements) =>
                  ReconciliationWorkspace(
                    elements: elements,
                    panneau: composeEnPanneau(context),
                  ),
            ),
    );
  }
}
