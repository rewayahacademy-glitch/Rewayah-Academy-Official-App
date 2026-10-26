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
import '../../core/theme/app_metriques.dart';
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

/// La vignette flottante du telephone (≈ 96 de large).
const double largeurVignetteTelephone = AppSpacing.respiration * 1.5;

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
  final VoidCallback? precedente = media?.onPagePrecedente;
  final VoidCallback? suivante = media?.onPageSuivante;
  const double cote = coteFlechesSalle + AppSpacing.sm;
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

  void _replier() {
    if (_profil) setState(() => _profil = false);
  }

  /// Un toucher hors de la carte du profil la replie.
  void _toucherPage(PointerDownEvent e) {
    if (!_profil) return;
    final RenderObject? carte = _cleProfil.currentContext?.findRenderObject();
    if (carte is RenderBox && carte.hasSize) {
      final Offset local = carte.globalToLocal(e.position);
      if ((Offset.zero & carte.size).contains(local)) return;
    }
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
          final Widget? pageVue = scene
              ? null
              : pageSalle(
                  context,
                  vue: vue,
                  zoom: local.zoom,
                  ecran: ecran,
                  telephone: telephone || enseignant,
                );
          final Widget? page = pageVue;
          // Fiche 1, lignes 1, 2, 5 : la capsule (ou le profil deplie) reste
          // en haut au repos comme au toucher. Sans page (scene video en
          // grand), rien a reduire : pas de capsule. Page illisible : son
          // constat et son « Reessayer » se lisent, rien ne se pose dessus.
          final bool capsule =
              enseignant && page != null && !(media?.pageEnErreur ?? false);
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
          return CommandesMasquables(
            delai: AppMouvement.masquageSalle,
            maintenir:
                vue.visioMaintenue ||
                (panneau && telephone) ||
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
                    child: Center(child: pageVue),
                  ),
                if (capsule)
                  PositionedDirectional(
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
                            if (_profil)
                              KeyedSubtree(
                                key: _cleProfil,
                                child: ProfilTelephone(
                                  vue: vue,
                                  onReduire: _replier,
                                ),
                              )
                            else
                              Center(
                                child: CapsuleVideoTelephone(
                                  vue: vue,
                                  onDeplier: () =>
                                      setState(() => _profil = true),
                                ),
                              ),
                            BandeauSecours(
                              vue: vue,
                              actions: actions,
                              gouttiere: 0,
                            ),
                            ?media?.alerte,
                          ],
                        ),
                      ),
                    ),
                  ),
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
                                child: DeclencheurCommandes(
                                  key: TelephonePleinEcran.cleCommandesRepos,
                                  onPress: _declencheur(actions, vue)!,
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
                : SizedBox.fromSize(
                    size: ecran,
                    child: Stack(
                      children: <Widget>[
                        // Fiche 1, ligne 1 : chez l'enseignant au telephone,
                        // rien en haut hors de la capsule (posee au repos).
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
                        // au lieu de la recouvrir.
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                if ((panneau || eleves) && enseignant)
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      child: eleves
                                          ? FeuilleElevesTelephone(
                                              vue: vue,
                                              actions: actions,
                                              hauteur: hauteurFeuille,
                                            )
                                          : TiroirCommandesTelephone(
                                              vue: vue,
                                              actions: actions,
                                              local: local,
                                              hauteur: hauteurFeuille,
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
                                      child: DeclencheurCommandes(
                                        key: TelephonePleinEcran
                                            .cleCommandesToucher,
                                        onPress: _declencheur(actions, vue)!,
                                      ),
                                    ),
                                  ),
                                bas,
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
                        if (!libre &&
                            !paletteADroite &&
                            commandesADroite == null &&
                            !((panneau || eleves) && enseignant) &&
                            (actions.onZoomPlus != null ||
                                actions.onZoomMoins != null))
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            end: AppSpacing.lg,
                            child: Center(
                              child: PiluleZoomSalle(actions: actions),
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
    super.key,
  });

  final VueSeance vue;
  final double largeur;

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

  CoinVignette get _coin =>
      PageStorage.maybeOf(context)?.readState(context, identifier: _cleStockage)
          as CoinVignette? ??
      CoinVignette.hautFin;

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
    final CoinVignette coin = enHaut
        ? (debut ? CoinVignette.hautDebut : CoinVignette.hautFin)
        : (debut ? CoinVignette.basDebut : CoinVignette.basFin);
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
/// tiroir a quelque chose a montrer.
VoidCallback? _declencheur(ActionsSeance actions, VueSeance vue) =>
    CommandesPedagogiques.aDesEntrees(vue, actions)
    ? actions.onCommandes
    : null;

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
    super.key,
  });

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
    return DecoratedBox(
      key: const ValueKey<String>('salle-zoom'),
      decoration: palette.piluleSalle.decoration(
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
    // Fiche 1, ligne 4 : les disques nommes, en interface standard (le cas
    // principal). En Mode Accessibilite, la pilule a icones seules du
    // standard du 24/10 reste (cas limite, tests `salle_200_test`).
    final bool rond =
        enseignantTelephone &&
        AppMetriques.of(context).mode != InterfaceMode.enfant;
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
