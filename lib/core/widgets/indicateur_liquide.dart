// L'effet liquide de la navigation (decisions du directeur du 10/11/2026,
// relayees par le garde-cap) : quand on change de destination, le fond de
// l'onglet ouvert est une goutte molle qui se deplace au ressort, s'etire
// dans le sens du mouvement puis se reforme ; de la pilule au cercle Compte
// et retour, un pont elastique (metaballe) relie les deux puis se detache.
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
    super.key,
  });

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
  bool _mesure = false;
  bool _enMouvement = false;

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
    if (sauter) {
      _gauche.value = cible.left;
      _droite.value = cible.right;
      _haut.value = cible.top;
      _bas.value = cible.bottom;
      // Un saut arrete une goutte en vol : elle disparait aussitot.
      if (_enMouvement) setState(() => _enMouvement = false);
      return;
    }
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
        painter: _PeintreLiquide(
          etat: this,
          repaint: _tout,
          couleur: widget.couleur,
        ),
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

/// La couche du dessous : le pont metaballe entre les parts de la goutte qui
/// tombent dans deux zones, et la part qui tombe dans une zone sans couche
/// interieure (le cercle, opaque, la recouvre presque toute).
class _PeintreLiquide extends CustomPainter {
  _PeintreLiquide({
    required this.etat,
    required this.couleur,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _EtatIndicateurLiquide etat;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? g = etat.goutte;
    if (g == null) return;
    final Paint pinceau = Paint()..color = couleur;
    final List<Rect> parts = <Rect>[
      for (final Rect z in etat.zones)
        if (g.overlaps(z)) g.intersect(z),
    ];
    for (final Rect p in parts) {
      canvas.drawRRect(_rond(p), pinceau);
    }
    if (parts.length == 2) {
      final Rect a = parts[0].center.dx <= parts[1].center.dx
          ? parts[0]
          : parts[1];
      final Rect b = identical(a, parts[0]) ? parts[1] : parts[0];
      final double ra = a.shortestSide / 2;
      final double rb = b.shortestSide / 2;
      final Path pont = pontMetaballe(
        Offset(a.right - ra, a.center.dy),
        ra,
        Offset(b.left + rb, b.center.dy),
        rb,
      );
      canvas.drawPath(pont, pinceau);
    }
  }

  @override
  bool shouldRepaint(_PeintreLiquide ancien) => ancien.couleur != couleur;
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
