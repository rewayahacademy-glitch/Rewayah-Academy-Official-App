import 'package:flutter/material.dart';

import '../admin/service_programme.dart';
import '../theme/app_spacing.dart';
import 'filter_pill.dart';

/// Les niveaux d'une version du programme, groupes par cycle.
///
/// **Le nom humain seul se montre**, jamais le code technique -- interdiction
/// UX explicite de la mission qui a ouvert le domaine Pedagogie. Partage par
/// les trois ecrans qui proposent un niveau reel : Diagnostics (`ADM-10`),
/// Progression (`ADM-11`) et Evaluations (`ADM-12`).
class SelecteurNiveauProgramme extends StatelessWidget {
  /// Cree le selecteur.
  const SelecteurNiveauProgramme({
    required this.niveaux,
    required this.selectionne,
    required this.onSelectionner,
    super.key,
  });

  /// Les niveaux proposes, dans l'ordre rendu par `programme_niveaux_admin()`.
  final List<NiveauProgramme> niveaux;

  /// L'identifiant du niveau retenu, nul si aucun.
  final String? selectionne;

  /// Appele au choix d'un niveau.
  final void Function(String niveauId) onSelectionner;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<NiveauProgramme>> parCycle =
        <String, List<NiveauProgramme>>{};
    for (final NiveauProgramme n in niveaux) {
      parCycle.putIfAbsent(n.cycle, () => <NiveauProgramme>[]).add(n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final MapEntry<String, List<NiveauProgramme>> entree
            in parCycle.entries) ...<Widget>[
          Text(entree.key, style: Theme.of(context).textTheme.bodySmall),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final NiveauProgramme n in entree.value)
                FilterPill(
                  libelle: n.nomHumain,
                  retenue: n.id == selectionne,
                  onPress: () => onSelectionner(n.id),
                ),
            ],
          ),
          Ecart.vMd,
        ],
      ],
    );
  }
}
