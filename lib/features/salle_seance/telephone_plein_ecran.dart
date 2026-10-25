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
//
// K4 (directeur, 25/10/2026) : la meme composition sur ordinateur et
// tablette ([pleinEcranSalle]). La page se compose sur la hauteur de la
// fenetre ([boitePagePleinEcran]) ; la pilule d'etat et « Eleves » en haut a
// gauche, la vignette en haut a droite, la pilule d'appel en bas au centre,
// les Commandes ouvertes et la palette du tableau flottent au bord droit ;
// tout se masque a 3 s.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessibilite/commandes_masquables.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouton_icone.dart';
import '../tc_mushaf/fleches_page_mushaf.dart';
import '../tc_mushaf/page_madina_15.dart' show ratioHauteurPageMadina15;
import 'actions_seance.dart';
import 'commandes_pedagogiques.dart';
import 'dock_seance.dart';
import 'media_salle.dart';
import 'palette_tableau.dart';
import 'panneau_seance.dart' show largeurPanneauSeance;
import 'pilule_etat_salle.dart';
import 'salle_seance.dart' show BandeauSecours, EtatLocalSeance;
import 'surface_page_fixe.dart';
import 'vignette_video.dart';
import 'vue_seance.dart';
import 'zone_support.dart' show ZoneSupport, coteFlechesSalle, surfaceAMontrer;

/// K4 (directeur, 25/10/2026, essai en production sur ordinateur) : la loi
/// du telephone vaut pour l'ordinateur : « full screen, full body, no
/// bezels ; tout ce qui reste est superpose au-dessus et disparait ». Vrai
/// dans `/salle`, a toutes les largeurs : la page (ou le tableau) occupe la
/// fenetre, quatre bords ; aucun en-tete reserve, aucun panneau qui prend
/// de la place.
bool pleinEcranSalle(BuildContext context) =>
    PorteeMediaSalle.de(context)?.pleinCadre ?? false;

/// Vrai quand `/salle` est sur un telephone (portrait ou couche) : vignette
/// etroite, palette du tableau au-dessus de la pilule d'appel.
bool telephonePleinEcran(BuildContext context) =>
    pleinEcranSalle(context) &&
    MediaQuery.sizeOf(context).shortestSide < AppGabarit.seuilTablette;

/// Ordinateur et tablette : la page du Coran se compose sur toute la hauteur
/// de la fenetre ; sa largeur suit la composition (ratio du mushaf), jusqu'a
/// [plafondLargeurPage] fois cette largeur au plus, centree ; au-dela, des
/// marges vides. Au telephone, la page est l'ecran entier.
const double plafondLargeurPage = 1.4;

/// La boite de la page dans la fenetre [ecran] (voir [plafondLargeurPage]).
Size boitePagePleinEcran(Size ecran, {required bool telephone}) {
  if (telephone) return ecran;
  final double naturelle = ecran.height / ratioHauteurPageMadina15;
  return Size(
    math.min(ecran.width, naturelle * plafondLargeurPage),
    ecran.height,
  );
}

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
          final bool telephone = telephonePleinEcran(context);
          final Size boite = boitePagePleinEcran(ecran, telephone: telephone);
          // S0.2d (directeur, 24/10/2026) : « Full screen, full body, no
          // bezels. » Au telephone, la page n'est plus au ratio A4 : son cadre
          // EST l'ecran, largeur et hauteur, zero marge. La page Madina se
          // compose sur cette place (`PageMadina15`, interligne libre). Les
          // notes gardent le repere de cette page (coordonnees normalisees).
          final SupportPageFixe? support = vue.supportPresente;
          // S0.3, K4 : le tableau blanc prend toute la fenetre ; sa feuille
          // garde la forme fixe de la classe (16:9), ajustee sans etirement
          // ([TableauLibre.classe]).
          final VueSeance vuePage = support == null
              ? vue
              : vue.copyWith(
                  supportPresente: SupportPageFixe(
                    id: support.id,
                    version: support.version,
                    titre: support.titre,
                    page: support.page,
                    total: support.total,
                    largeurCanonique: math.max(1, boite.width.round()),
                    hauteurCanonique: math.max(1, boite.height.round()),
                    mention: support.mention,
                    cleImage: support.cleImage,
                  ),
                );
          final bool libre = support == null;
          final Widget? page = scene || surface == null
              ? null
              : SizedBox.fromSize(
                  key: clePage,
                  // Le tableau occupe la fenetre ; la page du Coran, sa boite.
                  size: libre ? ecran : boite,
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
          // Ordinateur : les grandes fleches de page (reference 4 du
          // directeur) dans les marges vides a cote de la page, quand elles y
          // tiennent : elles ne prennent rien a la page.
          final VoidCallback? precedente = media?.onPagePrecedente;
          final VoidCallback? suivante = media?.onPageSuivante;
          const double cote = coteFlechesSalle + AppSpacing.sm;
          final Widget? pageVue =
              page != null &&
                  !telephone &&
                  !libre &&
                  (precedente != null || suivante != null) &&
                  ecran.width >= boite.width + 2 * cote
              ? SizedBox(
                  // La page garde sa boite : chaque fleche prend son cote.
                  width: boite.width + 2 * coteFlechesSalle,
                  height: boite.height,
                  child: PageAvecFlechesMushaf(
                    key: const ValueKey<String>('fleches-page-salle'),
                    libellePrecedente: t.salle.seance.pagePrecedente,
                    libelleSuivante: t.salle.seance.pageSuivante,
                    onPrecedente: precedente,
                    onSuivante: suivante,
                    cote: coteFlechesSalle,
                    focusAuto: false,
                    child: page,
                  ),
                )
              : page;
          final Widget haut = _Haut(
            vue: vue,
            actions: actions,
            largeur: ecran.width,
            vignette: !scene && vue.voitVignetteSurSupport,
            aCote: !telephone,
          );
          final Widget bas = Padding(
            // Standard : marge 16 des bords (et la zone sure).
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _Bas(
              vue: vue,
              actions: actions,
              local: local,
              paletteAuDessus: telephone,
            ),
          );
          // Ordinateur : la palette du tableau, verticale au bord droit.
          final bool paletteADroite =
              !telephone && vue.tableauOuvert && actions.onTableau != null;
          // Ordinateur : les Commandes ouvertes flottent au bord droit, dans
          // la couche qui se masque a 3 s ; aucune carte pleine hauteur.
          final Widget? commandesADroite = !telephone && panneau
              ? _PanneauCommandes(
                  vue: vue,
                  actions: actions,
                  local: local,
                  hauteurMax: ecran.height * _partPanneau,
                )
              : null;
          return CommandesMasquables(
            delai: AppMouvement.masquageSalle,
            maintenir: vue.visioMaintenue || (panneau && telephone),
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
                  Center(child: pageVue),
                if (panneau && telephone)
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
                // Scene en grand (sans page) : les Commandes restent sur la
                // scene, au bord droit.
                if (page == null && commandesADroite != null)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: AppSpacing.lg,
                    child: Center(child: commandesADroite),
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
                        // Zoom de la page (directeur, 25/10/2026 : « aucune
                        // commande de zoom vue sur ordinateur ») : une pilule
                        // flottante au bord droit, - et +, icones seules ;
                        // Ctrl + molette et le pincement restent.
                        if (!libre &&
                            !paletteADroite &&
                            commandesADroite == null &&
                            (actions.onZoomPlus != null ||
                                actions.onZoomMoins != null))
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            end: AppSpacing.lg,
                            child: Center(child: _PiluleZoom(actions: actions)),
                          ),
                        if (paletteADroite || commandesADroite != null)
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            end: AppSpacing.lg,
                            child: Center(
                              child:
                                  commandesADroite ??
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: PaletteTableau(
                                      vue: vue,
                                      actions: actions,
                                      verticale: true,
                                    ),
                                  ),
                            ),
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
    final Widget? alerte = media?.alerte;
    final ({int nombre, VoidCallback onPress})? eleves = media?.boutonEleves;
    // Standard des commandes d'appel (24/10/2026) : une pilule translucide en
    // haut a gauche, hauteur 36 : « ● En ligne · Visite de controle
    // possible. » (ADR-011), seule sur sa rangee ; dessous, a droite, le
    // bouton rond « Eleves » et la vignette. Marge 16 des bords.
    // Section 6.6 : la presence de l'eleve (la sienne seulement), a cote de
    // la pilule d'etat.
    final Widget? presence = media?.pastille;
    final Widget pilule = PiluleEtatSalle(
      vue: vue,
      largeurMax: math.max(
        0,
        aCote
            // Ordinateur : la pilule partage sa rangee avec « Eleves » et la
            // vignette.
            ? largeur / 2
            : largeur - 2 * AppSpacing.lg,
      ),
      cle: const ValueKey<String>('ligne-etat-telephone'),
    );
    final Widget ligne = presence == null
        ? pilule
        // Texte agrandi, ecran etroit : la presence passe sous la pilule.
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[pilule, presence],
          );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // K4 (ordinateur, 25/10/2026) : une rangee ; la pilule d'etat et
            // « Eleves » a sa droite, en haut a gauche ; la vignette en haut a
            // droite.
            if (aCote)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  Flexible(child: ligne),
                  if (eleves != null)
                    _BoutonEleves(
                      nombre: eleves.nombre,
                      onPress: eleves.onPress,
                    ),
                  const Spacer(),
                  if (vignette)
                    VignetteVideo(
                      vue: vue,
                      largeur: MesuresVignette.largeurPleinCadreLarge,
                    ),
                ],
              )
            // Arbitrage du pilote (24/10/2026) : la pilule d'etat occupe seule
            // la premiere rangee, a gauche, phrase entiere ; Eleves et la
            // vignette descendent sur une seconde rangee, a droite, 8 sous la
            // pilule.
            else
              Align(alignment: AlignmentDirectional.topStart, child: ligne),
            if (!aCote && (eleves != null || vignette)) ...<Widget>[
              Ecart.vSm,
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    if (eleves != null)
                      _BoutonEleves(
                        nombre: eleves.nombre,
                        onPress: eleves.onPress,
                      ),
                    if (vignette)
                      VignetteVideo(
                        vue: vue,
                        largeur: largeurVignetteTelephone,
                      ),
                  ],
                ),
              ),
            ],
            BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
            ?alerte,
          ],
        ),
      ),
    );
  }
}

/// Le bouton rond « Eleves » de l'enseignant au telephone : icone personnes
/// et pastille du nombre (standard Meet), jamais un lien texte.
class _BoutonEleves extends StatelessWidget {
  const _BoutonEleves({required this.nombre, required this.onPress});

  final int nombre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        BoutonIcone(
          key: const ValueKey<String>('salle-eleves'),
          forme: FormeBoutonIcone.appel,
          icone: AppIcons.eleves,
          diametre: AppTouchTarget.standard,
          libelle: t.salle.seance.eleves,
          onPress: onPress,
        ),
        if (nombre > 0)
          PositionedDirectional(
            top: -AppSpacing.xs,
            end: -AppSpacing.xs,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: palette.surfacePrimary.decoration(
                    borderRadius: AppRadius.arrondiFull,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.lg + AppSpacing.xs,
                      minHeight: AppSpacing.lg + AppSpacing.xs,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          '$nombre',
                          style: palette.surfacePrimary.applyTo(
                            Theme.of(context).textTheme.labelMedium ??
                                const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// La pilule du zoom local de la page : moins en bas, plus en haut (100 a
/// 200 %). Au premier et au dernier palier, le bouton disparait et garde sa
/// place (jamais grise).
class _PiluleZoom extends StatelessWidget {
  const _PiluleZoom({required this.actions});

  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double diametre = diametreBoutonAppel(context);
    Widget bouton(Key cle, AppIcon icone, String libelle, VoidCallback? f) =>
        f == null
        ? SizedBox.square(dimension: diametre)
        : BoutonIcone(
            key: cle,
            forme: FormeBoutonIcone.appel,
            icone: icone,
            diametre: diametre,
            libelle: libelle,
            infobulle: libelle,
            onPress: f,
          );
    return DecoratedBox(
      key: const ValueKey<String>('salle-zoom'),
      decoration: palette.piluleSalle.decoration(
        borderRadius: AppRadius.arrondiFull,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: <Widget>[
            bouton(
              const ValueKey<String>('salle-zoom-plus'),
              AppIcons.zoomPlus,
              t.salle.seance.zoomPlus,
              actions.onZoomPlus,
            ),
            bouton(
              const ValueKey<String>('salle-zoom-moins'),
              AppIcons.zoomMoins,
              t.salle.seance.zoomMoins,
              actions.onZoomMoins,
            ),
          ],
        ),
      ),
    );
  }
}

/// Le bas : les commandes rondes de l'appel, et chez l'enseignant
/// « Commandes » (pagination, zoom, outils).
class _Bas extends StatelessWidget {
  const _Bas({
    required this.vue,
    required this.actions,
    required this.local,
    required this.paletteAuDessus,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Telephone : la palette du tableau au-dessus de la pilule d'appel ;
  /// ordinateur : au bord droit (posee ailleurs).
  final bool paletteAuDessus;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? commandes = actions.onCommandes;
    // Standard des commandes d'appel (24/10/2026) : une seule pilule, « Plus »
    // dedans ; aucun declencheur a cote. S0.3b : tableau ouvert, sa palette
    // juste au-dessus, horizontale.
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      agrandi: local.agrandi,
      plus:
          commandes != null &&
              CommandesPedagogiques.aDesEntrees(vue, actions) &&
              vue.panneau != PanneauOuvert.commandes
          ? BoutonPlusAppel(onPress: commandes)
          : null,
    );
    if (!paletteAuDessus || !vue.tableauOuvert || actions.onTableau == null) {
      return dock;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: PaletteTableau(vue: vue, actions: actions),
          ),
        ),
        Ecart.vSm,
        dock,
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
      constraints: BoxConstraints(
        maxHeight: hauteurMax,
        // Ordinateur : une colonne flottante etroite au bord droit.
        maxWidth: telephonePleinEcran(context)
            ? double.infinity
            : largeurPanneauSeance,
      ),
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
