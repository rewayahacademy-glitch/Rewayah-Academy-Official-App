// Lot VIGNETTE-TELEPHONE (directeur, 11/11/2026 : « est-ce qu'on peut bouger
// les vignettes de video ou les cacher comme on le veut ? ») : la languette
// d'une vignette rangee au bord de l'ecran, et la poignee qui la range.
//
// Standard : l'image dans l'image de FaceTime (Apple HIG, Picture in
// Picture) : glissee vers le bord, la video se range et laisse une languette ;
// toucher ou tirer la languette la ramene. WCAG 2.5.7 : le glissement a une
// alternative au simple appui (ce composant) ; WCAG 2.5.8 : la cible fait 48
// sur 48 alors que la languette ne fait que 24 de large a l'oeil.

import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Le bord physique de l'ecran ou se pose une [LanguetteBord]. Un bord
/// d'ecran ne se miroite pas en arabe : c'est l'appelant qui choisit le bord
/// d'apres le sens de lecture.
enum BordLanguette { gauche, droite }

/// Une languette collee a un bord de l'ecran : petite a l'oeil (24 de large,
/// 48 de haut), cible tactile de 48 sur 48 qui deborde vers l'interieur.
///
/// Elle est sombre dans les deux themes (la couche des commandes de la salle,
/// `coucheSalle`) et porte toujours une icone : son sens ne tient jamais a la
/// couleur seule. Le libelle est lu par le lecteur d'ecran ; la languette est
/// atteinte au clavier et s'active par Entree ou Espace ([Pressable]).
class LanguetteBord extends StatelessWidget {
  /// Cree une languette.
  const LanguetteBord({
    required this.bord,
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.retourner = false,
    this.focusNode,
    super.key,
  });

  /// La largeur visible de la languette.
  static const double largeurVisible = AppSpacing.xxl;

  /// La hauteur de la languette, celle de sa cible.
  static const double hauteur = AppTouchTarget.standard;

  /// La taille de la cible tactile (carree).
  static const double cible = AppTouchTarget.standard;

  /// Le bord de l'ecran contre lequel elle est collee.
  final BordLanguette bord;

  /// L'icone, centree dans la partie visible.
  final AppIcon icone;

  /// Vrai : l'icone est retournee de gauche a droite (un chevron qui doit
  /// pointer vers le bord gauche).
  final bool retourner;

  /// Ce que lit le lecteur d'ecran : un verbe et son objet.
  final String libelle;

  /// L'action.
  final VoidCallback onPress;

  /// Le noeud du focus, pour qu'un hote y rende le focus.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool gauche = bord == BordLanguette.gauche;
    const Radius arrondi = Radius.circular(AppRadius.sm);
    Widget glyphe = Icon(icone.repos);
    if (retourner) glyphe = Transform.flip(flipX: true, child: glyphe);
    return SizedBox(
      width: cible,
      height: hauteur,
      child: Pressable(
        libelleSemantique: libelle,
        onPress: onPress,
        focusNode: focusNode,
        child: Align(
          // Le bord est physique ; l'alignement passe par le sens de
          // lecture (debut a gauche en francais, a droite en arabe).
          alignment: gauche == (Directionality.of(context) == TextDirection.ltr)
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: SizedBox(
            key: const ValueKey<String>('languette-visible'),
            width: largeurVisible,
            height: hauteur,
            child: DecoratedBox(
              decoration: palette.coucheSalle.decoration(
                borderRadius: gauche
                    ? const BorderRadius.horizontal(right: arrondi)
                    : const BorderRadius.horizontal(left: arrondi),
                side: palette.borderHairline.asBorderSide(),
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: palette.coucheSalle.onBackground,
                    size: AppSpacing.lg,
                  ),
                  child: glyphe,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
