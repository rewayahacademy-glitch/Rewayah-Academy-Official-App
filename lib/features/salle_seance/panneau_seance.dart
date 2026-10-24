// Le panneau ouvert a cote du support (enseignant) : Eleves ou Supports.
//
// Trois formes (plan de code T5, I-8 ; TB-5 : `CompositionSalle` choisit) :
// - colonne a cote du support, jamais par-dessus (Participants a gauche,
//   panneau pedagogique a droite) ;
// - volet par-dessus le support quand la colonne ne tient pas, avec la croix ;
// - telephone : feuille du bas (grammaire d'`AppBottomSheet` : poignee,
//   arrondi de feuille, filet et ombre de niveau 3) avec la croix, le haut du
//   support restant visible au-dessus.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/pressable.dart';

/// La largeur du volet en web etroit (image CLV-07 : ≈ 313 a 640 de large).
const double largeurPanneauSeance = AppSpacing.respiration * 5;

/// La largeur de la colonne en desktop (image CLV-07 : ≈ 328 a 1440 de large,
/// le support gardant son titre sur deux lignes).
const double largeurColonneSeance = AppSpacing.respiration * 5 + AppSpacing.sm;

/// La hauteur de support laissee visible au-dessus de la feuille du
/// telephone : le haut de la diapositive et la vignette entiere (image).
const double supportVisibleSousFeuille =
    AppSpacing.respiration * 2 + AppSpacing.xxl;

/// TB-RC (revue TB-R m3) : la largeur d'un volet ou d'une colonne au texte
/// agrandi. Elle suit le facteur de texte ([largeurPanneauSeance] a 100 %,
/// le double a 200 %), bornee par [disponible] (la place laissee par la
/// salle, par exemple la moitie de la largeur moins un palier) et jamais
/// sous [largeurPanneauSeance] quand la place le permet. Un seul calcul,
/// ici ; la salle le lit a la place de la constante.
double largeurPanneauPour(BuildContext context, double disponible) {
  final double voulue = MediaQuery.textScalerOf(context)
      .scale(largeurPanneauSeance);
  final double au100 = math.max(voulue, largeurPanneauSeance);
  if (!disponible.isFinite) return au100;
  return math.max(0, math.min(au100, disponible));
}

/// La forme du panneau.
enum FormePanneau {
  /// Desktop : colonne, a cote du support.
  colonne,

  /// Web etroit : volet gauche par-dessus le support.
  volet,

  /// Telephone : feuille du bas.
  feuille;

  /// La forme d'un gabarit.
  static FormePanneau pour(Gabarit gabarit) => switch (gabarit) {
    Gabarit.desktop => FormePanneau.colonne,
    Gabarit.tablette => FormePanneau.volet,
    Gabarit.mobile => FormePanneau.feuille,
  };
}

/// Le cadre d'un panneau : [titre], croix de fermeture, [enfant] qui defile.
class PanneauSeance extends StatefulWidget {
  const PanneauSeance({
    required this.titre,
    required this.onFermer,
    this.enfant = const SizedBox.shrink(),
    this.forme = FormePanneau.colonne,
    this.enMenu = false,
    this.ajusteAuContenu = false,
    this.libelleFermer,
    this.semantiqueFermer,
    this.cleFermer = cleReduire,
    super.key,
  });

  final String titre;
  final VoidCallback? onFermer;

  /// TB-4 (plan V2 §20) : le mot visible de la fermeture (« Reduire ») a la
  /// place de la croix, et son nom lu ([semantiqueFermer], « Reduire les
  /// commandes »), qui contient le mot visible (W-253). `null` : la croix.
  final String? libelleFermer;
  final String? semantiqueFermer;

  /// La cle de « Reduire » quand [libelleFermer] remplace la croix.
  static const Key cleReduire = ValueKey<String>('panneau-seance-reduire');

  /// TB-5 : la « Reduire » de la colonne des Participants, distincte de
  /// celle des Commandes (les deux colonnes coexistent sur bureau).
  static const Key cleReduireParticipants = ValueKey<String>(
    'panneau-participants-reduire',
  );

  /// La cle de « Reduire » de ce panneau.
  final Key cleFermer;

  /// Image CLV-07 desktop : un menu « … » (Fermer le panneau) a la place de
  /// la croix. Colonne seulement.
  final bool enMenu;

  /// Image CLV-07 desktop : la colonne s'arrete apres la liste au lieu de
  /// descendre jusqu'en bas. L'[enfant] doit alors se mesurer (liste
  /// `shrinkWrap`). Colonne seulement.
  final bool ajusteAuContenu;

  /// Le contenu, deja defilant (une liste) ou court.
  final Widget enfant;
  final FormePanneau forme;

  /// Le chevron « suite en bas » du volet et de la feuille, rendu
  /// seulement quand le contenu continue sous le bord (revue TB-R m4).
  static const Key cleSuite = ValueKey<String>('panneau-seance-suite');

  @override
  State<PanneauSeance> createState() => _PanneauSeanceState();

  /// La hauteur sous laquelle le panneau ne se tasse pas : sa tete (poignee,
  /// titre ou croix, mesure du titre tel qu'il est rendu, une seule ligne)
  /// plus une rangee de contenu a l'echelle courante du texte. La salle
  /// reduit d'abord le support visible au-dessus de la feuille pour la lui
  /// laisser ([supportVisiblePour]) ; s'il manque encore de la place, le
  /// panneau defile au lieu d'etre rogne.
  static double hauteurMinimale(
    BuildContext context, {
    required FormePanneau forme,
  }) {
    final bool feuille = forme == FormePanneau.feuille;
    // Marge haute du cadre, puis l'interieur.
    return (feuille ? AppSpacing.sm : AppSpacing.md) +
        _hauteurInterieure(context, forme: forme);
  }

  /// [hauteurMinimale] sans la marge haute du cadre : poignee (feuille),
  /// titre ou croix, ecart, une rangee de contenu.
  static double _hauteurInterieure(
    BuildContext context, {
    required FormePanneau forme,
  }) {
    final bool feuille = forme == FormePanneau.feuille;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(context).style
            .merge(Theme.of(context).textTheme.titleLarge),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double ligne = p.height;
    p.dispose();
    return (feuille ? AppBottomSheet.hauteurPoignee + AppSpacing.sm : 0) +
        (ligne > AppSpacing.titreEcran ? ligne : AppSpacing.titreEcran) +
        AppSpacing.sm +
        echelle.scale(AppSpacing.respiration);
  }
}

class _PanneauSeanceState extends State<PanneauSeance> {
  /// Le contenu continue sous le bord bas (revue TB-R m4, TB_RAPPORT n. 21).
  bool _suite = false;

  String get titre => widget.titre;
  VoidCallback? get onFermer => widget.onFermer;
  FormePanneau get forme => widget.forme;
  bool get enMenu => widget.enMenu;
  bool get ajusteAuContenu => widget.ajusteAuContenu;
  String? get libelleFermer => widget.libelleFermer;
  String? get semantiqueFermer => widget.semantiqueFermer;
  Key get cleFermer => widget.cleFermer;
  Widget get enfant => widget.enfant;

  /// Le defilement vertical du contenu (le premier, pas une liste
  /// imbriquee) : reste-t-il plus que sa marge interne sous le bord ? Un
  /// contenu qui porte son propre indice ([DefilementAFondu] : fondu et
  /// chevron poses sur son bord, sans prendre de place) n'en recoit pas un
  /// second.
  bool _suivre(ScrollNotification n) {
    final ScrollMetrics m = n.metrics;
    if (n.depth != 0 || m.axis != Axis.vertical) return false;
    final bool propre =
        n.context?.findAncestorWidgetOfExactType<DefilementAFondu>() != null;
    final bool suite = !propre && m.extentAfter > AppSpacing.md + 0.5;
    if (suite != _suite) setState(() => _suite = suite);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool feuille = forme == FormePanneau.feuille;
    final bool colonne = forme == FormePanneau.colonne;
    final bool ajuste = colonne && ajusteAuContenu;
    final Widget suivi = NotificationListener<ScrollMetricsNotification>(
      onNotification: (ScrollMetricsNotification n) {
        if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
        final bool propre =
            n.context.findAncestorWidgetOfExactType<DefilementAFondu>() != null;
        final bool suite =
            !propre && n.metrics.extentAfter > AppSpacing.md + 0.5;
        if (suite != _suite) setState(() => _suite = suite);
        return false;
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: _suivre,
        child: enfant,
      ),
    );
    final BoxDecoration decoration = feuille
        ? AppElevation.avecFilet(
            surface: palette.surfaceRaised,
            filet: palette.borderHairline,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiFeuille,
            ombres: AppElevation.niveau3(palette.ombre),
          )
        : palette.surfaceRaised
              .decoration(
                borderRadius: AppRadius.arrondiLg,
                side: palette.borderHairline.asBorderSide(),
              )
              .copyWith(
                boxShadow: forme == FormePanneau.volet
                    ? AppElevation.niveau3(palette.ombre)
                    : AppElevation.niveau1(palette.ombre),
              );
    // Revue TB-R M4 (plan V2 §18.3, WCAG 2.4.3) : le panneau est une region
    // du parcours au clavier. Tab en parcourt toutes les commandes, dans
    // l'ordre du contenu (celui de la lecture, miroite en arabe), avant
    // d'en sortir ; le second tour suit le premier.
    final Widget cadre = FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: titre,
        child: DecoratedBox(
          key: ValueKey<String>('panneau-seance-${forme.name}'),
          decoration: decoration,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              forme == FormePanneau.colonne ? AppSpacing.xs : AppSpacing.sm,
              feuille ? AppSpacing.sm : AppSpacing.md,
              forme == FormePanneau.colonne ? AppSpacing.xs : AppSpacing.sm,
              0,
            ),
            child: _HauteurMinimale(
              actif: !ajuste,
              minimum: PanneauSeance._hauteurInterieure(context, forme: forme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: ajuste ? MainAxisSize.min : MainAxisSize.max,
                children: <Widget>[
                  if (feuille) ...<Widget>[
                    Center(
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: AppBottomSheet.largeurPoignee,
                          height: AppBottomSheet.hauteurPoignee,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.borderResting.asBorderSide().color,
                              borderRadius: AppRadius.arrondiFull,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Ecart.vSm,
                  ],
                  _EnTete(
                    titre: titre,
                    onFermer: onFermer,
                    enMenu: colonne && enMenu,
                    libelleFermer: libelleFermer,
                    semantiqueFermer: semantiqueFermer,
                    cleFermer: cleFermer,
                  ),
                  Ecart.vSm,
                  if (ajuste)
                    Flexible(child: suivi)
                  else
                    Expanded(child: suivi),
                  // Web etroit : le chevron de bas de volet (image CLV-07-08-10),
                  // seulement s'il reste du contenu sous le bord (revue TB-R
                  // m4, TB_RAPPORT n. 21). Les Commandes posent le leur sur
                  // leur fondu ([DefilementAFondu]), sans prendre de place.
                  if (forme == FormePanneau.volet && _suite)
                    ExcludeSemantics(
                      key: PanneauSeance.cleSuite,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: IconTheme(
                          data: palette.inkMuted.asIconTheme(
                            size: AppSpacing.lg,
                          ),
                          child: Icon(AppIcons.suiteEnBas.repos),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!ajuste) return cadre;
    return Align(alignment: AlignmentDirectional.topCenter, child: cadre);
  }
}

/// Le support laisse visible au-dessus de la feuille du telephone dans une
/// hauteur [disponible] : [supportVisibleSousFeuille], reduit (jusqu'a zero)
/// pour que la feuille garde sa [PanneauSeance.hauteurMinimale].
double supportVisiblePour(BuildContext context, double disponible) {
  if (!disponible.isFinite) return supportVisibleSousFeuille;
  final double reste =
      disponible -
      PanneauSeance.hauteurMinimale(context, forme: FormePanneau.feuille);
  if (reste >= supportVisibleSousFeuille) return supportVisibleSousFeuille;
  return reste > 0 ? reste : 0;
}

/// Quand la place laissee au panneau est plus basse que [minimum] (feuille
/// ecrasee sous un en-tete de salle haut, 320 px a 200 %), le panneau garde
/// sa hauteur minimale et DEFILE : son contenu reste joignable (la liste
/// defile a l'interieur, le panneau entier autour), rien n'est rogne. Avec
/// assez de place, rien ne change.
class _HauteurMinimale extends StatelessWidget {
  const _HauteurMinimale({
    required this.actif,
    required this.minimum,
    required this.child,
  });

  final bool actif;
  final double minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!actif) return child;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) =>
          !c.maxHeight.isFinite || c.maxHeight >= minimum
          ? child
          : SingleChildScrollView(
              key: const ValueKey<String>('panneau-seance-defile'),
              child: SizedBox(height: minimum, child: child),
            ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.titre,
    required this.onFermer,
    required this.enMenu,
    this.libelleFermer,
    this.semantiqueFermer,
    this.cleFermer = PanneauSeance.cleReduire,
  });

  final Key cleFermer;
  final String titre;
  final VoidCallback? onFermer;
  final bool enMenu;
  final String? libelleFermer;
  final String? semantiqueFermer;

  /// Le mot le plus long du titre tient-il, a l'echelle de l'appareil, a
  /// cote de « Reduire » [mot] dans [largeur] ?
  bool _titreTientACote(BuildContext context, String mot, double largeur) {
    if (!largeur.isFinite) return true;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: mot,
        style: DefaultTextStyle.of(context).style
            .merge(Theme.of(context).textTheme.labelLarge),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double cible =
        p.width + AppSpacing.xs + AppSpacing.xl + 2 * AppSpacing.sm;
    p.dispose();
    final double fermer = cible > AppSpacing.titreEcran
        ? cible
        : AppSpacing.titreEcran;
    final double motTitre = largeurMotLePlusLong(
      context,
      titre,
      Theme.of(context).textTheme.titleLarge,
      echelle,
    );
    return motTitre + fermer <= largeur;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? fermer = onFermer;
    if (enMenu && fermer != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            Expanded(child: _Titre(titre: titre)),
            _MenuPanneau(titre: titre, onFermer: fermer),
          ],
        ),
      );
    }
    final String? mot = libelleFermer;
    if (mot != null && fermer != null) {
      // « Reduire » et son chevron (planches 1 et 6) : une cible de 48 au
      // moins, le mot passe a la ligne plutot que d'etre coupe.
      final Widget reduire = Pressable(
        key: cleFermer,
        onPress: fermer,
        libelleSemantique: semantiqueFermer ?? mot,
        arrondiFocus: AppRadius.arrondiMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.titreEcran,
            minWidth: AppSpacing.titreEcran,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    mot,
                    style: palette.inkAccent.applyTo(
                      Theme.of(context).textTheme.labelLarge ??
                          const TextStyle(),
                    ),
                  ),
                  Ecart.hXs,
                  IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.suiteEnBas.repos),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // TB-10 (COUPE-MOTS-1) : quand le mot le plus long du titre ne tient
      // plus a cote de « Reduire » (Mode Accessibilite, 320 a 200 %), le
      // titre prend toute la ligne et « Reduire » passe dessous, au bord de
      // fin : jamais « Comman / des ».
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints c) {
            if (!_titreTientACote(contexte, mot, c.maxWidth)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Titre(titre: titre),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: reduire,
                  ),
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: _Titre(titre: titre)),
                reduire,
              ],
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: _Titre(titre: titre)),
          if (fermer != null)
            Pressable(
              onPress: fermer,
              libelleSemantique: t.salle.seance.fermerPanneau,
              arrondiFocus: AppRadius.arrondiFull,
              child: SizedBox.square(
                dimension: AppSpacing.titreEcran,
                child: Center(
                  child: IconTheme(
                    data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(AppIcons.fermer.repos),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    // TB-3 : jamais de points de suspension (« Informations de la sea... »,
    // COUPE-MOTS-1) ; le titre passe a la ligne entre les mots, un mot trop
    // long se reduit juste assez pour tenir.
    child: TexteSansCoupure(
      titre,
      style: AppPalette.of(context).inkStrong
          .applyTo(Theme.of(context).textTheme.titleLarge ?? const TextStyle()),
    ),
  );
}

/// Le menu « … » de la colonne desktop (image CLV-07) : une seule entree,
/// « Fermer le panneau ».
class _MenuPanneau extends StatelessWidget {
  const _MenuPanneau({required this.titre, required this.onFermer});

  final String titre;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) => MenuActions(
    key: const ValueKey<String>('menu-panneau-seance'),
    libelle: t.salle.seance.optionsPanneau(titre: titre),
    points: true,
    actions: <EntreeAction>[
      EntreeAction(libelle: t.salle.seance.fermerPanneau, onChoix: onFermer),
    ],
  );
}

/// Une colonne qui defile avec l'indice de defilement de la salle : un
/// fondu au bord bas tant qu'il reste du contenu dessous, au bord haut des
/// qu'elle a defile.
///
/// Revue TB-R m29 : un seul composant pour cet indice, parametre (cles,
/// marge interne, borne du fondu), a la place des deux copies qui
/// divergeaient (Commandes et `TeteSalleBornee`). Revue TB-R m8 : le fondu
/// disparait sur la derniere ligne (la marge interne [margeBas] n'est pas du
/// contenu), et un element qui prend le focus au clavier est ramene hors du
/// fondu, jamais laisse a demi transparent.
class DefilementAFondu extends StatefulWidget {
  /// Cree la colonne.
  const DefilementAFondu({
    required this.child,
    this.cleDefilement,
    this.cleFonduBas,
    this.cleFonduHaut,
    this.margeBas = 0,
    this.borne = 1 / 8,
    this.chevron = true,
    super.key,
  });

  /// Le chevron « suite en bas » pose sur le fondu du bas.
  final bool chevron;

  /// Le contenu (une colonne).
  final Widget child;

  /// La cle du `SingleChildScrollView`.
  final Key? cleDefilement;

  /// La cle du fondu du bas, puis celle du fondu du haut.
  final Key? cleFonduBas;
  final Key? cleFonduHaut;

  /// La marge sous le contenu, dans le defilement : elle n'appelle pas de
  /// fondu.
  final double margeBas;

  /// La part maximale de la hauteur visible prise par un fondu : une vue
  /// basse (320 x2, 80 a 100 px) garde l'essentiel lisible.
  final double borne;

  /// La hauteur du fondu dans une vue de [hauteur].
  static double fonduPour(double hauteur, {double borne = 1 / 8}) =>
      math.max(0, math.min(AppSpacing.xxxl, hauteur * borne));

  @override
  State<DefilementAFondu> createState() => _DefilementAFonduState();
}

class _DefilementAFonduState extends State<DefilementAFondu> {
  bool _suite = false;
  bool _avant = false;
  final ScrollController _defile = ScrollController();

  /// Le defilement garde sa position quand un fondu se pose ou se retire.
  final GlobalKey _cleDefile = GlobalKey(debugLabel: 'defilement-a-fondu');

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChange);
    _defile.dispose();
    super.dispose();
  }

  bool _suivre(ScrollMetrics m) {
    final bool suite = m.extentAfter > widget.margeBas + 0.5;
    final bool avant = m.extentBefore > 0.5;
    if (suite != _suite || avant != _avant) {
      setState(() {
        _suite = suite;
        _avant = avant;
      });
    }
    return false;
  }

  /// Le focus a bouge : s'il est dans cette colonne, l'element est degage
  /// des fondus apres le defilement de la traversee (meme cadre).
  void _focusChange() {
    final BuildContext? cible = FocusManager.instance.primaryFocus?.context;
    if (cible == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && cible.mounted) _degager(cible);
    });
  }

  void _degager(BuildContext cible) {
    if (!_defile.hasClients) return;
    final ScrollPosition position = _defile.position;
    final ScrollableState? defile = Scrollable.maybeOf(cible);
    if (defile == null || !identical(defile.position, position)) return;
    final RenderObject? objet = cible.findRenderObject();
    final RenderObject? vue = defile.context.findRenderObject();
    if (objet is! RenderBox ||
        vue is! RenderBox ||
        !objet.attached ||
        !objet.hasSize ||
        !vue.hasSize) {
      return;
    }
    final double hauteur = vue.size.height;
    final double fondu = DefilementAFondu.fonduPour(
      hauteur,
      borne: widget.borne,
    );
    final double haut = objet.localToGlobal(Offset.zero, ancestor: vue).dy;
    final double bas = haut + objet.size.height;
    double voulu = position.pixels;
    if (bas > hauteur - fondu) {
      voulu += bas - (hauteur - fondu);
    } else if (haut < fondu && position.pixels > position.minScrollExtent) {
      voulu -= fondu - haut;
    }
    voulu = voulu.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((voulu - position.pixels).abs() > 0.5) position.jumpTo(voulu);
  }

  /// Seule l'opacite de [fond] compte (melange `dstIn`).
  Widget _fondre(
    Key? cle,
    Color fond, {
    required bool versLeBas,
    required Widget child,
  }) => ShaderMask(
    key: cle,
    blendMode: BlendMode.dstIn,
    shaderCallback: (Rect r) {
      final double fondu = DefilementAFondu.fonduPour(
        r.height,
        borne: widget.borne,
      );
      return LinearGradient(
        begin: versLeBas ? Alignment.topCenter : Alignment.bottomCenter,
        end: versLeBas ? Alignment.bottomCenter : Alignment.topCenter,
        stops: <double>[
          if (r.height <= 0) 0 else math.max(0, 1 - fondu / r.height),
          1,
        ],
        colors: <Color>[fond, fond.withValues(alpha: 0)],
      ).createShader(r);
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    Widget contenu = KeyedSubtree(
      key: _cleDefile,
      child: SingleChildScrollView(
        key: widget.cleDefilement,
        controller: _defile,
        padding: EdgeInsets.only(bottom: widget.margeBas),
        child: widget.child,
      ),
    );
    final Color fond = AppPalette.of(context).surfaceRaised.background;
    if (_suite) {
      contenu = _fondre(
        widget.cleFonduBas,
        fond,
        versLeBas: true,
        child: contenu,
      );
    }
    if (_avant) {
      contenu = _fondre(
        widget.cleFonduHaut,
        fond,
        versLeBas: false,
        child: contenu,
      );
    }
    // TB_RAPPORT n. 2 et n. 10 : le fondu seul passait inapercu. Le chevron
    // « suite en bas » se pose sur lui, au centre du bord bas, tant qu'il
    // reste du contenu (revue TB-R m4) ; il ne prend aucune place (la vue
    // garde sa hauteur, rien ne deborde a 320 x2), ne capte aucun toucher
    // et n'est pas lu (decoratif, comme celui du volet).
    if (_suite && widget.chevron) {
      contenu = Stack(
        children: <Widget>[
          Positioned.fill(child: contenu),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                key: PanneauSeance.cleSuite,
                child: Center(
                  child: IconTheme(
                    data: AppPalette.of(context).inkMuted
                        .asIconTheme(size: AppSpacing.lg),
                    child: Icon(AppIcons.suiteEnBas.repos),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (ScrollUpdateNotification n) =>
          n.depth == 0 && _suivre(n.metrics),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (ScrollMetricsNotification n) =>
            n.depth == 0 && _suivre(n.metrics),
        child: contenu,
      ),
    );
  }
}
