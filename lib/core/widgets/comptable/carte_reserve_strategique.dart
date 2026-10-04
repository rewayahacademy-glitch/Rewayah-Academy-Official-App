import 'package:flutter/material.dart';

import '../../comptable/modeles_comptable.dart';
import '../../finance/montant.dart';
import '../../i18n/strings.g.dart';
import '../../icons/app_icons.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../app_card.dart';
import '../montant_argent.dart';
import '../montant_sensible.dart';
import '../pastilles_comptable.dart';
import 'ligne_activite.dart' show dateComptable;

/// La Reserve strategique en lecture (`StrategicReserveCard`, spec §9 ;
/// CPT-F) : **le titre est toujours « Reserve strategique »** (§9.1,
/// R-FIN-05), l'objectif est redige selon le mode (montant fixe : « Objectif :
/// montant fixe » et le montant ; couverture : « Objectif actuel : N mois de
/// charges essentielles », R-FIN-06, 07), puis la seule jauge de la vague
/// (progression du theme, DR-09) avec son pourcentage ecrit, le montant
/// actuel, le manque, les dates d'allocation et le statut en pastille.
///
/// Aucune plage commerciale codee : 10 USD et 1 000 000 USD rendent pareil
/// (R-FIN-08, 09). Tous les montants sont masquables.
///
/// Posee par CPT-F pour W01 (zone 2) et W04 ; **propriete de CPT-TRES-1
/// ensuite** (`20_comptable/02_DECOUPAGE.md`), CPT-JOUR l'importe seulement.
class CarteReserveStrategique extends StatelessWidget {
  /// Cree la carte.
  const CarteReserveStrategique(this.indicateurs, {super.key, this.onOuvrir});

  /// Les indicateurs §9.7, rendus par la source.
  final IndicateursReserve indicateurs;

  /// Ouvre la Tresorerie (W04) depuis Aujourd'hui ; nul en W04 meme.
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle cle = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final c = t.comptable.commun;
    final IndicateursReserve i = indicateurs;
    final int? mois = i.nombreMois;
    final double fraction = (i.atteintPourMille / 1000).clamp(0, 1).toDouble();
    final DateTime? derniere = i.derniereAllocation;
    final DateTime? prochaine = i.prochaineAllocation;
    return AppCard(
      onPress: onOuvrir,
      libelleSemantique: onOuvrir == null ? null : c.reserveStrategique,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTheme(
                data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
                child: Icon(AppIcons.reserve.repos),
              ),
              Ecart.hMd,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    c.reserveStrategique,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
              Ecart.hSm,
              PastilleEtatReserve(i.etat),
            ],
          ),
          Ecart.vMd,
          if (i.mode == ModeObjectifReserve.couvertureMois && mois != null)
            Text(c.objectifMois(n: mois), style: corps)
          else
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(c.objectifFixe, style: corps),
                MontantSensible(i.objectif),
              ],
            ),
          Ecart.vMd,
          Semantics(
            label: c.atteint(pourcent: i.atteintPourMille ~/ 10),
            excludeSemantics: true,
            child: LinearProgressIndicator(value: fraction),
          ),
          Ecart.vXs,
          Text(c.atteint(pourcent: i.atteintPourMille ~/ 10), style: cle),
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              _Valeur(libelle: c.montantActuel, montant: i.actuel),
              _Valeur(libelle: c.manque, montant: i.manque),
            ],
          ),
          Ecart.vMd,
          Text(
            derniere == null
                ? c.aucuneAllocation
                : c.derniereAllocation(date: dateComptable(derniere)),
            style: cle,
          ),
          if (prochaine != null) ...<Widget>[
            Ecart.vXs,
            Text(
              c.prochaineAllocation(date: dateComptable(prochaine)),
              style: cle,
            ),
          ],
        ],
      ),
    );
  }
}

class _Valeur extends StatelessWidget {
  const _Valeur({required this.libelle, required this.montant});

  final String libelle;
  final Montant montant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            libelle,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          MontantSensible(montant, taille: TailleMontant.titre),
        ],
      ),
    );
  }
}
