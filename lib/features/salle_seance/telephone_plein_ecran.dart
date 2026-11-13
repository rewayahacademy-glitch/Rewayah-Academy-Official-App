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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show DeviceGestureSettings, DragStartBehavior, PanGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/commandes_masquables.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/passage_visages.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/languette_bord.dart';
import '../tc_mushaf/fleches_page_mushaf.dart';
import '../tc_mushaf/page_madina_15.dart' show ratioHauteurPageMadina15;
import 'actions_seance.dart';
import 'commandes_pedagogiques.dart';
import 'dock_seance.dart';
import 'dynamique_chrono.dart';
import 'glisser_page.dart';
import 'media_salle.dart';
import 'palette_tableau.dart';
import 'panneau_seance.dart' show largeurPanneauSeance;
import 'salle_seance.dart' show BandeauSecours, EtatLocalSeance;
import 'surface_page_fixe.dart';
import 'telephone_enseignant.dart';
import 'vignette_video.dart';
import 'vue_seance.dart';
import 'zone_support.dart'
    show ZoneSupport, coteFlechesSalle, modeSceneDe, surfaceAMontrer;

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

/// Fiche 1 (26/10/2026) : la composition du telephone de l'enseignant (la
/// capsule, « Commandes », le tiroir, la feuille des eleves) vaut pour toute
/// fenetre de moins de 840 points de large : telephone et iPad en portrait.
bool salleTelephoneEnseignant(BuildContext context, VueSeance vue) =>
    pleinEcranSalle(context) &&
    vue.conduitLaSeance &&
    MediaQuery.sizeOf(context).width < AppGabarit.seuilEtendu;

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

/// PAGES-FLUIDES (directeur, 12/11/2026 : « les pages du Coran et de tout
/// document sont trop pres des bords ; il faut un cadre et des marges ») :
/// la marge autour d'une page de document dans sa [boite] plein cadre. Elle
/// amende S0.2d et K4 (« zero marge ») : 16 de chaque cote au telephone ;
/// sur tablette et sur ordinateur, davantage (jusqu'a 24, puis 32) quand la
/// boite le permet, c'est-a-dire quand la page n'y perd rien de sa largeur
/// (la hauteur fixe deja sa taille) ; en haut et en bas, une reserve pour
/// que rien ne colle aux bords.
EdgeInsets margesPageSalle(Size boite) {
  final double vertical = boite.width >= AppGabarit.seuilTablette
      ? AppSpacing.lg
      : AppSpacing.md;
  final double plafond = boite.width >= AppGabarit.seuilEtendu
      ? AppSpacing.xxxl
      : boite.width >= AppGabarit.seuilTablette
      ? AppSpacing.xxl
      : AppSpacing.lg;
  // La place laissee de chaque cote par une page que la hauteur limite.
  final double naturelle =
      math.max(0, boite.height - 2 * vertical) / ratioHauteurPageMadina15;
  final double libre = (boite.width - naturelle) / 2;
  double lateral = AppSpacing.lg;
  for (final double palier in <double>[
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxxl,
  ]) {
    if (palier <= plafond && palier <= libre) lateral = palier;
  }
  return EdgeInsets.symmetric(horizontal: lateral, vertical: vertical);
}

/// PAGES-FLUIDES : l'arrondi d'une page de document en plein cadre.
const BorderRadius arrondiPageSalle = AppRadius.arrondiSm;

/// La marge d'une grande fleche de page, sa place comprise.
const double margeFlechePage = coteFlechesSalle + AppSpacing.sm;

/// La boite de la page sur ordinateur quand ses grandes fleches doivent
/// tenir a cote.
///
/// UX-010 (revue UX, lot 10) : a 1200 x 760 avec les deux panneaux, la
/// boite elargie (plafond 1,4) ne laissait pas la place des fleches, qui
/// disparaissaient. On rogne la marge vide de la boite, jamais la page : la
/// boite reste au moins a la largeur naturelle de la page Madina ; en
/// dessous, la boite ne change pas (les fleches ne tiennent pas).
Size boitePageAvecFleches(
  Size ecran, {
  required bool telephone,
  required bool avecFleches,
}) {
  final Size large = boitePagePleinEcran(ecran, telephone: telephone);
  if (telephone || !avecFleches) return large;
  if (ecran.width >= large.width + 2 * margeFlechePage) return large;
  final double sansMarge = ecran.width - 2 * margeFlechePage;
  return sansMarge >= ecran.height / ratioHauteurPageMadina15
      ? Size(sansMarge, large.height)
      : large;
}

/// La vignette flottante du telephone (≈ 96 de large).
const double largeurVignetteTelephone = AppSpacing.respiration * 1.5;

/// RUBAN-TELEPHONE : la largeur d'un cadre de la bande de cote de l'eleve
/// (l'enseignant, le recitant) : la meme pour les deux.
///
/// Directeur, 11/11/2026 (soir, « attention sur les alignements ») : le cadre
/// prend toute la largeur utile de la bande, bord a bord avec la pilule de
/// l'appel posee dessous ; plus de cadre plus etroit que ce qui l'entoure.
double largeurCadreBande(GeometrieEleve geometrie) =>
    math.max(0, geometrie.bande - 2 * AppSpacing.lg);

/// RUBAN-TELEPHONE : la cle de la grille qui part vers le ruban (tests).
const Key cleGrilleSortante = ValueKey<String>('grille-sortante');

/// RUBAN-TELEPHONE : la cle du voile qui fait arriver la page en fondu.
const Key cleVoilePage = ValueKey<String>('voile-page');

/// RUBAN-TELEPHONE : la cle du cadre du recitant dans la bande de cote.
const Key cleRecitantBande = ValueKey<String>('bande-cadre-recitant');

/// Lot CORAN-ELEVE (directeur, 11/11/2026) : la place de la page de l'eleve
/// (et du tuteur, du controleur) et de ce qui l'entoure, pour que rien ne
/// recouvre le texte ni le numero de page.
///
/// - **Cotes** ([cote]) : quand les bandes vides a cote d'une page pleine
///   hauteur logent la pilule de l'appel (ordinateur, tablette et telephone
///   en paysage), la page garde toute la hauteur ; la Dynamique chrono en
///   haut de la bande de debut ; la vignette de l'enseignant en haut de la
///   bande de fin (deplacable en bas de la bande de debut), le zoom au
///   milieu et les
///   commandes de l'appel en bas de la bande de fin ; chaque bande large
///   d'au moins [bande].
/// - **Superposee** ([superposee], telephone et tablette en portrait, pilote
///   le 11/11/2026 : « sans compacter la page du Coran ») : la page garde
///   toute la place sous la rangee reservee de la Dynamique chrono
///   (DYNAMIQUE-CHRONO-1, 12/11/2026 : plus rien n'est pose dessus au
///   repos) ; au toucher, la pilule de l'appel, la vignette et le zoom
///   passent par-dessus et s'effacent au delai de [CommandesMasquables].
/// - **Haut et bas** (Interface guidee en portrait : un enfant voit toujours
///   ses boutons) : la vignette et le zoom sur une rangee en haut (la
///   Dynamique chrono a sa rangee au-dessus, DYNAMIQUE-CHRONO-1) ; les
///   commandes de l'appel en bas ; la page prend la place libre entre les
///   deux.
class GeometrieEleve {
  const GeometrieEleve._({
    required this.cote,
    this.superposee = false,
    required this.page,
    required this.bande,
    required this.rangee,
    required this.finRangee,
  });

  /// Vrai : tout passe sur les cotes, la page garde toute la hauteur.
  final bool cote;

  /// Vrai : la page a l'ecran entier ; les commandes passent par-dessus au
  /// toucher et s'effacent.
  final bool superposee;

  /// La zone ou la page se compose (centree dedans).
  final Rect page;

  /// La largeur des bandes de cote reservees ([cote]) ; 0 sinon.
  final double bande;

  /// La hauteur de la rangee du haut (Dynamique chrono repliee, vignette,
  /// zoom) ; 0 sur les cotes.
  final double rangee;

  /// La place prise au bout de la rangee du haut par la vignette et le zoom.
  final double finRangee;

  /// La largeur du zoom horizontal (moins, plus) pour [diametre].
  static double largeurZoom(double diametre) =>
      2 * diametre + 3 * AppSpacing.sm;

  /// La largeur minimale d'une bande de cote : la pilule de l'appel de quatre
  /// boutons (micro, camera, reduire, quitter) SUR UNE RANGEE, et ses marges.
  ///
  /// Directeur, 11/11/2026 (« un arriere-plan deborde qui n'a aucune
  /// forme ») : l'ancienne mesure comptait des ecarts de 8 et quatre boutons
  /// egaux ; la pilule reelle a des ecarts de 16 et un « Quitter » plus large
  /// (16 de plus). Elle ne tenait donc pas dans la bande, passait sur deux
  /// rangees, et son fond arrondi devenait une tache sans forme. La bande se
  /// mesure maintenant sur la pilule telle qu'elle est dessinee
  /// ([DockSeance] : ecart `lg`, marge interieure `sm`, Quitter `+ lg`).
  static double largeurBande(double diametre) =>
      4 * diametre +
      AppSpacing.lg +
      3 * AppSpacing.lg +
      2 * AppSpacing.sm +
      2 * AppSpacing.lg;

  /// [hauteurBas] : la hauteur mesuree des commandes de l'appel (marges
  /// comprises, zone sure exclue) ; `null` avant la premiere mesure.
  static GeometrieEleve calculer({
    required Size ecran,
    required EdgeInsets zoneSure,
    required double diametre,
    required bool vignette,
    required bool zoom,
    bool rangees = false,
    double? hauteurBas,
  }) {
    final double bande = largeurBande(diametre);
    final double naturelle = ecran.height / ratioHauteurPageMadina15;
    if ((ecran.width - naturelle) / 2 >= bande) {
      return GeometrieEleve._(
        cote: true,
        page: Rect.fromLTWH(bande, 0, ecran.width - 2 * bande, ecran.height),
        bande: bande,
        rangee: 0,
        finRangee: 0,
      );
    }
    if (!rangees) {
      return GeometrieEleve._(
        cote: false,
        superposee: true,
        page: Offset.zero & ecran,
        bande: 0,
        rangee: 0,
        finRangee: 0,
      );
    }
    final double hautVignette = vignette
        ? largeurVignetteTelephone / MesuresVignette.ratio
        : 0;
    // DYNAMIQUE-CHRONO-1 : la barre a sa propre rangee, au-dessus ; celle-ci
    // ne porte plus que la vignette et le zoom.
    final double rangee = math.max(
      hautVignette,
      zoom ? diametre + 2 * AppSpacing.sm : 0,
    );
    final double finRangee =
        (vignette ? largeurVignetteTelephone + AppSpacing.sm : 0) +
        (zoom ? largeurZoom(diametre) + AppSpacing.sm : 0);
    final double haut = zoneSure.top + AppSpacing.lg + rangee + AppSpacing.sm;
    final double bas =
        (hauteurBas ?? diametre + 2 * AppSpacing.sm + 2 * AppSpacing.lg) +
        zoneSure.bottom;
    return GeometrieEleve._(
      cote: false,
      page: Rect.fromLTRB(
        0,
        haut,
        ecran.width,
        math.max(haut, ecran.height - bas),
      ),
      bande: 0,
      rangee: rangee,
      finRangee: finRangee,
    );
  }
}

/// Mesure la hauteur de son enfant apres chaque mise en page et la signale
/// (apres l'image) quand elle change.
class _MesureHauteur extends SingleChildRenderObjectWidget {
  const _MesureHauteur({required this.onHauteur, required super.child});

  final ValueChanged<double> onHauteur;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduMesureHauteur(onHauteur);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduMesureHauteur renderObject,
  ) => renderObject.onHauteur = onHauteur;
}

class _RenduMesureHauteur extends RenderProxyBox {
  _RenduMesureHauteur(this.onHauteur);

  ValueChanged<double> onHauteur;
  double? _derniere;

  @override
  void performLayout() {
    super.performLayout();
    final double h = size.height;
    if (_derniere == h) return;
    _derniere = h;
    SchedulerBinding.instance.addPostFrameCallback((_) => onHauteur(h));
  }
}

/// La page (ou le tableau) de la salle composee dans [ecran], avec ses
/// grandes fleches quand elles tiennent a cote ; `null` : rien a montrer
/// (la scene prend la place). Un seul calcul pour le telephone et
/// l'ordinateur (plan de composition du 26/10/2026, K-10).
Widget? pageSalle(
  BuildContext context, {
  required VueSeance vue,
  required double zoom,
  required Size ecran,
  required bool telephone,
}) {
  final VueSurface? surface = surfaceAMontrer(vue);
  if (surface == null) return null;
  final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
  final VoidCallback? precedente = media?.onPagePrecedente;
  final VoidCallback? suivante = media?.onPageSuivante;
  const double cote = margeFlechePage;
  final bool avecFleches =
      !telephone &&
      vue.supportPresente != null &&
      (precedente != null || suivante != null);
  final Size boite = boitePageAvecFleches(
    ecran,
    telephone: telephone,
    avecFleches: avecFleches,
  );
  // S0.2d (directeur, 24/10/2026) : « Full screen, full body, no
  // bezels. » Au telephone, la page n'est plus au ratio A4 : son cadre
  // EST l'ecran, largeur et hauteur. La page Madina se compose sur cette
  // place (`PageMadina15`, interligne libre). Les notes gardent le repere
  // de cette page (coordonnees normalisees). Amende par la demande du
  // directeur du 12/11/2026 (PAGES-FLUIDES, cadre et marges) : la page se
  // pose dans sa boite avec une marge (`margesPageSalle`), sur le fond de
  // la salle ; le repere des notes est la page, marge exclue.
  final SupportPageFixe? support = vue.supportPresente;
  final EdgeInsets marges = support == null
      ? EdgeInsets.zero
      : margesPageSalle(boite);
  final Size interieure = Size(
    math.max(0, boite.width - marges.horizontal),
    math.max(0, boite.height - marges.vertical),
  );
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
            // PARTAGE-GENERIQUE : une page aux proportions fixes garde
            // les siennes (centree dans la boite, jamais etiree).
            largeurCanonique: support.ratioFixe
                ? support.largeurCanonique
                : math.max(1, interieure.width.round()),
            hauteurCanonique: support.ratioFixe
                ? support.hauteurCanonique
                : math.max(1, interieure.height.round()),
            mention: support.mention,
            cleImage: support.cleImage,
            ratioFixe: support.ratioFixe,
          ),
        );
  final bool libre = support == null;
  final Widget page = SizedBox.fromSize(
    key: TelephonePleinEcran.clePage,
    // Le tableau occupe la fenetre ; la page du Coran, sa boite.
    size: libre ? ecran : boite,
    // La page et ses notes restent claires (meme regle que la
    // carte de la surface).
    child: libre
        ? Theme(
            data: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            child: SurfacePageFixe(vue: vuePage, surface: surface, zoom: zoom),
          )
        // PAGES-FLUIDES : la marge, puis la page (claire, arrondie, filet
        // fin : `SurfacePageFixe`). Rien n'est peint dans la marge : on y
        // voit le fond de la salle lui-meme, clair en theme clair, sombre en
        // theme sombre. Pas de boite sombre autour de la page : dans une
        // salle claire elle faisait un cadre noir (relecture du 12/11).
        : Padding(
            key: TelephonePleinEcran.cleFondPage,
            padding: marges,
            child: Theme(
              data: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              child: SurfacePageFixe(
                vue: vuePage,
                surface: surface,
                zoom: zoom,
              ),
            ),
          ),
  );
  // Ordinateur : les grandes fleches de page (reference 4 du
  // directeur) dans les marges vides a cote de la page, quand elles y
  // tiennent : elles ne prennent rien a la page.
  return !telephone &&
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
      // Constat S-1 (11/11/2026) : au telephone, ou les fleches ne tiennent
      // pas a cote de la page, la page se tourne au doigt. Sans rappel
      // (eleve, tableau), le geste n'existe pas ; page agrandie, le doigt
      // la deplace au lieu de la tourner.
      : telephone &&
            !libre &&
            zoom <= 1 &&
            (precedente != null || suivante != null)
      ? GlisserPage(
          key: const ValueKey<String>('glisser-page-salle'),
          onPrecedente: precedente,
          onSuivante: suivante,
          child: page,
        )
      // Lot CORAN-ELEVE (directeur, 11/11/2026) : l'eleve suit la page de
      // la classe ; il ne la tourne pas. Un glissement le lui dit un court
      // instant (« La page suit celle de l'enseignant »), au lieu de laisser
      // croire a une panne.
      : !libre && precedente == null && suivante == null && !vue.conduitLaSeance
      ? GlisserPage(
          key: const ValueKey<String>('glisser-page-salle'),
          onPrecedente: null,
          onSuivante: null,
          messageSansDroit: t.salle.coranEleve.pageDeLaClasse,
          child: page,
        )
      : page;
}

/// Le micro local est ouvert et entendu (le signe de la Dynamique chrono).
bool microOuvertEntendu(VueSeance vue, EtatLocalSeance local) =>
    vue.commandesDock.contains(CommandeDock.micro) &&
    local.microOuvert &&
    !vue.microBloque &&
    !vue.microEnAttente &&
    vue.commandesPublicationActives;

/// La salle au telephone (et sur tablette, et chez l'eleve sur ordinateur).
///
/// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026 : « le chrono cache le
/// document ; a refaire pour que rien ne cache rien ») : la Dynamique chrono
/// a une PLACE RESERVEE ([ZoneChrono]). Au telephone et sur tablette sans
/// colonne, une rangee de toute la largeur, au-dessus de tout le reste : la
/// page, la scene, la capsule et les commandes se composent dessous, dans la
/// place qui reste (la zone sure du haut est deja prise par la rangee). Chez
/// l'eleve devant une page sur un ecran large (les bandes de cote), la zone
/// est en haut de la bande de debut, a cote de la page.
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

  /// La cle de la boite de la page (tests, captures).
  static const Key clePage = ValueKey<String>('telephone-page');

  /// PAGES-FLUIDES : la marge autour d'une page de document (le fond de la
  /// salle s'y voit).
  static const Key cleFondPage = ValueKey<String>('telephone-page-fond');

  /// GRILLE-COMMANDES (11/11/2026) : « Plus », la case de la barre de
  /// l'enseignant qui ouvre le tiroir (l'ancien bouton « Commandes »).
  static const Key cleCommandesToucher = BarreCommandesTelephone.clePlus;

  /// « Eleves » dans la barre de l'enseignant.
  static const Key cleEleves = BarreCommandesTelephone.cleEleves;

  /// La rangee reservee de la Dynamique chrono (tests de geometrie).
  static const Key cleRangeeChrono = ValueKey<String>('rangee-chrono');

  /// Vrai quand l'eleve (ou le tuteur, le controleur) est devant une page
  /// qui garde toute la hauteur, ses commandes dans les bandes de cote :
  /// la zone de la barre va en haut de la bande de debut.
  static bool zoneDansLaBande(BuildContext context, VueSeance vue, Size ecran) {
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final bool scene =
        media?.scene != null && modeSceneDe(context, vue) == ModeScene.classe;
    final bool eleve =
        !vue.conduitLaSeance &&
        !scene &&
        vue.supportPresente != null &&
        surfaceAMontrer(vue) != null;
    if (!eleve) return false;
    return GeometrieEleve.calculer(
      ecran: ecran,
      zoneSure: EdgeInsets.zero,
      diametre: diametreBoutonAppel(context),
      vignette: false,
      zoom: false,
    ).cote;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Material(
      color: palette.surfaceCanvas.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final Widget corps = _CorpsTelephone(
            vue: vue,
            actions: actions,
            local: local,
            zoneDansBande: zoneDansLaBande(context, vue, c.biggest),
          );
          if (zoneDansLaBande(context, vue, c.biggest)) return corps;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: Padding(
                  key: cleRangeeChrono,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: LayoutBuilder(
                    builder: (BuildContext _, BoxConstraints z) => ZoneChrono(
                      vue: vue,
                      largeur: z.maxWidth,
                      onPause: actions.onPause,
                      microOuvert: microOuvertEntendu(vue, local),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: corps,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Le corps de la salle au telephone, sous la rangee de la Dynamique chrono
/// (ou a cote d'elle, dans la bande de debut).
class _CorpsTelephone extends StatefulWidget {
  const _CorpsTelephone({
    required this.vue,
    required this.actions,
    required this.local,
    required this.zoneDansBande,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Vrai : la zone de la Dynamique chrono est en haut de la bande de debut
  /// (posee par le corps) ; faux : elle est deja au-dessus, dans sa rangee.
  final bool zoneDansBande;

  @override
  State<_CorpsTelephone> createState() => _EtatTelephonePleinEcran();
}

class _EtatTelephonePleinEcran extends State<_CorpsTelephone> {
  VueSeance get vue => widget.vue;
  ActionsSeance get actions => widget.actions;
  EtatLocalSeance get local => widget.local;

  /// Fiche 1, ligne 5 : le profil deplie depuis la capsule ; il reste
  /// jusqu'a « Reduire » ou un toucher de la page (pas de masquage a 3 s).
  bool _profil = false;
  final GlobalKey _cleProfil = GlobalKey();

  /// Le panneau du bas ouvert et la pilule : un toucher sur eux traverse
  /// jusqu'a la page (les zones vides laissent passer le toucher) ; il ne
  /// referme rien.
  final GlobalKey _clePanneau = GlobalKey();
  final GlobalKey _cleBas = GlobalKey();

  /// Lot CORAN-ELEVE : la hauteur mesuree des commandes de l'appel de
  /// l'eleve (rangee du bas) ; la page s'arrete au-dessus.
  double? _hauteurBas;

  /// SCENE-CLASSE : la hauteur mesuree de la barre de l'enseignant au
  /// telephone ; la grille des visages s'arrete au-dessus (rien ne passe sur
  /// un visage, MODES-AFFICHAGE §3).
  double? _hauteurBasScene;

  void _surHauteurBasScene(double h) {
    if (!mounted || _hauteurBasScene == h) return;
    setState(() => _hauteurBasScene = h);
  }

  void _surHauteurBas(double h) {
    if (!mounted || _hauteurBas == h) return;
    setState(() => _hauteurBas = h);
  }

  /// Lot CORAN-ELEVE (pilote, 11/11/2026) : « votre micro s'ouvrira quand
  /// votre enseignant sera la » doit pouvoir se lire. Les commandes restent
  /// visibles [AppMouvement.ilePassage] quand la phrase apparait, puis
  /// suivent le masquage habituel.
  bool _microAttente = false;

  /// RUBAN-TELEPHONE (MODES-AFFICHAGE §5) : le dernier mode vu, pour savoir
  /// quel passage jouer quand il change ; `null` avant la premiere image (rien
  /// ne se joue a l'entree ni a une reconnexion qui remonte l'ecran).
  ModeScene? _modeVu;

  /// Le passage en cours, seulement pendant l'image ou le mode change (remis
  /// a faux apres elle) : un cadre monte plus tard ne le rejoue pas.
  bool _versRuban = false;
  bool _versGrille = false;

  /// Vrai le temps du fondu d'arrivee de la page (un voile du fond qui
  /// s'efface au-dessus d'elle, sans geste ni lecture).
  bool _voilePage = false;

  /// La grille qui part (Classe vers Document ou Tableau), le temps de son
  /// passage ; `null` sinon.
  Widget? _grilleSortante;

  /// Le numero du passage : la cle de ce qui se joue (un passage, un
  /// montage).
  int _passage = 0;

  /// RUBAN-TELEPHONE : note le mode de cette image et le passage a jouer.
  void _suivreMode(ModeScene mode, Widget? laScene) {
    final ModeScene? avant = _modeVu;
    if (avant == mode) return;
    _modeVu = mode;
    if (avant == null) return;
    _passage++;
    _versRuban = avant == ModeScene.classe;
    _versGrille = mode == ModeScene.classe;
    _grilleSortante = _versRuban ? laScene : null;
    // La page (ou le tableau) arrive en fondu : depuis la classe, sur la
    // duree du passage ; d'un document au tableau, fondu enchaine court.
    _voilePage = !_versGrille;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _versRuban = false;
      _versGrille = false;
    });
  }

  Timer? _minuterieMicroAttente;

  void _suivreMicroAttente({required bool avant}) {
    final bool maintenant = vue.texteMicroEnAttente != null;
    if (maintenant == avant) return;
    _minuterieMicroAttente?.cancel();
    _microAttente = maintenant;
    if (!maintenant) return;
    _minuterieMicroAttente = Timer(AppMouvement.ilePassage, () {
      if (mounted) setState(() => _microAttente = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _suivreMicroAttente(avant: false);
  }

  @override
  void dispose() {
    _minuterieMicroAttente?.cancel();
    super.dispose();
  }

  /// Le micro local est ouvert et entendu (le signe de la Dynamique chrono).
  bool get _microOuvertEntendu => microOuvertEntendu(vue, local);

  /// La hauteur mesuree du haut de la bande de debut (la zone de la
  /// Dynamique chrono), quand la zone y est : la phrase d'etat se pose
  /// dessous.
  double? _hauteurHautBande;

  void _surHauteurHautBande(double h) {
    if (!mounted || _hauteurHautBande == h) return;
    setState(() => _hauteurHautBande = h);
  }

  /// Vrai quand [position] tombe dans le widget de [cle].
  bool _dans(GlobalKey cle, Offset position) {
    final RenderObject? r = cle.currentContext?.findRenderObject();
    if (r is! RenderBox || !r.hasSize) return false;
    return (Offset.zero & r.size).contains(r.globalToLocal(position));
  }

  void _replier() {
    if (_profil) setState(() => _profil = false);
  }

  /// Fiche 1, ligne 11 : le panneau du bas ouvert (tiroir ou feuille des
  /// eleves) se referme.
  void _fermerPanneau() {
    switch (vue.panneau) {
      case PanneauOuvert.commandes:
        actions.onCommandes?.call();
      case PanneauOuvert.eleves:
        actions.onEleves?.call();
      default:
        break;
    }
  }

  /// Pilote (26/10, L11) : Stylo, Surligner ou Gomme retenu, un toucher de
  /// la page dessine et le tiroir reste ouvert ; seul « Reduire » le ferme.
  bool _outilActif() {
    if (!vue.ecritureProposee ||
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() ==
            null) {
      return false;
    }
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(etatOutilsProvider).styletArme;
  }

  void _deplierProfil() {
    // Ligne 11 : un panneau du bas ne couvre jamais le haut ; le profil
    // deplie le referme.
    _fermerPanneau();
    setState(() => _profil = true);
  }

  @override
  void didUpdateWidget(_CorpsTelephone ancien) {
    super.didUpdateWidget(ancien);
    _suivreMicroAttente(avant: ancien.vue.texteMicroEnAttente != null);
    // Un panneau du bas s'ouvre : le profil se replie (rien ne se recouvre).
    if (_profil &&
        widget.vue.panneau != PanneauOuvert.aucun &&
        widget.vue.panneau != ancien.vue.panneau) {
      _profil = false;
    }
  }

  /// SCENE-CLASSE : le haut de la grille de l'enseignant au telephone, sous
  /// la capsule (zone sure, marge, capsule, petit ecart).
  double _hautSceneEnseignant(BuildContext context) =>
      MediaQuery.paddingOf(context).top +
      AppSpacing.lg +
      CapsuleVideoTelephone.hauteur(context) +
      AppSpacing.sm;

  /// Un toucher de la page replie le profil (hors de sa carte) et referme le
  /// panneau du bas (lignes 5 et 11).
  void _toucherPage(PointerDownEvent e) {
    if (salleTelephoneEnseignant(context, vue) &&
        (vue.panneau == PanneauOuvert.eleves ||
            (vue.panneau == PanneauOuvert.commandes && !_outilActif())) &&
        !_dans(_clePanneau, e.position) &&
        !_dans(_cleBas, e.position) &&
        !_dans(_cleProfil, e.position)) {
      _fermerPanneau();
    }
    if (!_profil || _dans(_cleProfil, e.position)) return;
    _replier();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final VueSurface? surface = surfaceAMontrer(vue);
    final Widget? laScene = media?.scene;
    // SCENE-CLASSE : un seul etat de la scene (MODES-AFFICHAGE §2, regle 7).
    final bool scene =
        laScene != null && modeSceneDe(context, vue) == ModeScene.classe;
    final bool panneau = vue.panneau == PanneauOuvert.commandes;
    return Material(
      color: palette.surfaceCanvas.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final Size ecran = c.biggest;
          final bool telephone = telephonePleinEcran(context);
          // Plan de composition du 26/10/2026, §4 (PR B) : l'enseignant au
          // telephone a sa capsule, son tiroir des Commandes et ses eleves en
          // feuille ; l'eleve, le tuteur et le controleur ne changent pas.
          final bool enseignant = salleTelephoneEnseignant(context, vue);
          final bool eleves = enseignant && vue.panneau == PanneauOuvert.eleves;
          final bool libre = vue.supportPresente == null;
          // Lot CORAN-ELEVE (directeur, 11/11/2026 : « rien ne recouvre le
          // texte du Coran chez l'eleve ») : l'eleve, le tuteur et le
          // controleur devant une page ([GeometrieEleve]). Sur un ecran
          // large, tout passe dans les bandes vides des cotes ; en portrait,
          // la page garde l'ecran entier et les commandes passent par-dessus
          // au toucher, puis s'effacent (pilote, 11/11) ; en Interface
          // guidee, la page se pose entre deux rangees.
          final bool eleve =
              !vue.conduitLaSeance && !scene && !libre && surface != null;
          final bool sceneDevant = enseignant && scene;
          // RUBAN-TELEPHONE (MODES-AFFICHAGE §5) : le passage entre modes.
          // La place du ruban : la capsule (enseignant, en haut au centre) ou
          // la vignette (en haut a la fin) ; l'echelle : la taille de ce
          // cadre rapportee a la largeur de l'ecran.
          _suivreMode(
            scene
                ? ModeScene.classe
                : modeSceneDe(context, vue) == ModeScene.tableau
                ? ModeScene.tableau
                : ModeScene.document,
            laScene,
          );
          final AlignmentGeometry placeRuban = enseignant
              ? Alignment.topCenter
              : AlignmentDirectional.topEnd;
          final double echelleRuban = ecran.width <= 0
              ? 1
              : math.min(
                  1,
                  (enseignant
                          ? CapsuleVideoTelephone.largeurVideo
                          : telephone
                          ? largeurVignetteTelephone
                          : MesuresVignette.largeurPleinCadreLarge) /
                      ecran.width,
                );
          final Widget haut = _Haut(
            vue: vue,
            actions: actions,
            largeur: ecran.width,
            // Lot salle 2 : la vignette est posee a part, deplacable.
            vignette: false,
            aCote: !telephone && !enseignant,
            microOuvert: _microOuvertEntendu,
          );
          // Plan §4 : le tiroir des Commandes et la feuille des eleves
          // montent du bas, au-dessus de la pilule de l'appel.
          final double hauteurFeuille = ecran.height * _partPanneau;
          final bool large = ecran.width >= AppGabarit.seuilTablette;
          // Ordinateur : la palette du tableau, verticale au bord droit.
          final bool paletteADroite =
              !telephone &&
              !enseignant &&
              vue.tableauOuvert &&
              actions.onTableau != null;
          // Ordinateur : les Commandes ouvertes flottent au bord droit, dans
          // la couche qui se masque a 3 s ; aucune carte pleine hauteur.
          final Widget? commandesADroite = !telephone && !enseignant && panneau
              ? _PanneauCommandes(
                  vue: vue,
                  actions: actions,
                  local: local,
                  hauteurMax: ecran.height * _partPanneau,
                )
              : null;
          // Fiche 1, ligne 13 : la pilule du zoom ni sur un panneau ouvert,
          // ni sur le profil deplie.
          // Directeur, 11/11/2026 : au telephone, plus de bouton de zoom
          // (« ca ne sert a rien car on peut pincer, en plus ca bloque la
          // vue ») : le pincement et le double toucher restent, et le tiroir
          // des Commandes garde plus et moins chez l'enseignant.
          final bool zoom =
              !telephone &&
              !libre &&
              !sceneDevant &&
              !paletteADroite &&
              commandesADroite == null &&
              !((panneau || eleves) && enseignant) &&
              !_profil &&
              (actions.onZoomPlus != null || actions.onZoomMoins != null);
          final GeometrieEleve? geometrie = eleve
              ? GeometrieEleve.calculer(
                  ecran: ecran,
                  zoneSure: MediaQuery.paddingOf(context),
                  diametre: diametreBoutonAppel(context),
                  vignette: vue.voitVignetteSurSupport,
                  zoom: zoom,
                  // Interface guidee : un enfant voit toujours ses boutons ;
                  // la page se pose entre deux rangees.
                  rangees: vue.role == RoleSeance.guidee,
                  hauteurBas: _hauteurBas,
                )
              : null;
          // RUBAN-TELEPHONE (cahier §8, regle du directeur : une information
          // se pose en haut, jamais sur la page) : devant une page qui garde
          // l'ecran (portrait superpose ou bandes de cote), les phrases
          // d'etat de l'eleve (« Camera desactivee pour ce profil. », le
          // micro en attente) quittent le dessus de la pilule du bas et
          // passent en haut ([_StatutEnHaut]). En Interface guidee (la page
          // entre deux rangees) et sur la scene, la pilule a sa place
          // reservee : la phrase y reste, elle ne couvre rien.
          final bool statutEnHaut =
              geometrie != null && (geometrie.cote || geometrie.superposee);
          final Widget bas = Padding(
            // Standard : marge 16 des bords (et la zone sure). GRILLE-
            // COMMANDES : sous 360 de large, la barre de l'enseignant
            // s'approche des bords (8) pour garder ses six cases de 48.
            padding: enseignant && ecran.width < 360
                ? const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.lg,
                  )
                : const EdgeInsets.all(AppSpacing.lg),
            child: _Bas(
              vue: vue,
              actions: actions,
              local: local,
              paletteAuDessus: telephone || enseignant,
              enseignantTelephone: enseignant,
              statutEnTete: statutEnHaut,
            ),
          );
          // La Dynamique chrono de l'eleve : toujours la, repliee (au repos
          // comme au toucher) ; sur les cotes, dans la bande de debut ; en
          // portrait, posee en haut de la page (elle est petite) ; avec les
          // rangees, dans celle du haut.
          final double largeurHautEleve = geometrie == null
              ? 0
              : geometrie.cote
              ? geometrie.bande
              : geometrie.superposee
              ? ecran.width
              : ecran.width - geometrie.finRangee;
          final Widget? hautEleve = geometrie == null
              ? null
              : PositionedDirectional(
                  top: 0,
                  start: 0,
                  width: largeurHautEleve,
                  child: geometrie.cote && widget.zoneDansBande
                      ? _MesureHauteur(
                          onHauteur: _surHauteurHautBande,
                          child: _Haut(
                            vue: vue,
                            actions: actions,
                            largeur: largeurHautEleve,
                            vignette: false,
                            aCote: false,
                            microOuvert: _microOuvertEntendu,
                            zone: true,
                          ),
                        )
                      : _Haut(
                          vue: vue,
                          actions: actions,
                          largeur: largeurHautEleve,
                          vignette: false,
                          aCote: false,
                          microOuvert: _microOuvertEntendu,
                        ),
                );
          final Widget? pageVue = scene
              ? null
              : pageSalle(
                  context,
                  vue: vue,
                  zoom: local.zoom,
                  ecran: geometrie?.page.size ?? ecran,
                  telephone: telephone || enseignant,
                );
          // Pilote (26/10) : la video en grand devant une page qui attend est
          // la meme scene pour l'enseignant au telephone (lignes 1 a 3) : la
          // capsule seule en haut, son oeil devient « Revenir a la page ».
          final VoidCallback? revenir = media?.onBasculerScene;
          // Pilote C9 (option a) : la scene sans aucune page suit les memes
          // regles ; la capsule y est sans oeil, et « Ouvrir le Coran » reste
          // le seul bouton plein, au centre de la scene.
          final ({String libelle, VoidCallback onPress})? actionScene =
              sceneDevant
              ? ActionSousLaScene.avecGeste(
                  media?.actionScene,
                  _declencheur(actions, vue),
                )
              : null;
          final VoidCallback? revenirPage =
              sceneDevant &&
                  (media?.scenePremierPlan ?? false) &&
                  actionScene == null
              ? revenir
              : null;
          final Widget? page =
              pageVue ??
              (sceneDevant
                  ? SizedBox.fromSize(
                      size: ecran,
                      child: Stack(
                        children: <Widget>[
                          // SCENE-CLASSE (MODES-AFFICHAGE §3) : la capsule
                          // en haut et la barre en bas ont leur place
                          // reservee ; la grille se calcule dans ce qui
                          // reste, rien ne passe sur un visage.
                          Positioned.fill(
                            top: _hautSceneEnseignant(context),
                            bottom:
                                MediaQuery.paddingOf(context).bottom +
                                (_hauteurBasScene ??
                                    diametreBoutonAppel(context) +
                                        2 * AppSpacing.lg),
                            child: KeyedSubtree(
                              key: const ValueKey<String>('telephone-scene'),
                              // « Ouvrir le Coran » est pose par la scene,
                              // jamais par-dessus sa phrase d'attente.
                              // RUBAN-TELEPHONE : au retour en mode Classe,
                              // la grille revient en grandissant depuis la
                              // capsule, plus vite (deux tiers).
                              child: PassageVisages(
                                key: ValueKey<String>(
                                  'scene-arrivee-$_passage',
                                ),
                                jouer: _versGrille,
                                facon: FaconVisages.entree,
                                duree: AppMouvement.deplacementSortie,
                                alignement: placeRuban,
                                echelle: echelleRuban,
                                child: actionScene == null
                                    ? laScene
                                    : ActionSousLaScene(
                                        action: actionScene,
                                        child: laScene,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null);
          // RUBAN-TELEPHONE (MODES-AFFICHAGE §5) : la page arrive en fondu
          // par un voile du fond qui s'efface au-dessus d'elle ([_voilePage]) ;
          // la page elle-meme n'est jamais enveloppee (elle garde son arbre,
          // ses lectures et son zoom).
          final Widget? pagePassee = page;
          // Fiche 1, lignes 1, 2, 5 : la capsule (ou le profil deplie) en
          // haut. Sans page ni scene devant une page, rien a reduire : pas de
          // capsule. Page illisible : son constat et son « Reessayer » se
          // lisent, rien ne se pose dessus.
          final bool capsule =
              enseignant && page != null && !(media?.pageEnErreur ?? false);
          // Le haut de la colonne du bas : sous la capsule (ligne 11).
          final double hautColonne = capsule
              ? MediaQuery.paddingOf(context).top +
                    AppSpacing.lg +
                    CapsuleVideoTelephone.hauteur(context) +
                    AppSpacing.sm
              : 0;
          // TELEPHONE-REDUIT (cahier de la salle §9) : le telephone de
          // l'enseignant, sous 600 points ; la tablette ne change pas.
          final bool reduit = enseignant && !large;
          // Fiche 1, ligne 2 : la capsule (ou le profil deplie) en haut au
          // centre. Pilote C12 : le bandeau de secours et l'alerte sont des
          // alertes, pas des commandes (fiche 0, regle 22) : au-dessus, au
          // repos comme au toucher, poses sur la page sans la retrecir ; la
          // capsule se place sous eux et suit le toucher (C10), sauf sur la
          // scene video en grand.
          // DYNAMIQUE-CHRONO-2 (relecture du 13/11/2026) : la capsule ne se
          // rend pas tant que la Dynamique chrono est depliee par-dessus ;
          // elle revient quand la barre se replie.
          final Widget laCapsule = CacheSousDynamique(
            child: _profil
                ? KeyedSubtree(
                    key: _cleProfil,
                    child: ProfilTelephone(vue: vue, onReduire: _replier),
                  )
                : Center(
                    child: CapsuleVideoTelephone(
                      vue: vue,
                      onDeplier: _deplierProfil,
                      onRevenirPage: revenirPage,
                      oeil: !sceneDevant || revenirPage != null,
                      // RUBAN-TELEPHONE (MODES-AFFICHAGE §4) : en mode
                      // Document ou Tableau, l'eleve qui recite ; en mode
                      // Classe il est deja dans la grille (une personne, un
                      // cadre) : l'enseignant lui-meme.
                      recitant: sceneDevant ? null : media?.identiteRecitant,
                      nomRecitant: vue.recitantPrenom,
                      // SORTIE-SALLE, Q1 : seulement si l'appel continue hors
                      // de l'ecran ; jamais en Interface guidee.
                      onReduireSalle: vue.role == RoleSeance.guidee
                          ? null
                          : actions.onRetour,
                    ),
                  ),
          );
          final Widget capsuleEnHaut = PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
                    ?media?.alerte,
                    if (sceneDevant)
                      laCapsule
                    else
                      // DYNAMIQUE-CHRONO-1 : la Dynamique chrono a sa rangee,
                      // au-dessus ; la capsule (au toucher) se pose dessous,
                      // elle ne la cache plus.
                      MasqueAvecCommandes(child: laCapsule),
                  ],
                ),
              ),
            ),
          );
          return CommandesMasquables(
            delai: AppMouvement.masquageSalle,
            // SCENE-CLASSE (MODES-AFFICHAGE §3) : sans page, la scene (les
            // visages) s'arrete au-dessus de la barre : rien ne passe sur un
            // visage. Sur la page, rien ne change (la page garde l'ecran).
            margeLecture: page == null,
            maintenir:
                vue.visioMaintenue ||
                // Lot CORAN-ELEVE : rien a lire avant qu'un support soit
                // presente (scene, videos) ; la phrase du micro en attente ;
                // l'Interface guidee entre ses deux rangees.
                (!vue.conduitLaSeance && page == null) ||
                (!vue.conduitLaSeance && _microAttente) ||
                (geometrie != null &&
                    !geometrie.cote &&
                    !geometrie.superposee) ||
                (panneau && telephone) ||
                (_profil && enseignant) ||
                ((panneau || eleves) && enseignant),
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
                          // RUBAN-TELEPHONE : au retour en mode Classe, la
                          // grille revient en grandissant depuis la
                          // vignette, plus vite (deux tiers).
                          child: PassageVisages(
                            key: ValueKey<String>('scene-arrivee-$_passage'),
                            jouer: _versGrille,
                            facon: FaconVisages.entree,
                            duree: AppMouvement.deplacementSortie,
                            alignement: placeRuban,
                            echelle: echelleRuban,
                            child: ZoneSupport(
                              vue: vue,
                              zoom: local.zoom,
                              geste: _declencheur(actions, vue),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _toucherPage,
                    child: geometrie == null
                        ? Center(child: pagePassee)
                        : Stack(
                            children: <Widget>[
                              Positioned.fromRect(
                                rect: geometrie.page,
                                child: Center(child: pagePassee),
                              ),
                            ],
                          ),
                  ),
                // RUBAN-TELEPHONE : la grille qui part retrecit vers la place
                // du ruban et s'efface (ni geste ni lecture), pendant que le
                // cadre du ruban arrive en grandissant ; puis elle est
                // retiree.
                if (_voilePage && page != null && !sceneDevant)
                  Positioned.fill(
                    child: PassageVisages(
                      key: ValueKey<String>('voile-page-$_passage'),
                      jouer: true,
                      facon: FaconVisages.sortie,
                      duree: _grilleSortante != null
                          ? AppMouvement.deplacementEntree
                          : AppMouvement.fonduEntree,
                      onFini: () {
                        if (mounted) setState(() => _voilePage = false);
                      },
                      child: DecoratedBox(
                        key: cleVoilePage,
                        decoration: palette.surfaceCanvas.decoration(),
                      ),
                    ),
                  ),
                if (_grilleSortante case final Widget grille)
                  Positioned.fill(
                    top: enseignant
                        ? _hautSceneEnseignant(context)
                        : MediaQuery.paddingOf(context).top + AppSpacing.lg,
                    bottom: enseignant
                        ? MediaQuery.paddingOf(context).bottom +
                              (_hauteurBasScene ??
                                  diametreBoutonAppel(context) +
                                      2 * AppSpacing.lg)
                        : 0,
                    child: PassageVisages(
                      key: ValueKey<String>('grille-sortante-$_passage'),
                      jouer: true,
                      facon: FaconVisages.sortie,
                      duree: AppMouvement.deplacementEntree,
                      alignement: placeRuban,
                      echelle: echelleRuban,
                      onFini: () {
                        if (mounted) setState(() => _grilleSortante = null);
                      },
                      child: KeyedSubtree(
                        key: cleGrilleSortante,
                        child: grille,
                      ),
                    ),
                  ),
                ?hautEleve,
                // Pilote C10 (27/10) : sur la scene video en grand, rien a
                // proteger, la capsule reste au repos ; sur la page, elle se
                // masque avec les commandes (C12 : sous les alertes).
                // DYNAMIQUE-CHRONO-2 : pas de capsule sous la barre depliee.
                if (capsule) capsuleEnHaut,
                if (panneau && telephone && !enseignant)
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
                // GRILLE-COMMANDES (directeur, 11/11/2026) : au repos, plus
                // de bouton « Commandes » ; seul le Pointeur tenu reste, a
                // sa place dans la barre (l'enseignant voit qu'il l'a en
                // main, et le repose d'un appui).
                if (enseignant &&
                    vue.panneau == PanneauOuvert.aucun &&
                    BarreCommandesTelephone.aLePointeur(context, vue, actions))
                  Builder(
                    builder: (BuildContext contexte) =>
                        CommandesMasquables.visiblesDe(contexte)
                        ? const SizedBox.shrink()
                        : PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 0,
                            child: SafeArea(
                              top: false,
                              child: _PointeurTenuAuRepos(
                                vue: vue,
                                actions: actions,
                                local: local,
                              ),
                            ),
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
                : geometrie != null
                ? _commandesEleve(
                    ecran: ecran,
                    geometrie: geometrie,
                    zoom: zoom,
                    bas: bas,
                    commandesADroite: commandesADroite,
                    paletteADroite: paletteADroite,
                  )
                : SizedBox.fromSize(
                    size: ecran,
                    child: Stack(
                      children: <Widget>[
                        // Chez l'enseignant au telephone, rien en haut hors
                        // de la capsule et des alertes (posees dans le
                        // contenu).
                        if (!capsule)
                          PositionedDirectional(
                            top: 0,
                            start: 0,
                            end: 0,
                            child: haut,
                          ),
                        // Lot salle 2 (directeur, 25/10/2026) : la vignette se
                        // deplace au doigt et a la souris, aimantee aux quatre
                        // coins (standard Meet, FaceTime).
                        if (!scene && vue.voitVignetteSurSupport && !enseignant)
                          VignetteAimantee(
                            vue: vue,
                            largeur: telephone
                                ? largeurVignetteTelephone
                                : MesuresVignette.largeurPleinCadreLarge,
                            haut:
                                AppSpacing.lg +
                                (telephone
                                    ? (media?.boutonEleves == null
                                          ? 0
                                          : AppTouchTarget.standard +
                                                AppSpacing.sm)
                                    : 0),
                            bas:
                                AppSpacing.lg +
                                diametreBoutonAppel(context) +
                                2 * AppSpacing.sm +
                                AppSpacing.lg,
                          ),
                        // Plan §4 : le tiroir des Commandes et la feuille
                        // des eleves montent du bas, AU-DESSUS de la pilule
                        // de l'appel : a 360 en texte agrandi, ils se tassent
                        // au lieu de la recouvrir. Fiche 1, ligne 11 : ils
                        // s'arretent aussi sous la capsule.
                        PositionedDirectional(
                          top: hautColonne,
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                // Fiche 1, lignes 13 et 14 : chez
                                // l'enseignant, le zoom flotte au bord de fin,
                                // a mi-hauteur de l'ecran quand il y tient,
                                // sinon remonte juste au-dessus de
                                // « Commandes » et de la pilule (texte
                                // agrandi) : il ne les recouvre jamais.
                                if (zoom && enseignant)
                                  Expanded(
                                    child: _ZoomFlottant(
                                      actions: actions,
                                      milieu: ecran.height / 2 - hautColonne,
                                    ),
                                  ),
                                if ((panneau || eleves) && enseignant)
                                  Flexible(
                                    key: _clePanneau,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      // Pilote C8 : a 600 et plus, centre,
                                      // 640 au plus (feuille du bas M3 sur
                                      // tablette), hauteur du contenu.
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        heightFactor: 1,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: largeurMaxFeuille,
                                          ),
                                          child: eleves
                                              ? FeuilleElevesTelephone(
                                                  vue: vue,
                                                  actions: actions,
                                                  hauteur: hauteurFeuille,
                                                  ajuste: large,
                                                )
                                              : TiroirCommandesTelephone(
                                                  vue: vue,
                                                  actions: actions,
                                                  local: local,
                                                  hauteur: hauteurFeuille,
                                                  ajuste: large,
                                                  reduit: reduit,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                KeyedSubtree(
                                  key: _cleBas,
                                  child: sceneDevant
                                      ? _MesureHauteur(
                                          onHauteur: _surHauteurBasScene,
                                          child: bas,
                                        )
                                      : bas,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Zoom de la page (directeur, 25/10/2026 : « aucune
                        // commande de zoom vue sur ordinateur ») : une pilule
                        // flottante au bord droit, - et +, icones seules ;
                        // Ctrl + molette et le pincement restent.
                        // Plan §4 : un panneau ouvert au telephone prend le
                        // bas de l'ecran ; la pilule du zoom ne flotte pas
                        // par-dessus.
                        // Fiche 1, ligne 13 : ni sur un panneau ouvert, ni
                        // sur le profil deplie.
                        if (zoom && !enseignant)
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            end: AppSpacing.lg,
                            child: Center(
                              child: PiluleZoomSalle(
                                actions: actions,
                                couche: enseignant,
                              ),
                            ),
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

  /// Lot CORAN-ELEVE, telephone et tablette en portrait (pilote, 11/11) :
  /// la page a sa pleine taille ; au toucher, la vignette (deplacable aux
  /// quatre coins, lot salle 2), le zoom et la pilule de l'appel passent
  /// par-dessus, puis s'effacent au delai de [CommandesMasquables] ;
  /// la Dynamique chrono reste (posee dans le contenu).
  Widget _commandesSuperposees({
    required Size ecran,
    required bool zoom,
    required Widget bas,
  }) {
    final bool telephone = telephonePleinEcran(context);
    final EdgeInsets zoneSure = MediaQuery.paddingOf(context);
    return SizedBox.fromSize(
      size: ecran,
      child: Stack(
        children: <Widget>[
          if (vue.voitVignetteSurSupport)
            VignetteAimantee(
              vue: vue,
              largeur: telephone
                  ? largeurVignetteTelephone
                  : MesuresVignette.largeurPleinCadreLarge,
              haut: zoneSure.top + AppSpacing.lg,
              bas:
                  zoneSure.bottom +
                  AppSpacing.lg +
                  diametreBoutonAppel(context) +
                  2 * AppSpacing.sm +
                  AppSpacing.lg,
              // Lot VIGNETTE-TELEPHONE : glissee au bord, elle se range.
              rangeable: true,
              arrivee: _versRuban,
            ),
          // RUBAN-TELEPHONE : la phrase d'etat, en haut, sous la Dynamique
          // chrono, avant la vignette ; elle vient et part avec les commandes.
          PositionedDirectional(
            top: zoneSure.top + AppSpacing.lg,
            start: AppSpacing.lg,
            width: math.max(
              0,
              ecran.width -
                  2 * AppSpacing.lg -
                  (vue.voitVignetteSurSupport
                      ? largeurVignetteTelephone + AppSpacing.sm
                      : 0),
            ),
            child: _StatutEnHaut(vue: vue),
          ),
          if (zoom)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: AppSpacing.lg,
              child: Center(child: PiluleZoomSalle(actions: actions)),
            ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: KeyedSubtree(key: _cleBas, child: bas),
            ),
          ),
        ],
      ),
    );
  }

  /// Lot CORAN-ELEVE : ce qui flotte autour de la page de l'eleve, chacun a
  /// sa place hors de la page ([GeometrieEleve]) ; tout se masque ensemble
  /// au delai, et la place reste reservee (la page ne bouge pas).
  Widget _commandesEleve({
    required Size ecran,
    required GeometrieEleve geometrie,
    required bool zoom,
    required Widget bas,
    required Widget? commandesADroite,
    required bool paletteADroite,
  }) {
    final EdgeInsets zoneSure = MediaQuery.paddingOf(context);
    final bool cote = geometrie.cote;
    final bool vignette = vue.voitVignetteSurSupport;
    if (geometrie.superposee) {
      return _commandesSuperposees(ecran: ecran, zoom: zoom, bas: bas);
    }
    return SizedBox.fromSize(
      size: ecran,
      child: Stack(
        children: <Widget>[
          // La vignette de l'enseignant : en haut, au bout. Sur les cotes,
          // grande, et deplacable entre le haut de la bande de fin et le bas
          // de la bande de debut (les deux coins libres) ; ailleurs, elle
          // reste dans la rangee du haut (tout autre coin tombe sur le texte
          // ou sur les commandes de l'appel).
          if (vignette)
            VignetteAimantee(
              vue: vue,
              largeur: cote
                  ? largeurCadreBande(geometrie)
                  : largeurVignetteTelephone,
              haut: zoneSure.top + AppSpacing.lg,
              bas: zoneSure.bottom + AppSpacing.lg,
              coinsPermis: cote
                  ? const <CoinVignette>[
                      CoinVignette.hautFin,
                      CoinVignette.basDebut,
                    ]
                  : const <CoinVignette>[CoinVignette.hautFin],
              // Lot VIGNETTE-TELEPHONE : sur les cotes (ordinateur, paysage),
              // la languette vit au bord de la bande, hors de la page. En
              // Interface guidee (rangees), l'enfant garde toujours le visage
              // de son enseignant : pas de rangement.
              rangeable: cote,
              arrivee: _versRuban,
            ),
          // RUBAN-TELEPHONE (MODES-AFFICHAGE §4) : sur un ecran large, la bande
          // de cote porte aussi le cadre de l'eleve qui recite, apres celui de
          // l'enseignant : au milieu de la bande de debut (sous la Dynamique
          // chrono, au-dessus du coin bas ou l'on peut poser l'enseignant), a
          // la meme taille. La page garde toute sa taille, rien ne la
          // recouvre ; une personne, un cadre (le recitant n'est nulle part ailleurs
          // dans ce mode).
          if (PorteeMediaSalle.de(context)?.identiteRecitant
              case final String recitant when cote)
            PositionedDirectional(
              start: AppSpacing.lg,
              top: 0,
              bottom: 0,
              width: largeurCadreBande(geometrie),
              child: Center(
                child: VignetteVideo(
                  vue: vue,
                  largeur: largeurCadreBande(geometrie),
                  identite: recitant,
                  nom: vue.recitantPrenom ?? '',
                  touchable: false,
                  avecSignal: false,
                  cleCadre: cleRecitantBande,
                ),
              ),
            ),
          // RUBAN-TELEPHONE : sur les cotes, la phrase d'etat en haut de la
          // bande de debut, sous la Dynamique chrono ; elle vient et part avec
          // les commandes. (En Interface guidee, elle reste sur la pilule du
          // bas, dans sa rangee reservee.)
          if (cote)
            PositionedDirectional(
              // DYNAMIQUE-CHRONO-1 : sous la zone de la barre, mesuree.
              top:
                  _hauteurHautBande ??
                  zoneSure.top +
                      AppSpacing.lg +
                      hauteurPiluleEtat +
                      AppSpacing.sm,
              start: AppSpacing.lg,
              width: math.max(0, geometrie.bande - 2 * AppSpacing.lg),
              child: _StatutEnHaut(vue: vue),
            ),
          // Le zoom : sur les cotes, debout au milieu de la bande de fin ;
          // sinon couche, dans la rangee du haut, avant la vignette.
          if (zoom)
            cote
                // Sur l'axe de la bande, comme la vignette et la pilule de
                // l'appel ; sans fond (les boutons ronds portent le leur) :
                // plus de pilule blanche a moitie vide quand un seul sens du
                // zoom est possible.
                ? PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: 0,
                    width: geometrie.bande,
                    child: Center(
                      child: PiluleZoomSalle(actions: actions, nue: true),
                    ),
                  )
                : PositionedDirectional(
                    top: zoneSure.top + AppSpacing.lg,
                    end:
                        AppSpacing.lg +
                        (vignette
                            ? largeurVignetteTelephone + AppSpacing.sm
                            : 0),
                    child: PiluleZoomSalle(actions: actions, horizontale: true),
                  ),
          // Les commandes de l'appel : sur les cotes, en bas de la bande de
          // fin (l'infobulle reste dans la bande) ; sinon en bas, sous la
          // page, mesurees pour que la page s'arrete au-dessus. Sous la page,
          // l'infobulle se poserait sur la derniere ligne : elle ne s'affiche
          // pas (le nom reste lu par le lecteur d'ecran).
          PositionedDirectional(
            end: 0,
            bottom: 0,
            width: cote ? geometrie.bande : ecran.width,
            child: SafeArea(
              top: false,
              child: KeyedSubtree(
                key: _cleBas,
                child: cote
                    ? bas
                    : TooltipVisibility(
                        visible: false,
                        child: _MesureHauteur(
                          onHauteur: _surHauteurBas,
                          child: bas,
                        ),
                      ),
              ),
            ),
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
    );
  }
}

/// La pilule du zoom de l'enseignant au telephone, dans la place libre
/// au-dessus du bas : son centre a [milieu] (mi-hauteur de l'ecran, dans le
/// repere de cette place), ramene dans la place si elle n'y tient pas.
class _ZoomFlottant extends StatelessWidget {
  const _ZoomFlottant({required this.actions, required this.milieu});

  final ActionsSeance actions;
  final double milieu;

  @override
  Widget build(BuildContext context) {
    final bool seul =
        (actions.onZoomPlus == null) != (actions.onZoomMoins == null);
    final double hauteur = seul
        ? diametreBoutonAppel(context)
        : 2 * diametreBoutonAppel(context) + 3 * AppSpacing.sm;
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) {
        final double place = c.maxHeight;
        final double haut = math.max(
          0,
          math.min(milieu - hauteur / 2, place - hauteur - AppSpacing.sm),
        );
        return Stack(
          children: <Widget>[
            PositionedDirectional(
              top: haut,
              end: AppSpacing.lg,
              child: PiluleZoomSalle(actions: actions, couche: true),
            ),
          ],
        );
      },
    );
  }
}

/// RUBAN-TELEPHONE (directeur, 11/11/2026, cahier §8 : « messages tantot en
/// haut, tantot en bas ») : la phrase d'etat de l'eleve posee en haut, sous la
/// Dynamique chrono, au lieu d'etre posee sans fond sur la page au-dessus de la
/// pilule. Elle vit dans la couche des commandes : elle se lit a l'entree (le
/// micro en attente retient les commandes [AppMouvement.ilePassage]) et a
/// chaque toucher qui les ramene, puis part avec elles ; jamais posee sur la
/// page pour de bon. Le lecteur d'ecran l'entend comme avant (zone vivante pour
/// le micro) ; les commandes restent toujours visibles pour lui.
class _StatutEnHaut extends StatelessWidget {
  const _StatutEnHaut({required this.vue});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final String? micro = vue.texteMicroEnAttente;
    final String? camera = vue.texteCameraInterdite;
    final Widget? phrase = micro != null
        ? StatutMicroEnAttente(texte: micro)
        : camera != null
        ? StatutCameraInterdite(texte: camera, surFond: true)
        : null;
    if (phrase == null) return const SizedBox.shrink();
    return Align(
      key: cleStatutEnHaut,
      alignment: AlignmentDirectional.topStart,
      child: phrase,
    );
  }
}

/// RUBAN-TELEPHONE : la cle de la phrase d'etat posee en haut (tests).
const Key cleStatutEnHaut = ValueKey<String>('statut-en-haut');

/// La hauteur de la pilule d'etat ([DynamiqueChrono]).
const double hauteurPiluleEtat = AppSpacing.xxxl + AppSpacing.xs;

/// Un coin de la scene ou la vignette s'aimante.
enum CoinVignette { hautDebut, hautFin, basDebut, basFin }

/// Lot salle 2 (directeur, 25/10/2026) : la vignette video, deplacable au
/// doigt et a la souris, aimantee au coin le plus proche du lacher (standard
/// Meet, FaceTime). Le coin choisi est garde pendant la seance (stockage de
/// la route). Toucher la vignette la met toujours en grand.
///
/// Lot VIGNETTE-TELEPHONE (directeur, 11/11/2026 : « bouger les vignettes de
/// video ou les cacher comme on le veut ») : quand elle est [rangeable],
/// glissee au-dela du bord gauche ou droit, elle se range et laisse une
/// [LanguetteBord] sur ce bord, a la hauteur du rangement ; toucher ou tirer
/// la languette la ramene au coin le plus proche de ce bord. Une poignee
/// (« Ranger la video de … ») la range d'un simple appui (WCAG 2.5.7).
/// Ranger la video ne touche qu'a l'affichage chez soi : la camera de
/// l'enseignant et les droits ne changent pas, rien n'est envoye au serveur.
/// L'etat range est garde pendant la seance, comme le coin.
class VignetteAimantee extends StatefulWidget {
  const VignetteAimantee({
    required this.vue,
    required this.largeur,
    required this.haut,
    required this.bas,
    this.coinsPermis,
    this.rangeable = false,
    this.arrivee = false,
    super.key,
  });

  /// RUBAN-TELEPHONE (MODES-AFFICHAGE §5) : vrai pendant l'image ou la salle
  /// passe du mode Classe a la page : la vignette arrive en grandissant
  /// (une fois, au montage), pendant que la grille retrecit vers elle.
  final bool arrivee;

  final VueSeance vue;
  final double largeur;

  /// Lot CORAN-ELEVE : les coins ou la vignette peut se poser sans recouvrir
  /// la page de l'eleve (le premier est celui par defaut) ; lachee ailleurs,
  /// elle rejoint le plus proche. `null` : les quatre coins.
  final List<CoinVignette>? coinsPermis;

  /// La marge des coins du haut (sous la ligne d'etat) et du bas (au-dessus
  /// de la pilule d'appel).
  final double haut;
  final double bas;

  /// Lot VIGNETTE-TELEPHONE : la vignette se range au bord (eleve, tuteur,
  /// controleur devant une page) ; faux ailleurs (rien ne change).
  final bool rangeable;

  /// La cle de la vignette deplacable (tests).
  static const Key cle = ValueKey<String>('vignette-aimantee');

  /// La poignee « Ranger la video » (tests).
  static const Key clePoignee = ValueKey<String>('vignette-poignee');

  /// La languette de la vignette rangee (tests).
  static const Key cleLanguette = ValueKey<String>('vignette-languette');

  @override
  State<VignetteAimantee> createState() => _EtatVignetteAimantee();
}

/// Une vignette rangee : le bord physique et le haut de la vignette au
/// moment du rangement (la languette se pose a cette hauteur).
@immutable
class _Rangement {
  const _Rangement({required this.gauche, required this.haut});

  final bool gauche;
  final double haut;
}

class _EtatVignetteAimantee extends State<VignetteAimantee>
    with SingleTickerProviderStateMixin {
  static const String _cleStockage = 'salle-vignette-coin';
  static const String _cleRangement = 'salle-vignette-rangee';

  /// Le ressort qui pose la vignette apres le lacher (sans rebond).
  late final AnimationController _ressort = AnimationController.unbounded(
    vsync: this,
  )..addListener(_suivreRessort);

  /// Le coin haut-gauche de la vignette pendant le geste ou le ressort ;
  /// `null` au repos (a son coin, ou rangee).
  Offset? _position;
  Offset _depart = Offset.zero;
  Offset _arrivee = Offset.zero;

  /// Vrai quand le geste en cours a commence sur la languette.
  bool _depuisLanguette = false;

  /// Le chemin parcouru vers l'interieur depuis la languette.
  double _tire = 0;

  /// La taille de la scene (mesuree a chaque mise en page).
  Size _ecran = Size.zero;

  final FocusNode _noeudPoignee = FocusNode(debugLabel: 'vignette-poignee');
  final FocusNode _noeudLanguette = FocusNode(debugLabel: 'vignette-languette');

  @override
  void dispose() {
    _ressort.dispose();
    _noeudPoignee.dispose();
    _noeudLanguette.dispose();
    super.dispose();
  }

  double get _hauteur => widget.largeur / MesuresVignette.ratio;

  bool get _ltr => Directionality.of(context) == TextDirection.ltr;

  CoinVignette get _coin {
    final CoinVignette? lu = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _cleStockage) as CoinVignette?;
    final List<CoinVignette>? permis = widget.coinsPermis;
    if (permis == null) return lu ?? CoinVignette.hautFin;
    return lu != null && permis.contains(lu) ? lu : permis.first;
  }

  void _ecrireCoin(CoinVignette coin) =>
      PageStorage.maybeOf(context)
          ?.writeState(context, coin, identifier: _cleStockage);

  _Rangement? get _rangement => widget.rangeable
      ? PageStorage.maybeOf(context)
                ?.readState(context, identifier: _cleRangement)
            as _Rangement?
      : null;

  void _ecrireRangement(_Rangement? r) =>
      PageStorage.maybeOf(context)
          ?.writeState(context, r, identifier: _cleRangement);

  static bool _enHaut(CoinVignette c) =>
      c == CoinVignette.hautDebut || c == CoinVignette.hautFin;
  static bool _debut(CoinVignette c) =>
      c == CoinVignette.hautDebut || c == CoinVignette.basDebut;

  /// Le coin permis le plus proche de [voulu] (meme rangee d'abord).
  CoinVignette _permis(CoinVignette voulu) {
    final List<CoinVignette>? permis = widget.coinsPermis;
    if (permis == null || permis.contains(voulu)) return voulu;
    int ecart(CoinVignette c) =>
        (_enHaut(c) == _enHaut(voulu) ? 0 : 2) +
        (_debut(c) == _debut(voulu) ? 0 : 1);
    return permis.reduce(
      (CoinVignette a, CoinVignette b) => ecart(b) < ecart(a) ? b : a,
    );
  }

  /// Le coin pres de [centre] ; avec [bord], le coin de ce bord physique
  /// d'abord (rappel depuis la languette).
  CoinVignette _coinPres(Offset centre, {bool? bord}) {
    final bool gauche = bord ?? centre.dx < _ecran.width / 2;
    final bool enHaut = centre.dy < _ecran.height / 2;
    // Debut et fin suivent le sens de lecture.
    final bool debut = gauche == _ltr;
    final CoinVignette voulu = enHaut
        ? (debut ? CoinVignette.hautDebut : CoinVignette.hautFin)
        : (debut ? CoinVignette.basDebut : CoinVignette.basFin);
    final List<CoinVignette>? permis = widget.coinsPermis;
    if (bord != null && permis != null && !permis.contains(voulu)) {
      final Iterable<CoinVignette> memeBord = permis.where(
        (CoinVignette c) => _debut(c) == debut,
      );
      if (memeBord.isNotEmpty) return memeBord.first;
    }
    return _permis(voulu);
  }

  /// Le coin haut-gauche de la vignette posee a [coin].
  Offset _placeDuCoin(CoinVignette coin) {
    final bool gauche = _debut(coin) == _ltr;
    return Offset(
      gauche ? AppSpacing.lg : _ecran.width - AppSpacing.lg - widget.largeur,
      _enHaut(coin) ? widget.haut : _ecran.height - widget.bas - _hauteur,
    );
  }

  /// [y] ramene entre la marge du haut et celle du bas.
  double _borne(double y, double hauteur) => y.clamp(
    widget.haut,
    math.max(widget.haut, _ecran.height - widget.bas - hauteur),
  );

  /// La vignette rangee : juste hors de l'ecran, sur son bord.
  Offset _placeRangee(_Rangement r) => Offset(
    r.gauche ? -widget.largeur : _ecran.width,
    _borne(r.haut, _hauteur),
  );

  Offset _placeAuRepos() {
    final _Rangement? r = _rangement;
    return r == null ? _placeDuCoin(_coin) : _placeRangee(r);
  }

  void _suivreRessort() {
    if (!mounted) return;
    setState(() => _position = Offset.lerp(_depart, _arrivee, _ressort.value));
  }

  /// Pose la vignette a [arrivee] sur le ressort (sans rebond) ; sans
  /// mouvement si « reduire les animations » ou [instantane].
  void _allerA(
    Offset arrivee, {
    Offset vitesse = Offset.zero,
    bool instantane = false,
  }) {
    final Offset depart = _position ?? arrivee;
    final double distance = (arrivee - depart).distance;
    if (instantane || AppMouvement.mouvementReduit(context) || distance < 1) {
      _ressort.stop();
      setState(() => _position = null);
      return;
    }
    _depart = depart;
    _arrivee = arrivee;
    final Offset sens = (arrivee - depart) / distance;
    // L'elan du lacher, dans le sens du trajet ; borne pour que le ressort
    // critique n'aille jamais au-dela de sa place (aucun rebond).
    final double elan =
        ((vitesse.dx * sens.dx + vitesse.dy * sens.dy) / distance).clamp(
          0,
          _elanMax,
        );
    _ressort.value = 0;
    _ressort
        .animateWith(SpringSimulation(AppMouvement.ressort, 0, 1, elan))
        .whenComplete(() {
          if (mounted) setState(() => _position = null);
        });
  }

  /// Au-dela, le ressort critique depasserait sa place.
  static const double _elanMax = 10;

  void _ranger({
    required bool gauche,
    Offset vitesse = Offset.zero,
    bool instantane = false,
  }) {
    final double haut = _borne((_position ?? _placeDuCoin(_coin)).dy, _hauteur);
    final _Rangement r = _Rangement(gauche: gauche, haut: haut);
    _ecrireRangement(r);
    _allerA(_placeRangee(r), vitesse: vitesse, instantane: instantane);
  }

  void _montrer({
    required _Rangement r,
    Offset vitesse = Offset.zero,
    bool instantane = false,
  }) {
    final Offset depart = _position ?? _placeRangee(r);
    final CoinVignette coin = _coinPres(
      Offset(r.gauche ? 0 : _ecran.width, depart.dy + _hauteur / 2),
      bord: r.gauche,
    );
    _ecrireCoin(coin);
    _ecrireRangement(null);
    _position = depart;
    _allerA(_placeDuCoin(coin), vitesse: vitesse, instantane: instantane);
  }

  /// La poignee : ranger d'un appui. Au clavier, le focus passe a la
  /// languette (sans mouvement, pour qu'elle existe tout de suite).
  void _rangerParAppui({required bool gauche}) {
    final bool clavier = _noeudPoignee.hasFocus;
    _ranger(gauche: gauche, instantane: clavier);
    if (clavier) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _noeudLanguette.requestFocus();
      });
    }
  }

  /// La languette : montrer d'un appui ; au clavier, le focus passe a la
  /// poignee.
  void _montrerParAppui(_Rangement r) {
    final bool clavier = _noeudLanguette.hasFocus;
    _montrer(r: r, instantane: clavier);
    if (clavier) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _noeudPoignee.requestFocus();
      });
    }
  }

  void _debutGeste(DragStartDetails d) {
    _ressort.stop();
    final _Rangement? r = _rangement;
    setState(() {
      _depuisLanguette = r != null;
      _tire = 0;
      _position ??= _placeAuRepos();
    });
  }

  void _suivreGeste(DragUpdateDetails d) {
    final Offset? p = _position;
    if (p == null) return;
    final _Rangement? r = _rangement;
    if (_depuisLanguette && r != null) {
      _tire += r.gauche ? d.delta.dx : -d.delta.dx;
    }
    // La vignette suit le doigt, sans retard ni lissage.
    setState(() => _position = p + d.delta);
  }

  void _finGeste(DragEndDetails d) {
    final Offset? p = _position;
    if (p == null) return;
    final Offset v = d.velocity.pixelsPerSecond;
    final double l = widget.largeur;
    final _Rangement? r = _rangement;
    if (_depuisLanguette && r != null) {
      // Tirer la languette vers l'interieur ramene la vignette ; un tirage
      // trop court la laisse rangee.
      final double elan = r.gauche ? v.dx : -v.dx;
      if (_tire >= AppSpacing.xxl || elan > AppMouvement.elanRangement) {
        _montrer(r: r, vitesse: v);
      } else {
        _allerA(_placeRangee(r), vitesse: v);
      }
      return;
    }
    if (widget.rangeable) {
      // Ranger : la vignette passe a moitie au-dela du bord, ou elle y est
      // lancee vite apres en avoir passe le quart. Un glissement court (le
      // bord est a 16 de la vignette) ne range jamais.
      bool vers({required bool gauche}) {
        final double hors = gauche ? -p.dx : p.dx + l - _ecran.width;
        final double elan = gauche ? -v.dx : v.dx;
        return hors > l / 2 ||
            (hors > l / 4 && elan > AppMouvement.elanRangement);
      }

      for (final bool gauche in <bool>[true, false]) {
        if (vers(gauche: gauche)) {
          _ranger(gauche: gauche, vitesse: v);
          return;
        }
      }
    }
    final CoinVignette coin = _coinPres(p + Offset(l, _hauteur) / 2);
    _ecrireCoin(coin);
    _allerA(_placeDuCoin(coin), vitesse: v);
  }

  void _annulerGeste() {
    if (_position == null || _ressort.isAnimating) return;
    _allerA(_placeAuRepos());
  }

  /// Le glisser de la vignette et de sa languette. La page dessous a son
  /// propre glissement horizontal ([GlisserPage]), qui part a 18 points :
  /// le seuil du glisser de la vignette est plus court (16), pour qu'un
  /// glissement commence sur la vignette la deplace toujours, et jamais la
  /// page. Un appui sans deplacement reste un appui ([Pressable]).
  Widget _glissable(Widget enfant) => RawGestureDetector(
    gestures: <Type, GestureRecognizerFactory>{
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            PanGestureRecognizer.new,
            (PanGestureRecognizer r) => r
              // Le premier deplacement compte le seuil : la vignette ne
              // saute pas derriere le doigt.
              ..dragStartBehavior = DragStartBehavior.down
              ..gestureSettings = const DeviceGestureSettings(
                touchSlop: AppSpacing.sm,
              )
              ..onStart = _debutGeste
              ..onUpdate = _suivreGeste
              ..onEnd = _finGeste
              ..onCancel = _annulerGeste,
          ),
    },
    child: enfant,
  );

  /// Pose [child] a l'abscisse physique [x] (depuis le bord gauche de la
  /// scene) : le geste et les bords de l'ecran sont physiques ; la pose passe
  /// par le debut et la fin du sens de lecture.
  Widget _poser({
    required Key cle,
    required double x,
    required double largeur,
    required double top,
    required Widget child,
  }) => PositionedDirectional(
    key: cle,
    start: _ltr ? x : _ecran.width - x - largeur,
    top: top,
    child: child,
  );

  /// Pendant un geste ou un ressort, la poignee et la languette restent
  /// dans l'arbre (leur geste en cours n'est pas perdu) mais ne se voient
  /// pas, ne se touchent pas et ne se lisent pas. La forme de l'arbre ne
  /// change pas d'un etat a l'autre (sinon le geste serait perdu).
  Widget _pendantGeste({required bool auRepos, required Widget child}) =>
      ExcludeSemantics(
        excluding: !auRepos,
        child: IgnorePointer(
          ignoring: !auRepos,
          child: Opacity(opacity: auRepos ? 1 : 0, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final String nom = deDevant(widget.vue.nomEnseignant);
    return Positioned.fill(
      // DYNAMIQUE-CHRONO-2 : pas de vignette sous la barre depliee, au
      // telephone (sur les cotes, elle vit dans la bande, hors de la barre).
      child: CacheSousDynamique(
        actif: !widget.rangeable,
        child: LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints c) {
            _ecran = c.biggest;
            final _Rangement? r = _rangement;
            final Offset? mobile = _position;
            final Offset place = mobile ?? _placeAuRepos();
            final bool auRepos = mobile == null;
            final bool gauche =
                place.dx + widget.largeur / 2 < _ecran.width / 2;
            final double hautLanguette = _borne(
              place.dy + _hauteur / 2 - LanguetteBord.hauteur / 2,
              LanguetteBord.hauteur,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                if (r == null || !auRepos)
                  _poser(
                    cle: const ValueKey<String>('pose-vignette'),
                    x: place.dx,
                    largeur: widget.largeur,
                    top: place.dy,
                    child: _glissable(
                      KeyedSubtree(
                        key: VignetteAimantee.cle,
                        child: PassageVisages(
                          jouer: widget.arrivee,
                          facon: FaconVisages.entree,
                          duree: AppMouvement.deplacementEntree,
                          alignement: Alignment.center,
                          echelle: AppMouvement.echelleVersIle,
                          child: VignetteVideo(
                            vue: widget.vue,
                            largeur: widget.largeur,
                          ),
                        ),
                      ),
                    ),
                  ),
                // La poignee, au bord de la vignette posee : la ranger d'un
                // appui, sans glisser (WCAG 2.5.7) ; elle se glisse aussi.
                // Pendant un geste, elle reste dans l'arbre, invisible : un
                // glisser commence sur elle n'est pas perdu.
                if (widget.rangeable && r == null)
                  _poser(
                    cle: const ValueKey<String>('pose-poignee'),
                    x: gauche ? 0 : _ecran.width - LanguetteBord.cible,
                    largeur: LanguetteBord.cible,
                    top: hautLanguette,
                    child: _pendantGeste(
                      auRepos: auRepos,
                      child: _glissable(
                        LanguetteBord(
                          key: VignetteAimantee.clePoignee,
                          bord: gauche
                              ? BordLanguette.gauche
                              : BordLanguette.droite,
                          icone: AppIcons.suivant,
                          retourner: gauche,
                          libelle: t.salle.vignette.ranger(deNom: nom),
                          focusNode: _noeudPoignee,
                          onPress: () => _rangerParAppui(gauche: gauche),
                        ),
                      ),
                    ),
                  ),
                // La vignette rangee : la languette sur son bord, en fondu ;
                // invisible (mais dans l'arbre) pendant qu'on la tire.
                if (r != null)
                  _poser(
                    cle: const ValueKey<String>('pose-languette'),
                    x: r.gauche ? 0 : _ecran.width - LanguetteBord.cible,
                    largeur: LanguetteBord.cible,
                    top: _borne(
                      _borne(r.haut, _hauteur) +
                          _hauteur / 2 -
                          LanguetteBord.hauteur / 2,
                      LanguetteBord.hauteur,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: AppMouvement.duree(
                        context,
                        AppMouvement.apparition,
                      ),
                      curve: AppMouvement.entree,
                      builder: (
                        BuildContext _,
                        double opacite,
                        Widget? enfant,
                      ) => Opacity(opacity: opacite, child: enfant),
                      child: _pendantGeste(
                        auRepos: auRepos,
                        child: _glissable(
                          LanguetteBord(
                            key: VignetteAimantee.cleLanguette,
                            bord: r.gauche
                                ? BordLanguette.gauche
                                : BordLanguette.droite,
                            icone: AppIcons.camera,
                            libelle: t.salle.vignette.montrer(deNom: nom),
                            focusNode: _noeudLanguette,
                            onPress: () => _montrerParAppui(r),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Plan §4 : le rappel de « Commandes » de l'enseignant au telephone, si le
/// tiroir a quelque chose a montrer. Pilote C11 : le Tableau (onglet Support)
/// suffit, meme sans droit de presenter ; [CommandesPedagogiques.aDesEntrees]
/// reste celui de l'ordinateur, ou le panneau n'a pas de ligne Tableau.
VoidCallback? _declencheur(ActionsSeance actions, VueSeance vue) =>
    CommandesPedagogiques.aDesEntrees(vue, actions) ||
        (vue.voitCommandes && actions.onTableau != null)
    ? actions.onCommandes
    : null;

/// GRILLE-COMMANDES : la barre de l'enseignant ([BarreCommandesTelephone]),
/// a la marge de l'ecran (16), jamais plus large qu'une feuille du bas.
class _BarreEnseignant extends StatelessWidget {
  const _BarreEnseignant({
    required this.vue,
    required this.actions,
    required this.local,
    this.seulPointeur = false,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final bool seulPointeur;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: largeurMaxFeuille),
      child: BarreCommandesTelephone(
        vue: vue,
        actions: actions,
        local: local,
        onPlus: _declencheur(actions, vue),
        seulPointeur: seulPointeur,
      ),
    ),
  );
}

/// Au repos (commandes masquees), le Pointeur tenu : seul, a sa place dans
/// la barre. Rien quand il n'est pas en main.
class _PointeurTenuAuRepos extends ConsumerWidget {
  const _PointeurTenuAuRepos({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OutilDock? outil = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    if (outil != OutilDock.pointeur) return const SizedBox.shrink();
    return Padding(
      // Les memes marges que la barre : le Pointeur ne bouge pas.
      padding: MediaQuery.sizeOf(context).width < 360
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.lg,
            )
          : const EdgeInsets.all(AppSpacing.lg),
      child: _BarreEnseignant(
        vue: vue,
        actions: actions,
        local: local,
        seulPointeur: true,
      ),
    );
  }
}

/// Pilote C8 : la largeur maximale du tiroir et de la feuille des eleves
/// (feuille du bas Material 3 sur tablette).
const double largeurMaxFeuille = AppSpacing.respiration * 10;

/// La part maximale de l'ecran que prend le panneau des Commandes.
const double _partPanneau = 0.6;

/// Le haut de la scene : le bandeau de secours s'il y a lieu, l'alerte
/// (camera) ; « Eleves », la vignette et la croix en coin.
///
/// DYNAMIQUE-CHRONO-1 : la Dynamique chrono, la presence et la mention n'y
/// sont plus (elles ont leur rangee reservee, au-dessus), sauf dans la bande
/// de debut d'un ecran large ([zone]) : c'est alors la place reservee.
class _Haut extends StatelessWidget {
  const _Haut({
    required this.vue,
    required this.actions,
    required this.largeur,
    required this.vignette,
    required this.aCote,
    this.microOuvert = false,
    this.zone = false,
  });

  /// Le micro local est ouvert : signe dans la Dynamique chrono.
  final bool microOuvert;

  /// Vrai : la zone de la Dynamique chrono se pose ici (bande de debut).
  final bool zone;

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
    // Lot salle 3 (directeur, 25/10/2026) : un support ouvert se ferme. La
    // croix « Ranger dans la bibliotheque » se tient au bord de fin, en haut,
    // pour l'enseignant qui presente une page.
    final VoidCallback? ranger = vue.voitRanger ? actions.onRanger : null;
    final Widget? fermer = ranger == null
        ? null
        : BoutonIcone(
            key: const ValueKey<String>('salle-ranger-support'),
            icone: AppIcons.fermer,
            libelle: t.salle.seance.rangement.ranger,
            onPress: ranger,
            forme: FormeBoutonIcone.appel,
          );
    final Widget? ligne = zone
        ? ZoneChrono(
            vue: vue,
            largeur: math.max(0, largeur - 2 * AppSpacing.lg),
            onPause: actions.onPause,
            microOuvert: microOuvert,
          )
        : null;
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
                  if (ligne != null) Flexible(child: ligne),
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
                  ?fermer,
                ],
              )
            // Arbitrage du pilote (24/10/2026) : la pilule d'etat occupe seule
            // la premiere rangee, a gauche, phrase entiere ; Eleves et la
            // vignette descendent sur une seconde rangee, a droite, 8 sous la
            // pilule.
            else if (ligne != null)
              Align(alignment: AlignmentDirectional.topStart, child: ligne),
            if (!aCote &&
                (eleves != null || vignette || fermer != null)) ...<Widget>[
              if (ligne != null) Ecart.vSm,
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
                    ?fermer,
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
class PiluleZoomSalle extends StatelessWidget {
  const PiluleZoomSalle({
    required this.actions,
    this.horizontale = false,
    this.couche = false,
    this.nue = false,
    super.key,
  });

  /// Directeur, 11/11/2026 : sans fond. Les boutons ronds portent deja le
  /// leur ; un bouton absent (premier ou dernier palier) garde sa place,
  /// invisible, et ne laisse plus une pilule a moitie vide.
  final bool nue;

  /// Pilote C2 : la couche sombre de l'enseignant au telephone.
  final bool couche;

  final ActionsSeance actions;

  /// Ordinateur (plan du 26/10/2026) : moins puis plus, en rangee, dans la
  /// ligne du titre de la page.
  final bool horizontale;

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
    final Widget moins = bouton(
      const ValueKey<String>('salle-zoom-moins'),
      AppIcons.zoomMoins,
      t.salle.seance.zoomMoins,
      actions.onZoomMoins,
    );
    // Pilote C7 : une seule action possible (100 % : « + » seulement ;
    // 200 % : « - » seulement), un seul bouton rond, sans case vide.
    // Telephone de l'enseignant seulement : l'ordinateur garde sa pilule.
    if (couche &&
        (actions.onZoomPlus == null) != (actions.onZoomMoins == null)) {
      final Widget seul = KeyedSubtree(
        key: const ValueKey<String>('salle-zoom'),
        child: actions.onZoomPlus != null
            ? bouton(
                const ValueKey<String>('salle-zoom-plus'),
                AppIcons.zoomPlus,
                t.salle.seance.zoomPlus,
                actions.onZoomPlus,
              )
            : moins,
      );
      return couche ? CoucheSalle(child: seul) : seul;
    }
    final Widget pilule = DecoratedBox(
      key: const ValueKey<String>('salle-zoom'),
      decoration: nue
          ? const BoxDecoration()
          : (couche ? palette.coucheSalle : palette.piluleSalle).decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Flex(
          direction: horizontale ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: <Widget>[
            if (horizontale) moins,
            bouton(
              const ValueKey<String>('salle-zoom-plus'),
              AppIcons.zoomPlus,
              t.salle.seance.zoomPlus,
              actions.onZoomPlus,
            ),
            if (!horizontale) moins,
          ],
        ),
      ),
    );
    return couche ? CoucheSalle(child: pilule) : pilule;
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
    this.enseignantTelephone = false,
    this.statutEnTete = false,
  });

  /// RUBAN-TELEPHONE : la phrase d'etat de l'eleve est posee en haut
  /// ([_StatutEnHaut]), pas au-dessus de la pilule.
  final bool statutEnTete;

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Plan §4 : la pilule de l'enseignant au telephone ne garde que micro,
  /// camera et quitter ; le tableau passe dans l'onglet Outils du tiroir, et
  /// « Commandes » ouvre le tiroir (dans la pilule, au toucher ; seul en bas,
  /// au repos).
  final bool enseignantTelephone;

  /// Telephone : la palette du tableau au-dessus de la pilule d'appel ;
  /// ordinateur : au bord droit (posee ailleurs).
  final bool paletteAuDessus;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? commandes = actions.onCommandes;
    // GRILLE-COMMANDES (directeur, 11/11/2026) : chez l'enseignant, UNE
    // barre aux cases egales (Micro, Camera, Eleves, Pointeur, Plus,
    // Quitter) ; la palette du tableau ouvert reste juste au-dessus.
    if (enseignantTelephone) {
      final Widget barre = _BarreEnseignant(
        vue: vue,
        actions: actions,
        local: local,
      );
      if (!paletteAuDessus || !vue.tableauOuvert || actions.onTableau == null) {
        return barre;
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
          barre,
        ],
      );
    }
    // Standard des commandes d'appel (24/10/2026) : une seule pilule, « Plus »
    // dedans ; aucun declencheur a cote. S0.3b : tableau ouvert, sa palette
    // juste au-dessus, horizontale.
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      agrandi: local.agrandi,
      statutEnTete: statutEnTete,
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
