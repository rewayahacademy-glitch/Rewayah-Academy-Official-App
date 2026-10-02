// La navigation precedent / suivant, facon lecteur de musique.
//
// NAV-FLECHES-1 (revue du directeur, 02/10/2026, K-54, K-56). Fleche a gauche,
// position courante au centre, fleche a droite : deux icones rondes de meme
// taille, centrees dans leur disque, cible tactile du mode d'interface (48 en
// standard). Aux bornes (premiere page, derniere page) la fleche DISPARAIT :
// elle n'est pas grisee, une commande qui ne peut pas aboutir n'est pas rendue
// (lib/CLAUDE.md). Sa place reste reservee, pour que la position reste au
// centre et que l'autre fleche ne bouge pas.
//
// Sens de lecture : la fleche « precedent » est au bord de debut de la ligne
// (a gauche en francais, a droite en arabe) et pointe vers lui ; « suivant »
// au bord de fin. Le glyphe est celui du jeu d'icones des jetons
// ([AppIcons.suivant], qui ne se miroite pas seul) : c'est ici, et ici
// seulement, qu'il est retourne selon `Directionality`.
//
// Un seul composant pour la salle, le lecteur de Coran et la presentation de
// l'enseignant : on l'ameliore, on n'en recree pas un.

import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La barre precedent / position / suivant.
class BarrePrecedentSuivant extends StatelessWidget {
  const BarrePrecedentSuivant({
    required this.position,
    required this.libellePrecedent,
    required this.libelleSuivant,
    this.positionSemantique,
    this.onPrecedent,
    this.onSuivant,
    this.etendue = true,
    super.key,
  });

  /// La position courante, au centre (« 12 / 604 »).
  final String position;

  /// Ce que le lecteur d'ecran annonce pour la position (« Page 12 sur 604 »).
  /// Par defaut, [position].
  final String? positionSemantique;

  /// Ce que le lecteur d'ecran annonce pour la fleche de debut
  /// (« Verset precedent », « Page precedente »).
  final String libellePrecedent;

  /// Idem pour la fleche de fin (« Verset suivant »).
  final String libelleSuivant;

  /// `null` : on est au debut, la fleche n'est pas rendue (pas grisee).
  final VoidCallback? onPrecedent;

  /// `null` : on est a la fin, la fleche n'est pas rendue (pas grisee).
  final VoidCallback? onSuivant;

  /// Vrai : la barre prend toute la largeur offerte, la position au centre.
  /// Faux : la barre se resserre autour de son contenu (pastille de la salle).
  final bool etendue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    final Widget centre = Semantics(
      label: positionSemantique ?? position,
      excludeSemantics: true,
      liveRegion: true,
      child: Text(
        position,
        key: const ValueKey<String>('nav-position'),
        textAlign: TextAlign.center,
        style: palette.inkStrong.applyTo(
          Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
        ),
      ),
    );
    return Row(
      key: const ValueKey<String>('nav-precedent-suivant'),
      mainAxisSize: etendue ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _Fleche(
          cle: const ValueKey<String>('nav-precedent'),
          libelle: libellePrecedent,
          onPress: onPrecedent,
          versLeDebut: true,
          cote: cible,
        ),
        if (etendue)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: centre,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: centre,
          ),
        _Fleche(
          cle: const ValueKey<String>('nav-suivant'),
          libelle: libelleSuivant,
          onPress: onSuivant,
          versLeDebut: false,
          cote: cible,
        ),
      ],
    );
  }
}

/// Une fleche ronde, ou sa place vide quand [onPress] est nul.
class _Fleche extends StatelessWidget {
  const _Fleche({
    required this.cle,
    required this.libelle,
    required this.onPress,
    required this.versLeDebut,
    required this.cote,
  });

  final Key cle;
  final String libelle;
  final VoidCallback? onPress;
  final bool versLeDebut;
  final double cote;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = onPress;
    // La place reste reservee : la position ne bouge pas, l'autre fleche non
    // plus.
    if (action == null) return SizedBox.square(dimension: cote);
    final AppPalette palette = AppPalette.of(context);
    // Le glyphe de [AppIcons.suivant] pointe vers la droite. En lecture de
    // gauche a droite, « precedent » le retourne ; en arabe, c'est « suivant »
    // qui pointe vers la gauche.
    final bool arabe = Directionality.of(context) == TextDirection.rtl;
    final bool retourne = versLeDebut != arabe;
    return Pressable(
      onPress: action,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: SizedBox.square(
        key: cle,
        dimension: cote,
        child: DecoratedBox(
          decoration: palette.surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiFull,
            side: palette.borderResting.asBorderSide(),
          ),
          child: Center(
            child: IconTheme(
              data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
              child: Transform.flip(
                flipX: retourne,
                child: Icon(AppIcons.suivant.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
