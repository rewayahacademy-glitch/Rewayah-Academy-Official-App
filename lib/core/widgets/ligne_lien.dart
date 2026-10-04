import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une ligne qui mene ailleurs, posee **dans** une carte : un titre, une
/// legende facultative dessous, un chevron au bord de fin.
///
/// C'est la ligne de `SettingRow` sans ce qui en fait une rubrique de
/// reglages : ni icone de tete, ni surface, ni marge propre. La carte qui la
/// porte (`BentoTile`, `AppCard`) donne le fond et la marge, si bien que le
/// titre part du meme bord que le reste du contenu de la carte, et que le
/// chevron tombe sur le bord de fin du contenu. Elle existe pour qu'aucun
/// ecran ne recompose cette ligne autour d'un `Pressable` (K-54).
///
/// - Annoncee comme **lien**, nommee par le titre ; la legende est lue a la
///   suite. Le titre n'est pas lu deux fois, le chevron pas du tout.
/// - Cible : toute la largeur, au moins la cible tactile du mode en hauteur.
/// - Texte agrandi : aucun mot n'est coupe ([TexteSansCoupure]), la ligne
///   grandit en hauteur ; le chevron reste centre. A l'echelle 1, un simple
///   texte, sans mesure (meme regle que `SettingRow`).
/// - Le chevron se miroite en RTL (`AppIcons.chevron`).
class LigneLien extends StatelessWidget {
  /// Cree une ligne lien.
  const LigneLien({
    required this.titre,
    required this.onPress,
    super.key,
    this.legende,
  });

  /// Le nom de la destination : « Le Coran ».
  final String titre;

  /// Une phrase sous le titre : « A lire quand tu veux ».
  final String? legende;

  /// La destination.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleTitre = textes.titleMedium ?? const TextStyle();
    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final bool agrandi = MediaQuery.textScalerOf(context).scale(1) > 1;
    Widget texte(String s, TextStyle style) =>
        agrandi ? TexteSansCoupure(s, style: style) : Text(s, style: style);

    return Pressable(
      onPress: onPress,
      libelleSemantique: titre,
      lien: true,
      arrondiFocus: metriques.arrondi,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Le lien porte deja le titre : il n'est pas lu deux fois.
                ExcludeSemantics(child: texte(titre, styleTitre)),
                if (legende != null) ...<Widget>[
                  Ecart.vSm,
                  texte(legende!, styleSecondaire),
                ],
              ],
            ),
          ),
          Ecart.hSm,
          ExcludeSemantics(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
              child: Icon(AppIcons.chevron.repos),
            ),
          ),
        ],
      ),
    );
  }
}
