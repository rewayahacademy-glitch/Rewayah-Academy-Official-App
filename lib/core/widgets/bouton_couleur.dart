import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_contour.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Plan de la salle du 26/10/2026 (§3, « des couleurs, tout accessible ») :
/// une pastille du nuancier des traits. **Seul point d'entree** d'un bouton
/// qui montre une couleur a choisir (K-54) : aucun ecran ne peint lui-meme
/// un disque de couleur dans un `Pressable`.
///
/// Un disque plein de la couleur (24) dans une cible de 48 ; la couleur
/// retenue se lit par TROIS signaux, jamais la couleur seule : un anneau de
/// contour fort autour du disque, la coche blanche dedans, et l'etat
/// « selectionne » lu par le lecteur d'ecran. Le nom de la couleur
/// (« À renforcer », « Bleu ») est lu et montre en infobulle.
class BoutonCouleur extends StatelessWidget {
  const BoutonCouleur({
    required this.encre,
    required this.libelle,
    required this.retenue,
    required this.onPress,
    super.key,
  });

  /// La couleur du disque.
  final AppInkColor encre;

  /// Le nom de la couleur, lu et en infobulle.
  final String libelle;

  /// La couleur des prochains traits.
  final bool retenue;

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color couleur = encre.asBorderSide().color;
    return Tooltip(
      message: libelle,
      excludeFromSemantics: true,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: libelle,
        selectionne: retenue,
        arrondiFocus: AppRadius.arrondiFull,
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Center(
            child: DecoratedBox(
              key: const ValueKey<String>('disque-couleur'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  retenue
                      ? palette.borderStrong.asBorderSide(
                          width: AppContour.fort,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: SizedBox.square(
                  dimension: AppSpacing.xxl,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: couleur,
                      shape: BoxShape.circle,
                      // Un filet autour du disque : le noir reste visible
                      // sur la pilule sombre, le clair sur la claire.
                      border: Border.fromBorderSide(
                        palette.borderHairline.asBorderSide(),
                      ),
                    ),
                    child: retenue
                        ? IconTheme(
                            data: IconThemeData(
                              color:
                                  AppPalette.claire().surfaceAlert.onBackground,
                              size: AppSpacing.lg,
                            ),
                            child: Icon(AppIcons.succes.actif),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
