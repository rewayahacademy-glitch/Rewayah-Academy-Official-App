// Le dock de la salle de seance (I-4) et son bouton unique.
//
// Un seul style de bouton : des cercles de meme diametre, icone au centre,
// libelle dessous. Quitter est un disque plein d'alerte et passe toujours par
// une confirmation.

import 'package:flutter/material.dart';

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
}

/// Le diametre commun des boutons d'appel : la cible tactile du mode
/// d'interface, plus un palier, pour tenir la taille des images (≈ 56 en
/// standard). Tous les cercles d'un dock ont ce diametre.
double diametreBoutonAppel(BuildContext context) =>
    AppMetriques.of(context).cibleTactile + AppSpacing.sm;

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
    final BoxDecoration disque = switch (fond) {
      FondBoutonAppel.surface => palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiFull,
        side: palette.borderHairline.asBorderSide(),
      ),
      FondBoutonAppel.alerte => palette.pointsStatut.alerte.pastille(),
    };
    final IconThemeData encre = switch (fond) {
      FondBoutonAppel.surface => palette.inkStrong.asIconTheme(
        size: AppSpacing.xxl,
      ),
      FondBoutonAppel.alerte => IconThemeData(
        color: palette.surfaceAlert.onBackground,
        size: AppSpacing.xxl,
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
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final bool cameraAllumee;

  Future<void> _quitter(BuildContext context, VoidCallback quitter) async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.salle.seance.quitterQuestion,
      consequence: t.salle.seance.quitterConsequence,
      libelleConfirmer: t.salle.quitter,
    );
    if (confirme) quitter();
  }

  Widget? _bouton(BuildContext context, CommandeDock commande) {
    switch (commande) {
      case CommandeDock.micro:
        final VoidCallback? micro = actions.onMicro;
        if (micro == null) return null;
        return BoutonAppel(
          icone: (microOuvert ? AppIcons.micro : AppIcons.microCoupe).repos,
          libelle: t.salle.micro,
          libelleSemantique: microOuvert
              ? t.salle.fermerMicro
              : t.salle.ouvrirMicro,
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
          onPress: camera,
        );
      case CommandeDock.agrandir:
        final VoidCallback? agrandir = actions.onAgrandir;
        if (agrandir == null) return null;
        return BoutonAppel(
          icone: AppIcons.agrandir.repos,
          libelle: t.salle.seance.agrandir,
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
          onPress: () => _quitter(context, quitter),
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
      return DecoratedBox(
        key: const ValueKey<String>('dock-seance'),
        decoration: cadre,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xl,
            children: boutons,
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
