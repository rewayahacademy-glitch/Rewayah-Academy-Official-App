import 'package:flutter/material.dart';

import '../finance/finances_profil.dart';
import '../finance/format_montant.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                t.argent.soldes.total,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              MontantArgent(synthese.totalSoldes, taille: TailleMontant.grand),
              Text(
                t.argent.soldes.totalDetail,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
        Ecart.vMd,
        LigneCleValeur(
          cle: t.argent.soldes.aPayer,
          valeur: formaterMontant(synthese.aPayerCeMois),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.argent.soldes.profilsFinances,
          valeur: t.argent.soldes.profilsFinancesValeur(
            n: synthese.profilsFinances,
            total: synthese.profils,
          ),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.argent.soldes.paiements,
          valeur: '${synthese.paiementsDuMois}',
          chiffres: true,
        ),
      ],
    );
  }
}
