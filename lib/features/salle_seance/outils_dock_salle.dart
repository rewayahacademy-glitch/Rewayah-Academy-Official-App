// « Ouvrir les outils d'enseignement » (EN-10) : le Teaching Dock de
// `tc_dock` raccorde a la salle `/salle`, sans seconde salle.
//
// La salle est l'hote du dock ([HoteDockSalle]). Elle ne fournit ni support
// presente ni capacites avant BR-1 (jeton serveur, K-28) : le dock ne rend
// donc que les outils qui peuvent aboutir (la Bibliotheque, qui ouvre le
// selecteur de ressources). Les outils de la salle (Pointeur, Marquer,
// Masquer, Annoter) sont rendus au-dessus, s'ils ont un rappel.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../tc_dock/teaching_dock.dart';
import 'actions_seance.dart';
import 'outils_enseignement.dart';

/// La salle, hote du Teaching Dock.
class HoteDockSalle implements PortDockHote {
  /// Cree l'hote ; [ouvrir] ouvre le selecteur de ressources de la salle.
  const HoteDockSalle({required this.ouvrir});

  /// Ouvre le selecteur de ressources (la salle reste ouverte).
  final Future<void> Function() ouvrir;

  @override
  ContexteDock contexte() => const ContexteDock();

  @override
  SupportPresente? supportActif() => null;

  @override
  SelectionSupport? selectionCourante() => null;

  @override
  CapacitesPedagogiques? capacites() => null;

  @override
  Future<void> ouvrirBibliotheque() => ouvrir();
}

/// Ouvre les outils d'enseignement : feuille sur mobile, dialogue sur bureau
/// (`AppBottomSheet`). La salle reste ouverte dessous.
Future<void> ouvrirOutilsEnseignement(
  BuildContext context, {
  required ActionsSeance actions,
}) {
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: t.salle.seance.outils.titre,
    constructeur: (BuildContext contexte) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (actions.onOutil != null) ...<Widget>[
          OutilsEnseignement(
            onOutil: actions.onOutil,
            forme: FormeOutils.rangee,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Center(
          child: TeachingDock(
            hote: HoteDockSalle(
              ouvrir: () async {
                Navigator.of(contexte).pop();
                actions.onBibliotheque?.call();
              },
            ),
          ),
        ),
      ],
    ),
  );
}
