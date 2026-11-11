// L'effet liquide de la navigation (decisions du directeur du 10/11/2026,
// relayees par le garde-cap) : quand on change d'onglet dans la pilule, le
// fond de l'onglet ouvert est une goutte molle qui se deplace au ressort,
// s'etire dans le sens du mouvement puis se reforme.
//
// LIQUIDE-MATIERE (correction du directeur du 11/11/2026) : la pilule et le
// cercle Compte sont deux morceaux de la meme matiere (meme fond, meme ombre,
// meme contour). De l'une a l'autre, c'est le CORPS de la pilule qui s'etire :
// un pont de matiere (metaballe entre les deux silhouettes) relie les deux,
// puis se rompt comme une goutte d'huile qui se detache ; le cercle la recoit
// d'un leger rebond. La couleur de selection n'entre jamais dans le pont :
// elle ne change que sur la destination, une fois le pont rompu, en fondu.
//
// Un composant du core, reutilisable (« la barre est un laboratoire ») :
// d'abord la barre flottante, ensuite les profils de l'Accueil.
//
// - Au repos, la goutte ne se dessine pas : la destination ouverte garde son
//   propre fond (rien ne change a l'ecran tant que rien ne bouge).
// - Les deux bords de la goutte suivent deux ressorts : celui de devant, plus
//   raide, arrive le premier ; celui de derriere suit. La goutte s'etire,
//   puis se reforme. Aucun rebond (`AppMouvement.ressort*`).
// - Les positions sont mesurees sur la mise en page : le miroir arabe est
//   donc naturel.
// - « Reduire les animations » : changement immediat, aucune goutte.
// - Aucun geste n'est retenu : la goutte suit le toucher, elle ne le
//   retarde jamais (DECISION-FLUIDITE).

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// La goutte d'une rangee de destinations.
///
/// [cibles] : une cle par destination, posee sur ce que la goutte recouvre
/// (l'onglet, le cercle). [zones] : les surfaces ou la goutte se dessine (la
/// pilule, le cercle) ; entre deux zones, elle se dessine en pont. [child] :
/// la rangee ; la couche interieure de chaque zone opaque se pose avec
/// [CoucheLiquide].
class IndicateurLiquide extends StatefulWidget {
  /// Cree l'indicateur.
  const IndicateurLiquide({
    required this.cibles,
    required this.zones,
    required this.indexActif,
    required this.couleur,
    required this.child,
    this.matiere,
    this.contour,
    this.ombres = const <BoxShadow>[],
    super.key,
  });

  /// La matiere des zones (le fond de la pilule et du cercle) : celle du pont
  /// qui les relie. Nulle : aucun pont, la destination change seule.
  final Color? matiere;

  /// Le contour des zones, repris sur le bord du pont (nul : aucun).
  final BorderSide? contour;

  /// L'ombre des zones, reprise sous le pont.
  final List<BoxShadow> ombres;

  /// Une cle par destination, dans l'ordre de [indexActif].
  final List<GlobalKey> cibles;

  /// Les zones ou la goutte se dessine (la pilule, le cercle).
  final List<GlobalKey> zones;

  /// La destination ouverte, ou `null`.
  final int? indexActif;

  /// La couleur de la goutte : le fond doux de l'onglet ouvert.
  final Color couleur;

  /// La rangee.
  final Widget child;

  /// Vrai quand la goutte se deplace au-dessus de [context] : la
  /// destination ouverte cache alors son propre fond, que la goutte remplace.
  static bool enMouvement(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PorteeLiquide>()
          ?.enMouvement ??
      false;

  /// La goutte en cours au-dessus de [context], dans le repere de
  /// l'indicateur, ou `null` au repos (tests).
  @visibleForTesting
  static Rect? goutteDe(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PorteeLiquide>()?.etat.goutte;

  /// Les zones au-dessus de [context], dans le repere de l'indicateur (tests).
  @visibleForTesting
  static List<Rect> zonesDe(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PorteeLiquide>()?.etat.zones ??
      const <Rect>[];

  /// L'avancee du pont de matiere au-dessus de [context] (0 a 1), ou `null`
  /// sans pont en cours (tests).
  @visibleForTesting
  static double? pontDe(BuildContext context) {
    final _EtatIndicateurLiquide? etat = context
        .getInheritedWidgetOfExactType<_PorteeLiquide>()
        ?.etat;
    return etat == null || !etat._pontActif ? null : etat._pont.value;
  }

  /// Le fondu de la couleur de selection sur la destination, au-dessus de
  /// [context] : 0 tant que le pont n'est pas rompu, puis 1. Nul hors d'un
  /// indicateur.
  static Animation<double>? fonduDestination(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PorteeLiquide>()?.etat._fondu;

  @override
  State<IndicateurLiquide> createState() => _EtatIndicateurLiquide();
}

class _EtatIndicateurLiquide extends State<IndicateurLiquide>
    with TickerProviderStateMixin {
  late final AnimationController _gauche = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _droite = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _haut = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _bas = AnimationController.unbounded(
    vsync: this,
  );
  late final Listenable _tout = Listenable.merge(<Listenable>[
    _gauche,
    _droite,
    _haut,
    _bas,
  ]);
  // LIQUIDE-MATIERE : l'avancee du pont (0 a 1), la reception du cercle
  // (le rebond, autour de 0) et le fondu de la couleur sur la destination.
  late final AnimationController _pont = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _reception = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _fondu = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMouvement.apparition,
  );
  late final Listenable _toutPont = Listenable.merge(<Listenable>[
    _pont,
    _gauche,
    _droite,
    _haut,
    _bas,
  ]);
  bool _mesure = false;
  bool _enMouvement = false;
  bool _pontActif = false;
  bool _recu = false;
  int _de = 0;
  int _vers = 0;
  int? _ancien;

  /// La part du pont ou la goutte se detache de sa source.
  static const double _rupture = 0.55;

  /// La part du pont ou le cercle recoit la goutte.
  static const double _arrivee = 0.8;

  @override
  void initState() {
    super.initState();
    for (final AnimationController c in <AnimationController>[
      _gauche,
      _droite,
      _haut,
      _bas,
    ]) {
      c.addStatusListener(_statut);
    }
    _pont
      ..addListener(_suivrePont)
      ..addStatusListener(_finPont);
    _ancien = widget.indexActif;
    WidgetsBinding.instance.addPostFrameCallback((_) => _viser(anime: false));
  }

  void _statut(AnimationStatus statut) {
    // Une simulation finie : la goutte s'arrete quand toutes le sont. (Le
    // statut seul ne suffit pas : sans bornes, il reste « en avant » au
    // repos.)
    if (statut != AnimationStatus.completed &&
        statut != AnimationStatus.dismissed) {
      return;
    }
    final bool bouge =
        _gauche.isAnimating ||
        _droite.isAnimating ||
        _haut.isAnimating ||
        _bas.isAnimating;
    if (!bouge && _enMouvement && mounted) {
      setState(() => _enMouvement = false);
    }
  }

  void _suivrePont() {
    final double e = _pont.value;
    if (!_recu && e >= _arrivee) {
      _recu = true;
      // La goutte rompue : la couleur gagne la destination, en fondu.
      _fondu.forward(from: 0);
      // Le cercle (une zone qui n'est pas la pilule) recoit d'un rebond.
      if (_vers != 0) {
        _reception.animateWith(
          SpringSimulation(
            AppMouvement.ressortReception,
            0,
            0,
            AppMouvement.elanReception,
          ),
        );
      }
    }
  }

  void _finPont(AnimationStatus statut) {
    if (statut != AnimationStatus.completed &&
        statut != AnimationStatus.dismissed) {
      return;
    }
    if (!_pont.isAnimating && _pontActif && mounted) {
      if (!_recu) _fondu.value = 1;
      setState(() => _pontActif = false);
    }
  }

  /// La zone de la destination [i] : celle qui contient son centre.
  int? _zoneDe(int? i) {
    if (i == null || i < 0 || i >= widget.cibles.length) return null;
    final Rect? c = _rect(widget.cibles[i]);
    if (c == null) return null;
    final List<Rect> z = zones;
    for (int k = 0; k < z.length; k++) {
      if (z[k].contains(c.center)) return k;
    }
    return null;
  }

  @override
  void didUpdateWidget(IndicateurLiquide ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.indexActif != widget.indexActif) {
      // La nouvelle destination n'a sa place qu'apres la mise en page.
      WidgetsBinding.instance.addPostFrameCallback((_) => _viser(anime: true));
    }
  }

  /// Le rectangle de [cle] dans le repere de l'indicateur.
  Rect? _rect(GlobalKey cle) {
    final RenderObject? moi = context.findRenderObject();
    final RenderObject? lui = cle.currentContext?.findRenderObject();
    if (moi is! RenderBox || lui is! RenderBox || !lui.hasSize) return null;
    return MatrixUtils.transformRect(
      lui.getTransformTo(moi),
      Offset.zero & lui.size,
    );
  }

  /// Les zones, dans le repere de l'indicateur.
  List<Rect> get zones => <Rect>[
    for (final GlobalKey z in widget.zones) ?_rect(z),
  ];

  void _viser({required bool anime}) {
    if (!mounted) return;
    final int? i = widget.indexActif;
    if (i == null || i < 0 || i >= widget.cibles.length) return;
    final Rect? cible = _rect(widget.cibles[i]);
    if (cible == null) return;
    final bool sauter =
        !anime || !_mesure || AppMouvement.mouvementReduit(context);
    _mesure = true;
    final int? zoneAvant = _zoneDe(_ancien);
    final int? zoneApres = _zoneDe(i);
    _ancien = i;
    // LIQUIDE-MATIERE : d'une zone a l'autre (la pilule, le cercle), aucune
    // goutte de couleur ne voyage : la goutte saute a sa place, et c'est la
    // matiere qui fait le pont.
    if (!sauter &&
        widget.matiere != null &&
        zoneAvant != null &&
        zoneApres != null &&
        zoneAvant != zoneApres) {
      _gauche.value = cible.left;
      _droite.value = cible.right;
      _haut.value = cible.top;
      _bas.value = cible.bottom;
      _de = zoneAvant;
      _vers = zoneApres;
      _recu = false;
      _fondu.value = 0;
      _pont
        ..value = 0
        ..animateWith(SpringSimulation(AppMouvement.ressortPont, 0, 1, 0));
      setState(() {
        _enMouvement = false;
        _pontActif = true;
      });
      return;
    }
    // Un saut, ou une goutte dans la pilule, arrete un pont en cours.
    final bool pontEnCours = _pontActif;
    if (pontEnCours) _pont.stop();
    _fondu.value = 1;
    if (sauter) {
      _gauche.value = cible.left;
      _droite.value = cible.right;
      _haut.value = cible.top;
      _bas.value = cible.bottom;
      // Un saut arrete une goutte en vol : elle disparait aussitot.
      if (_enMouvement || pontEnCours) {
        setState(() {
          _enMouvement = false;
          _pontActif = false;
        });
      }
      return;
    }
    if (pontEnCours) _pontActif = false;
    // Le bord de devant, plus raide, part le premier ; celui de derriere
    // suit : la goutte s'etire dans le sens du mouvement, puis se reforme.
    final bool versLaDroite =
        cible.center.dx > (_gauche.value + _droite.value) / 2;
    final bool lance =
        _lancer(
          _droite,
          cible.right,
          versLaDroite
              ? AppMouvement.ressortGoutteTete
              : AppMouvement.ressortGoutteQueue,
        ) |
        _lancer(
          _gauche,
          cible.left,
          versLaDroite
              ? AppMouvement.ressortGoutteQueue
              : AppMouvement.ressortGoutteTete,
        ) |
        _lancer(_haut, cible.top, AppMouvement.ressortGoutteTete) |
        _lancer(_bas, cible.bottom, AppMouvement.ressortGoutteTete);
    // Rien a deplacer : pas de goutte (aucune fin ne viendrait l'eteindre).
    if (lance) setState(() => _enMouvement = true);
  }

  static bool _lancer(
    AnimationController c,
    double cible,
    SpringDescription ressort,
  ) {
    if (c.value == cible) return false;
    c.animateWith(SpringSimulation(ressort, c.value, cible, c.velocity));
    return true;
  }

  @override
  void dispose() {
    for (final AnimationController c in <AnimationController>[
      _gauche,
      _droite,
      _haut,
      _bas,
      _pont,
      _reception,
      _fondu,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// La goutte dans le repere de l'indicateur, ou `null` au repos.
  Rect? get goutte => _enMouvement
      ? Rect.fromLTRB(
          math.min(_gauche.value, _droite.value),
          math.min(_haut.value, _bas.value),
          math.max(_gauche.value, _droite.value),
          math.max(_haut.value, _bas.value),
        )
      : null;

  @override
  Widget build(BuildContext context) => _PorteeLiquide(
    etat: this,
    enMouvement: _enMouvement,
    // Deux frontieres de repeint : la goutte se repeint seule a chaque image,
    // sans entrainer la page au-dessus ni les onglets au-dessous (mesure
    // CanvasKit du 11/11/2026).
    child: RepaintBoundary(
      child: CustomPaint(
        // La couche du dessous : le pont entre les zones, et la goutte hors
        // des zones opaques (le cercle la recouvre presque toute).
        painter: _PeintreLiquide(etat: this, repaint: _toutPont),
        child: RepaintBoundary(child: widget.child),
      ),
    ),
  );
}

class _PorteeLiquide extends InheritedWidget {
  const _PorteeLiquide({
    required this.etat,
    required this.enMouvement,
    required super.child,
  });

  final _EtatIndicateurLiquide etat;
  final bool enMouvement;

  @override
  bool updateShouldNotify(_PorteeLiquide ancien) =>
      ancien.enMouvement != enMouvement || ancien.etat != etat;
}

/// La couche de la goutte a l'interieur d'une zone opaque (la pilule) : posee
/// entre son fond et son contenu, elle y dessine la part de la goutte.
class CoucheLiquide extends StatelessWidget {
  /// Cree la couche.
  const CoucheLiquide({required this.child, super.key});

  /// Le contenu de la zone (les onglets).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeLiquide? portee = context
        .dependOnInheritedWidgetOfExactType<_PorteeLiquide>();
    if (portee == null) return child;
    return CustomPaint(
      painter: _PeintreInterieur(
        etat: portee.etat,
        repaint: portee.etat._tout,
        couleur: portee.etat.widget.couleur,
        moi: context,
      ),
      // Les onglets ne se repeignent pas a chaque image de la goutte.
      child: RepaintBoundary(child: child),
    );
  }
}

/// Le cercle (ou toute zone) qui recoit la goutte de matiere d'un leger
/// rebond (LIQUIDE-MATIERE, directeur, 11/11/2026). Pose autour de la zone,
/// sous un [IndicateurLiquide] ; ailleurs, l'enfant tel quel.
class ReceptionLiquide extends StatelessWidget {
  /// Cree la reception.
  const ReceptionLiquide({required this.child, super.key});

  /// La zone qui recoit (le cercle Compte).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeLiquide? portee = context
        .dependOnInheritedWidgetOfExactType<_PorteeLiquide>();
    if (portee == null) return child;
    final AnimationController reception = portee.etat._reception;
    return AnimatedBuilder(
      animation: reception,
      child: child,
      builder: (BuildContext _, Widget? enfant) => Transform.scale(
        scale:
            1 +
            AppMouvement.amplitudeReception *
                reception.value.clamp(-1, 1).toDouble(),
        child: enfant,
      ),
    );
  }
}

/// La couche du dessous : le pont de matiere entre la pilule et le cercle
/// (LIQUIDE-MATIERE). Il se peint SOUS les zones : seule sa part entre elles
/// se voit, de leur fond, sous leur ombre, bordee de leur contour.
class _PeintreLiquide extends CustomPainter {
  _PeintreLiquide({required this.etat, required Listenable repaint})
    : super(repaint: repaint);

  final _EtatIndicateurLiquide etat;

  /// Le disque d'une zone, du cote de l'autre : le bout arrondi de la
  /// pilule, ou le cercle lui-meme.
  static ({Offset c, double r}) _disque(Rect zone, Rect autre) {
    final double r = zone.shortestSide / 2;
    if (zone.width <= zone.height + 1) return (c: zone.center, r: r);
    final bool versLaDroite = autre.center.dx > zone.center.dx;
    return (
      c: Offset(versLaDroite ? zone.right - r : zone.left + r, zone.center.dy),
      r: r,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color? matiere = etat.widget.matiere;
    final List<Rect> z = etat.zones;
    if (!etat._pontActif ||
        matiere == null ||
        etat._de >= z.length ||
        etat._vers >= z.length) {
      return;
    }
    final double e = etat._pont.value.clamp(0, 1).toDouble();
    if (e <= 0 || e >= 1) return;
    final ({Offset c, double r}) s = _disque(z[etat._de], z[etat._vers]);
    final ({Offset c, double r}) t = _disque(z[etat._vers], z[etat._de]);
    // La goutte voyage d'un disque a l'autre, plus petite qu'eux.
    final Offset cb = Offset.lerp(s.c, t.c, e)!;
    // Assez grosse pour que le pont remplisse l'espace entre les deux
    // silhouettes (8 points) : c'est le corps de la pilule qui s'etire.
    final double rb = (s.r + (t.r - s.r) * e) * 0.8;
    Path forme = Path()..addOval(Rect.fromCircle(center: cb, radius: rb));
    // Le corps de la source s'etire, s'amincit, puis se rompt.
    if (e < _EtatIndicateurLiquide._rupture) {
      final double v = 0.6 * (1 - e / _EtatIndicateurLiquide._rupture);
      forme = Path.combine(
        PathOperation.union,
        forme,
        pontMetaballe(s.c, s.r, cb, rb, v: v, portee: 6),
      );
    }
    // La destination l'aspire en fin de course.
    if (e > 1 - _EtatIndicateurLiquide._rupture) {
      final double v =
          0.6 *
          (e - (1 - _EtatIndicateurLiquide._rupture)) /
          _EtatIndicateurLiquide._rupture;
      forme = Path.combine(
        PathOperation.union,
        forme,
        pontMetaballe(cb, rb, t.c, t.r, v: v, portee: 6),
      );
    }
    for (final BoxShadow o in etat.widget.ombres) {
      canvas.drawPath(
        forme.shift(o.offset),
        Paint()
          ..color = o.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, o.blurSigma),
      );
    }
    canvas.drawPath(forme, Paint()..color = matiere);
    final BorderSide? bord = etat.widget.contour;
    if (bord != null && bord.style != BorderStyle.none) {
      canvas.drawPath(
        forme,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bord.width
          ..color = bord.color,
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreLiquide ancien) => true;
}

class _PeintreInterieur extends CustomPainter {
  _PeintreInterieur({
    required this.etat,
    required this.couleur,
    required this.moi,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _EtatIndicateurLiquide etat;
  final Color couleur;
  final BuildContext moi;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? g = etat.goutte;
    final RenderObject? ici = moi.findRenderObject();
    final RenderObject? racine = etat.context.findRenderObject();
    if (g == null || ici is! RenderBox || racine is! RenderBox) return;
    // La goutte, ramenee dans le repere de cette couche, coupee a ses bords.
    final Matrix4 versIci = racine.getTransformTo(ici);
    final Rect locale = MatrixUtils.transformRect(versIci, g);
    final Rect zone = Offset.zero & size;
    if (!locale.overlaps(zone)) return;
    canvas.drawRRect(_rond(locale.intersect(zone)), Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintreInterieur ancien) => ancien.couleur != couleur;
}

RRect _rond(Rect r) =>
    RRect.fromRectAndRadius(r, Radius.circular(r.shortestSide / 2));

/// Le pont metaballe entre deux disques ([c1], [r1]) et ([c2], [r2]) : une
/// forme molle qui les relie, s'amincit quand ils s'eloignent et se rompt
/// au-dela de [portee] fois la somme des rayons. Vide s'ils sont trop loin ou
/// l'un dans l'autre.
Path pontMetaballe(
  Offset c1,
  double r1,
  Offset c2,
  double r2, {
  double v = 0.5,
  double poignee = 2.4,
  double portee = 2.5,
}) {
  final Path chemin = Path();
  final double d = (c2 - c1).distance;
  if (r1 <= 0 || r2 <= 0 || d > portee * (r1 + r2) || d <= (r1 - r2).abs()) {
    return chemin;
  }
  double u1 = 0;
  double u2 = 0;
  if (d < r1 + r2) {
    u1 = math.acos(((r1 * r1 + d * d - r2 * r2) / (2 * r1 * d)).clamp(-1, 1));
    u2 = math.acos(((r2 * r2 + d * d - r1 * r1) / (2 * r2 * d)).clamp(-1, 1));
  }
  final double entre = math.atan2(c2.dy - c1.dy, c2.dx - c1.dx);
  final double ouverture = math.acos(((r1 - r2) / d).clamp(-1, 1));
  final double a1 = entre + u1 + (ouverture - u1) * v;
  final double a2 = entre - u1 - (ouverture - u1) * v;
  final double a3 = entre + math.pi - u2 - (math.pi - u2 - ouverture) * v;
  final double a4 = entre - math.pi + u2 + (math.pi - u2 - ouverture) * v;
  Offset polaire(Offset c, double a, double r) =>
      c + Offset(math.cos(a) * r, math.sin(a) * r);
  final Offset p1 = polaire(c1, a1, r1);
  final Offset p2 = polaire(c1, a2, r1);
  final Offset p3 = polaire(c2, a3, r2);
  final Offset p4 = polaire(c2, a4, r2);
  final double base = math.min(v * poignee, (p1 - p3).distance / (r1 + r2));
  final double t = base * math.min(1, d * 2 / (r1 + r2));
  final Offset h1 = polaire(p1, a1 - math.pi / 2, r1 * t);
  final Offset h2 = polaire(p2, a2 + math.pi / 2, r1 * t);
  final Offset h3 = polaire(p3, a3 + math.pi / 2, r2 * t);
  final Offset h4 = polaire(p4, a4 - math.pi / 2, r2 * t);
  return chemin
    ..moveTo(p1.dx, p1.dy)
    ..cubicTo(h1.dx, h1.dy, h3.dx, h3.dy, p3.dx, p3.dy)
    ..lineTo(p4.dx, p4.dy)
    ..cubicTo(h4.dx, h4.dy, h2.dx, h2.dy, p2.dx, p2.dy)
    ..close();
}
