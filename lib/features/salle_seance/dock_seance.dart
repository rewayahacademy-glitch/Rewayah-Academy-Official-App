// Le dock de la salle de seance (I-4) et son bouton unique.
//
// Un seul style de bouton : des cercles de meme diametre, icone au centre,
// libelle dessous. Quitter est un disque plein d'alerte et passe toujours par
// une confirmation.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/pressable.dart';
import 'actions_seance.dart';
import 'vue_seance.dart';

/// Le fond d'un [BoutonAppel].
enum FondBoutonAppel {
  /// Surface surelevee : Micro, Camera, Agrandir, Reseau.
  surface,

  /// Disque plein d'alerte : Quitter.
  alerte,

  /// Disque plein de la paire succes : Parler, en guidee (Q1).
  succes,

  /// Disque plein de la paire primaire : Camera, en guidee (Q1).
  primaire,
}

/// Quitter la seance, apres confirmation : le dock (Quitter) et l'icone de
/// sortie de l'en-tete guide passent par la meme question.
Future<void> confirmerQuitterSeance(
  BuildContext context,
  VoidCallback quitter,
) async {
  final bool confirme = await ConfirmDestructive.demander(
    context,
    question: t.salle.seance.quitterQuestion,
    consequence: t.salle.seance.quitterConsequence,
    libelleConfirmer: t.salle.quitter,
  );
  if (confirme) quitter();
}

/// Le diametre commun des boutons d'appel : la cible tactile du mode
/// d'interface, plus un palier, pour tenir la taille des images (≈ 56 en
/// standard). Tous les cercles d'un dock ont ce diametre.
/// En Interface guidee, le diametre est la cible tactile du mode enfant
/// elle-meme (Q1, S CLV-05 : 72).
double diametreBoutonAppel(BuildContext context) {
  final AppMetriques metriques = AppMetriques.of(context);
  return metriques.mode == InterfaceMode.enfant
      ? metriques.cibleTactile
      : metriques.cibleTactile + AppSpacing.sm;
}

/// La taille de l'icone dans le disque : plus grande en guidee (images).
double _tailleIconeAppel(BuildContext context) =>
    AppMetriques.of(context).mode == InterfaceMode.enfant
    ? AppSpacing.xxxl
    : AppSpacing.xxl;

/// L'encre claire fixe de Quitter : l'encre de la paire d'alerte du theme
/// clair (blanc), prise au jeton et non ecrite en dur.
final Color _encreClaire = AppPalette.claire().surfaceAlert.onBackground;

/// Un bouton du dock : cercle, icone, libelle dessous.
class BoutonAppel extends StatelessWidget {
  const BoutonAppel({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.libelleSemantique,
    this.fond = FondBoutonAppel.surface,
    super.key,
  });

  final IconData icone;
  final String libelle;
  final String? libelleSemantique;
  final VoidCallback onPress;
  final FondBoutonAppel fond;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final double diametre = diametreBoutonAppel(context);
    final double tailleIcone = _tailleIconeAppel(context);
    final BoxDecoration disque = switch (fond) {
      FondBoutonAppel.surface => palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiFull,
        side: palette.borderHairline.asBorderSide(),
      ),
      FondBoutonAppel.alerte => palette.pointsStatut.alerte.pastille(),
      FondBoutonAppel.succes => palette.surfaceSuccess.decoration(
        borderRadius: AppRadius.arrondiFull,
      ),
      FondBoutonAppel.primaire => palette.surfacePrimary.decoration(
        borderRadius: AppRadius.arrondiFull,
      ),
    };
    final IconThemeData encre = switch (fond) {
      FondBoutonAppel.surface => palette.inkStrong.asIconTheme(
        size: tailleIcone,
      ),
      // Encre claire fixe, dans les deux themes (images : combine blanc sur
      // disque rouge). Le disque est un point d'alerte, pas la paire
      // `surfaceAlert` : son encre sombre en theme sombre tombait sous 2:1
      // sur le rouge vif. Le blanc tient 4,1:1 (clair) et 3,3:1 (sombre),
      // au-dessus du seuil de 3:1 d'un element graphique (WCAG 1.4.11).
      FondBoutonAppel.alerte => IconThemeData(
        color: _encreClaire,
        size: tailleIcone,
      ),
      FondBoutonAppel.succes => IconThemeData(
        color: palette.surfaceSuccess.onBackground,
        size: tailleIcone,
      ),
      FondBoutonAppel.primaire => IconThemeData(
        color: palette.surfacePrimary.onBackground,
        size: tailleIcone,
      ),
    };
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelleSemantique ?? libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            key: const ValueKey<String>('disque-appel'),
            dimension: diametre,
            child: DecoratedBox(
              decoration: disque,
              child: Center(
                child: IconTheme(data: encre, child: Icon(icone)),
              ),
            ),
          ),
          Ecart.vXs,
          Text(
            libelle,
            maxLines: 1,
            style: palette.inkStrong.applyTo(
              theme.textTheme.labelMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le dock : les commandes de [VueSeance.commandesDock], dans l'ordre.
///
/// Desktop : une pilule centree. Telephone et web etroit : un panneau sur
/// toute la largeur, boutons repartis.
class DockSeance extends StatelessWidget {
  const DockSeance({
    required this.vue,
    required this.actions,
    this.microOuvert = true,
    this.cameraAllumee = true,
    this.agrandi = false,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final bool cameraAllumee;

  /// Le support occupe l'ecran : le bouton devient « Reduire ».
  final bool agrandi;

  Widget? _bouton(BuildContext context, CommandeDock commande) {
    // Guidee (Q1) : « Parler » et « Camera » en disques pleins.
    final bool colore = vue.dockColore;
    switch (commande) {
      case CommandeDock.micro:
        final VoidCallback? micro = actions.onMicro;
        if (micro == null) return null;
        return BoutonAppel(
          icone: colore
              ? (microOuvert ? AppIcons.micro : AppIcons.microCoupe).actif
              : (microOuvert ? AppIcons.micro : AppIcons.microCoupe).repos,
          libelle: colore ? t.salle.seance.parler : t.salle.micro,
          libelleSemantique: microOuvert
              ? t.salle.fermerMicro
              : t.salle.ouvrirMicro,
          fond: colore ? FondBoutonAppel.succes : FondBoutonAppel.surface,
          onPress: micro,
        );
      case CommandeDock.camera:
        final VoidCallback? camera = actions.onCamera;
        if (camera == null) return null;
        return BoutonAppel(
          icone:
              (cameraAllumee ? AppIcons.camera : AppIcons.cameraCoupee).actif,
          libelle: t.salle.camera,
          libelleSemantique: cameraAllumee
              ? t.salle.fermerCamera
              : t.salle.ouvrirCamera,
          fond: colore ? FondBoutonAppel.primaire : FondBoutonAppel.surface,
          onPress: camera,
        );
      case CommandeDock.agrandir:
        final VoidCallback? agrandir = actions.onAgrandir;
        if (agrandir == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('bouton-agrandir'),
          icone: (agrandi ? AppIcons.reduire : AppIcons.agrandir).repos,
          libelle: agrandi ? t.salle.seance.reduire : t.salle.seance.agrandir,
          onPress: agrandir,
        );
      case CommandeDock.reseau:
        // Enseignant seulement (T4).
        return null;
      case CommandeDock.quitter:
        final VoidCallback? quitter = actions.onQuitter;
        if (quitter == null) return null;
        return BoutonAppel(
          icone: AppIcons.raccrocher.actif,
          libelle: t.salle.quitter,
          libelleSemantique: t.salle.seance.sortir,
          fond: FondBoutonAppel.alerte,
          onPress: () => confirmerQuitterSeance(context, quitter),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final List<Widget> boutons = <Widget>[
      for (final CommandeDock commande in vue.commandesDock)
        ?_bouton(context, commande),
    ];
    final AppColorPair fond = palette.surfaceRaised;
    final BoxDecoration cadre = fond.decoration(
      borderRadius: AppRadius.arrondiLg,
      side: palette.borderHairline.asBorderSide(),
    );
    if (large) {
      // Guidee desktop (image CLV-05) : des disques bien separes, centres
      // a ≈ 130 l'un de l'autre, dans une pilule de ≈ 555 de large.
      // Chaque bouton tient une case de largeur egale, centree : l'ecart
      // entre les centres ne depend pas de la longueur des libelles.
      final bool aere = vue.dockColore;
      final double caseAeree =
          diametreBoutonAppel(context) + AppSpacing.titreEcran + AppSpacing.sm;
      return DecoratedBox(
        key: const ValueKey<String>('dock-seance'),
        decoration: cadre,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: aere ? AppSpacing.xl : AppSpacing.xxl,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: aere ? 0 : AppSpacing.xl,
            children: aere
                ? <Widget>[
                    for (final Widget bouton in boutons)
                      SizedBox(
                        width: caseAeree,
                        child: Center(child: bouton),
                      ),
                  ]
                : boutons,
          ),
        ),
      );
    }
    return DecoratedBox(
      key: const ValueKey<String>('dock-seance'),
      decoration: cadre,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: boutons,
        ),
      ),
    );
  }
}
