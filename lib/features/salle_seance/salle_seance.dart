// La salle de seance unique (plan de code section 2).
//
// Un gabarit, parametre par la `VueSeance` du role effectif : plein ecran,
// sans barre d'application (I-8). Dispositions par `Gabarit` : compacte
// (< 600), moyenne (600-1199), large (>= 1200).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'chrome_seance.dart';
import 'dock_seance.dart';
import 'outils_enseignement.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart';
import 'panneau_supports.dart';
import 'rail_seance.dart';
import 'vue_seance.dart';
import 'zone_support.dart';

/// L'etat local de l'appareil : il ne publie rien vers les autres.
@immutable
class EtatLocalSeance {
  const EtatLocalSeance({
    this.microOuvert = true,
    this.cameraAllumee = true,
    this.zoom = 1,
    this.agrandi = false,
  });

  final bool microOuvert;
  final bool cameraAllumee;

  /// Le zoom local du support (1 = 100 %).
  final double zoom;

  /// Le support occupe l'ecran : l'en-tete se retire (Agrandir).
  final bool agrandi;
}

/// La salle : en-tete, support dominant, vignette, dock et barre basse.
class SalleSeance extends StatelessWidget {
  const SalleSeance({
    required this.vue,
    required this.actions,
    this.local = const EtatLocalSeance(),
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Gabarit gabarit = AppGabarit.de(context);
    final bool large = gabarit == Gabarit.desktop;
    if (vue.role == RoleSeance.enseignant) {
      // Telephone, panneau ouvert : la feuille descend jusqu'au bord de
      // l'ecran (image) ; elle garde elle-meme la marge du systeme.
      final bool feuilleOuverte =
          gabarit == Gabarit.mobile &&
          vue.voitBoutonsPanneaux &&
          vue.panneau != PanneauOuvert.aucun;
      return Material(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
          bottom: !feuilleOuverte,
          child: _SalleEnseignant(
            vue: vue,
            actions: actions,
            local: local,
            gabarit: gabarit,
          ),
        ),
      );
    }
    // Sans support, rien a agrandir : l'etat local est ignore.
    final bool agrandi = local.agrandi && vue.support != null;
    // Gouttiere : 16 au telephone et en web etroit (images), 32 en desktop.
    final double gouttiere = large
        ? AppPage.gouttiereDesktop
        : AppPage.gouttiereMobile;
    // Plein cadre, sans coquille de page : ni titre d'ecran, ni colonne
    // bornee (CONTENT > CHROME). Le fond reste celui du theme (clair et
    // sombre), comme sur les images, et non le registre inverse.
    return Material(
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (agrandi)
              Ecart.vLg
            else ...<Widget>[
              ChromeSeance(vue: vue, actions: actions),
              if (!large) Ecart.vLg,
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gouttiere),
                child: ZoneSupport(vue: vue, zoom: local.zoom),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: gouttiere,
                end: gouttiere,
                top: large ? AppSpacing.xl : AppSpacing.lg,
                bottom: large ? AppSpacing.xl : AppSpacing.md,
              ),
              child: large
                  ? _BarreBasse(vue: vue, actions: actions, local: local)
                  : DockSeance(
                      vue: vue,
                      actions: actions,
                      microOuvert: local.microOuvert,
                      cameraAllumee: local.cameraAllumee,
                      agrandi: agrandi,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La salle de l'enseignant (CLV-06) : rail (desktop), outils, boutons
/// Eleves et Supports, support dominant, pagination active et zoom (desktop),
/// dock Micro, Camera, Reseau, Quitter. Jamais Agrandir.
class _SalleEnseignant extends StatelessWidget {
  const _SalleEnseignant({
    required this.vue,
    required this.actions,
    required this.local,
    required this.gabarit,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;

  @override
  Widget build(BuildContext context) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool outils = vue.voitOutils && actions.onOutil != null;
    // Telephone et desktop : le support partage la hauteur avec les boutons
    // et les outils, il se resserre pour montrer la diapositive entiere.
    final Widget support = ZoneSupport(vue: vue, zoom: local.zoom, serre: true);
    final Widget? boutons = _BoutonsPanneaux.ou(vue, actions, gabarit);
    final Widget? panneau = _panneau();
    if (panneau != null) {
      return gabarit == Gabarit.desktop
          ? _avecRail(
              _desktopAvecPanneau(
                context,
                panneau: panneau,
                support: support,
                outils: outils,
              ),
            )
          : _etroitAvecPanneau(panneau: panneau, support: support);
    }
    switch (gabarit) {
      case Gabarit.desktop:
        final SupportSeance? page = vue.support;
        final Widget contenu = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChromeSeance(vue: vue, actions: actions),
            if (outils || boutons != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  gouttiere,
                  0,
                  gouttiere,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (outils)
                      OutilsEnseignement(
                        onOutil: actions.onOutil,
                        forme: FormeOutils.rangee,
                      ),
                    const Spacer(),
                    ?boutons,
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: support,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                gouttiere,
                AppSpacing.xxl,
                gouttiere,
                AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: page != null && vue.voitPaginationActive(gabarit)
                          ? PaginationSupport(
                              page: page.page,
                              pages: page.pages,
                              onPrecedente: actions.onPagePrecedente,
                              onSuivante: actions.onPageSuivante,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  DockSeance(
                    vue: vue,
                    actions: actions,
                    microOuvert: local.microOuvert,
                    cameraAllumee: local.cameraAllumee,
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: vue.voitZoomLocal(gabarit)
                          ? Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.respiration,
                              ),
                              child: ZoomLocal(
                                zoom: local.zoom,
                                onMoins: actions.onZoomMoins,
                                onPlus: actions.onZoomPlus,
                                avecLibelle: false,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        return _avecRail(contenu);
      case Gabarit.tablette:
      case Gabarit.mobile:
        final bool mobile = gabarit == Gabarit.mobile;
        // Telephone : les ecarts entre les rangees se resserrent d'un
        // palier, la place revient au support (image mobile, enseignant).
        final Widget ecart = mobile ? Ecart.vSm : Ecart.vMd;
        final double ecartDock = mobile ? AppSpacing.sm : AppSpacing.md;
        final Widget milieu = mobile || !outils
            ? support
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: support),
                  Ecart.hMd,
                  OutilsEnseignement(
                    onOutil: actions.onOutil,
                    forme: FormeOutils.colonne,
                  ),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChromeSeance(vue: vue, actions: actions),
            ecart,
            if (boutons != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: boutons,
              ),
              ecart,
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: milieu,
              ),
            ),
            if (mobile && outils) ...<Widget>[
              ecart,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: OutilsEnseignement(
                  onOutil: actions.onOutil,
                  forme: FormeOutils.rangee,
                ),
              ),
            ],
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gouttiere,
                ecartDock,
                gouttiere,
                ecartDock,
              ),
              child: DockSeance(
                vue: vue,
                actions: actions,
                microOuvert: local.microOuvert,
                cameraAllumee: local.cameraAllumee,
              ),
            ),
          ],
        );
    }
  }

  /// Desktop : le rail enseignant a gauche, s'il a un rappel.
  Widget _avecRail(Widget contenu) {
    final ValueChanged<String>? naviguer = actions.onNaviguer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (vue.voitRail(gabarit) && naviguer != null)
          RailSeance(onNaviguer: naviguer, groupeId: vue.groupeId),
        Expanded(child: contenu),
      ],
    );
  }

  /// Le panneau ouvert, ou `null`. Enseignant seulement : ce widget n'est
  /// construit que pour `RoleSeance.enseignant`, et la vue le confirme.
  Widget? _panneau() {
    if (!vue.voitBoutonsPanneaux) return null;
    final FormePanneau forme = FormePanneau.pour(gabarit);
    return switch (vue.panneau) {
      PanneauOuvert.aucun => null,
      PanneauOuvert.eleves => PanneauSeance(
        titre: t.salle.seance.eleves,
        onFermer: actions.onEleves,
        forme: forme,
        enfant: PanneauEleves(
          eleves: vue.eleves,
          actions: actions,
          large: forme == FormePanneau.colonne,
        ),
      ),
      PanneauOuvert.supports => PanneauSeance(
        titre: t.salle.seance.supports,
        onFermer: actions.onSupports,
        forme: forme,
        enfant: PanneauSupports(
          supports: vue.supports,
          actions: actions,
          forme: forme,
        ),
      ),
    };
  }

  /// Desktop, panneau ouvert (CLV-07, CLV-08) : panneau a gauche, support au
  /// centre, colonne droite (Eleves et Supports, puis carte des outils, Q2) ;
  /// pagination, dock et zoom sous le support seulement.
  Widget _desktopAvecPanneau(
    BuildContext context, {
    required Widget panneau,
    required Widget support,
    required bool outils,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final SupportSeance? page = vue.support;
    // CLV-08 : carte des outils en tete de la colonne droite, puis Eleves et
    // Supports en liste ; sous le support, dock puis pagination et zoom.
    final bool supports = vue.panneau == PanneauOuvert.supports;
    final Widget? boutons = _BoutonsPanneaux.ou(
      vue,
      actions,
      gabarit,
      etire: true,
      serre: true,
      enColonne: supports,
    );
    final Widget? carteOutils = outils
        // Images CLV-07 et CLV-08 : aucun outil selectionne.
        ? OutilsEnseignement(
            onOutil: actions.onOutil,
            forme: FormeOutils.carte,
            initial: null,
          )
        : null;
    final Widget? pagination = page != null && vue.voitPaginationActive(gabarit)
        ? PaginationSupport(
            page: page.page,
            pages: page.pages,
            onPrecedente: actions.onPagePrecedente,
            onSuivante: actions.onPageSuivante,
          )
        : null;
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
    );
    final Widget? zoom = vue.voitZoomLocal(gabarit)
        ? ZoomLocal(
            zoom: local.zoom,
            onMoins: actions.onZoomMoins,
            onPlus: actions.onZoomPlus,
            avecLibelle: false,
          )
        : null;
    if (supports) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChromeSeance(vue: vue, actions: actions),
          Ecart.vSm,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: gouttiere),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: largeurColonneSeance, child: panneau),
                  Ecart.hMd,
                  Expanded(child: support),
                  Ecart.hMd,
                  SizedBox(
                    width: largeurColonneDroiteSeance,
                    // Une seule carte haute comme le support : les outils,
                    // puis Eleves et Supports (image CLV-08).
                    child: outils
                        ? OutilsEnseignement(
                            onOutil: actions.onOutil,
                            forme: FormeOutils.carte,
                            initial: null,
                            pied: boutons,
                          )
                        : Column(children: <Widget>[?boutons]),
                  ),
                ],
              ),
            ),
          ),
          // Image CLV-08 : le dock part sous le debut du support, pagination
          // et zoom a sa droite.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              gouttiere + largeurPanneauSeance,
              AppSpacing.xl,
              gouttiere,
              AppSpacing.lg,
            ),
            // A 1200 de large (bas du gabarit desktop), la rangee se reduit
            // d'un bloc plutot que de deborder.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xl,
                children: <Widget>[dock, ?pagination, ?zoom],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChromeSeance(vue: vue, actions: actions),
        Ecart.vSm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: largeurColonneSeance, child: panneau),
                Ecart.hMd,
                Expanded(child: support),
                Ecart.hMd,
                SizedBox(
                  width: largeurColonneDroiteSeance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ?boutons,
                      if (carteOutils != null) ...<Widget>[
                        Ecart.vLg,
                        carteOutils,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // La barre basse part juste apres le bas du panneau (image : ≈ 580
        // a 1440 de large), la ou la colonne elargie laisse sa place.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            gouttiere + largeurPanneauSeance,
            AppSpacing.xl,
            gouttiere,
            AppSpacing.lg,
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: <Widget>[?pagination, dock, ?zoom],
          ),
        ),
      ],
    );
  }

  /// Web etroit et telephone, panneau ouvert : le panneau recouvre le
  /// support (volet a gauche, ou feuille du bas qui laisse voir le haut du
  /// support et la vignette). Les boutons Eleves et Supports et les outils
  /// se retirent : le panneau les remplace (images CLV-07-08-10).
  Widget _etroitAvecPanneau({
    required Widget panneau,
    required Widget support,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool mobile = gabarit == Gabarit.mobile;
    final double ecartDock = mobile ? AppSpacing.sm : AppSpacing.md;
    Widget dessous(double largeurVolet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: support,
          ),
        ),
        Padding(
          // Web etroit : le dock se centre a droite du volet (image).
          padding: EdgeInsetsDirectional.fromSTEB(
            mobile ? gouttiere : largeurVolet + AppSpacing.sm + AppSpacing.xs,
            ecartDock,
            mobile ? gouttiere : AppSpacing.sm,
            ecartDock,
          ),
          child: Align(
            child: DockSeance(
              vue: vue,
              actions: actions,
              microOuvert: local.microOuvert,
              cameraAllumee: local.cameraAllumee,
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChromeSeance(vue: vue, actions: actions),
        mobile ? Ecart.vSm : Ecart.vMd,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints c) {
              // Volet : au plus la moitie de la largeur, moins un palier, pour
              // laisser au dock toute sa place a droite (image : ≈ 313).
              final double largeurVolet = math.min(
                largeurPanneauSeance,
                c.maxWidth / 2 - AppSpacing.lg,
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(child: dessous(largeurVolet)),
                  if (mobile)
                    Positioned.fill(
                      top: supportVisibleSousFeuille,
                      child: panneau,
                    )
                  else
                    // Le volet descend jusqu'au bas de l'ecran (image).
                    PositionedDirectional(
                      start: AppSpacing.sm,
                      top: 0,
                      bottom: 0,
                      width: largeurVolet,
                      child: panneau,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// « Eleves 1/3 › » et « Supports › » : enseignant seulement. Desktop :
/// deux boutons a droite de la rangee d'outils ; ailleurs, deux boutons de
/// meme largeur au-dessus du support.
class _BoutonsPanneaux extends StatelessWidget {
  const _BoutonsPanneaux({
    required this.compteur,
    required this.onEleves,
    required this.onSupports,
    required this.etire,
    this.serre = false,
    this.enColonne = false,
  });

  static Widget? ou(
    VueSeance vue,
    ActionsSeance actions,
    Gabarit gabarit, {
    bool? etire,
    bool serre = false,
    bool enColonne = false,
  }) {
    final String? compteur = vue.compteurEleves;
    if (!vue.voitBoutonsPanneaux || compteur == null) return null;
    if (actions.onEleves == null && actions.onSupports == null) return null;
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: actions.onEleves,
      onSupports: actions.onSupports,
      etire: etire ?? gabarit != Gabarit.desktop,
      serre: serre,
      enColonne: enColonne,
    );
  }

  final String compteur;
  final VoidCallback? onEleves;
  final VoidCallback? onSupports;
  final bool etire;

  /// Desktop, panneau ouvert : colonne droite etroite (CLV-07).
  final bool serre;

  /// Desktop, panneau Supports : l'un sous l'autre, pleine largeur (CLV-08).
  final bool enColonne;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? eleves = onEleves;
    final VoidCallback? supports = onSupports;
    final List<Widget> boutons = <Widget>[
      if (eleves != null)
        BoutonPanneau(
          key: const ValueKey<String>('bouton-eleves'),
          icone: AppIcons.eleves,
          libelle: compteur,
          onPress: eleves,
          etire: etire,
          serre: serre,
        ),
      if (supports != null)
        BoutonPanneau(
          key: const ValueKey<String>('bouton-supports'),
          icone: AppIcons.supports,
          libelle: t.salle.seance.supports,
          onPress: supports,
          etire: etire,
          serre: serre,
        ),
    ];
    if (enColonne) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: boutons,
      );
    }
    return Row(
      mainAxisSize: etire ? MainAxisSize.max : MainAxisSize.min,
      spacing: AppSpacing.md,
      children: <Widget>[
        for (final Widget b in boutons) etire ? Expanded(child: b) : b,
      ],
    );
  }
}

/// Un bouton compact de la salle : icone, libelle, chevron ›.
class BoutonPanneau extends StatelessWidget {
  const BoutonPanneau({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.etire = false,
    this.serre = false,
    super.key,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;

  /// Largeur imposee (telephone, web etroit) : le chevron va au bout.
  final bool etire;

  /// Icones et ecarts resserres (colonne droite desktop, CLV-07).
  final bool serre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Widget texte = Text(
      libelle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: palette.inkStrong.applyTo(
        Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
      ),
    );
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: DecoratedBox(
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiMd,
          side: palette.borderHairline.asBorderSide(),
        ),
        child: SizedBox(
          // Telephone et web etroit : plus bas et plus serre (images).
          height: etire
              ? AppSpacing.titreEcran
              : AppSpacing.titreEcran + AppSpacing.xs,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: etire ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(
                    size: serre ? AppSpacing.xl : AppSpacing.xxl,
                  ),
                  child: Icon(icone.repos),
                ),
                if (serre) Ecart.hSm else Ecart.hMd,
                if (etire) Expanded(child: texte) else texte,
                if (serre) Ecart.hXs else if (etire) Ecart.hSm else Ecart.hLg,
                IconTheme(
                  data: palette.inkMuted.asIconTheme(
                    size: serre ? AppSpacing.lg : AppSpacing.xl,
                  ),
                  child: Icon(AppIcons.chevron.repos),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop : indicateur a gauche, dock au centre, zoom local a droite.
class _BarreBasse extends StatelessWidget {
  const _BarreBasse({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) {
    const Gabarit gabarit = Gabarit.desktop;
    final SupportSeance? support = vue.support;
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: support != null && vue.voitIndicateurPage(gabarit)
                ? IndicateurPage(page: support.page, pages: support.pages)
                : const SizedBox.shrink(),
          ),
        ),
        DockSeance(
          vue: vue,
          actions: actions,
          microOuvert: local.microOuvert,
          cameraAllumee: local.cameraAllumee,
          agrandi: local.agrandi && support != null,
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: vue.voitZoomLocal(gabarit)
                ? ZoomLocal(
                    zoom: local.zoom,
                    onMoins: actions.onZoomMoins,
                    onPlus: actions.onZoomPlus,
                    onAgrandir: actions.onAgrandir,
                    agrandi: local.agrandi,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
