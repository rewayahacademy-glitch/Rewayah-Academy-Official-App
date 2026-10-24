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
import 'zone_support.dart' show ZoneSupport, surfaceAMontrer;

/// Vrai quand `/salle` est sur un telephone (portrait ou couche) : la page
/// devient l'ecran.
bool telephonePleinEcran(BuildContext context) =>
    (PorteeMediaSalle.de(context)?.pleinCadre ?? false) &&
    MediaQuery.sizeOf(context).shortestSide < AppGabarit.seuilTablette;

/// La vignette flottante du telephone (≈ 96 de large).
const double largeurVignetteTelephone = AppSpacing.respiration * 1.5;

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
          // S0.2d (directeur, 24/10/2026) : « Full screen, full body, no
          // bezels. » Au telephone, la page n'est plus au ratio A4 : son cadre
          // EST l'ecran, largeur et hauteur, zero marge. La page Madina se
          // compose sur cette place (`PageMadina15`, interligne libre). Les
          // notes gardent le repere de cette page (coordonnees normalisees).
          final SupportPageFixe? support = vue.supportPresente;
          final VueSeance vuePage = support == null
              // S0.3 : le tableau blanc prend lui aussi tout l'ecran.
              ? (vue.tableauLibre == null
                    ? vue
                    : vue.copyWith(
                        tableauLibre: TableauLibre(
                          largeurCanonique: math.max(1, ecran.width.round()),
                          hauteurCanonique: math.max(1, ecran.height.round()),
                          aDesNotes: vue.tableauLibre!.aDesNotes,
                        ),
                      ))
              : vue.copyWith(
                  supportPresente: SupportPageFixe(
                    id: support.id,
                    version: support.version,
                    titre: support.titre,
                    page: support.page,
                    total: support.total,
                    largeurCanonique: math.max(1, ecran.width.round()),
                    hauteurCanonique: math.max(1, ecran.height.round()),
                    mention: support.mention,
                    cleImage: support.cleImage,
                  ),
                );
          final Widget? page = scene || surface == null
              ? null
              : SizedBox.fromSize(
                  key: clePage,
                  size: ecran,
                  // La page et ses notes restent claires (meme regle que la
                  // carte de la surface).
                  child: Theme(
                    data: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    child: SurfacePageFixe(
                      vue: vuePage,
                      surface: surface,
                      zoom: local.zoom,
                    ),
                  ),
                );
          final Widget haut = _Haut(
            vue: vue,
            actions: actions,
            largeur: ecran.width,
            vignette: !scene && vue.voitVignetteSurSupport,
            aCote: false,
          );
          final Widget bas = Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _Bas(vue: vue, actions: actions, local: local),
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
                if (page == null)
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
                else
                  page,
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
            // Sur la page, tout flotte et disparait ensemble au delai : la
            // ligne d'etat et la vignette en haut, les commandes en bas. Les
            // zones vides laissent passer le toucher vers la page.
            commandes: page == null
                ? bas
                : SizedBox.fromSize(
                    size: ecran,
                    child: Stack(
                      children: <Widget>[
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          child: haut,
                        ),
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: SafeArea(top: false, child: bas),
                        ),
                      ],
                    ),
                  ),
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
    // S0.2d : la ligne flotte sur la page ; elle porte sa propre surface
    // (comme la barre des commandes) pour se lire sur le papier.
    final Widget ligne = SizedBox(
      width: largeurLigne,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: DecoratedBox(
          decoration: AppPalette.of(context).surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiLg,
            side: AppPalette.of(context).borderHairline.asBorderSide(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
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
