import 'package:flutter/material.dart';

import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pastille_etat_seance.dart';

/// Une ligne « cle : valeur » de fiche de detail : « Horaire : 18:00 (heure
/// de Paris) », « Presence : En cours de verification » (detail de seance et
/// detail d'observation, manifeste visuel Tuteur V1 section 3.4).
///
/// La cle se lit en encre attenuee, la valeur en encre forte. Cote a cote
/// quand la place le permet, **empilees des que le texte est agrandi**
/// (`AppGabarit.seuilTexteColonne`) : a 200 %, deux colonnes coupent les
/// mots, une pile ne coupe rien.
///
/// Le lecteur d'ecran lit la cle puis la valeur, en un seul noeud
/// (`MergeSemantics`) : une valeur lue seule, « 18:00 », ne dit rien.
class LigneCleValeur extends StatelessWidget {
  /// Cree une ligne.
  const LigneCleValeur({
    required this.cle,
    required this.valeur,
    super.key,
    this.complement,
    this.chiffres = false,
    this.annulee = false,
  });

  /// Ce que la valeur designe : « Horaire », « Duree », « Presence ».
  final String cle;

  /// La valeur, deja mise en mots par le service ou l'ecran.
  final String valeur;

  /// Un element pose apres la valeur : une pastille d'etat, par exemple.
  final Widget? complement;

  /// Vrai pour une valeur faite de chiffres (horaire, duree, code) : chiffres
  /// tabulaires, qui ne dansent pas d'une ligne a l'autre.
  final bool chiffres;

  /// Vrai quand la valeur est l'horaire d'une seance annulee : barree et
  /// attenuee, annoncee « Annulee : ... » (ANNUL-VIS-1).
  final bool annulee;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleValeur = palette.inkStrong.applyTo(
      chiffres
          ? AppTypography.tabulaire(textes.bodyLarge ?? const TextStyle())
          : textes.bodyLarge ?? const TextStyle(),
    );
    final Text texteCle = Text(
      cle,
      style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
    );
    final Widget blocValeur = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (annulee)
          TexteHeureSeance(heure: valeur, annulee: true, style: styleValeur)
        else
          Text(valeur, style: styleValeur),
        ?complement,
      ],
    );
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: empiler
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[texteCle, Ecart.vXs, blocValeur],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 2, child: texteCle),
                  Ecart.hLg,
                  Expanded(flex: 3, child: blocValeur),
                ],
              ),
      ),
    );
  }
}
