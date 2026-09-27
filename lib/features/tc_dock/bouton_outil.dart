import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// Un bouton du Teaching Dock ou de la barre du stylet.
///
/// **Grandes cibles tactiles en Interface guidee** (spec section 8) : la cible
/// vient de `AppMetriques.cibleTactile`, que `Pressable` applique deja -- 72
/// points en interface guidee, 48 ailleurs. Le bouton ne pose donc aucune
/// dimension lui-meme, et ne peut pas devenir plus petit que la regle.
///
/// L'etat retenu se lit **deux fois** : la graisse de l'icone change **et** un
/// aplat doux apparait. Jamais la couleur seule (invariant J7).
class BoutonOutil extends StatelessWidget {
  /// Cree un bouton d'outil.
  const BoutonOutil({
    required this.icone,
    required this.libelle,
    required this.onPress,
    super.key,
    this.retenu = false,
    this.avecLibelle = false,
  });

  /// L'icone de l'outil.
  final AppIcon icone;

  /// Le libelle, lu par les technologies d'assistance et affiche quand la
  /// place le permet.
  final String libelle;

  /// L'action. `null` rend le bouton inerte.
  final VoidCallback? onPress;

  /// Vrai quand l'outil est celui qui est arme.
  final bool retenu;

  /// Vrai pour afficher le libelle sous l'icone.
  final bool avecLibelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final double tailleIcone = metriques.estEnfant
        ? AppSpacing.xxxl
        : AppSpacing.xxl;

    // Doc 04 §28 et §33 n. 13 : sans libelle visible, ou quand l'agrandissement
    // du texte le coupe, une infobulle le montre (comme `nav_shell`).
    final bool libelleVisible =
        avecLibelle && MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final Widget bouton = Pressable(
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiSm,
      onPress: onPress,
      // Le contenu est exclu de la semantique : l'icone n'a rien a dire, et le
      // libelle affiche redirait le nom que `Pressable` porte deja. Sans cela,
      // un lecteur d'ecran annoncerait le bouton deux fois.
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: retenu
              ? palette.washAccent.decoration(
                  borderRadius: AppRadius.arrondiSm,
                )
              : const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconTheme(
                  data: (retenu ? palette.inkAccent : palette.inkStrong)
                      .asIconTheme(size: tailleIcone),
                  child: Icon(icone.resoudre(selectionne: retenu)),
                ),
                if (avecLibelle) ...<Widget>[
                  Ecart.vXs,
                  Text(
                    libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (retenu ? palette.inkAccent : palette.inkMuted)
                        .applyTo(textes.labelSmall ?? const TextStyle()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return libelleVisible
        ? bouton
        : Tooltip(message: libelle, excludeFromSemantics: true, child: bouton);
  }
}
