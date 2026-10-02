// Le dock de la salle de seance (I-4) et son bouton unique.
//
// Un seul style de bouton : des cercles de meme diametre, icone au centre,
// libelle dessous. Quitter est un disque plein d'alerte et passe toujours par
// une confirmation.

import 'dart:math' as math;

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
import 'libelles_salle_b.dart';
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

/// EN-12 (UX_REVIEW_04 n° 17 d, K-42) : le dock etroit trop serre (390,
/// 768 a sept boutons) ou le texte agrandi. Les boutons y passent en icone
/// seule, le libelle reste lu par le lecteur d'ecran, et le disque tient
/// sa case moins un ecart, sans descendre sous la cible tactile.
class _DockEtroit extends InheritedWidget {
  const _DockEtroit({required this.diametre, required super.child});

  final double diametre;

  @override
  bool updateShouldNotify(_DockEtroit ancien) => ancien.diametre != diametre;
}

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
    this.selectionne,
    super.key,
  });

  /// Le noeud de focus du bouton : la salle y rend le focus a la fermeture
  /// d'une feuille ouverte par ce bouton (micro bloque, W2 2.4.3).
  final FocusNode? focusNode;

  /// EN-10 : Supports dit « selectionne » quand son panneau est ouvert.
  final bool? selectionne;

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
    final _DockEtroit? etroit = context
        .dependOnInheritedWidgetOfExactType<_DockEtroit>();
    final bool iconeSeule = etroit != null;
    final double diametre = etroit?.diametre ?? diametreBoutonAppel(context);
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
    final Widget pressable = Pressable(
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
          if (!iconeSeule) ...<Widget>[
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
    this.focusSupports,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final bool cameraAllumee;

  /// Le support occupe l'ecran : le bouton devient « Reduire ».
  final bool agrandi;

  /// EN-10 : le focus rendu a Supports a la fermeture de son panneau.
  final FocusNode? focusSupports;

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
      case CommandeDock.supports:
        final VoidCallback? supports = actions.onSupports;
        if (supports == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('bouton-supports'),
          focusNode: focusSupports,
          selectionne:
              vue.panneau == PanneauOuvert.supports ||
              vue.panneau == PanneauOuvert.ressources,
          icone: AppIcons.supports.repos,
          libelle: t.salle.seance.supports,
          onPress: supports,
        );
      case CommandeDock.partager:
        final VoidCallback? partager = actions.onPartager;
        if (partager == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('dock-partager'),
          icone: AppIcons.flecheAction.repos,
          libelle: LibellesSalleB.partager,
          onPress: partager,
        );
      case CommandeDock.outils:
        final VoidCallback? outils = actions.onOutilsEnseignement;
        if (outils == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('dock-outils'),
          icone: AppIcons.stylet.repos,
          libelle: t.salle.seance.outils.titre,
          libelleSemantique: LibellesSalleB.ouvrirOutils,
          onPress: outils,
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
    final Gabarit gabarit = AppGabarit.de(context);
    final bool large = gabarit == Gabarit.desktop;
    final String? texteCamera = vue.texteCameraInterdite;
    final Widget? statutCamera = texteCamera == null
        ? null
        : StatutCameraInterdite(texte: texteCamera);
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
    final Widget dock;
    if (large) {
      // Guidee desktop (image CLV-05) : des disques bien separes, centres
      // a ≈ 130 l'un de l'autre, dans une pilule de ≈ 555 de large.
      // Chaque bouton tient une case de largeur egale, centree : l'ecart
      // entre les centres ne depend pas de la longueur des libelles.
      final bool aere = vue.dockColore;
      final double caseAeree =
          diametreBoutonAppel(context) + AppSpacing.titreEcran + AppSpacing.sm;
      dock = DecoratedBox(
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
    } else {
      dock = DecoratedBox(
        key: const ValueKey<String>('dock-seance'),
        decoration: cadre,
        child: Padding(
          // MA-CMD-1 : dock plus mince en Mode Accessibilite.
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppMetriques.of(context).mode == InterfaceMode.enfant
                ? AppSpacing.xs
                : AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints contraintes) {
              final Widget rangee = Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // Chaque bouton prend une part egale.
                children: <Widget>[
                  for (final Widget bouton in boutons) Expanded(child: bouton),
                ],
              );
              if (boutons.isEmpty) return rangee;
              final double diametre = diametreBoutonAppel(contexte);
              final double parCase = contraintes.maxWidth / boutons.length;
              final bool serre = parCase < diametre + AppSpacing.sm;
              final bool texteAgrandi =
                  MediaQuery.textScalerOf(contexte).scale(1) > 1;
              // MA-CMD-1 (directeur, 02/10/2026) : en Mode Accessibilite, a
              // toute taille de texte, icones seules et compactes, disque a
              // la cible tactile (le libelle reste lu et en infobulle).
              // Annule le dock a libelles visibles de M1.
              final bool accessibilite =
                  AppMetriques.of(contexte).mode == InterfaceMode.enfant;
              if (!serre && !texteAgrandi && !accessibilite) return rangee;
              // EN-12 (17 d) : icone seule, libelle lu ; disque a la case
              // moins un ecart, jamais sous la cible tactile.
              // MA-CMD-1 : disque compact de 56 (cible de 48 et plus), pour
              // que toutes les commandes tiennent sur une rangee a 390.
              final double cible = accessibilite
                  ? AppTouchTarget.standard + AppSpacing.sm
                  : AppMetriques.of(contexte).cibleTactile;
              // UX_REVIEW_04 n. 17 d, WCAG 1.4.10 : quand la part egale
              // tombe sous la cible (320), les boutons ne se partagent plus
              // la largeur ; ils passent sur deux lignes, en cases fixes, et
              // chaque disque garde la cible tactile.
              if (parCase < cible + AppSpacing.xs) {
                return _DockEtroit(
                  diametre: cible,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final Widget bouton in boutons)
                        SizedBox(
                          width: cible + AppSpacing.xs,
                          child: Center(child: bouton),
                        ),
                    ],
                  ),
                );
              }
              final double reduit = accessibilite
                  ? cible
                  : math.max(
                      math.min(diametre, parCase - AppSpacing.xs),
                      cible,
                    );
              return _DockEtroit(diametre: reduit, child: rangee);
            },
          ),
        ),
      );
    }
    if (statutCamera == null) return dock;
    // Q-S1 (option par defaut), corrige apres T-S5 : a toutes les tailles,
    // le statut est une ligne de texte d'etat discret au-dessus du dock,
    // alignee start, ecart 8. Dans le dock, la pilule de deux mots passait
    // sur deux lignes des 768.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: large
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(alignment: AlignmentDirectional.centerStart, child: statutCamera),
        Ecart.vSm,
        dock,
      ],
    );
  }
}

/// Le statut « Camera desactivee pour ce profil. » de l'eleve standard
/// (P10.3, [VueSeance.texteCameraInterdite]) : un **texte d'etat discret**
/// (encre `inkMuted`, `bodyMedium`), comme « La seance se poursuit. » de la
/// ligne d'etat. Non interactif (aucun [Pressable], ni survol ni focus), lu
/// avant le dock. Une phrase de cinq mots : une `StatusPill` (deux mots au
/// plus) passait a la ligne ; le texte reflue librement a 320 et a 200 %.
class StatutCameraInterdite extends StatelessWidget {
  const StatutCameraInterdite({required this.texte, super.key});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ConstrainedBox(
      key: const ValueKey<String>('statut-camera-interdite'),
      constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
      child: Text(
        texte,
        style: palette.inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
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
