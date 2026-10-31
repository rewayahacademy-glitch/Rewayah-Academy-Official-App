/// Une ligne de seance de la direction : la classe, ce qui la situe dans le
/// temps et chez qui, et son etat en pastille. Partagee par le planning et
/// les incidents (DASH-ADM-PLANNING, DASH-ADM-INC).
library;

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart' show StatutSeance;
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import 'planning_libelles.dart';

/// La ligne d'une seance : un rapport, jamais un bouton grise. Quand le
/// serveur permet un geste sur la seance (designer un remplacant), il passe
/// par [actions], dans le menu de la ligne (LISTES-1, `MenuActions`).
class LigneSeanceDirection extends StatelessWidget {
  /// Cree la ligne. [detail] tient en trois lignes au plus (horaire,
  /// enseignant, remplacement) ; [mot] est le mot du statut.
  const LigneSeanceDirection({
    required this.classe,
    required this.detail,
    required this.statut,
    required this.mot,
    this.actions = const <EntreeAction>[],
    super.key,
  });

  /// Les gestes possibles sur la seance ; vide : aucun menu.
  final List<EntreeAction> actions;

  /// Le nom de la classe, distinct parmi les classes paralleles (R16).
  final String classe;

  /// Quand et avec qui.
  final String detail;

  /// Le statut de la seance.
  final StatutSeance statut;

  /// Le mot du statut, jamais la couleur seule.
  final String mot;

  TonEtat _ton() => switch (statut) {
    StatutSeance.terminee || StatutSeance.enCours => TonEtat.succes,
    StatutSeance.incidentTechnique ||
    StatutSeance.enseignantAbsent ||
    StatutSeance.eleveAbsent => TonEtat.alerte,
    _ => TonEtat.neutre,
  };

  @override
  Widget build(BuildContext context) {
    final EtatPastilleSeance? pastille = pastilleDe(statut);
    final Widget etat = pastille != null
        ? PastilleEtatSeance(etat: pastille)
        : StatusPill(libelle: mot, ton: _ton());
    return SettingRow(
      title: classe,
      description: detail,
      controle: actions.isEmpty
          ? etat
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: <Widget>[
                etat,
                MenuActions(points: true, objet: classe, actions: actions),
              ],
            ),
    );
  }
}
