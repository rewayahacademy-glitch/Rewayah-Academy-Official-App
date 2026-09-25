// La salle de seance unique (plan de code section 2).
//
// Un gabarit, parametre par la `VueSeance` du role effectif : plein ecran,
// sans barre d'application (I-8). Dispositions par `Gabarit` : compacte
// (< 600), moyenne (600-1199), large (>= 1200).

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
import 'panneau_seance.dart';
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
      return Material(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
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
    final Widget support = ZoneSupport(vue: vue, zoom: local.zoom);
    final Widget? boutons = _BoutonsPanneaux.ou(vue, actions, gabarit);
    final Widget? panneau = _panneau();
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (panneau != null) ...<Widget>[
                      SizedBox(width: largeurPanneauSeance, child: panneau),
                      Ecart.hLg,
                    ],
                    Expanded(child: support),
                  ],
                ),
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
        final ValueChanged<String>? naviguer = actions.onNaviguer;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (vue.voitRail(gabarit) && naviguer != null)
              RailSeance(onNaviguer: naviguer, groupeId: vue.groupeId),
            Expanded(child: contenu),
          ],
        );
      case Gabarit.tablette:
      case Gabarit.mobile:
        final bool mobile = gabarit == Gabarit.mobile;
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
            Ecart.vMd,
            if (boutons != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: boutons,
              ),
              Ecart.vMd,
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: milieu),
                    // Web etroit : volet a gauche, par-dessus le support
                    // (I-8) ; telephone : feuille depuis le bas.
                    if (panneau != null)
                      if (mobile)
                        Positioned.fill(
                          top: AppSpacing.respiration * 2,
                          child: panneau,
                        )
                      else
                        PositionedDirectional(
                          start: 0,
                          top: 0,
                          bottom: 0,
                          width: largeurPanneauSeance,
                          child: panneau,
                        ),
                  ],
                ),
              ),
            ),
            if (mobile && outils) ...<Widget>[
              Ecart.vMd,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: OutilsEnseignement(
                  onOutil: actions.onOutil,
                  forme: FormeOutils.rangee,
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                gouttiere,
                AppSpacing.md,
                gouttiere,
                AppSpacing.md,
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

  /// Le panneau ouvert (cadre seul en T4), ou `null`.
  Widget? _panneau() => switch (vue.panneau) {
    PanneauOuvert.aucun => null,
    PanneauOuvert.eleves => PanneauSeance(
      titre: vue.compteurEleves ?? '',
      onFermer: actions.onEleves,
    ),
    PanneauOuvert.supports => PanneauSeance(
      titre: t.salle.seance.supports,
      onFermer: actions.onSupports,
    ),
  };
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
  });

  static Widget? ou(VueSeance vue, ActionsSeance actions, Gabarit gabarit) {
    final String? compteur = vue.compteurEleves;
    if (!vue.voitBoutonsPanneaux || compteur == null) return null;
    if (actions.onEleves == null && actions.onSupports == null) return null;
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: actions.onEleves,
      onSupports: actions.onSupports,
      etire: gabarit != Gabarit.desktop,
    );
  }

  final String compteur;
  final VoidCallback? onEleves;
  final VoidCallback? onSupports;
  final bool etire;

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
        ),
      if (supports != null)
        BoutonPanneau(
          key: const ValueKey<String>('bouton-supports'),
          icone: AppIcons.supports,
          libelle: t.salle.seance.supports,
          onPress: supports,
          etire: etire,
        ),
    ];
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
    super.key,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;

  /// Largeur imposee (telephone, web etroit) : le chevron va au bout.
  final bool etire;

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
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(icone.repos),
                ),
                Ecart.hMd,
                if (etire) Expanded(child: texte) else texte,
                if (etire) Ecart.hSm else Ecart.hLg,
                IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
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
