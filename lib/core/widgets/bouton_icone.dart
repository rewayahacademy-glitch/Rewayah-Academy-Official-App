import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_elevation.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La forme d'un [BoutonIcone].
enum FormeBoutonIcone {
  /// Un disque a contour fin, sans fond : zoom, pas precedent, pas suivant.
  cercle,

  /// Un carre arrondi, surface elevee a filet et ombre : action d'une carte.
  carre,
}

/// Un bouton fait d'une seule icone, a cible tactile pleine (48 au moins).
///
/// **Seul point d'entree** d'un bouton icone peint (disque ou carre) : aucun
/// ecran ne le recompose (K-54, `bouton-recompose`). L'icone est centree en
/// largeur et en hauteur dans la cible ; le libelle n'est pas affiche, il est
/// lu par les technologies d'assistance et montre en infobulle (un bouton sans
/// mot se nomme toujours).
class BoutonIcone extends StatelessWidget {
  /// Cree un bouton icone.
  const BoutonIcone({
    required this.icone,
    required this.libelle,
    required this.onPress,
    super.key,
    this.forme = FormeBoutonIcone.cercle,
    this.infobulle,
  });

  /// L'icone.
  final AppIcon icone;

  /// Ce que lit le lecteur d'ecran : un verbe et son objet.
  final String libelle;

  /// L'action. `null` rend le bouton inerte (icone en encre attenuee).
  final VoidCallback? onPress;

  /// Disque a contour ou carre eleve.
  final FormeBoutonIcone forme;

  /// L'infobulle, quand elle dit plus que le libelle (raccourci clavier).
  /// Par defaut, le libelle.
  final String? infobulle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool cercle = forme == FormeBoutonIcone.cercle;
    final BorderRadius arrondi = cercle
        ? AppRadius.arrondiFull
        : AppRadius.arrondiSm;

    return Tooltip(
      message: infobulle ?? libelle,
      excludeFromSemantics: true,
      child: Pressable(
        onPress: onPress,
        actif: onPress != null,
        libelleSemantique: libelle,
        arrondiFocus: arrondi,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppTouchTarget.standard,
            child: DecoratedBox(
              decoration: cercle
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        palette.contourCarte.asBorderSide(),
                      ),
                    )
                  : AppElevation.avecFilet(
                      surface: palette.surfaceRaised,
                      filet: palette.contourCarte,
                      ombre: palette.ombre,
                      arrondi: arrondi,
                    ),
              child: Center(
                child: IconTheme(
                  data: (onPress == null ? palette.inkMuted : palette.inkAccent)
                      .asIconTheme(size: AppSpacing.xxl),
                  child: Icon(icone.repos),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
