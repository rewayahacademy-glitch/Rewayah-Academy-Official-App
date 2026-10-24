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

  /// Standard des commandes d'appel (directeur, 24/10/2026 ; Google Meet,
  /// Material 3) : un bouton rond rempli de la pilule d'appel, icone seule
  /// de 24, couleur de [TonAppel] ; le libelle vit dans l'infobulle et la
  /// semantique, jamais sous le bouton.
  appel,
}

/// La couleur d'un bouton [FormeBoutonIcone.appel] (standard Meet).
enum TonAppel {
  /// Actif (micro ouvert, camera allumee, plus) : rempli sombre, icone
  /// claire.
  actif,

  /// Coupe ou eteint : rempli rouge, icone barree (choisie par l'appelant).
  coupe,

  /// Ouvert (tableau) : rempli de la couleur primaire.
  ouvert,

  /// Quitter : pilule rouge plus large, icone du combine.
  quitter,
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
    this.focusNode,
    this.suitTexte = false,
    this.tonAppel = TonAppel.actif,
    this.diametre,
    this.largeur,
    this.selectionne,
    this.actif = true,
  });

  /// [FormeBoutonIcone.appel] : faux, le bouton reste rendu dans la couleur
  /// de son etat mais ne repond pas (reconnexion). Aucun gris (K-56).
  final bool actif;

  /// [FormeBoutonIcone.appel] : la couleur du bouton.
  final TonAppel tonAppel;

  /// [FormeBoutonIcone.appel] : la hauteur du bouton (56 au telephone, 48
  /// ailleurs), `null` pour la cible du mode.
  final double? diametre;

  /// [FormeBoutonIcone.appel] : la largeur, quand elle depasse la hauteur
  /// (Quitter, 72 x 56).
  final double? largeur;

  /// Annonce l'etat d'une bascule (micro, camera, tableau) au lecteur
  /// d'ecran.
  final bool? selectionne;

  /// Le noeud du bouton, ou `null` : un hote y rend le focus (fermeture
  /// d'un panneau ouvert par ce bouton).
  final FocusNode? focusNode;

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

  Widget _appel(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair plein = switch (tonAppel) {
      TonAppel.actif => palette.boutonAppelActif,
      TonAppel.coupe || TonAppel.quitter => AppPalette.claire().surfaceAlert,
      TonAppel.ouvert => palette.surfacePrimary,
    };
    final double hauteur = math.max(
      diametre ?? AppTouchTarget.standard,
      AppTouchTarget.standard,
    );
    final double large = math.max(largeur ?? hauteur, hauteur);
    return Tooltip(
      message: infobulle ?? libelle,
      excludeFromSemantics: true,
      child: Pressable(
        onPress: onPress,
        actif: actif && onPress != null,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiFull,
        focusNode: focusNode,
        selectionne: selectionne,
        child: ExcludeSemantics(
          child: SizedBox(
            key: const ValueKey<String>('disque-appel'),
            width: large,
            height: hauteur,
            child: DecoratedBox(
              decoration: plein.decoration(borderRadius: AppRadius.arrondiFull),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: plein.onBackground,
                    size: AppSpacing.xxl,
                  ),
                  child: Icon(icone.actif),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (forme == FormeBoutonIcone.appel) return _appel(context);
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
      FormeBoutonIcone.nue || FormeBoutonIcone.appel => const BoxDecoration(),
    };

    return Tooltip(
      message: infobulle ?? libelle,
      excludeFromSemantics: true,
      child: Pressable(
        onPress: onPress,
        actif: onPress != null,
        libelleSemantique: libelle,
        arrondiFocus: arrondi,
        focusNode: focusNode,
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
