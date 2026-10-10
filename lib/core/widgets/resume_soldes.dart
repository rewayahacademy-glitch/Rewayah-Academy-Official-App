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
  const ResumeSoldes({
    required this.synthese,
    super.key,
    this.action,
    this.note,
  });

  /// La synthese rendue par la source.
  final SyntheseFoyer synthese;

  /// L'action de la synthese (« Recharger plusieurs profils », FI-5) : le
  /// 4e bloc de la rangee, a la place des paiements du mois, que l'appelant
  /// pose alors ailleurs ; sous les lignes sur telephone. `null` : le 4e bloc
  /// reste « Paiements du mois ».
  final Widget? action;

  /// La note sous [action] dans le 4e bloc (maquette 05) ; jamais sur
  /// telephone, ou la phrase sous le total suffit.
  final String? note;

  /// La largeur d'un indicateur pose en ligne, a texte 100 % : sous quatre
  /// fois cette largeur (fois l'echelle du texte), la synthese s'empile.
  static const double largeurIndicateur = 150;

  /// Sous six fois [largeurIndicateur] (900 a texte 100 %), les quatre
  /// blocs passent sur deux rangees de deux (revue FI-VAGUE-R, R1-04).
  static const int indicateursRangeeUnique = 6;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleCle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle styleNote = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Widget total = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t.argent.soldes.total, style: styleCle),
          MontantArgent(synthese.totalSoldes, taille: TailleMontant.grand),
          Text(t.argent.soldes.totalDetail, style: styleNote),
        ],
      ),
    );
    final String profilsFinances = t.argent.soldes.profilsFinancesValeur(
      n: synthese.profilsFinances,
      total: synthese.profils,
    );
    final Widget? actionPosee = action;
    final String? notePosee = note;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double echelle = MediaQuery.textScalerOf(context).scale(1);
        final double unite = largeurIndicateur * (echelle < 1 ? 1 : echelle);
        // FI-5 (guide §5.1 « Desktop : resume horizontal », maquette 05) :
        // quand la place le permet, les quatre blocs cote a cote ; a la
        // tablette, deux rangees de deux ; jamais le telephone etire.
        if (c.maxWidth >= unite * 4) {
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
          final Widget aPayer = indicateur(
            t.argent.soldes.aPayer,
            MontantArgent(synthese.aPayerCeMois, taille: TailleMontant.titre),
          );
          final Widget profils = indicateur(
            t.argent.soldes.profilsFinances,
            Text(profilsFinances, style: styleValeur),
          );
          final Widget quatrieme = actionPosee == null
              ? indicateur(
                  t.argent.soldes.paiements,
                  Text('${synthese.paiementsDuMois}', style: styleValeur),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    actionPosee,
                    if (notePosee != null) ...<Widget>[
                      Ecart.vSm,
                      Text(notePosee, style: styleNote),
                    ],
                  ],
                );
          Widget rangee(List<Widget> blocs) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < blocs.length; i++) ...<Widget>[
                if (i > 0) Ecart.hLg,
                Expanded(child: blocs[i]),
              ],
            ],
          );
          if (c.maxWidth >= unite * indicateursRangeeUnique) {
            return rangee(<Widget>[total, aPayer, profils, quatrieme]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              rangee(<Widget>[total, aPayer]),
              Ecart.vLg,
              rangee(<Widget>[profils, quatrieme]),
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
              valeurEnFin: true,
            ),
            LigneCleValeur(
              cle: t.argent.soldes.profilsFinances,
              valeur: profilsFinances,
              chiffres: true,
              valeurEnFin: true,
            ),
            LigneCleValeur(
              cle: t.argent.soldes.paiements,
              valeur: '${synthese.paiementsDuMois}',
              chiffres: true,
              valeurEnFin: true,
            ),
            if (actionPosee != null) ...<Widget>[Ecart.vLg, actionPosee],
          ],
        );
      },
    );
  }
}
