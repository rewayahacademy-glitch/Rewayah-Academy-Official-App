// S0.2c (pilote, 24/10/2026, loi du directeur) : « Sur telephone, la page du
// Coran EST l'ecran. Une page A4 = un ecran de smartphone. Rien au-dessus,
// rien en dessous, rien a cote. »
//
// La composition du telephone (portrait et couche) dans `/salle`
// ([PorteeMediaSalle.pleinCadre]) : la page bord a bord, sans carte, sans
// arrondi, sans ombre ; tout le reste en surimpression sur la scene, dans
// l'espace libre au-dessus et au-dessous de la page (portrait) ou a cote
// d'elle (couche), masque au delai par [CommandesMasquables]. Rien de neuf :
// la page est [SurfacePageFixe], les commandes [DockSeance] et
// [DeclencheurCommandes], le panneau [CommandesPedagogiques], la mention
// [MentionSeance], la vignette [VignetteVideo].

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessibilite/commandes_masquables.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_pill.dart';
import 'actions_seance.dart';
import 'commandes_pedagogiques.dart';
import 'dock_seance.dart';
import 'media_salle.dart';
import 'mention_seance.dart';
import 'salle_seance.dart' show BandeauSecours, EtatLocalSeance;
import 'surface_page_fixe.dart';
import 'vignette_video.dart';
import 'vue_seance.dart';
import 'zone_support.dart' show ZoneSupport, ratioSurface, surfaceAMontrer;

/// Vrai quand `/salle` est sur un telephone (portrait ou couche) : la page
/// devient l'ecran.
bool telephonePleinEcran(BuildContext context) =>
    (PorteeMediaSalle.de(context)?.pleinCadre ?? false) &&
    MediaQuery.sizeOf(context).shortestSide < AppGabarit.seuilTablette;

/// La vignette flottante du telephone (≈ 96 de large).
const double largeurVignetteTelephone = AppSpacing.respiration * 1.5;

/// La largeur d'un cote libre en dessous de laquelle les surimpressions ne
/// s'y posent pas (couche) : elles passent en haut et en bas.
const double _coteLibreMinimal = AppSpacing.respiration * 3;

/// Sans ratio connu, celui d'une page A4 en portrait.
const double _ratioA4 = 1000 / 1414;

/// La salle au telephone : la page est l'ecran.
class TelephonePleinEcran extends StatelessWidget {
  const TelephonePleinEcran({
    required this.vue,
    required this.actions,
    required this.local,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// La cle de la page bord a bord (tests, captures).
  static const Key clePage = ValueKey<String>('telephone-page');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final VueSurface? surface = surfaceAMontrer(vue);
    final Widget? laScene = media?.scene;
    final bool scene =
        laScene != null &&
        ((media?.scenePremierPlan ?? false) || surface == null);
    final bool panneau = vue.panneau == PanneauOuvert.commandes;
    return Material(
      color: palette.surfaceCanvas.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final Size ecran = c.biggest;
          final double ratio = ratioSurface(vue) ?? _ratioA4;
          // La page en `contain` sur tout l'ecran : toute la largeur en
          // portrait, toute la hauteur couche.
          final Size page = ecran.width / ratio <= ecran.height
              ? Size(ecran.width, ecran.width / ratio)
              : Size(ecran.height * ratio, ecran.height);
          final double cote = (ecran.width - page.width) / 2;
          final bool aCote = !scene && cote >= _coteLibreMinimal;
          final double largeurRangee = aCote
              ? cote - AppSpacing.sm
              : ecran.width;
          // La scene video passe par [ZoneSupport] : « Revenir a la page »
          // et « Ouvrir le Coran » y vivent, sous la ligne du haut.
          final Widget fond = laScene != null && scene
              ? const SizedBox.shrink()
              : Center(
                  child: SizedBox.fromSize(
                    key: clePage,
                    size: page,
                    // La page et ses notes restent claires (meme regle que
                    // la carte de la surface).
                    child: Theme(
                      data: AppTheme.pour(
                        InterfaceMode.standard,
                        Brightness.light,
                      ),
                      child: SurfacePageFixe(
                        vue: vue,
                        surface: surface!,
                        zoom: local.zoom,
                      ),
                    ),
                  ),
                );
          final Widget haut = _Haut(
            vue: vue,
            actions: actions,
            largeur: largeurRangee,
            vignette: !scene && vue.voitVignetteSurSupport,
            aCote: aCote,
          );
          final Widget bas = Align(
            alignment: aCote
                ? AlignmentDirectional.bottomStart
                : Alignment.bottomCenter,
            child: SizedBox(
              width: largeurRangee,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _Bas(vue: vue, actions: actions, local: local),
              ),
            ),
          );
          return CommandesMasquables(
            delai: AppMouvement.masquageSalle,
            maintenir: vue.visioMaintenue || panneau,
            libelleEntree: t.salle.seance.commandesAppel,
            contenu: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Sans page (scene video en grand), il n'y a rien a
                // proteger : le haut se pose au-dessus de la scene, qui passe
                // par [ZoneSupport] (« Revenir a la page », « Ouvrir le
                // Coran »).
                if (scene)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      haut,
                      Expanded(
                        child: SafeArea(
                          top: false,
                          child: ZoneSupport(vue: vue, zoom: local.zoom),
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  fond,
                  // Le haut : etat, presence, mention ; la vignette en coin.
                  PositionedDirectional(top: 0, start: 0, end: 0, child: haut),
                ],
                if (panneau)
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    end: AppSpacing.sm,
                    bottom: AppSpacing.respiration * 2,
                    child: _PanneauCommandes(
                      vue: vue,
                      actions: actions,
                      local: local,
                      hauteurMax: ecran.height * _partPanneau,
                    ),
                  ),
              ],
            ),
            commandes: bas,
          );
        },
      ),
    );
  }
}

/// La part maximale de l'ecran que prend le panneau des Commandes.
const double _partPanneau = 0.6;

/// Le haut de la scene : la ligne d'etat (En ligne, presence, mention), le
/// bandeau de secours s'il y a lieu, l'alerte (camera) ; la vignette en coin.
class _Haut extends StatelessWidget {
  const _Haut({
    required this.vue,
    required this.actions,
    required this.largeur,
    required this.vignette,
    required this.aCote,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final double largeur;
  final bool vignette;
  final bool aCote;

  @override
  Widget build(BuildContext context) {
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final Widget? pastille = media?.pastille;
    final Widget? alerte = media?.alerte;
    final double largeurLigne = math.max(
      0,
      aCote
          ? largeur
          : largeur - (vignette ? largeurVignetteTelephone + AppSpacing.md : 0),
    );
    final Widget ligne = SizedBox(
      width: largeurLigne,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                StatusPill(
                  libelle: vue.texteConnexion,
                  ton: vue.connexion.etablie
                      ? TonEtat.succes
                      : TonEtat.avertissement,
                ),
                ?pastille,
              ],
            ),
            Ecart.vXs,
            MentionSeance(vue: vue),
            BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
            ?alerte,
          ],
        ),
      ),
    );
    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Align(alignment: AlignmentDirectional.topStart, child: ligne),
          if (vignette)
            PositionedDirectional(
              top: AppSpacing.sm,
              end: AppSpacing.sm,
              child: VignetteVideo(vue: vue, largeur: largeurVignetteTelephone),
            ),
        ],
      ),
    );
  }
}

/// Le bas : les commandes rondes de l'appel, et chez l'enseignant
/// « Commandes » (pagination, zoom, outils).
class _Bas extends StatelessWidget {
  const _Bas({required this.vue, required this.actions, required this.local});

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? commandes = actions.onCommandes;
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      agrandi: local.agrandi,
    );
    if (commandes == null ||
        !CommandesPedagogiques.aDesEntrees(vue, actions) ||
        vue.panneau == PanneauOuvert.commandes) {
      return dock;
    }
    // Sur la meme rangee que l'appel, en icone seule : rien ne monte sur la
    // page.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: dock),
        Ecart.hSm,
        DeclencheurCommandes(onPress: commandes, iconeSeule: true),
      ],
    );
  }
}

/// Le panneau des Commandes de l'enseignant, pose sur la scene au-dessus des
/// commandes de l'appel ; il defile s'il ne tient pas.
class _PanneauCommandes extends StatelessWidget {
  const _PanneauCommandes({
    required this.vue,
    required this.actions,
    required this.local,
    required this.hauteurMax,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final double hauteurMax;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hauteurMax),
      child: DecoratedBox(
        key: const ValueKey<String>('telephone-commandes'),
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiLg,
          side: palette.borderHairline.asBorderSide(),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CommandesPedagogiques(
            vue: vue,
            actions: actions,
            zoom: local.zoom,
            agrandi: local.agrandi,
          ),
        ),
      ),
    );
  }
}
