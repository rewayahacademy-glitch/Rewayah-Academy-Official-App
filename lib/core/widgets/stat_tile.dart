import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'status_pill.dart';

/// Un chiffre et son libelle, dans une carte qui mene a son ecran d'action.
///
/// Trois regles, et elles se tiennent (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md`) :
///
/// 1. **Le zero s'affiche comme les autres valeurs**, jamais masque. Un
///    compteur qui disparait a zero fait douter s'il a ete charge ou s'il est
///    reellement nul. C'est deja l'invariant I9 d'`ADM-01`, generalise ici ;
/// 2. **les chiffres sont tabulaires**. Sans `tnum`, un compteur qui passe de
///    17 a 18 fait bouger toute la ligne ;
/// 3. **un signal mene directement a son ecran d'action**, jamais a un menu.
///    Une tuile sans [onPress] est un rapport, pas un tableau de bord : elle
///    reste permise, mais elle se justifie.
class StatTile extends StatelessWidget {
  /// Cree une tuile de statistique.
  const StatTile({
    required this.valeur,
    required this.libelle,
    super.key,
    this.onPress,
    this.ton = TonEtat.neutre,
  });

  /// Le nombre affiche. Zero compris.
  final int valeur;

  /// Ce que le nombre compte, en deux ou trois mots.
  final String libelle;

  /// L'ecran d'action ou mene le chiffre.
  final VoidCallback? onPress;

  /// La famille semantique du compteur.
  ///
  /// **Le ton ne se lit pas sur la valeur** : c'est l'ecran qui sait si dix
  /// dossiers en attente sont normaux ou anormaux, pas la tuile. Un compteur
  /// qui virerait au rouge tout seul mentirait le jour ou le seuil change.
  final TonEtat ton;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = _paire(palette);

    return AppCard(
      surface: paire,
      onPress: onPress,
      // Le libelle lu tient le chiffre ET ce qu'il compte : « 17 » seul ne dit
      // rien a qui ne voit pas la tuile.
      libelleSemantique: '$valeur $libelle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$valeur',
            style: AppTypography.tabulaire(
              paire.applyTo(textes.displaySmall ?? const TextStyle()),
            ),
          ),
          Ecart.vXs,
          Text(
            libelle,
            style: paire.applyTo(textes.labelMedium ?? const TextStyle()),
          ),
        ],
      ),
    );
  }

  /// La surface de la tuile : elevee au neutre, teinte douce sinon.
  ///
  /// Jamais un aplat sature : une grille de quatre chiffres en aplats pleins
  /// est exactement le carnaval que la regle de la zone pleine unique
  /// interdit (`01-systeme-visuel.md` section 3).
  AppColorPair _paire(AppPalette palette) => switch (ton) {
    TonEtat.neutre => palette.surfaceRaised,
    TonEtat.accent => palette.washAccent,
    TonEtat.succes => palette.washSuccess,
    TonEtat.avertissement => palette.washWarning,
    TonEtat.alerte => palette.washAlert,
  };
}
