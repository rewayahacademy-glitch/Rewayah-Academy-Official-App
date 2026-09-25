// La salle de seance unique (plan de code section 2).
//
// Un gabarit, parametre par la `VueSeance` du role effectif : plein ecran,
// sans barre d'application (I-8). Dispositions par `Gabarit` : compacte
// (< 600), moyenne (600-1199), large (>= 1200).

import 'package:flutter/material.dart';

import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'chrome_seance.dart';
import 'dock_seance.dart';
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
            if (local.agrandi)
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
                    ),
            ),
          ],
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
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
