import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/status_pill.dart';

/// Vrai quand cet eleve doit recevoir l'indicateur discret.
///
/// **Lui seul.** La specification 11.3 est explicite : « les autres eleves
/// n'ont pas besoin d'etre interrompus ». Une classe de cinq enfants ou tout le
/// monde apprend qu'un parent regarde transformerait une visite de deux minutes
/// en evenement collectif.
///
/// Fonction pure, testable sans arbre de widgets.
bool enfantConcerneParObservation(
  List<AnnonceObservation> annonces,
  String? monProfilId,
) {
  if (monProfilId == null) {
    return false;
  }
  for (final AnnonceObservation annonce in annonces) {
    if (annonce.enfantConcerneId == monProfilId) {
      return true;
    }
  }
  return false;
}

/// L'annonce lue par l'enseignant pendant qu'un tuteur observe.
///
/// **Discrete par construction.** Une ligne, un temps restant, et rien quand
/// personne n'observe : ni bandeau qui pousse le contenu, ni son, ni fenetre.
/// Et **aucune notification de sortie** -- le flux cesse simplement de porter
/// l'annonce.
///
/// L'enseignant n'apprend jamais **quel** tuteur observe : voir
/// `t.tc.observation.annonce.tuteurObserve`.
class IndicateurObservation extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurObservation({required this.annonces, super.key});

  /// Les observations en cours. Vide = rien ne s'affiche.
  final List<AnnonceObservation> annonces;

  @override
  Widget build(BuildContext context) {
    if (annonces.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AnnonceObservation annonce in annonces)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                  child: Icon(AppIcons.foyer.repos),
                ),
                Ecart.hSm,
                Expanded(
                  child: Text(
                    annonce.libelle,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
                if (annonce.tempsRestant case final Duration restant) ...<Widget>[
                  Ecart.hSm,
                  StatusPill(
                    libelle: t.tc.observation.annonce.restant(
                      secondes: restant.inSeconds,
                    ),
                    ton: TonEtat.neutre,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// L'indicateur discret, du cote de l'enfant observe.
///
/// Un mot, sans action et sans bouton. Un enfant de sept ans n'a rien a decider
/// ici : il a seulement le droit de savoir.
class IndicateurObservationEnfant extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurObservationEnfant({required this.visible, super.key});

  /// Vrai quand le tuteur de cet enfant observe.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconTheme(
          data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
          child: Icon(AppIcons.foyer.repos),
        ),
        Ecart.hSm,
        Flexible(
          child: Text(
            t.tc.observation.annonce.enfantIndicateur,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
