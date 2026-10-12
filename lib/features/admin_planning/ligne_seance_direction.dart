/// Une ligne de seance de la direction : la classe, ce qui la situe dans le
/// temps et chez qui, et son etat en pastille. Partagee par le planning et
/// les incidents (DASH-ADM-PLANNING, DASH-ADM-INC).
library;

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart' show StatutSeance;
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import 'planning_libelles.dart';

/// La ligne d'une seance, sans appui : un rapport, jamais un bouton grise.
class LigneSeanceDirection extends StatelessWidget {
  /// Cree la ligne. [detail] tient en deux lignes au plus (horaire, puis
  /// enseignant) ; [mot] est le mot du statut.
  const LigneSeanceDirection({
    required this.classe,
    required this.detail,
    required this.statut,
    required this.mot,
    super.key,
  });

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
    return SettingRow(
      title: classe,
      description: detail,
      controle: pastille != null
          ? PastilleEtatSeance(etat: pastille)
          : StatusPill(libelle: mot, ton: _ton()),
    );
  }
}
