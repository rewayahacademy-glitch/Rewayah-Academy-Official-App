// Le dock de la salle de seance (I-4) et son bouton unique.
//
// Un seul style de bouton : des cercles de meme diametre, icone au centre,
// libelle dessous. Quitter est un disque plein d'alerte et passe toujours par
// une confirmation.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/commande_salle.dart';
import '../../core/widgets/confirm_destructive.dart';
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

/// Le diametre commun des boutons d'appel : celui des commandes rondes du
/// core ([diametreCommandeSalle]). Tous les cercles d'un dock l'ont.
double diametreBoutonAppel(BuildContext context) =>
    diametreCommandeSalle(context);

/// Un bouton du dock : cercle, icone, libelle dessous. Le dessin vit dans
/// [CommandeSalle] (core), partage avec la salle ; ce widget n'ajoute que la
/// correspondance des fonds du dock.
///
/// [bascule] renseigne : c'est une bascule (Micro, Camera), son etat se lit
/// par le disque (plein / contour), l'icone et le mot d'etat [libelle]
/// (ETATS-BTN-1).
class BoutonAppel extends StatelessWidget {
  const BoutonAppel({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.libelleSemantique,
    this.fond = FondBoutonAppel.surface,
    this.actif = true,
    this.bascule,
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
  /// pendant la reconnexion, lot CL-7, UX_REVIEW U1).
  final bool actif;

  /// `null` : bouton ordinaire. Sinon l'etat de la bascule (vrai : active).
  final bool? bascule;

  @override
  Widget build(BuildContext context) => CommandeSalle(
    icone: icone,
    libelle: libelle,
    libelleSemantique: libelleSemantique,
    onPress: onPress,
    actif: actif,
    bascule: bascule,
    focusNode: focusNode,
    selectionne: selectionne,
    fond: switch (fond) {
      FondBoutonAppel.surface => FondCommande.surface,
      FondBoutonAppel.alerte => FondCommande.alerte,
      FondBoutonAppel.succes => FondCommande.succes,
      FondBoutonAppel.primaire => FondCommande.primaire,
      FondBoutonAppel.reseau => FondCommande.reseau,
    },
  );
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
          bascule: cameraAllumee,
          // Le mot d'etat sous l'icone (ETATS-BTN-1) ; la reconnexion garde
          // le nom de la commande, qu'elle dit indisponible.
          libelle: cameraAllumee ? t.salle.cameraAllumee : t.salle.cameraCoupee,
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
    final List<Widget> boutons = <Widget>[];
    // Une bascule (Micro, Camera) porte son mot d'etat : sa case est plus
    // large que celle d'une commande ordinaire (ETATS-BTN-1).
    final List<bool> bascules = <bool>[];
    for (final CommandeDock commande in vue.commandesDock) {
      // Enseignant desktop (image CLV-06) : un filet vertical avant Quitter.
      if (large &&
          commande == CommandeDock.quitter &&
          vue.quitterOuvreCahier &&
          actions.onQuitter != null) {
        boutons.add(_Separateur(hauteur: diametreBoutonAppel(context)));
        bascules.add(false);
      }
      final Widget? bouton = _bouton(context, commande);
      if (bouton == null) continue;
      boutons.add(bouton);
      bascules.add(
        commande == CommandeDock.micro || commande == CommandeDock.camera,
      );
    }
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints contraintes) {
              final Widget rangee = Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // Chaque bouton prend une part egale ; le mot d'etat d'une
                // bascule passe a la ligne dans sa part.
                children: <Widget>[
                  for (int i = 0; i < boutons.length; i++)
                    Expanded(child: boutons[i]),
                ],
              );
              if (boutons.isEmpty) return rangee;
              final double diametre = diametreBoutonAppel(contexte);
              final double parCase = contraintes.maxWidth / boutons.length;
              final bool serre = parCase < diametre + AppSpacing.sm;
              final bool texteAgrandi =
                  MediaQuery.textScalerOf(contexte).scale(1) > 1;
              if (!serre && !texteAgrandi) return rangee;
              // EN-12 (17 d) : icone seule, libelle lu ; disque a la case
              // moins un ecart, jamais sous la cible tactile.
              final double cible = AppMetriques.of(contexte).cibleTactile;
              // UX_REVIEW_04 n. 17 d, WCAG 1.4.10 : quand la part egale
              // tombe sous la cible (320), les boutons ne se partagent plus
              // la largeur ; ils passent sur deux lignes, en cases fixes, et
              // chaque disque garde la cible tactile.
              if (parCase < cible + AppSpacing.xs) {
                return CommandeSalleCompacte(
                  diametre: cible,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (int i = 0; i < boutons.length; i++)
                        SizedBox(
                          width: bascules[i]
                              ? largeurCaseCommande(contexte, bascule: true)
                              : cible + AppSpacing.xs,
                          child: Center(child: boutons[i]),
                        ),
                    ],
                  ),
                );
              }
              final double reduit = math.max(
                math.min(diametre, parCase - AppSpacing.xs),
                cible,
              );
              return CommandeSalleCompacte(diametre: reduit, child: rangee);
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
    // Le mot d'etat (ETATS-BTN-1) : « Micro ouvert » / « Micro coupe », en
    // standard comme en guidee ; le nom de la commande (« Micro », « Parler »
    // en guidee) reste dit par l'indisponibilite (reconnexion) et par l'acte
    // lu.
    final String libelle = ouvert ? t.salle.microOuvert : t.salle.microCoupe;
    return BoutonAppel(
      key: const ValueKey<String>('bouton-micro'),
      focusNode: _focus,
      icone: colore
          ? (ouvert ? AppIcons.micro : AppIcons.microCoupe).actif
          : (ouvert ? AppIcons.micro : AppIcons.microCoupe).repos,
      bascule: ouvert,
      libelle: libelle,
      libelleSemantique:
          vue.libelleIndisponible(colore ? t.salle.seance.parler : t.salle.micro) ??
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
