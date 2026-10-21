import 'package:flutter/material.dart';

import '../../comptable/modeles_comptable.dart';
import '../../finance/montant.dart';
import '../../i18n/strings.g.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../app_card.dart';
import '../montant_argent.dart';
import '../montant_sensible.dart';

/// La synthese de tresorerie (`AvailableTreasurySummary`, spec §11 ; CPT-F) :
/// **la Tresorerie libre est le chiffre central**, en grand ; la tresorerie
/// detenue, les fonds proteges et le transit en dessous, plus petits. Le
/// solde brut n'est jamais presente comme de l'argent depensable ; aucun
/// « Disponible » ni « Reservee » (DR-07). Tous les montants sont masquables.
///
/// Posee par CPT-F pour W01 (zone 1) et W04 ; **propriete de CPT-TRES-1
/// ensuite** (`20_comptable/02_DECOUPAGE.md`), CPT-JOUR l'importe seulement.
class ResumeTresorerie extends StatelessWidget {
  /// Cree la synthese.
  const ResumeTresorerie(this.synthese, {super.key});

  /// Les quatre montants, rendus par la source.
  final SyntheseTresorerie synthese;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle cle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final c = t.comptable.commun;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(header: true, child: Text(c.tresorerieLibre, style: cle)),
          Ecart.vXs,
          MontantSensible(synthese.libre, taille: TailleMontant.grand),
          Ecart.vXs,
          Text(
            c.tresorerieLibreDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              _Chiffre(libelle: c.tresorerieDetenue, montant: synthese.detenue),
              _Chiffre(libelle: c.fondsProteges, montant: synthese.protegee),
              _Chiffre(libelle: c.enTransit, montant: synthese.enTransit),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({required this.libelle, required this.montant});

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
