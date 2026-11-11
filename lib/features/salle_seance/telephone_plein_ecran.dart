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
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/commandes_masquables.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/etat_outils.dart';
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
import 'glisser_page.dart';
import 'media_salle.dart';
import 'palette_tableau.dart';
import 'panneau_seance.dart' show largeurPanneauSeance;
import 'pilule_etat_salle.dart';
import 'salle_seance.dart' show BandeauSecours, EtatLocalSeance;
import 'surface_page_fixe.dart';
import 'telephone_enseignant.dart';
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

/// Fiche 1 (26/10/2026) : la composition du telephone de l'enseignant (la
/// capsule, « Commandes », le tiroir, la feuille des eleves) vaut pour toute
/// fenetre de moins de 840 points de large : telephone et iPad en portrait.
bool salleTelephoneEnseignant(BuildContext context, VueSeance vue) =>
    pleinEcranSalle(context) &&
    vue.role == RoleSeance.enseignant &&
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

/// Lot CORAN-ELEVE (directeur, 11/11/2026) : la place de la page de l'eleve
/// (et du tuteur, du controleur) et de ce qui l'entoure, pour que rien ne
/// recouvre le texte ni le numero de page.
///
/// - **Cotes** ([cote]) : quand les bandes vides a cote d'une page pleine
///   hauteur logent la pilule de l'appel (ordinateur, tablette et telephone
///   en paysage), la page garde toute la hauteur ; l'ile en haut de la bande
///   de debut ; la vignette de l'enseignant en haut de la bande de fin
///   (deplacable en bas de la bande de debut), le zoom au milieu et les
///   commandes de l'appel en bas de la bande de fin ; chaque bande large
///   d'au moins [bande].
/// - **Haut et bas** sinon (telephone et tablette en portrait) : l'ile
///   repliee, la vignette et le zoom sur une rangee en haut ; les commandes
///   de l'appel en bas ; la page prend la place libre entre les deux. L'ile
///   qui se deplie passe par-dessus la page un court instant, sans la
///   pousser (la rangee garde sa hauteur repliee).
class GeometrieEleve {
  const GeometrieEleve._({
    required this.cote,
    required this.page,
    required this.bande,
    required this.rangee,
    required this.finRangee,
  });

  /// Vrai : tout passe sur les cotes, la page garde toute la hauteur.
  final bool cote;

  /// La zone ou la page se compose (centree dedans).
  final Rect page;

  /// La largeur des bandes de cote reservees ([cote]) ; 0 sinon.
  final double bande;

  /// La hauteur de la rangee du haut (ile repliee, vignette, zoom) ; 0 sur
  /// les cotes.
  final double rangee;

  /// La place prise au bout de la rangee du haut par la vignette et le zoom.
  final double finRangee;

  /// La largeur du zoom horizontal (moins, plus) pour [diametre].
  static double largeurZoom(double diametre) =>
      2 * diametre + 3 * AppSpacing.sm;

  /// La largeur minimale d'une bande de cote : la pilule de l'appel de quatre
  /// boutons (micro, camera, reduire, quitter) et ses marges.
  static double largeurBande(double diametre) =>
      4 * diametre + 5 * AppSpacing.sm + 2 * AppSpacing.lg;

  /// [hauteurBas] : la hauteur mesuree des commandes de l'appel (marges
  /// comprises, zone sure exclue) ; `null` avant la premiere mesure.
  static GeometrieEleve calculer({
    required Size ecran,
    required EdgeInsets zoneSure,
    required double diametre,
    required bool vignette,
    required bool zoom,
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
    final double hautVignette = vignette
        ? largeurVignetteTelephone / MesuresVignette.ratio
        : 0;
    final double rangee = math.max(
      hauteurPiluleEtat,
      math.max(hautVignette, zoom ? diametre + 2 * AppSpacing.sm : 0),
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
  final Widget page = SizedBox.fromSize(
    key: TelephonePleinEcran.clePage,
    // Le tableau occupe la fenetre ; la page du Coran, sa boite.
    size: libre ? ecran : boite,
    // La page et ses notes restent claires (meme regle que la
    // carte de la surface).
    child: Theme(
      data: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      child: SurfacePageFixe(vue: vuePage, surface: surface, zoom: zoom),
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
      : !libre &&
            precedente == null &&
            suivante == null &&
            vue.role != RoleSeance.enseignant
      ? GlisserPage(
          key: const ValueKey<String>('glisser-page-salle'),
          onPrecedente: null,
          onSuivante: null,
          messageSansDroit: t.salle.coranEleve.pageDeLaClasse,
          child: page,
        )
      : page;
}

/// La salle au telephone : la page est l'ecran.
class TelephonePleinEcran extends StatefulWidget {
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

  /// Plan §4 : « Commandes » au repos (seul en bas) et au toucher (au-dessus
  /// de la pilule de l'appel).
  static const Key cleCommandesRepos = ValueKey<String>(
    'telephone-commandes-repos',
  );

  /// Fiche 1, ligne 3 : « Commandes » au toucher, au-dessus de la pilule,
  /// au bord de fin.
  static const Key cleCommandesToucher = ValueKey<String>(
    'telephone-commandes-toucher',
  );

  /// Fiche 1, ligne 4 : « Eleves » dans la pilule de l'appel.
  static const Key cleEleves = ValueKey<String>('telephone-pilule-eleves');

  @override
  State<TelephonePleinEcran> createState() => _EtatTelephonePleinEcran();
}

class _EtatTelephonePleinEcran extends State<TelephonePleinEcran> {
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

  void _surHauteurBas(double h) {
    if (!mounted || _hauteurBas == h) return;
    setState(() => _hauteurBas = h);
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
  void didUpdateWidget(TelephonePleinEcran ancien) {
    super.didUpdateWidget(ancien);
    // Un panneau du bas s'ouvre : le profil se replie (rien ne se recouvre).
    if (_profil &&
        widget.vue.panneau != PanneauOuvert.aucun &&
        widget.vue.panneau != ancien.vue.panneau) {
      _profil = false;
    }
  }

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
          // Plan de composition du 26/10/2026, §4 (PR B) : l'enseignant au
          // telephone a sa capsule, son tiroir des Commandes et ses eleves en
          // feuille ; l'eleve, le tuteur et le controleur ne changent pas.
          final bool enseignant = salleTelephoneEnseignant(context, vue);
          final bool eleves = enseignant && vue.panneau == PanneauOuvert.eleves;
          final bool libre = vue.supportPresente == null;
          // Lot CORAN-ELEVE (directeur, 11/11/2026 : « rien ne recouvre le
          // texte du Coran chez l'eleve ») : l'eleve, le tuteur et le
          // controleur devant une page. La page prend la place libre entre
          // ce qui est fixe (l'ile repliee en haut, les commandes de l'appel
          // en bas) ; sur un ecran large, tout passe dans les bandes vides
          // des cotes et la page garde toute la hauteur.
          final bool eleve =
              vue.role != RoleSeance.enseignant &&
              !scene &&
              !libre &&
              surface != null;
          final bool sceneDevant = enseignant && scene;
          final Widget haut = _Haut(
            vue: vue,
            actions: actions,
            largeur: ecran.width,
            // Lot salle 2 : la vignette est posee a part, deplacable.
            vignette: false,
            aCote: !telephone && !enseignant,
          );
          final Widget bas = Padding(
            // Standard : marge 16 des bords (et la zone sure).
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _Bas(
              vue: vue,
              actions: actions,
              local: local,
              paletteAuDessus: telephone || enseignant,
              enseignantTelephone: enseignant,
            ),
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
                  hauteurBas: _hauteurBas,
                )
              : null;
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
              sceneDevant ? media?.actionScene : null;
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
                          Positioned.fill(
                            child: KeyedSubtree(
                              key: const ValueKey<String>('telephone-scene'),
                              // « Ouvrir le Coran » est pose par la scene,
                              // jamais par-dessus sa phrase d'attente.
                              child: actionScene == null
                                  ? laScene
                                  : ActionSousLaScene(
                                      action: actionScene,
                                      child: laScene,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null);
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
          // Fiche 1, ligne 2 : la capsule (ou le profil deplie) en haut au
          // centre. Pilote C12 : le bandeau de secours et l'alerte sont des
          // alertes, pas des commandes (fiche 0, regle 22) : au-dessus, au
          // repos comme au toucher, poses sur la page sans la retrecir ; la
          // capsule se place sous eux et suit le toucher (C10), sauf sur la
          // scene video en grand.
          final Widget laCapsule = _profil
              ? KeyedSubtree(
                  key: _cleProfil,
                  child: ProfilTelephone(
                    vue: vue,
                    onReduire: _replier,
                    onPause: actions.onPause,
                  ),
                )
              : Center(
                  child: CapsuleVideoTelephone(
                    vue: vue,
                    onDeplier: _deplierProfil,
                    onRevenirPage: revenirPage,
                    oeil: !sceneDevant || revenirPage != null,
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
                      MasqueAvecCommandes(child: laCapsule),
                  ],
                ),
              ),
            ),
          );
          return CommandesMasquables(
            delai: AppMouvement.masquageSalle,
            maintenir:
                vue.visioMaintenue ||
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
                          child: ZoneSupport(vue: vue, zoom: local.zoom),
                        ),
                      ),
                    ],
                  )
                else
                  Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _toucherPage,
                    child: geometrie == null
                        ? Center(child: page)
                        : Stack(
                            children: <Widget>[
                              Positioned.fromRect(
                                rect: geometrie.page,
                                child: Center(child: page),
                              ),
                            ],
                          ),
                  ),
                // Pilote C10 (27/10) : sur la scene video en grand, rien a
                // proteger, la capsule reste au repos ; sur la page, elle se
                // masque avec les commandes (C12 : sous les alertes).
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
                // Plan §4 : au repos, « Commandes » seul en bas ; au toucher,
                // il remonte au-dessus de la pilule, avec elle.
                if (enseignant &&
                    vue.panneau == PanneauOuvert.aucun &&
                    _declencheur(actions, vue) != null)
                  Builder(
                    builder: (BuildContext contexte) =>
                        CommandesMasquables.visiblesDe(contexte)
                        ? const SizedBox.shrink()
                        : PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: AppSpacing.lg,
                            child: SafeArea(
                              top: false,
                              child: Center(
                                child: CoucheSalle(
                                  child: DeclencheurCommandes(
                                    key: TelephonePleinEcran.cleCommandesRepos,
                                    surface: palette.coucheSalle,
                                    onPress: _declencheur(actions, vue)!,
                                  ),
                                ),
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
                                    ? hauteurPiluleEtat +
                                          AppSpacing.sm +
                                          (media?.boutonEleves == null
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
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Fiche 1, ligne 3 : au toucher,
                                // « Commandes » remonte au-dessus de la
                                // pilule, au bord de fin.
                                if (enseignant &&
                                    !(panneau || eleves) &&
                                    _declencheur(actions, vue) != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: AppSpacing.lg,
                                      end: AppSpacing.lg,
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: CoucheSalle(
                                        child: DeclencheurCommandes(
                                          key: TelephonePleinEcran
                                              .cleCommandesToucher,
                                          surface: palette.coucheSalle,
                                          onPress: _declencheur(actions, vue)!,
                                        ),
                                      ),
                                    ),
                                  ),
                                KeyedSubtree(key: _cleBas, child: bas),
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
    final double largeurHaut = cote
        ? geometrie.bande
        : ecran.width - geometrie.finRangee;
    return SizedBox.fromSize(
      size: ecran,
      child: Stack(
        children: <Widget>[
          // L'ile (et la presence) : en haut, au debut ; sur les cotes, dans
          // la bande de debut.
          PositionedDirectional(
            top: 0,
            start: 0,
            width: largeurHaut,
            child: _Haut(
              vue: vue,
              actions: actions,
              largeur: largeurHaut,
              vignette: false,
              aCote: false,
            ),
          ),
          // La vignette de l'enseignant : en haut, au bout. Sur les cotes,
          // grande, et deplacable entre le haut de la bande de fin et le bas
          // de la bande de debut (les deux coins libres) ; ailleurs, elle
          // reste dans la rangee du haut (tout autre coin tombe sur le texte
          // ou sur les commandes de l'appel).
          if (vignette)
            VignetteAimantee(
              vue: vue,
              largeur: cote
                  ? math.min(
                      MesuresVignette.largeurPleinCadreLarge,
                      geometrie.bande - 2 * AppSpacing.lg,
                    )
                  : largeurVignetteTelephone,
              haut: zoneSure.top + AppSpacing.lg,
              bas: zoneSure.bottom + AppSpacing.lg,
              coinsPermis: cote
                  ? const <CoinVignette>[
                      CoinVignette.hautFin,
                      CoinVignette.basDebut,
                    ]
                  : const <CoinVignette>[CoinVignette.hautFin],
            ),
          // Le zoom : sur les cotes, debout au milieu de la bande de fin ;
          // sinon couche, dans la rangee du haut, avant la vignette.
          if (zoom)
            cote
                ? PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: AppSpacing.lg,
                    child: Center(child: PiluleZoomSalle(actions: actions)),
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

/// La hauteur de la pilule d'etat ([PiluleEtatSalle]).
const double hauteurPiluleEtat = AppSpacing.xxxl + AppSpacing.xs;

/// Un coin de la scene ou la vignette s'aimante.
enum CoinVignette { hautDebut, hautFin, basDebut, basFin }

/// Lot salle 2 (directeur, 25/10/2026) : la vignette video, deplacable au
/// doigt et a la souris, aimantee au coin le plus proche du lacher (standard
/// Meet, FaceTime). Le coin choisi est garde pendant la seance (stockage de
/// la route). Toucher la vignette la met toujours en grand.
class VignetteAimantee extends StatefulWidget {
  const VignetteAimantee({
    required this.vue,
    required this.largeur,
    required this.haut,
    required this.bas,
    this.coinsPermis,
    super.key,
  });

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

  /// La cle de la vignette deplacable (tests).
  static const Key cle = ValueKey<String>('vignette-aimantee');

  @override
  State<VignetteAimantee> createState() => _EtatVignetteAimantee();
}

class _EtatVignetteAimantee extends State<VignetteAimantee> {
  static const String _cleStockage = 'salle-vignette-coin';

  CoinVignette get _coin {
    final CoinVignette? lu = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _cleStockage) as CoinVignette?;
    final List<CoinVignette>? permis = widget.coinsPermis;
    if (permis == null) return lu ?? CoinVignette.hautFin;
    return lu != null && permis.contains(lu) ? lu : permis.first;
  }

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

  void _lacher(DraggableDetails d) {
    final Size ecran = MediaQuery.sizeOf(context);
    final Offset centre =
        d.offset +
        Offset(widget.largeur, widget.largeur / MesuresVignette.ratio) / 2;
    final bool gauche = centre.dx < ecran.width / 2;
    final bool enHaut = centre.dy < ecran.height / 2;
    // Debut et fin suivent le sens de lecture.
    final bool debut =
        gauche == (Directionality.of(context) == TextDirection.ltr);
    final CoinVignette coin = _permis(
      enHaut
          ? (debut ? CoinVignette.hautDebut : CoinVignette.hautFin)
          : (debut ? CoinVignette.basDebut : CoinVignette.basFin),
    );
    PageStorage.maybeOf(context)
        ?.writeState(context, coin, identifier: _cleStockage);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final CoinVignette coin = _coin;
    final bool enHaut =
        coin == CoinVignette.hautDebut || coin == CoinVignette.hautFin;
    final bool debut =
        coin == CoinVignette.hautDebut || coin == CoinVignette.basDebut;
    final Widget vignette = VignetteVideo(
      vue: widget.vue,
      largeur: widget.largeur,
    );
    return PositionedDirectional(
      key: VignetteAimantee.cle,
      top: enHaut ? widget.haut : null,
      bottom: enHaut ? null : widget.bas,
      start: debut ? AppSpacing.lg : null,
      end: debut ? null : AppSpacing.lg,
      child: Draggable<CoinVignette>(
        data: coin,
        feedback: Material(type: MaterialType.transparency, child: vignette),
        childWhenDragging: SizedBox(
          width: widget.largeur,
          height: widget.largeur / MesuresVignette.ratio,
        ),
        onDragEnd: _lacher,
        child: vignette,
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

/// Pilote C8 : la largeur maximale du tiroir et de la feuille des eleves
/// (feuille du bas Material 3 sur tablette).
const double largeurMaxFeuille = AppSpacing.respiration * 10;

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
      avecChrono: true,
      onPause: actions.onPause,
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
                  ?fermer,
                ],
              )
            // Arbitrage du pilote (24/10/2026) : la pilule d'etat occupe seule
            // la premiere rangee, a gauche, phrase entiere ; Eleves et la
            // vignette descendent sur une seconde rangee, a droite, 8 sous la
            // pilule.
            else
              Align(alignment: AlignmentDirectional.topStart, child: ligne),
            if (!aCote &&
                (eleves != null || vignette || fermer != null)) ...<Widget>[
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
    super.key,
  });

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
      decoration: (couche ? palette.coucheSalle : palette.piluleSalle)
          .decoration(borderRadius: AppRadius.arrondiFull),
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
  });

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
    // Fiche 1, ligne 4 : les disques nommes, dans tous les modes (pilote,
    // 26/10 : un mode d'accessibilite ne retire pas les mots).
    final bool rond = enseignantTelephone;
    // Standard des commandes d'appel (24/10/2026) : une seule pilule, « Plus »
    // dedans ; aucun declencheur a cote. S0.3b : tableau ouvert, sa palette
    // juste au-dessus, horizontale.
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      agrandi: local.agrandi,
      commandes: enseignantTelephone
          ? const <CommandeDock>[
              CommandeDock.micro,
              CommandeDock.camera,
              CommandeDock.quitter,
            ]
          : null,
      // Fiche 1, ligne 4 : Micro, Camera, Eleves, Quitter, des disques
      // nommes ; Eleves porte le nombre d'eleves presents.
      rond: rond,
      avantQuitter: <Widget>[
        if (enseignantTelephone && actions.onEleves != null)
          BoutonAppel(
            key: TelephonePleinEcran.cleEleves,
            icone: AppIcons.eleves,
            libelle: t.salle.seance.compteurEleves(
              connectes: vue.connectes,
              inscrits: vue.inscrits,
            ),
            libelleSemantique: t.salle.seance.eleves,
            nom: rond ? t.salle.seance.eleves : null,
            pastille: vue.connectes,
            selectionne: vue.panneau == PanneauOuvert.eleves,
            onPress: actions.onEleves!,
          ),
      ],
      // Fiche 1, ligne 3 : chez l'enseignant au telephone, « Commandes » est
      // au-dessus de la pilule, jamais dedans.
      plus:
          !enseignantTelephone &&
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
