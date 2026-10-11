import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
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

  /// Une commande de lecteur (BOUTON-ICONE-1) : disque plein de surface
  /// d'overlay (`surfaceOverlay`) a filet fin (`borderHairline`), icone de
  /// 20 en encre forte. Commandes du lecteur du Coran en Mode Accessibilite,
  /// posees sur le texte (elles se masquent apres quelques secondes).
  disque,

  /// L'icone seule, sans disque ni contour, icone de 20 en encre forte : le
  /// retour d'un en-tete de lecteur.
  nue,
}

/// Un bouton fait d'une seule icone, a cible tactile pleine (48 au moins).
/// La cible suit le mode d'interface : `Pressable` impose la cible tactile
/// du mode (`AppMetriques.cibleTactile`, 72 en interface guidee), et la
/// surface peinte (disque, carre) la remplit.
///
/// **Seul point d'entree** d'un bouton fait d'une seule icone, quelle que
/// soit sa forme ([FormeBoutonIcone] : cercle a contour, carre eleve, disque
/// de commande de lecteur, icone nue) : aucun ecran ne le recompose (K-54, `bouton-recompose`). L'icone est centree en
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
    this.suitTexte = false,
  });

  /// Vrai pour que l'icone suive l'echelle du texte (lot K) : posee a cote
  /// d'un bouton a libelle (le micro a cote d'« Envoyer »), une icone de
  /// taille fixe paraissait minuscule a texte double. L'icone grandit avec
  /// le texte, bornee a [echelleMax] fois sa taille ; la cible reste de 48
  /// au moins et entoure l'icone d'une marge de 8 de chaque cote.
  final bool suitTexte;

  /// La borne de l'echelle de l'icone quand elle [suitTexte].
  static const double echelleMax = 2;

  /// L'icone.
  final AppIcon icone;

  /// Ce que lit le lecteur d'ecran : un verbe et son objet.
  final String libelle;

  /// L'action. `null` rend le bouton inerte (icone en encre attenuee).
  final VoidCallback? onPress;

  /// La forme : [FormeBoutonIcone.cercle] (par defaut, disque a contour sans
  /// fond), [FormeBoutonIcone.carre] (surface elevee), [FormeBoutonIcone.disque]
  /// (commande de lecteur sur surface d'overlay) ou [FormeBoutonIcone.nue]
  /// (icone seule). Cercle et carre portent une icone de 24 en encre
  /// d'accent ; disque et nue une icone de 20 en encre forte. Toutes
  /// remplissent la cible du mode.
  final FormeBoutonIcone forme;

  /// L'infobulle, quand elle dit plus que le libelle (raccourci clavier).
  /// Par defaut, le libelle.
  final String? infobulle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool commande =
        forme == FormeBoutonIcone.disque || forme == FormeBoutonIcone.nue;
    final BorderRadius arrondi = forme == FormeBoutonIcone.carre
        ? AppRadius.arrondiSm
        : AppRadius.arrondiFull;
    final double tailleBase = commande ? AppSpacing.xl : AppSpacing.xxl;
    final double tailleIcone = suitTexte
        ? MediaQuery.textScalerOf(context)
              .scale(tailleBase)
              .clamp(tailleBase, tailleBase * echelleMax)
        : tailleBase;
    final double cible = math.max(
      AppTouchTarget.standard,
      tailleIcone + AppSpacing.lg,
    );
    final AppInkColor encre = onPress == null
        ? palette.inkMuted
        : commande
        ? palette.inkStrong
        : palette.inkAccent;
    final Decoration decoration = switch (forme) {
      FormeBoutonIcone.cercle => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(palette.contourCarte.asBorderSide()),
      ),
      FormeBoutonIcone.carre => AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: arrondi,
      ),
      FormeBoutonIcone.disque => palette.surfaceOverlay.decoration(
        borderRadius: arrondi,
        side: palette.borderHairline.asBorderSide(),
      ),
      FormeBoutonIcone.nue => const BoxDecoration(),
    };

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
            dimension: cible,
            child: DecoratedBox(
              decoration: decoration,
              child: Center(
                child: IconTheme(
                  data: encre.asIconTheme(size: tailleIcone),
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
