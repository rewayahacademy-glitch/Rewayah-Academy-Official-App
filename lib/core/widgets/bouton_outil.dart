import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_contour.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La forme d'un [BoutonOutil].
enum FormeBoutonOutil {
  /// Sans surface au repos : une icone et son libelle, a la suite d'autres
  /// dans une barre (le Teaching Dock, la barre du stylet). Retenue, elle
  /// prend un aplat doux.
  nue,

  /// Une tuile : surface elevee a filet fin, qui remplit sa cellule (grille
  /// d'outils, actions d'une ligne d'eleve). Retenue, elle prend l'aplat doux
  /// de l'accent.
  tuile,
}

/// Le bouton d'outil du produit : une icone, son libelle dessous, un etat
/// retenu. **Seul point d'entree** d'un bouton fait d'une icone et d'un mot
/// (outil du Dock, tuile d'outil de la salle, tuile d'action d'un eleve) :
/// aucun ecran ne le peint lui-meme (K-54, `bouton-recompose`).
///
/// **Contenu centre en largeur et en hauteur** (K-54), y compris quand la
/// cible tactile (48, 72 en Interface guidee) ou la cellule de la grille est
/// plus grande que le contenu : l'icone et le libelle restent au milieu, le
/// libelle centre ligne a ligne s'il passe a la ligne.
///
/// **Grandes cibles tactiles en Interface guidee** : la cible vient de
/// `AppMetriques.cibleTactile`, que [Pressable] applique deja. Le bouton ne
/// pose donc aucune dimension lui-meme, et ne peut pas devenir plus petit que
/// la regle.
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
    this.forme = FormeBoutonOutil.nue,
    this.tailleIcone,
    this.lignesLibelle = 1,
    this.iconeActive = false,
    this.serre = false,
    this.focusNode,
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

  /// La forme : sans surface (barre) ou tuile (grille).
  final FormeBoutonOutil forme;

  /// La taille de l'icone. Par defaut `xxl` (`xxxl` en Interface guidee).
  final double? tailleIcone;

  /// Le nombre de lignes du libelle avant les points de suspension.
  final int lignesLibelle;

  /// Vrai pour toujours montrer la variante pleine de l'icone, retenue ou non
  /// (action d'une ligne d'eleve : l'icone porte l'accent).
  final bool iconeActive;

  /// Vrai pour resserrer les marges (colonne des eleves de la salle).
  final bool serre;

  /// Le noeud de focus du bouton, quand l'hote doit y rendre le focus (la
  /// fermeture d'un panneau qu'il ouvre).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool tuile = forme == FormeBoutonOutil.tuile;
    final double taille =
        tailleIcone ??
        (metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl);

    // Doc 04 §28 et §33 n. 13 : sans libelle visible, ou quand l'agrandissement
    // du texte le coupe, une infobulle le montre (comme `nav_shell`).
    final bool infobulle =
        !avecLibelle ||
        MediaQuery.textScalerOf(context).scale(1) > AppContour.seuilTexteAgrandi;

    final TextStyle base = textes.labelSmall ?? const TextStyle();
    final TextStyle styleLibelle = tuile
        ? palette.inkStrong.applyTo(base)
        : retenu
        ? palette.surfaceInverse.applyTo(base)
        : palette.inkMuted.applyTo(base);
    final IconThemeData themeIcone = tuile
        ? (retenu || iconeActive ? palette.inkAccent : palette.inkStrong)
              .asIconTheme(size: taille)
        : retenu
        ? IconThemeData(color: palette.surfaceInverse.onBackground, size: taille)
        : (iconeActive ? palette.inkAccent : palette.inkStrong).asIconTheme(
            size: taille,
          );

    final Widget contenu = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tuile ? AppSpacing.xs : AppSpacing.sm,
        vertical: tuile && !serre ? AppSpacing.sm : AppSpacing.xs,
      ),
      // Le centre horizontal et vertical, fait une fois ici : la cible ou la
      // cellule peut etre plus grande que le contenu.
      child: Center(
        widthFactor: tuile ? null : 1,
        heightFactor: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconTheme(
              data: themeIcone,
              child: Icon(
                iconeActive ? icone.actif : icone.resoudre(selectionne: retenu),
              ),
            ),
            if (avecLibelle) ...<Widget>[
              Ecart.vXs,
              Text(
                libelle,
                textAlign: TextAlign.center,
                maxLines: lignesLibelle,
                overflow: TextOverflow.ellipsis,
                style: styleLibelle,
              ),
            ],
          ],
        ),
      ),
    );

    final Widget bouton = Pressable(
      libelleSemantique: libelle,
      // TB-RC (revue TB-R, m6) : l'outil retenu est annonce au lecteur
      // d'ecran (« selectionne »), pas seulement peint. Non retenu : rien
      // n'est annonce (une action comme Annuler n'a pas d'etat de choix).
      selectionne: retenu ? true : null,
      arrondiFocus: tuile ? AppRadius.arrondiMd : AppRadius.arrondiSm,
      onPress: onPress,
      focusNode: focusNode,
      // Le contenu est exclu de la semantique : l'icone n'a rien a dire, et le
      // libelle affiche redirait le nom que `Pressable` porte deja. Sans cela,
      // un lecteur d'ecran annoncerait le bouton deux fois.
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: tuile
              ? (retenu ? palette.washAccent : palette.surfaceRaised).decoration(
                  borderRadius: AppRadius.arrondiMd,
                  side: palette.borderHairline.asBorderSide(),
                )
              : retenu
              // ETATS-BTN-1 : l'outil arme est un aplat plein et contraste ;
              // l'outil inactif garde un contour seul (jamais l'absence de
              // forme : l'etat se lit sans la couleur).
              ? palette.surfaceInverse.decoration(
                  borderRadius: AppRadius.arrondiSm,
                )
              : BoxDecoration(
                  borderRadius: AppRadius.arrondiSm,
                  border: Border.fromBorderSide(
                    palette.borderStrong.asBorderSide(width: AppContour.fort),
                  ),
                ),
          child: contenu,
        ),
      ),
    );
    return infobulle
        ? Tooltip(message: libelle, excludeFromSemantics: true, child: bouton)
        : bouton;
  }
}
