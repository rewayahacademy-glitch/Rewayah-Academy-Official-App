// ENTREE-PRAXIS (directeur, 20/11/2026, maquette « Praxis vous accueille »
// confirmee : « j'espere qu'elle sera fidele en production ») : la coquille
// de la page d'entree. La scene (la porte du logo, sa lumiere, la route,
// Praxis) occupe le haut de l'ecran sur telephone et tout l'ecran sur
// ordinateur ; le formulaire est pose dessus, dans une feuille (telephone) ou
// une carte au bord de fin (ordinateur).
//
// Trois regles tiennent cette mise en page :
//
// 1. **La page defile, pas un cadre** (DECISION-DEFILEMENT) : sur telephone,
//    la scene et la feuille defilent ensemble ; sur ordinateur, la carte seule
//    defile devant la scene quand elle depasse l'ecran.
// 2. **Rien de la scene ne recouvre le formulaire.** Le premier plan (Praxis,
//    ses mots) est peint dans un calque borne a la zone libre : la
//    verification anti-robot, posee sous le bouton, reste toujours peinte et
//    jamais recouverte. Aucune opacite n'enveloppe le formulaire.
// 3. **La scene ne retarde rien** : ses textures se preparent apres la
//    premiere image, son horloge s'arrete quand plus rien ne bouge.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vivant/entree/outils_entree.dart';
import '../../core/vivant/entree/regie_praxis.dart';
import '../../core/vivant/entree/scene_entree.dart';
import '../../core/widgets/page_shell.dart';
import 'scenes_entree.dart';

/// La largeur de la carte du formulaire sur ordinateur : 448, soit 368 de
/// contenu entre deux marges de 40 (la maquette : 440 et 36, meme contenu).
const double largeurCarteEntree = 448;

/// La hauteur de la carte sur ordinateur quand l'ecran le permet (maquette).
const double hauteurCarteEntree = 560;

/// Ce dont la feuille recouvre le bas de la scene, sur telephone (maquette).
const double recouvrementFeuilleEntree = 26;

/// La largeur du contenu de la feuille sur une tablette tenue droite.
const double _largeurContenuFeuille = AppPage.largeurDialogue;

/// La coquille de la page d'entree : la scene de Praxis et le formulaire.
class CoquillePraxis extends StatefulWidget {
  /// Pose [formulaire] et [pied] devant la scene.
  const CoquillePraxis({
    required this.formulaire,
    required this.situation,
    this.pied = const <Widget>[],
    this.pli,
    this.texteSaisi = '',
    this.adresseComplete = false,
    super.key,
  });

  /// Le formulaire. Il est toujours pose sur une surface de carte : le
  /// parametre vaut vrai (les composants prennent leurs couleurs de carte).
  final Widget Function(bool bureau) formulaire;

  /// Les liens du bas, sous le formulaire.
  final List<Widget> pied;

  /// La cle du dernier element que le premier ecran doit montrer sur
  /// telephone (dans la maquette : le bouton Google). La scene prend la place
  /// que laisse le formulaire jusqu'a lui ; ce qui suit vient en faisant
  /// defiler la page. Nul : tout le formulaire compte.
  final GlobalKey? pli;

  /// Ce qui se passe sur la page : Praxis joue la scene qui lui correspond.
  final SituationEntree situation;

  /// L'adresse en cours de saisie : Praxis reagit a l'arobase.
  final String texteSaisi;

  /// Vrai quand l'adresse saisie peut recevoir un lien.
  final bool adresseComplete;

  @override
  State<CoquillePraxis> createState() => CoquillePraxisState();
}

/// L'etat de la coquille ; public pour que les tests lisent la regie.
class CoquillePraxisState extends State<CoquillePraxis>
    with SingleTickerProviderStateMixin<CoquillePraxis> {
  /// La regie de la scene.
  late final RegiePraxis regie = RegiePraxis(this);
  final ReactionsToucher _reactions = ReactionsToucher();
  final GlobalKey _cleDecor = GlobalKey();
  final GlobalKey _cleFeuille = GlobalKey();
  final GlobalKey _cleContenu = GlobalKey();

  /// La hauteur du contenu du formulaire, mesuree ; une estimation avant la
  /// premiere mesure (titre, onglets, champ, trois boutons, liens).
  double _besoin = 400;
  double _besoinLisse = 400;
  bool _mesure = false;

  Size _taille = Size.zero;
  bool _large = false;
  bool _rtl = false;
  bool _parfaitDit = false;
  Timer? _minuterie;
  SituationEntree? _jouee;

  @override
  void initState() {
    super.initState();
    regie
      ..cadrage = _cadrer
      ..surImage = _surImage;
    RegiePraxis.preparerLumiere();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _jouer(widget.situation, neuf: true);
    });
  }

  @override
  void didUpdateWidget(CoquillePraxis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.situation != widget.situation) {
      _jouer(widget.situation);
    } else if (widget.situation == SituationEntree.saisie) {
      final bool arobase =
          widget.texteSaisi.contains('@') && !oldWidget.texteSaisi.contains('@');
      if (arobase) {
        reactionArobase(regie.th);
        regie.reveiller();
      }
      if (widget.texteSaisi.isEmpty) _parfaitDit = false;
      if (widget.adresseComplete && !oldWidget.adresseComplete && !_parfaitDit) {
        _parfaitDit = true;
        unawaited(regie.reagir(reactionAdresseComplete()));
      } else if (widget.texteSaisi != oldWidget.texteSaisi) {
        regie.reveiller();
      }
    }
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    regie.fermer();
    super.dispose();
  }

  Rect get _carte {
    final double x = _rtl
        ? AppSpacing.respiration
        : _taille.width - largeurCarteEntree - AppSpacing.respiration;
    return Rect.fromLTWH(x, 0, largeurCarteEntree, _taille.height);
  }

  double get _hautScene => _large
      ? _taille.height
      : RegiePraxis.hauteurScene(
          ecran: _taille.height,
          besoin: _besoinLisse,
          recouvrement: recouvrementFeuilleEntree,
        );

  Geo _cadrer(double cam) => Geo(
    _taille.isEmpty ? const Size(390, 844) : _taille,
    _large ? CadreScene.large : CadreScene.tel,
    _rtl,
    _taille.isEmpty ? 400 : _hautScene,
    _carte,
    cam: cam,
  );

  void _surImage(double dt) {
    // Le formulaire change de hauteur en douceur : la scene suit.
    if (_besoinLisse != _besoin) {
      final double ecart = _besoin - _besoinLisse;
      _besoinLisse = ecart.abs() < 0.5
          ? _besoin
          : _besoinLisse + ecart * (1 - 1 / (1 + dt * 9));
      if (mounted) setState(() {});
    }
    if (widget.situation == SituationEntree.saisie) _suivreTexte();
  }

  /// Ses yeux suivent la fin du texte ecrit dans le champ qui a le focus.
  void _suivreTexte() {
    final RenderObject? champ = FocusManager.instance.primaryFocus?.context
        ?.findRenderObject();
    final RenderObject? decor = _cleDecor.currentContext?.findRenderObject();
    if (champ is! RenderBox || decor is! RenderBox || !champ.attached) return;
    final double avance = (AppSpacing.lg + widget.texteSaisi.length * 9)
        .clamp(0, champ.size.width)
        .toDouble();
    final Offset fin = decor.globalToLocal(
      champ.localToGlobal(
        Offset(_rtl ? champ.size.width - avance : avance, champ.size.height / 2),
      ),
    );
    final Offset d = fin - regie.th.centrePraxis;
    regie.th.px.regarder(d.dx / 130, d.dy / 110);
  }

  void _jouer(SituationEntree situation, {bool neuf = false}) {
    _minuterie?.cancel();
    final SituationEntree? avant = _jouee;
    _jouee = situation;
    final bool depuisPorte =
        neuf || situationDepuisLaPorte(situation, regie.th);
    unawaited(
      regie.jouer(
        sceneEntree(
          situation,
          depuisPorte: depuisPorte,
          avant: avant,
          rtl: _rtl,
          large: _large,
          sansArobase: !widget.texteSaisi.contains('@'),
        ),
        depuisPorte: depuisPorte,
      ),
    );
    // Deux situations de la maquette viennent du temps qui passe.
    final (Duration, SituationEntree)? suite = switch (situation) {
      SituationEntree.envoi => (
        AppDelais.praxisReseauLent,
        SituationEntree.reseauLent,
      ),
      SituationEntree.envoye => (
        AppDelais.praxisAttenteLongue,
        SituationEntree.attenteLongue,
      ),
      _ => null,
    };
    if (suite != null) {
      _minuterie = Timer(suite.$1, () {
        if (mounted && widget.situation == situation) _jouer(suite.$2);
      });
    }
  }

  void _pointeur(PointerUpEvent e) {
    final RenderObject? decor = _cleDecor.currentContext?.findRenderObject();
    if (decor is! RenderBox) return;
    if (regie.touche(decor.globalToLocal(e.position))) {
      unawaited(regie.reagir(_reactions.suivante()));
    }
  }

  /// La hauteur du formulaire a montrer : jusqu'au pli s'il est pose, plus
  /// la marge du haut de la feuille et un palier sous le pli.
  double _hauteurUtile(Size taille) {
    final RenderObject? pli = widget.pli?.currentContext?.findRenderObject();
    final RenderObject? contenu = _cleContenu.currentContext
        ?.findRenderObject();
    if (pli is RenderBox && contenu is RenderBox && pli.attached) {
      final double bas = pli
          .localToGlobal(Offset(0, pli.size.height), ancestor: contenu)
          .dy;
      return bas + AppSpacing.xxl + AppSpacing.lg;
    }
    return taille.height + AppSpacing.xxl + AppSpacing.xl;
  }

  void _mesurer(Size taille) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      final double utile = _hauteurUtile(taille);
      if ((utile - _besoin).abs() < 0.5) return;
      setState(() {
        _besoin = utile;
        // La premiere mesure se pose d'un coup ; sous mouvement reduit et
        // quand Praxis dort, les suivantes aussi.
        if (!_mesure || regie.reduit || !regie.eveillee) _besoinLisse = _besoin;
        _mesure = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final double facteur = MediaQuery.textScalerOf(context).scale(1);
    T.s = theme.brightness == Brightness.dark;
    _rtl = Directionality.of(context) == TextDirection.rtl;
    regie
      ..reduit = AppMouvement.mouvementReduit(context)
      ..th.arabe = _rtl
      ..th.styleBase = theme.textTheme.headlineSmall ?? const TextStyle();
    return PageShell(
      fond: palette.surfaceRaised,
      bordABord: true,
      defilante: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          _taille = contraintes.biggest;
          // Material 3, fenetre « expanded » : la carte au bord de fin des
          // 840, mesures en largeur utile (le texte agrandi ramene a la
          // feuille du telephone).
          _large = contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
          final Widget contenu = _Mesure(
            key: _cleContenu,
            surTaille: _mesurer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[widget.formulaire(true), ...widget.pied],
            ),
          );
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: _pointeur,
            child: _large
                ? _ordinateur(palette, contenu)
                : _telephone(palette, contenu),
          );
        },
      ),
    );
  }

  Widget _decor() => RepaintBoundary(
    child: Semantics(
      image: true,
      label: t.connexion.praxis.scene,
      child: CustomPaint(
        key: _cleDecor,
        painter: DecorPeintre(regie.th),
        child: const SizedBox.expand(),
      ),
    ),
  );

  /// Le premier plan (Praxis, ses mots), borne a [zone] : il ne passe jamais
  /// devant le formulaire.
  Widget _calque(Rect zone) => Positioned.fromRect(
    rect: zone,
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey<String>('entree-praxis-calque'),
          painter: _CalquePeintre(regie.th, zone.topLeft, _taille),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );

  Widget _telephone(AppPalette palette, Widget contenu) {
    final double h = _taille.height;
    final double haut = _hautScene - recouvrementFeuilleEntree;
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: h,
            child: _decor(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: haut),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: h - haut),
                child: DecoratedBox(
                  key: _cleFeuille,
                  decoration: ShapeDecoration(
                    color: palette.surfaceRaised.background,
                    shadows: AppElevation.niveau3(palette.ombre),
                    shape: const RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.entree),
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurContenuFeuille,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xl,
                        ),
                        child: contenu,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Le calque descend jusqu'au contenu de la feuille (sa marge du
          // haut, vide) : la main qui montre le champ n'est pas coupee.
          _calque(Rect.fromLTWH(0, 0, _taille.width, haut + AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _ordinateur(AppPalette palette, Widget contenu) {
    final double h = _taille.height;
    final Rect carte = _carte;
    const double marge = AppSpacing.sm;
    final Rect zone = _rtl
        ? Rect.fromLTRB(carte.right + marge, 0, _taille.width, h)
        : Rect.fromLTRB(0, 0, carte.left - marge, h);
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _decor()),
        Positioned.fill(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.respiration,
                    top: AppSpacing.xxl,
                    bottom: AppSpacing.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: largeurCarteEntree,
                      maxWidth: largeurCarteEntree,
                      minHeight: (h - 2 * AppSpacing.xxl)
                          .clamp(0, hauteurCarteEntree)
                          .toDouble(),
                    ),
                    child: DecoratedBox(
                      key: _cleFeuille,
                      decoration: ShapeDecoration(
                        color: palette.surfaceRaised.background,
                        shadows: AppElevation.niveau3(palette.ombre),
                        shape: const RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.entree),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.section),
                        child: Center(child: contenu),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _calque(zone),
      ],
    );
  }
}

/// Peint le premier plan de la scene dans une zone bornee : la scene garde
/// son repere (celui de l'ecran), la zone la coupe.
class _CalquePeintre extends CustomPainter {
  _CalquePeintre(this.th, this.origine, this.ecran) : super(repaint: th);

  final Theatre th;
  final Offset origine;
  final Size ecran;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(-origine.dx, -origine.dy);
    ScenePeintre(th).paint(canvas, ecran);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CalquePeintre oldDelegate) => true;
}

/// Mesure son enfant et le dit a [surTaille] quand sa taille change.
class _Mesure extends SingleChildRenderObjectWidget {
  const _Mesure({required this.surTaille, required super.child, super.key});

  final ValueChanged<Size> surTaille;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduMesure(surTaille);

  @override
  void updateRenderObject(BuildContext context, _RenduMesure renderObject) {
    renderObject.surTaille = surTaille;
  }
}

class _RenduMesure extends RenderProxyBox {
  _RenduMesure(this.surTaille);

  ValueChanged<Size> surTaille;
  Size? _derniere;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _derniere) {
      _derniere = size;
      surTaille(size);
    }
  }
}
