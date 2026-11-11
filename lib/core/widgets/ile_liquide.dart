// ILE-SALLE (directeur, 11/11/2026) : « il faut faire bon usage de la pilule.
// Pense a la Dynamic Island de Apple » ; l'effet liquide de la barre de
// navigation, « mais en le readaptant a la situation ».
//
// Une capsule dont la forme suit son contenu comme une goutte :
//
// - Le contenu est mesure a sa taille naturelle ; la capsule va vers cette
//   taille sur deux ressorts de l'effet liquide (`IndicateurLiquide`) : la
//   dimension qui change le plus est le bord de devant, raide
//   ([AppMouvement.ressortGoutteTete]) ; l'autre suit, plus souple
//   ([AppMouvement.ressortGoutteQueue]). La capsule s'etire donc dans le sens
//   du changement, puis se reforme. Amortissement critique, et chaque bord
//   est borne entre son depart et sa cible : **aucun rebond**, jamais un
//   depassement de la cible.
// - La taille de la mise en page suit la capsule, sans saut ni rebond : les
//   voisins glissent une fois, dans un seul sens, ils ne tremblent pas.
// - Le contenu est peint a sa taille finale, decoupe par la capsule : il ne se
//   recompose pas a chaque image (seule la forme bouge).
// - Miroir arabe naturel : l'alignement est directionnel (debut, fin).
// - « Reduire les animations » : la capsule prend sa taille d'un coup.
// - Aucun geste n'est retenu : le contenu recoit le toucher des la premiere
//   image, la forme ne le retarde jamais (DECISION-FLUIDITE).
//
// Le mouvement signale un changement, il ne decore pas : au repos, rien ne
// bouge (aucune boucle, aucune respiration). Pendant qu'un eleve recite,
// l'ile ne change que si son contenu change.
//
// [FonduLiquide] fond un contenu sortant dans un contenu entrant a l'interieur
// de l'ile : **fondu et leger glissement**, pas de flou. Un flou
// (`ImageFiltered`) se recalcule a chaque image, coute cher sur un telephone
// d'entree de gamme et dans le navigateur, et brouille un texte qu'on doit
// pouvoir lire jusqu'au dernier instant ; le fondu ne touche que l'opacite et
// la position, que le moteur compose sans redessiner.

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Une capsule dont la forme suit son contenu, comme une goutte.
class IleLiquide extends StatefulWidget {
  /// Cree l'ile autour de [child].
  const IleLiquide({
    required this.child,
    required this.decoration,
    this.padding = EdgeInsets.zero,
    this.alignement = AlignmentDirectional.topStart,
    super.key,
  });

  /// Le contenu ; sa taille naturelle donne la forme de l'ile.
  final Widget child;

  /// Le fond, le filet et l'arrondi de la capsule (une paire du theme :
  /// `AppColorPair.decoration`). L'arrondi decoupe aussi le contenu.
  final BoxDecoration decoration;

  /// La marge interieure.
  final EdgeInsetsGeometry padding;

  /// Ou se pose le contenu pendant que la capsule change de taille.
  final AlignmentGeometry alignement;

  @override
  State<IleLiquide> createState() => _IleLiquideEtat();
}

class _IleLiquideEtat extends State<IleLiquide> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    return _FormeIle(
      vsync: this,
      reduit: AppMouvement.mouvementReduit(context),
      decoration: widget.decoration,
      alignement: widget.alignement.resolve(sens),
      sens: sens,
      child: Padding(padding: widget.padding, child: widget.child),
    );
  }
}

class _FormeIle extends SingleChildRenderObjectWidget {
  const _FormeIle({
    required this.vsync,
    required this.reduit,
    required this.decoration,
    required this.alignement,
    required this.sens,
    required super.child,
  });

  final TickerProvider vsync;
  final bool reduit;
  final BoxDecoration decoration;
  final Alignment alignement;
  final TextDirection sens;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduIle(vsync, reduit, decoration, alignement, sens);

  @override
  void updateRenderObject(BuildContext context, _RenduIle rendu) {
    rendu
      ..vsync = vsync
      ..reduit = reduit
      ..decoration = decoration
      ..alignement = alignement
      ..sens = sens;
  }
}

/// La forme de l'ile : deux ressorts, un par dimension.
class _RenduIle extends RenderShiftedBox {
  _RenduIle(
    this._vsync,
    this._reduit,
    this._decoration,
    this._alignement,
    this._sens,
  ) : super(null) {
    _largeur = AnimationController.unbounded(vsync: _vsync)
      ..addListener(_bouge);
    _hauteur = AnimationController.unbounded(vsync: _vsync)
      ..addListener(_bouge);
  }

  late final AnimationController _largeur;
  late final AnimationController _hauteur;

  /// La taille visee (celle du contenu), `null` avant la premiere mise en
  /// page.
  Size? _cible;

  /// D'ou chaque dimension est partie : elle reste entre ce depart et sa
  /// cible (aucun depassement, aucun rebond).
  double _departLargeur = 0;
  double _departHauteur = 0;

  /// Vrai pendant la mise en page : les ressorts y sont poses sans
  /// redemander de mise en page.
  bool _enMiseEnPage = false;

  BoxPainter? _peintre;
  final LayerHandle<ClipRRectLayer> _decoupe = LayerHandle<ClipRRectLayer>();

  TickerProvider _vsync;
  set vsync(TickerProvider valeur) {
    if (identical(valeur, _vsync)) return;
    _vsync = valeur;
    _largeur.resync(valeur);
    _hauteur.resync(valeur);
  }

  bool _reduit;
  set reduit(bool valeur) {
    if (valeur == _reduit) return;
    _reduit = valeur;
    markNeedsLayout();
  }

  BoxDecoration _decoration;
  set decoration(BoxDecoration valeur) {
    if (valeur == _decoration) return;
    _decoration = valeur;
    _peintre?.dispose();
    _peintre = null;
    markNeedsPaint();
  }

  Alignment _alignement;
  set alignement(Alignment valeur) {
    if (valeur == _alignement) return;
    _alignement = valeur;
    markNeedsLayout();
  }

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsPaint();
  }

  void _bouge() {
    if (!_enMiseEnPage && attached) markNeedsLayout();
  }

  /// Pose les deux dimensions sur [cible], sans mouvement.
  void _poser(Size cible) {
    _largeur.stop();
    _hauteur.stop();
    _largeur.value = cible.width;
    _hauteur.value = cible.height;
    _departLargeur = cible.width;
    _departHauteur = cible.height;
  }

  /// La vitesse gardee quand une cible change en vol : seulement si elle va
  /// deja vers la nouvelle cible (sinon la capsule repartirait en arriere).
  static double _elan(AnimationController c, double cible) {
    if (!c.isAnimating) return 0;
    final double v = c.velocity;
    return (cible - c.value) * v > 0 ? v : 0;
  }

  /// Lance les deux ressorts vers [cible] : la dimension qui change le plus
  /// part sur le ressort raide, l'autre suit sur le souple.
  void _viser(Size cible) {
    final double dl = (cible.width - _largeur.value).abs();
    final double dh = (cible.height - _hauteur.value).abs();
    final bool largeurDevant = dl >= dh;
    final SpringDescription tete = AppMouvement.ressortGoutteTete;
    final SpringDescription queue = AppMouvement.ressortGoutteQueue;
    _departLargeur = _largeur.value;
    _departHauteur = _hauteur.value;
    if (dl > 0) {
      _largeur.animateWith(
        SpringSimulation(
          largeurDevant ? tete : queue,
          _largeur.value,
          cible.width,
          _elan(_largeur, cible.width),
        ),
      );
    }
    if (dh > 0) {
      _hauteur.animateWith(
        SpringSimulation(
          largeurDevant ? queue : tete,
          _hauteur.value,
          cible.height,
          _elan(_hauteur, cible.height),
        ),
      );
    }
  }

  /// [valeur] bornee entre [depart] et [cible] : jamais au-dela.
  static double _borne(double valeur, double depart, double cible) {
    final double bas = depart < cible ? depart : cible;
    final double haut = depart < cible ? cible : depart;
    return valeur.clamp(bas, haut);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final RenderBox? c = child;
    if (c == null) return constraints.smallest;
    return constraints.constrain(c.getDryLayout(constraints.loosen()));
  }

  @override
  void performLayout() {
    final RenderBox? c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    _enMiseEnPage = true;
    try {
      c.layout(constraints.loosen(), parentUsesSize: true);
      final Size cible = constraints.constrain(c.size);
      if (_cible == null || _reduit) {
        _poser(cible);
      } else if (cible != _cible) {
        _viser(cible);
      }
      _cible = cible;
      size = constraints.constrain(
        Size(
          _borne(_largeur.value, _departLargeur, cible.width),
          _borne(_hauteur.value, _departHauteur, cible.height),
        ),
      );
      final BoxParentData donnees = c.parentData! as BoxParentData;
      donnees.offset = _alignement.alongOffset(
        Offset(size.width - c.size.width, size.height - c.size.height),
      );
    } finally {
      _enMiseEnPage = false;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _peintre ??= _decoration.createBoxPainter(markNeedsPaint);
    _peintre!.paint(
      context.canvas,
      offset,
      ImageConfiguration(size: size, textDirection: _sens),
    );
    if (child == null) return;
    final BorderRadius rayon =
        _decoration.borderRadius?.resolve(_sens) ?? BorderRadius.zero;
    final Rect cadre = Offset.zero & size;
    _decoupe.layer = context.pushClipRRect(
      needsCompositing,
      offset,
      cadre,
      rayon.toRRect(cadre),
      super.paint,
      oldLayer: _decoupe.layer,
    );
  }

  @override
  void detach() {
    // Hors de l'arbre, plus de mouvement : la capsule reprend sa cible.
    final Size? cible = _cible;
    _enMiseEnPage = true;
    if (cible != null) _poser(cible);
    _enMiseEnPage = false;
    super.detach();
  }

  @override
  void dispose() {
    _decoupe.layer = null;
    _peintre?.dispose();
    _largeur.dispose();
    _hauteur.dispose();
    super.dispose();
  }
}

/// Un contenu de l'ile qui se fond dans le suivant quand [cle] change : le
/// sortant s'efface en glissant un peu vers le haut, l'entrant monte et
/// apparait. Le sortant ne prend aucune place : l'ile se mesure sur
/// l'entrant seul, et sa forme part tout de suite (aucun geste retarde).
///
/// Sous « reduire les animations » : le nouveau contenu, d'un coup.
class FonduLiquide extends StatelessWidget {
  /// Cree le fondu.
  const FonduLiquide({required this.cle, required this.child, super.key});

  /// Ce qui distingue un contenu d'un autre (un etat, un mot) ; tant qu'elle
  /// ne change pas, le contenu se met a jour sur place.
  final Object? cle;

  /// Le contenu courant.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Duration duree = AppMouvement.duree(context, AppMouvement.apparition);
    final Widget courant = KeyedSubtree(
      key: ValueKey<Object?>(cle),
      child: child,
    );
    if (duree == Duration.zero) return courant;
    final double course = AppMouvement.translation(
      context,
      AppMouvement.translationAjout / 2,
    );
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedSwitcher(
      duration: duree,
      switchInCurve: AppMouvement.entree,
      switchOutCurve: AppMouvement.sortie,
      layoutBuilder: (Widget? actuel, List<Widget> precedents) => Stack(
        alignment: AlignmentDirectional.topStart,
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final Widget p in precedents)
            _SansEncombrement(
              rtl: rtl,
              child: IgnorePointer(child: ExcludeSemantics(child: p)),
            ),
          ?actuel,
        ],
      ),
      transitionBuilder: (Widget enfant, Animation<double> a) =>
          AnimatedBuilder(
            animation: a,
            builder: (BuildContext _, Widget? e) => Transform.translate(
              offset: Offset(0, course * (1 - a.value)),
              child: Opacity(opacity: a.value.clamp(0, 1), child: e),
            ),
            child: enfant,
          ),
      child: courant,
    );
  }
}

/// Le contenu sortant d'un [FonduLiquide] : mis en page comme l'entrant,
/// peint a sa place, mais il ne compte pas dans la taille (zero).
class _SansEncombrement extends SingleChildRenderObjectWidget {
  const _SansEncombrement({required this.rtl, required super.child});

  final bool rtl;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduSansEncombrement(rtl);

  @override
  void updateRenderObject(BuildContext context, _RenduSansEncombrement rendu) {
    rendu.rtl = rtl;
  }
}

class _RenduSansEncombrement extends RenderProxyBox {
  _RenduSansEncombrement(this._rtl);

  bool _rtl;
  set rtl(bool valeur) {
    if (valeur == _rtl) return;
    _rtl = valeur;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    child?.layout(constraints, parentUsesSize: true);
    size = constraints.smallest;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  /// En arabe, la boite vide est posee au bord de debut (a droite) : le
  /// contenu s'etend donc vers la gauche.
  Offset get _decalage => _rtl && child != null
      ? Offset(size.width - child!.size.width, 0)
      : Offset.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? c = child;
    if (c != null) context.paintChild(c, offset + _decalage);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset d = _decalage;
    transform.translateByDouble(d.dx, d.dy, 0, 1);
  }
}
