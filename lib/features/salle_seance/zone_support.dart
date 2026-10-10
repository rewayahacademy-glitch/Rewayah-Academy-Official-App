// Le support partage, dominant (CLV-04, 05, 06).
//
// Une carte claire, dans les deux themes : le support est un document, lu
// comme sur papier (images). La vignette video de l'enseignante est posee en
// coin haut droit, retrait de 12 ; c'est le seul chevauchement admis. Le
// contenu defile au pouce. Sans support : la video au centre et une phrase.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'composition_salle.dart';
import 'surface_page_fixe.dart';
import 'vignette_video.dart';
import 'vue_seance.dart';

/// Le support et la vignette video.
class ZoneSupport extends StatelessWidget {
  const ZoneSupport({
    required this.vue,
    this.zoom = 1,
    this.serre = false,
    this.contenu,
    super.key,
  });

  final VueSeance vue;

  /// Le rendu reel du support (Classe Live). `null` : `vue.support` est
  /// rendu par la salle. Il occupe la carte, sous la vignette, sans defiler
  /// ici : le rendu fourni gere lui-meme sa lecture.
  final Widget? contenu;

  /// Le zoom local (1 = 100 %), qui n'agit que sur cet ecran.
  final double zoom;

  /// Salle enseignant, telephone et desktop : le support partage l'ecran
  /// avec les boutons Eleves et Supports et la rangee d'outils. Marges et
  /// ecarts se resserrent pour que la diapositive entiere tienne dans la
  /// place laissee (images CLV-04-05-06 mobile et CLV-06 desktop).
  final bool serre;

  @override
  Widget build(BuildContext context) {
    // TB-6 : un support a page fixe presente, ou le tableau libre connu de
    // la vue, prend la surface ; la diapositive et le rendu fourni (Classe
    // Live, Coran) restent ce qu'ils etaient.
    final VueSurface? surface = contenu == null ? surfaceAMontrer(vue) : null;
    if (surface != null) return _carteSurface(context, surface);
    final SupportSeance? support = vue.support;
    if (support == null) return _RienPartage(vue: vue);
    final Gabarit gabarit = AppGabarit.de(context);
    // Le support est le document de l'enseignante, le meme pour tous : il
    // garde l'echelle standard, meme en guidee (images CLV-05 : texte de la
    // taille de CLV-04). Seules les commandes de la guidee grandissent.
    const InterfaceMode mode = InterfaceMode.standard;
    // Guidee desktop (Q8) : la video a cote du support, jamais par-dessus.
    final bool aCote = vue.videoACoteDuSupport(gabarit);
    // La vignette n'existe que si la camera de l'enseignante est active, et
    // jamais pendant le partage : la capsule de l'en-tete la remplace (TB-3,
    // UI-01, plan V2 §4.3).
    final bool video = vue.voitVignetteSurSupport;
    final double largeurVignette = MesuresVignette.largeur(
      gabarit,
      guidee: vue.vignetteAgrandie,
      enseignant: vue.meneLaSeance,
      panneau: vue.panneau != PanneauOuvert.aucun,
    );
    // Guidee web etroit (image CLV-04-05-06 web etroit) : la grande vignette
    // descend jusqu'a l'encadre, qui se range a cote d'elle ; la carte
    // s'arrete apres son contenu, un espace la separe du dock.
    final bool colonneGuidee =
        vue.vignetteAgrandie && gabarit == Gabarit.tablette && !aCote;
    final _Marges marges = _Marges.de(
      gabarit,
      serre: serre,
      panneau: vue.panneau != PanneauOuvert.aucun,
    );
    // A 200 % (texte agrandi, Mode Accessibilite compris), telephone et web
    // etroit : la vignette posee en coin laisserait au titre une colonne si
    // etroite que les mots s'y couperaient (« Chapitr / e 1 »). Elle passe
    // alors APRES le texte (A6 = a), qui reste en haut, prend toute la
    // largeur et ne revient a la ligne qu'entre les mots (MA-5). A 100 %,
    // rien ne change.
    final bool pile =
        contenu == null &&
        !aCote &&
        video &&
        gabarit != Gabarit.desktop &&
        MediaQuery.textScalerOf(context).scale(1) * zoom >= _seuilPile;
    // La carte lit le theme clair, quel que soit le theme de l'ecran.
    final Widget carte = Theme(
      data: AppTheme.pour(mode, Brightness.light),
      child: Builder(
        builder: (BuildContext contexte) {
          final AppPalette palette = AppPalette.of(contexte);
          final Widget? fourni = contenu;
          final Widget defilement = fourni != null
              ? Padding(
                  key: const ValueKey<String>('support-fourni'),
                  padding: EdgeInsets.symmetric(
                    horizontal: marges.x,
                    vertical: marges.y,
                  ),
                  child: fourni,
                )
              : MediaQuery(
                  data: MediaQuery.of(contexte).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(contexte).scale(1) * zoom,
                    ),
                  ),
                  child: _FonduBas(
                    couleur: palette.surfaceRaised.background,
                    hauteur: marges.fondu,
                    child: SingleChildScrollView(
                      key: const ValueKey<String>('support-defilement'),
                      padding: EdgeInsets.symmetric(
                        horizontal: marges.x,
                        vertical: marges.y,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _Contenu(
                            support: support,
                            gabarit: gabarit,
                            marges: marges,
                            largeurVignette: aCote || !video || pile
                                ? 0
                                : largeurVignette,
                            encadreACote: colonneGuidee && !pile,
                            sousVolet: vue.panneau != PanneauOuvert.aucun,
                          ),
                          // A6 = a (directeur, 27/09 ; ex-PT-B-cfbdb7a5) : en
                          // pile, le support reste en haut, a sa place ; la
                          // vignette le suit, elle ne le precede jamais.
                          if (pile) ...<Widget>[
                            SizedBox(height: marges.ecartTitre),
                            Align(
                              alignment: AlignmentDirectional.topEnd,
                              // La video garde le theme de l'ecran.
                              child: Theme(
                                data: Theme.of(context),
                                child: VignetteVideo(
                                  key: const ValueKey<String>(
                                    'vignette-support-pile',
                                  ),
                                  vue: vue,
                                  largeur: largeurVignette,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
          return DecoratedBox(
            key: const ValueKey<String>('zone-support'),
            decoration: palette.surfaceRaised
                .decoration(borderRadius: AppRadius.arrondiLg)
                .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
            child: ClipRRect(
              borderRadius: AppRadius.arrondiLg,
              child: Stack(
                children: <Widget>[
                  // Ajustee : la carte prend la hauteur de son contenu,
                  // bornee par la place disponible (puis elle defile).
                  if (colonneGuidee)
                    defilement
                  else
                    Positioned.fill(child: defilement),
                  if (!aCote && video && !pile)
                    PositionedDirectional(
                      top: marges.retraitVignette,
                      end: marges.retraitVignette,
                      // La video garde le theme de l'ecran.
                      child: Theme(
                        data: Theme.of(context),
                        child: VignetteVideo(
                          vue: vue,
                          largeur: largeurVignette,
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
    if (colonneGuidee) {
      return Align(alignment: Alignment.topCenter, child: carte);
    }
    if (gabarit != Gabarit.desktop) return carte;
    // Desktop : la carte est sertie dans un cadre du theme de l'ecran (le
    // lisere sombre de CLV-04), qui la detache du fond en clair comme en
    // sombre.
    final Widget cadre = _Serti(
      key: const ValueKey<String>('cadre-support'),
      child: carte,
    );
    if (!aCote) return cadre;
    // La colonne de la video, a droite du support (image CLV-05) : sertie
    // comme lui, en haut, le reste de la colonne laisse vide.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: cadre),
        Ecart.hLg,
        _Serti(
          key: const ValueKey<String>('colonne-video'),
          child: VignetteVideo(vue: vue, largeur: largeurVignette),
        ),
      ],
    );
  }
}

/// TB-6 (revue du 09/10) : la hauteur sous laquelle la carte de la surface
/// rognerait la phrase du §12 a la largeur [largeur] de la carte (serti
/// [serre] de la salle enseignant), ou 0 sans phrase. La salle du telephone
/// la reserve a la surface avant de borner sa tete.
double hauteurMinimaleSurface(
  BuildContext context,
  VueSeance vue, {
  required double largeur,
  bool serre = true,
}) {
  if (surfaceAMontrer(vue) != VueSurface.tableauLibre ||
      !vue.voitConsigneTableauLibre) {
    return 0;
  }
  final double serti = serre ? AppSpacing.sm : AppSpacing.md;
  return SurfacePageFixe.hauteurConsigne(context, largeur - 2 * serti) +
      2 * serti;
}

/// Le ratio d'une page sans ratio connu (A4 portrait), meme valeur que la
/// surface a page fixe.
const double _ratioPageParDefaut = 1240 / 1754;

/// TB-RC : le ratio (largeur / hauteur) de la page que la surface montre,
/// ou `null` quand elle ne montre pas de page fixe (diapositive, rendu
/// fourni).
double? ratioSurface(VueSeance vue) {
  final VueSurface? surface = surfaceAMontrer(vue);
  if (surface == null) return null;
  final SupportPageFixe? page = vue.supportPresente;
  return surface == VueSurface.tableauLibre || page == null
      ? (vue.tableauLibre?.ratio ?? _ratioPageParDefaut)
      : page.ratio;
}

/// TB-RC : le retrait de la page dans la surface de la salle (serti du
/// bureau et marge interieure de la carte), de chaque cote.
double retraitPageSurface(Gabarit gabarit, {bool serre = true}) =>
    (serre ? AppSpacing.sm : AppSpacing.md) +
    (gabarit == Gabarit.desktop ? _serti : 0);

/// TB-RC (TB_RAPPORT §d n. 3) : la hauteur a reserver au-dessus de la page
/// pour que la [vignette], posee au coin haut de fin de la carte (retrait
/// de 16), ne recouvre pas la page dans une carte de taille [boite] et de
/// marge interieure [marge]. 0 quand la page laisse le coin libre (ecran
/// large) ou sans page fixe ([ratio] nul). La page est centree : le sens de
/// lecture ne change pas le resultat.
double reserveSousVignette({
  required Size boite,
  required double marge,
  required double? ratio,
  required Size vignette,
}) {
  if (ratio == null) return 0;
  // Le coin de la vignette, avec un palier d'air sous elle.
  final Rect coin = Rect.fromLTWH(
    boite.width - AppSpacing.md - vignette.width,
    AppSpacing.md,
    vignette.width,
    vignette.height + AppSpacing.sm,
  );
  bool libre(double dessus) {
    final Size interieur = Size(
      math.max(0, boite.width - 2 * marge),
      math.max(0, boite.height - 2 * marge - dessus),
    );
    final Rect page = rectanglePage(
      ratio: ratio,
      boite: interieur,
    ).shift(Offset(marge, marge + dessus));
    return !coin.overlaps(page);
  }

  if (libre(0)) return 0;
  // La plus petite reserve qui libere le coin : une page qui a de la
  // hauteur de reste descend sans rapetisser (TB_RAPPORT §d n. 3).
  final double plafond = math.max(0, coin.bottom - marge);
  for (
    double dessus = AppSpacing.xs;
    dessus < plafond;
    dessus += AppSpacing.xs
  ) {
    if (libre(dessus)) return dessus;
  }
  return plafond;
}

/// TB-RC (revue TB-R M2 ; TB_RAPPORT §d n. 3) : la vignette video se
/// pose-t-elle sur la surface a page fixe ? Chez l'enseignant, sa propre
/// image cede la place quand la salle est courte (telephone couche, texte
/// x2 au bureau), comme pour la phrase du §12 ([ZoneSupport]) : la page et
/// ses entrees passent d'abord. L'eleve garde toujours celle de
/// l'enseignant.
bool vignetteEnseignantPosee(BuildContext context, VueSeance vue) =>
    vue.voitVignetteSurSupport &&
    !(vue.role == RoleSeance.enseignant && CompositionSalle.courte(context));

/// TB-6 : ce que la surface a page fixe montre, ou `null` (diapositive,
/// rendu fourni, rien de partage sans tableau connu).
VueSurface? surfaceAMontrer(VueSeance vue) {
  if (vue.supportPresente != null) return vue.vueSurface;
  if (vue.support == null && vue.tableauLibre != null) {
    return VueSurface.tableauLibre;
  }
  return null;
}

extension on ZoneSupport {
  /// TB-6 : la carte claire de la surface a page fixe (meme carte, meme
  /// serti que la diapositive), la page posee dedans en `BoxFit.contain`.
  Widget _carteSurface(BuildContext context, VueSurface surface) {
    final Gabarit gabarit = AppGabarit.de(context);
    // Tableau libre de l'enseignant, texte agrandi hors bureau : sa propre
    // vignette couvrirait la phrase du §12 (rien ne recouvre un texte a
    // lire) ; elle ne se pose pas sur la feuille. Les eleves gardent la
    // vignette de l'enseignant.
    final bool consigneSerree =
        surface == VueSurface.tableauLibre &&
        vue.voitConsigneTableauLibre &&
        gabarit != Gabarit.desktop &&
        MediaQuery.textScalerOf(context).scale(1) >= _seuilPile;
    final bool video = vignetteEnseignantPosee(context, vue) && !consigneSerree;
    final double largeurVignette = MesuresVignette.largeur(
      gabarit,
      guidee: vue.vignetteAgrandie,
      enseignant: vue.meneLaSeance,
      panneau: vue.panneau != PanneauOuvert.aucun,
    );
    final Widget carte = Theme(
      // La page et la feuille restent claires : jamais inversees en sombre.
      data: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      child: Builder(
        builder: (BuildContext contexte) {
          final AppPalette palette = AppPalette.of(contexte);
          return DecoratedBox(
            key: const ValueKey<String>('zone-support'),
            decoration: palette.surfaceSunken
                .decoration(borderRadius: AppRadius.arrondiLg)
                .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
            child: ClipRRect(
              borderRadius: AppRadius.arrondiLg,
              child: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints c) {
                  final double marge = serre ? AppSpacing.sm : AppSpacing.md;
                  final double? ratio = ratioSurface(vue);
                  // TB-RC (TB_RAPPORT §d n. 3) : la vignette ne recouvre
                  // jamais la feuille ; si elle la toucherait en coin, la
                  // page descend sous elle (la plus petite reserve).
                  final double dessus = video
                      ? reserveSousVignette(
                          boite: c.biggest,
                          marge: marge,
                          ratio: ratio,
                          vignette: Size(
                            largeurVignette,
                            largeurVignette / MesuresVignette.ratio,
                          ),
                        )
                      : 0;
                  // L'enseignant ne voit la que sa propre image : si la
                  // reserve faisait tomber sa page sous sa part minimale
                  // (CompositionSalle.partMinimalePage, 320 px), elle ne se
                  // pose pas, comme pour [consigneSerree]. L'eleve garde
                  // toujours celle de l'enseignant.
                  final bool vignette =
                      video &&
                      !(vue.role == RoleSeance.enseignant &&
                          dessus > 0 &&
                          ratio != null &&
                          rectanglePage(
                                ratio: ratio,
                                boite: Size(
                                  math.max(0, c.maxWidth - 2 * marge),
                                  math.max(0, c.maxHeight - 2 * marge - dessus),
                                ),
                              ).height <
                              CompositionSalle.partMinimalePage *
                                  CompositionSalle.hauteurUtile(context));
                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            marge,
                            marge + (vignette ? dessus : 0),
                            marge,
                            marge,
                          ),
                          child: SurfacePageFixe(
                            vue: vue,
                            surface: surface,
                            zoom: zoom,
                          ),
                        ),
                      ),
                      if (vignette)
                        PositionedDirectional(
                          top: AppSpacing.md,
                          end: AppSpacing.md,
                          // La video garde le theme de l'ecran.
                          child: Theme(
                            data: Theme.of(context),
                            child: VignetteVideo(
                              vue: vue,
                              largeur: largeurVignette,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
    if (gabarit != Gabarit.desktop) return carte;
    return _Serti(key: const ValueKey<String>('cadre-support'), child: carte);
  }
}

/// Le cadre du theme de l'ecran qui sertit la carte en desktop (le lisere
/// sombre de CLV-04), et la video de la guidee a cote d'elle (CLV-05).
class _Serti extends StatelessWidget {
  const _Serti({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.lg + _serti),
        ),
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(padding: const EdgeInsets.all(_serti), child: child),
    );
  }
}

/// L'epaisseur du cadre qui sertit la carte en desktop.
const double _serti = AppSpacing.sm;

/// L'echelle de texte (zoom local compris) a partir de laquelle la vignette
/// passe au-dessus du texte, hors desktop (MA-5).
const double _seuilPile = 1.5;

/// Un fondu en bas de la zone qui defile : une ligne coupee par l'arrondi de
/// la carte s'efface au lieu de s'arreter net. Sa hauteur egale la plus
/// petite marge interieure : en fin de defilement, il ne couvre que la marge.
class _FonduBas extends StatelessWidget {
  const _FonduBas({
    required this.couleur,
    required this.hauteur,
    required this.child,
  });

  /// Une couleur opaque quelconque : seul son canal alpha compte.
  final Color couleur;

  /// La hauteur du fondu : la plus petite marge interieure.
  final double hauteur;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (Rect zone) {
      final double debut = zone.height <= 0
          ? 1
          : (1 - hauteur / zone.height).clamp(0, 1);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[couleur, couleur, couleur.withValues(alpha: 0)],
        stops: <double>[0, debut, 1],
      ).createShader(zone);
    },
    child: child,
  );
}

/// Les marges et ecarts du support, par gabarit, ordinaires ou resserres.
@immutable
class _Marges {
  const _Marges({
    required this.x,
    required this.y,
    required this.retraitVignette,
    required this.serre,
    this.ecartTitre = AppSpacing.lg,
  });

  factory _Marges.de(
    Gabarit gabarit, {
    required bool serre,
    bool panneau = false,
  }) {
    final bool large = gabarit == Gabarit.desktop;
    // Resserre seulement au telephone et en desktop : en web etroit, les
    // outils sont en colonne et la diapositive tient deja.
    final bool actif = serre && gabarit != Gabarit.tablette;
    if (large) {
      // Panneau ouvert (images CLV-07 et CLV-08) : support plus etroit,
      // marge laterale ≈ 31 et titre proche de la vignette, pour que le
      // titre tienne sur deux lignes.
      return _Marges(
        x: panneau ? AppSpacing.xxxl : AppSpacing.section,
        y: actif ? AppSpacing.xxl : AppSpacing.section,
        retraitVignette: MesuresVignette.retrait,
        serre: actif,
        ecartTitre: panneau ? AppSpacing.sm : AppSpacing.lg,
      );
    }
    return _Marges(
      x: actif ? AppSpacing.lg : AppSpacing.xl,
      y: actif ? AppSpacing.lg : AppSpacing.xl,
      // Image mobile, colonne enseignant : la vignette serre le coin.
      retraitVignette: actif ? AppSpacing.sm : MesuresVignette.retrait,
      serre: actif,
      // Au telephone, l'ecart titre-vignette se resserre (images : ≈ 10).
      ecartTitre: gabarit == Gabarit.mobile ? AppSpacing.sm : AppSpacing.lg,
    );
  }

  /// L'ecart entre le titre et la vignette posee en coin.
  final double ecartTitre;

  /// Les marges interieures, laterales et verticales.
  final double x;
  final double y;

  /// Le retrait de la vignette depuis le coin du support.
  final double retraitVignette;

  /// Les ecarts du contenu sont resserres.
  final bool serre;

  /// Le fondu du bas ne couvre que la plus petite marge (et au plus xl).
  double get fondu => math.min(AppSpacing.xl, math.min(x, y));
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.support,
    required this.gabarit,
    required this.marges,
    required this.largeurVignette,
    this.encadreACote = false,
    this.sousVolet = false,
  });

  /// Web etroit : un panneau est ouvert, son volet couvre le support.
  final bool sousVolet;

  final SupportSeance support;
  final Gabarit gabarit;
  final _Marges marges;

  /// La largeur de la vignette posee en coin ; 0 quand elle est a cote.
  final double largeurVignette;

  /// Guidee web etroit : les lignes et l'encadre restent dans la colonne a
  /// cote de la grande vignette (image CLV-04-05-06 web etroit).
  final bool encadreACote;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final bool large = gabarit == Gabarit.desktop;
    // Web etroit (image CLV-04-05-06 web etroit) : le texte du support est
    // plus grand qu'au telephone, l'encadre tient sur deux lignes.
    // Volet Eleves ou Supports ouvert : le texte garde le petit corps et
    // reste entier sous le volet ; aucun mot coupe ne depasse de son bord
    // (image CLV-07-08-10 web etroit).
    final bool tablette = gabarit == Gabarit.tablette && !sousVolet;
    // Salle enseignant (telephone, desktop) : ecarts resserres pour que la
    // diapositive entiere tienne au-dessus des outils et du dock.
    final bool serre = marges.serre;
    // La place laissee a la vignette sur les premieres lignes : aucun texte
    // ne passe dessous au repos.
    final double reserve = largeurVignette <= 0
        ? 0
        : math.max(
            0,
            marges.retraitVignette +
                largeurVignette +
                marges.ecartTitre -
                marges.x,
          );
    final Widget ligneFine = _Ligne(
      fraction: 1,
      epaisseur: serre && !large ? AppSpacing.sm : AppSpacing.md,
    );
    Widget ligne(double fraction) => _Ligne(
      fraction: fraction,
      epaisseur: serre && !large ? AppSpacing.sm : AppSpacing.md,
    );
    // Sans texte, pas d'encadre : jamais une pastille vide (E16, EN-RC).
    final bool avecEncadre = support.encadre.trim().isNotEmpty;
    final Widget encadre = DecoratedBox(
      key: const ValueKey<String>('encadre-support'),
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiMd,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: serre ? AppSpacing.md : AppSpacing.lg,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tablette
                  ? _largeurEncadreEtroit
                  : (sousVolet && gabarit == Gabarit.tablette
                        ? _largeurEncadreSousVolet
                        : _largeurEncadre),
            ),
            child: Text(
              support.encadre,
              style: palette.inkAccent.applyTo(
                (large
                        ? theme.textTheme.titleLarge
                        : tablette
                        // Image : ≈ 18 px. Plus Jakarta Sans n'a pas d'axe
                        // `opsz` : la retaille est sure.
                        ? theme.textTheme.bodyLarge?.copyWith(
                            fontSize: _corpsEncadreEtroit,
                          )
                        : theme.textTheme.bodyMedium) ??
                    const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    );
    // Desktop sans illustration (panneau ouvert, CLV-07/08) : le titre de
    // l'image est ≈ 0,77 fois celui de CLV-06, il tient sur deux lignes.
    Widget entete({required bool reduit}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Pastille(texte: support.chapitre),
        if (serre && !large) Ecart.vSm else Ecart.vLg,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _largeurTitre),
          child: _TitreEquilibre(
            texte: support.titre,
            style: palette.inkStrong.applyTo(
              switch (gabarit) {
                    Gabarit.desktop =>
                      reduit
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.headlineLarge,
                    Gabarit.tablette => theme.textTheme.headlineSmall,
                    Gabarit.mobile => theme.textTheme.titleMedium,
                  } ??
                  const TextStyle(),
            ),
          ),
        ),
        if (serre && !large) Ecart.vMd else Ecart.vXl,
        ligneFine,
        if (large) ...<Widget>[Ecart.vMd, ligne(0.86), Ecart.vMd, ligne(0.7)],
        if (encadreACote) ...<Widget>[
          Ecart.vMd,
          ligneFine,
          Ecart.vMd,
          ligne(0.94),
          if (avecEncadre) ...<Widget>[Ecart.vLg, encadre],
          Ecart.vLg,
          ligneFine,
        ],
      ],
    );
    // Les ecarts autour de l'encadre et des consignes.
    final Widget autourEncadre = serre
        ? Ecart.vMd
        : (large ? Ecart.vXxl : Ecart.vLg);
    final double pastillePoint = switch ((large || tablette, serre)) {
      (true, false) => AppSpacing.xxxl + AppSpacing.sm,
      (true, true) => AppSpacing.xxxl + AppSpacing.xs,
      (false, false) => AppSpacing.xxxl,
      (false, true) => AppSpacing.xxl + AppSpacing.xs,
    };
    final double ecartPoint = serre && !large
        ? AppSpacing.xs / 2
        : AppSpacing.xs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext _, BoxConstraints c) {
            // Desktop : l'illustration seulement si le titre garde sa
            // place (panneau ouvert, CLV-07 : support plus etroit, sans
            // illustration).
            final bool illustration =
                large &&
                c.maxWidth >= reserve + _Illustration._largeur + _largeurTitre;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: entete(reduit: large && !illustration)),
                if (illustration) ...<Widget>[
                  Ecart.hXxl,
                  const _Illustration(),
                ],
                SizedBox(
                  width: reserve,
                  height: large || largeurVignette <= 0
                      ? 0
                      : math.max(
                          0,
                          largeurVignette / MesuresVignette.ratio +
                              marges.retraitVignette -
                              marges.y,
                        ),
                ),
              ],
            );
          },
        ),
        // Telephone et web etroit : deux lignes sous la vignette ; une
        // seule quand le support est resserre (image mobile, enseignant).
        if (!large && !encadreACote) ...<Widget>[
          if (serre) Ecart.vSm else Ecart.vMd,
          ligneFine,
          if (!serre) ...<Widget>[Ecart.vMd, ligne(0.7)],
        ],
        if (!encadreACote) ...<Widget>[
          autourEncadre,
          if (avecEncadre) ...<Widget>[encadre, autourEncadre],
          ligne(0.6),
        ],
        if (serre) Ecart.vMd else Ecart.vLg,
        for (int i = 0; i < support.points.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: ecartPoint),
            child: Row(
              children: <Widget>[
                // Un minimum et non une taille fixe : a 200 %, la pastille
                // grandit avec son chiffre au lieu de le rogner.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: pastillePoint,
                    minHeight: pastillePoint,
                  ),
                  child: DecoratedBox(
                    decoration: palette.washAccent.decoration(
                      borderRadius: AppRadius.arrondiFull,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: palette.washAccent.applyTo(
                            theme.textTheme.titleSmall ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (large || tablette) Ecart.hXl else Ecart.hLg,
                Expanded(
                  child: Text(
                    support.points[i],
                    style: palette.inkStrong.applyTo(
                      (large
                              ? theme.textTheme.titleMedium
                              : tablette
                              ? theme.textTheme.bodyLarge
                              : theme.textTheme.bodyMedium) ??
                          const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Desktop resserre (image CLV-06) : les trois consignes, puis la
        // marge, sans lignes de fin. Ailleurs : deux lignes de fin.
        if (!(serre && large)) ...<Widget>[
          if (serre) Ecart.vMd else if (large) Ecart.vXxl else Ecart.vLg,
          ligneFine,
          if (serre) Ecart.vSm else Ecart.vMd,
          ligne(0.66),
        ],
      ],
    );
  }
}

/// La largeur maximale du titre du support : en desktop, il tient sur deux
/// lignes comme sur les images.
const double _largeurTitre = 400;

/// Un titre aux lignes equilibrees (comme `text-wrap: balance`) : meme
/// nombre de lignes qu'a pleine largeur, mais dans la plus petite largeur
/// qui le garde. « Les bonnes / manieres en classe » plutot que « Les bonnes
/// manieres en / classe », avec un mot seul sur la derniere ligne.
class _TitreEquilibre extends StatelessWidget {
  const _TitreEquilibre({required this.texte, required this.style});

  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) {
      final Widget titre = Text(texte, style: style);
      final double pleine = contraintes.maxWidth;
      if (!pleine.isFinite) return titre;
      final TextStyle effectif = DefaultTextStyle.of(context).style
          .merge(style);
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: texte, style: effectif),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      int lignes(double largeur) {
        peintre.layout(maxWidth: largeur);
        return peintre.computeLineMetrics().length;
      }

      final int cible = lignes(pleine);
      if (cible <= 1) {
        peintre.dispose();
        return titre;
      }
      double bas = 0;
      double haut = pleine;
      for (int i = 0; i < 12; i++) {
        final double milieu = (bas + haut) / 2;
        if (lignes(milieu) > cible) {
          bas = milieu;
        } else {
          haut = milieu;
        }
      }
      peintre.dispose();
      return SizedBox(width: haut.ceilToDouble(), child: titre);
    },
  );
}

/// La largeur maximale du texte de l'encadre.
const double _largeurEncadre = 320;

/// Web etroit : l'encadre coupe apres « explications » (image), et son texte
/// reste sous le volet Eleves ou Supports quand il est ouvert.
const double _largeurEncadreEtroit = 256;

/// Web etroit, volet ouvert : l'encadre se coupe sur deux lignes qui
/// restent sous le volet (≈ 320 de large).
const double _largeurEncadreSousVolet = 200;

/// Web etroit : le corps du texte de l'encadre (image : ≈ 18 px).
const double _corpsEncadreEtroit = 18;

/// Une ligne de texte figuree, en gris clair.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.fraction, this.epaisseur = AppSpacing.md});

  final double fraction;

  /// L'epaisseur du trait ; plus fine dans le support resserre du telephone.
  final double epaisseur;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: fraction,
    child: SizedBox(
      height: epaisseur,
      child: DecoratedBox(
        decoration: AppPalette.of(context).surfaceSunken
            .decoration(borderRadius: AppRadius.arrondiFull),
      ),
    ),
  );
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          texte,
          style: palette.washAccent.applyTo(
            Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
          ),
        ),
      ),
    );
  }
}

/// L'illustration du support : un aplat aux jetons, jamais une photo.
class _Illustration extends StatelessWidget {
  const _Illustration();

  static const double _largeur = 284;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      image: true,
      label: t.salle.seance.illustration,
      excludeSemantics: true,
      child: SizedBox(
        width: _largeur,
        child: AspectRatio(
          aspectRatio: 1.3,
          child: DecoratedBox(
            decoration: palette.washWarning.decoration(
              borderRadius: AppRadius.arrondiMd,
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: palette.washWarning.onBackground,
                  size: AppSpacing.respiration,
                ),
                child: Icon(AppIcons.lecon.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rien n'est partage : la video de l'enseignante au centre, et une phrase.
class _RienPartage extends StatelessWidget {
  const _RienPartage({required this.vue});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      key: const ValueKey<String>('zone-support'),
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          final double largeur = math.min(
            _largeurVideoMax,
            math.min(
              contraintes.maxWidth - 2 * AppSpacing.xxl,
              (contraintes.maxHeight - _hauteurTexte) * MesuresVignette.ratio,
            ),
          );
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (largeur > 0) VignetteVideo(vue: vue, largeur: largeur),
                  Ecart.vXl,
                  Text(
                    t.salle.seance.rienPartage(nom: vue.nomEnseignant),
                    textAlign: TextAlign.center,
                    style: palette.inkMuted.applyTo(
                      Theme.of(context).textTheme.bodyLarge ??
                          const TextStyle(),
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

/// La plus grande video centree de l'etat « rien partage ».
const double _largeurVideoMax = 360;

/// La place gardee sous la video pour la phrase et les marges.
const double _hauteurTexte = 120;
