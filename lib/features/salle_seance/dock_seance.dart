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
import 'feuille_micro_bloque.dart';
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

  /// Surface surelevee, icone a l'encre de succes : Reseau (image CLV-06).
  reseau,
}

/// Quitter la seance, apres confirmation : le dock (Quitter) et l'icone de
/// sortie de l'en-tete guide passent par la meme question.
///
/// Enseignant ([cahier]) : « Quitter et ouvrir le cahier », la suite est le
/// cahier de transmission (S l.861-863). Jamais « Terminer pour tous » ni
/// « Prolonger ». Le rail enseignant passe aussi par cette question.
Future<void> confirmerQuitterSeance(
  BuildContext context,
  VoidCallback quitter, {
  bool cahier = false,
}) async {
  final bool confirme = await ConfirmDestructive.demander(
    context,
    question: t.salle.seance.quitterQuestion,
    consequence: cahier
        ? t.salle.seance.quitterCahierConsequence
        : t.salle.seance.quitterConsequence,
    libelleConfirmer: cahier ? t.salle.seance.quitterCahier : t.salle.quitter,
    // Spec CLV-06, textes exacts : « Rester » et « Quitter et ouvrir le
    // cahier ».
    libelleAnnuler: cahier ? t.salle.seance.rester : null,
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
    this.actif = true,
    this.focusNode,
    super.key,
  });

  /// Le noeud de focus du bouton : la salle y rend le focus a la fermeture
  /// d'une feuille ouverte par ce bouton (micro bloque, W2 2.4.3).
  final FocusNode? focusNode;

  final IconData icone;
  final String libelle;
  final String? libelleSemantique;
  final VoidCallback onPress;
  final FondBoutonAppel fond;

  /// Faux : le bouton reste rendu mais ne repond pas (Micro et Camera
  /// pendant la reconnexion, lot CL-7, UX_REVIEW U1). Aucune transparence :
  /// le disque passe au fond neutre et l'encre `inkMuted` dit l'attente,
  /// comme le bouton inerte d'`ActionPrincipale`.
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final double diametre = diametreBoutonAppel(context);
    final double tailleIcone = _tailleIconeAppel(context);
    final BoxDecoration disque = !actif
        ? palette.surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiFull,
            side: palette.borderResting.asBorderSide(),
          )
        : switch (fond) {
            FondBoutonAppel.surface ||
            FondBoutonAppel.reseau => palette.surfaceOverlay.decoration(
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
    final IconThemeData encre = !actif
        ? palette.inkMuted.asIconTheme(size: tailleIcone)
        : switch (fond) {
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
            FondBoutonAppel.reseau => palette.inkSuccess.asIconTheme(
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
      actif: actif,
      focusNode: focusNode,
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
            overflow: TextOverflow.ellipsis,
            style: (actif ? palette.inkStrong : palette.inkMuted).applyTo(
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
        return _BoutonMicro(
          vue: vue,
          actions: actions,
          microOuvert: microOuvert,
          onMicro: micro,
        );
      case CommandeDock.camera:
        final VoidCallback? camera = actions.onCamera;
        if (camera == null) return null;
        return BoutonAppel(
          icone:
              (cameraAllumee ? AppIcons.camera : AppIcons.cameraCoupee).actif,
          libelle: t.salle.camera,
          libelleSemantique:
              vue.libelleIndisponible(t.salle.camera) ??
              (cameraAllumee ? t.salle.fermerCamera : t.salle.ouvrirCamera),
          actif: vue.commandesPublicationActives,
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
        final VoidCallback? reseau = actions.onReseau;
        if (reseau == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('bouton-reseau'),
          icone: AppIcons.reseau.repos,
          libelle: t.salle.seance.reseau,
          fond: FondBoutonAppel.reseau,
          onPress: reseau,
        );
      case CommandeDock.quitter:
        final VoidCallback? quitter = actions.onQuitter;
        if (quitter == null) return null;
        return BoutonAppel(
          icone: AppIcons.raccrocher.actif,
          libelle: t.salle.quitter,
          libelleSemantique: t.salle.seance.sortir,
          fond: FondBoutonAppel.alerte,
          onPress: () => confirmerQuitterSeance(
            context,
            quitter,
            cahier: vue.quitterOuvreCahier,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final List<Widget> boutons = <Widget>[
      for (final CommandeDock commande in vue.commandesDock) ...<Widget>[
        // Enseignant desktop (image CLV-06) : un filet vertical avant Quitter.
        if (large &&
            commande == CommandeDock.quitter &&
            vue.quitterOuvreCahier &&
            actions.onQuitter != null)
          _Separateur(hauteur: diametreBoutonAppel(context)),
        ?_bouton(context, commande),
      ],
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
          // Chaque bouton prend une part egale : un libelle trop large
          // (texte agrandi, 320px) s'ellipse au lieu de deborder la ligne.
          children: <Widget>[
            for (final Widget bouton in boutons) Expanded(child: bouton),
          ],
        ),
      ),
    );
  }
}

/// Le filet vertical du dock enseignant desktop, avant Quitter.
/// Le bouton Micro du dock. Micro bloque par le systeme
/// ([VueSeance.microBloque], P09) : le geste ouvre la feuille « micro
/// bloque » au lieu de basculer le micro, le bouton reste « coupe » et, a la
/// fermeture, le focus revient ici (UX_REVIEW U5, W2 2.4.3).
class _BoutonMicro extends StatefulWidget {
  const _BoutonMicro({
    required this.vue,
    required this.actions,
    required this.microOuvert,
    required this.onMicro,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final VoidCallback onMicro;

  @override
  State<_BoutonMicro> createState() => _BoutonMicroState();
}

class _BoutonMicroState extends State<_BoutonMicro> {
  final FocusNode _focus = FocusNode(debugLabel: 'bouton-micro');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ouvrirFeuille() async {
    await ouvrirFeuilleMicroBloque(
      context,
      vue: widget.vue,
      actions: widget.actions,
    );
    if (mounted) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    // Guidee (Q1) : « Parler » en disque plein.
    final bool colore = vue.dockColore;
    // Bloque : jamais montre ouvert (P09.6).
    final bool ouvert = widget.microOuvert && !vue.microBloque;
    final String libelle = colore ? t.salle.seance.parler : t.salle.micro;
    return BoutonAppel(
      key: const ValueKey<String>('bouton-micro'),
      focusNode: _focus,
      icone: colore
          ? (ouvert ? AppIcons.micro : AppIcons.microCoupe).actif
          : (ouvert ? AppIcons.micro : AppIcons.microCoupe).repos,
      libelle: libelle,
      libelleSemantique:
          vue.libelleIndisponible(libelle) ??
          (ouvert ? t.salle.fermerMicro : t.salle.ouvrirMicro),
      actif: vue.commandesPublicationActives,
      fond: colore ? FondBoutonAppel.succes : FondBoutonAppel.surface,
      onPress: vue.microBloque ? _ouvrirFeuille : widget.onMicro,
    );
  }
}

class _Separateur extends StatelessWidget {
  const _Separateur({required this.hauteur});

  final double hauteur;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey<String>('separateur-dock'),
    // Un filet de 1 (la bordure) dans une case d'un demi-palier.
    width: AppSpacing.xs,
    height: hauteur,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: AppPalette.of(context).borderResting.asBorderSide(),
        ),
      ),
    ),
  );
}
