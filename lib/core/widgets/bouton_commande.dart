import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Le fond du disque d'un [BoutonCommande].
enum FondCommande {
  /// Disque a contour fort, sans fond : une commande au repos (Micro, Camera).
  contour,

  /// Disque plein de la surface elevee : une commande ouverte.
  releve,

  /// Surface surelevee a filet fin : Micro, Camera, Agrandir du dock.
  surface,

  /// Surface surelevee, icone a l'encre de succes : le reseau.
  reseau,

  /// Disque plein d'alerte, encre claire fixe : Quitter.
  alerte,

  /// Disque plein de la paire succes : Parler, en Interface guidee.
  succes,

  /// Disque plein de la paire primaire : Camera, en Interface guidee.
  primaire,
}

/// L'encre claire fixe du disque d'alerte : l'encre de la paire d'alerte du
/// theme clair (blanc), prise au jeton et non ecrite en dur. Le disque est un
/// point d'alerte, pas la paire `surfaceAlert` : son encre sombre en theme
/// sombre tombait sous 2:1 sur le rouge vif ; le blanc tient 4,1:1 (clair) et
/// 3,3:1 (sombre), au-dessus du seuil de 3:1 d'un element graphique (WCAG
/// 1.4.11).
final Color _encreClaire = AppPalette.claire().surfaceAlert.onBackground;

/// Une commande ronde : un disque, une icone, un mot court dessous.
///
/// **Seul point d'entree** d'une commande de la salle (micro, camera, quitter,
/// parler...) : le dock de la seance et la rangee de commandes de la salle la
/// partagent, aucun ecran ne peint son disque (K-54, `bouton-recompose`).
///
/// **Contenu centre** (K-54) : l'icone est au centre du disque, le disque et le
/// libelle sont centres l'un sur l'autre, le libelle centre ligne a ligne.
///
/// L'etat se lit par la forme (l'icone change, le disque se remplit), jamais
/// par la couleur seule. Un bouton [actif] faux reste rendu, sans transparence :
/// le disque passe au fond neutre et l'encre `inkMuted` dit l'attente.
class BoutonCommande extends StatelessWidget {
  /// Cree une commande ronde.
  const BoutonCommande({
    required this.icone,
    required this.libelle,
    required this.onPress,
    required this.diametre,
    required this.tailleIcone,
    super.key,
    this.libelleSemantique,
    this.fond = FondCommande.surface,
    this.actif = true,
    this.focusNode,
    this.selectionne,
    this.iconeSeule = false,
    this.styleLibelle,
    this.cleDisque,
  });

  /// L'icone, deja resolue (pleine ou non selon l'etat).
  final IconData icone;

  /// Le mot visible sous le disque, et par defaut ce que lit le lecteur
  /// d'ecran.
  final String libelle;

  /// Ce que lit le lecteur d'ecran quand il dit l'acte, plus long que le mot
  /// visible (« Ouvrir le micro » pour « Micro »).
  final String? libelleSemantique;

  /// L'action. `null` rend la commande inerte.
  final VoidCallback? onPress;

  /// Le diametre du disque.
  final double diametre;

  /// La taille de l'icone dans le disque.
  final double tailleIcone;

  /// Le fond du disque.
  final FondCommande fond;

  /// Faux : la commande reste rendue mais ne repond pas.
  final bool actif;

  /// Le noeud de focus de la commande, pour que l'ecran y rende le focus a la
  /// fermeture d'une feuille ouverte par elle.
  final FocusNode? focusNode;

  /// Dit « selectionne » aux technologies d'assistance. Nul : non annonce.
  final bool? selectionne;

  /// Vrai pour masquer le mot : il reste lu et montre en infobulle (dock
  /// etroit, texte agrandi).
  final bool iconeSeule;

  /// Le style du mot, quand la surface n'est pas celle de la page (salle).
  /// Par defaut : `labelMedium`, encre forte (attenuee si inerte).
  final TextStyle? styleLibelle;

  /// La cle du disque, pour les tests de geometrie.
  final Key? cleDisque;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);

    final BoxDecoration disque = !actif
        ? palette.surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiFull,
            side: palette.borderResting.asBorderSide(),
          )
        : switch (fond) {
            FondCommande.contour => BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
            ),
            FondCommande.releve => palette.surfaceRaised.decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
            FondCommande.surface ||
            FondCommande.reseau => palette.surfaceOverlay.decoration(
              borderRadius: AppRadius.arrondiFull,
              side: palette.borderHairline.asBorderSide(),
            ),
            FondCommande.alerte => palette.pointsStatut.alerte.pastille(),
            FondCommande.succes => palette.surfaceSuccess.decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
            FondCommande.primaire => palette.surfacePrimary.decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
          };
    final IconThemeData encre = !actif
        ? palette.inkMuted.asIconTheme(size: tailleIcone)
        : switch (fond) {
            FondCommande.contour => IconThemeData(size: tailleIcone),
            FondCommande.releve => IconThemeData(
              color: palette.surfaceRaised.onBackground,
              size: tailleIcone,
            ),
            FondCommande.surface => palette.inkStrong.asIconTheme(
              size: tailleIcone,
            ),
            FondCommande.alerte => IconThemeData(
              color: _encreClaire,
              size: tailleIcone,
            ),
            FondCommande.reseau => palette.inkSuccess.asIconTheme(
              size: tailleIcone,
            ),
            FondCommande.succes => IconThemeData(
              color: palette.surfaceSuccess.onBackground,
              size: tailleIcone,
            ),
            FondCommande.primaire => IconThemeData(
              color: palette.surfacePrimary.onBackground,
              size: tailleIcone,
            ),
          };

    final Widget pressable = Pressable(
      onPress: onPress,
      actif: actif,
      focusNode: focusNode,
      libelleSemantique: libelleSemantique ?? libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox.square(
            key: cleDisque,
            dimension: diametre,
            child: DecoratedBox(
              decoration: disque,
              child: Center(
                child: IconTheme(data: encre, child: Icon(icone)),
              ),
            ),
          ),
          if (!iconeSeule) ...<Widget>[
            Ecart.vXs,
            Text(
              libelle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  styleLibelle ??
                  (actif ? palette.inkStrong : palette.inkMuted).applyTo(
                    theme.textTheme.labelMedium ?? const TextStyle(),
                  ),
            ),
          ],
        ],
      ),
    );
    // Doc 04 §28 et §33 n. 13 : en icone seule, le libelle reste visible en
    // infobulle (comme `nav_shell`), deja lu par `Pressable`.
    final Widget bouton = iconeSeule
        ? Tooltip(
            message: libelleSemantique ?? libelle,
            excludeFromSemantics: true,
            child: pressable,
          )
        : pressable;
    final bool? choisi = selectionne;
    return choisi == null ? bouton : Semantics(selected: choisi, child: bouton);
  }
}
