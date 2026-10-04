import 'package:flutter/material.dart';

import '../finance/finances_profil.dart';
import '../finance/format_montant.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ligne_cle_valeur.dart';
import 'montant_argent.dart';

/// La synthese financiere d'un foyer (`BalanceSummary`, guide Finance V4
/// §5.1 ; FI-3b) : le total des soldes **en lecture**, ce qui reste a
/// financer ce mois, les profils finances, les paiements du mois.
///
/// Le total n'est jamais un solde commun (guide §5.3) : la phrase sous le
/// chiffre le dit. Tout vient de la source ([SyntheseFoyer]) : ce widget
/// n'additionne rien (FI6).
class ResumeSoldes extends StatelessWidget {
  /// Cree la synthese.
  const ResumeSoldes({required this.synthese, super.key});

  /// La synthese rendue par la source.
  final SyntheseFoyer synthese;

  /// La largeur d'un indicateur pose en ligne, a texte 100 % : sous quatre
  /// fois cette largeur (fois l'echelle du texte), la synthese s'empile.
  static const double largeurIndicateur = 150;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleCle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final Widget total = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t.argent.soldes.total, style: styleCle),
          MontantArgent(synthese.totalSoldes, taille: TailleMontant.grand),
          Text(
            t.argent.soldes.totalDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
    final String profilsFinances = t.argent.soldes.profilsFinancesValeur(
      n: synthese.profilsFinances,
      total: synthese.profils,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double echelle = MediaQuery.textScalerOf(context).scale(1);
        // FI-5 (guide §5.1 « Desktop : resume horizontal », maquette 05) :
        // quand la place le permet, les quatre indicateurs cote a cote,
        // jamais le telephone etire.
        if (c.maxWidth >= largeurIndicateur * 4 * (echelle < 1 ? 1 : echelle)) {
          Widget indicateur(String cle, Widget valeur) => MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(cle, style: styleCle),
                valeur,
              ],
            ),
          );
          final TextStyle styleValeur = palette.inkStrong.applyTo(
            AppTypography.tabulaire(textes.titleLarge ?? const TextStyle()),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 2, child: total),
              Ecart.hLg,
              Expanded(
                child: indicateur(
                  t.argent.soldes.aPayer,
                  MontantArgent(
                    synthese.aPayerCeMois,
                    taille: TailleMontant.titre,
                  ),
                ),
              ),
              Ecart.hLg,
              Expanded(
                child: indicateur(
                  t.argent.soldes.profilsFinances,
                  Text(profilsFinances, style: styleValeur),
                ),
              ),
              Ecart.hLg,
              Expanded(
                child: indicateur(
                  t.argent.soldes.paiements,
                  Text('${synthese.paiementsDuMois}', style: styleValeur),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            total,
            Ecart.vMd,
            LigneCleValeur(
              cle: t.argent.soldes.aPayer,
              valeur: formaterMontant(synthese.aPayerCeMois),
              chiffres: true,
            ),
            LigneCleValeur(
              cle: t.argent.soldes.profilsFinances,
              valeur: profilsFinances,
              chiffres: true,
            ),
            LigneCleValeur(
              cle: t.argent.soldes.paiements,
              valeur: '${synthese.paiementsDuMois}',
              chiffres: true,
            ),
          ],
        );
      },
    );
  }
}
