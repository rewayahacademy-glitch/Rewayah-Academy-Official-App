// L'effet liquide de la navigation (decisions du directeur du 10/11/2026,
// relayees par le garde-cap) : quand on change d'onglet dans la pilule, le
// fond de l'onglet ouvert est une goutte molle qui se deplace au ressort,
// s'etire dans le sens du mouvement puis se reforme.
//
// LIQUIDE-MATIERE (corrections du directeur du 11/11/2026) : la pilule et
// le cercle Compte sont deux morceaux de la meme matiere (meme fond, meme
// ombre, aucun contour). D'une zone a l'autre, le cercle est TIRE hors de la
// pilule, comme une goutte d'huile qui se detache de l'ile principale : il
// s'approche, s'y fond (une seule forme), puis s'eloigne ; un cou concave
// (le contour de l'union, deux arcs de Bezier tangents aux deux silhouettes)
// s'amincit avec la distance, puis se rompt d'un coup ; les deux bords
// reprennent leur forme d'un petit rebond. Au retour vers un onglet, le
// cercle s'approche, un cou se forme et il est absorbe : la pilule le recoit
// d'un rebond. La couleur de selection n'entre jamais dans le cou : elle ne
// change que sur la destination, en fondu.
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
/// pilule, le cercle) ; d'une zone a l'autre, le cercle se detache de la
/// pilule par un cou de matiere. [child] : la rangee ; la couche interieure
/// de chaque zone opaque se pose avec [CoucheLiquide], le cercle dans
/// [ReceptionLiquide], la pilule dans [BordLiquide].
class IndicateurLiquide extends StatefulWidget {
  /// Cree l'indicateur.
  const IndicateurLiquide({
    required this.cibles,
    required this.zones,
    required this.indexActif,
    required this.couleur,
    required this.child,
    this.matiere,
    this.ombres = const <BoxShadow>[],
    this.rapportDisque = 1,
    super.key,
  });

  /// La matiere des zones (le fond de la pilule et du cercle) : celle du cou
  /// qui les relie. Nulle : aucun cou, la destination change seule.
  final Color? matiere;

  /// L'ombre des zones, reprise sous le cou.
  final List<BoxShadow> ombres;

  /// Le disque d'une zone ronde (le cercle) rapporte a sa boite : le rond de
  /// repos est plus petit que la place reservee (58 dans 64).
  final double rapportDisque;

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

  /// Le detachement en cours au-dessus de [context], ou `null` sans
  /// detachement (tests) : l'ecart entre les deux silhouettes (negatif
  /// quand elles se fondent) et l'epaisseur du cou (0 a 0,5 ; nulle quand il
  /// n'y a pas, ou plus, de cou).
  @visibleForTesting
  static ({double ecart, double cou})? detachementDe(BuildContext context) {
    final _EtatIndicateurLiquide? etat = context
        .getInheritedWidgetOfExactType<_PorteeLiquide>()
        ?.etat;
    if (etat == null || !etat._pontActif) return null;
    final _Disques? d = etat._disques();
    if (d == null) return null;
    return (ecart: d.ecart, cou: etat._cou(d.ecart));
  }

  /// Le fondu de la couleur de selection sur la destination, au-dessus de
  /// [context] : 0 tant que le cou n'est pas rompu (ou le cercle absorbe),
  /// puis 1. Nul hors d'un indicateur.
  static Animation<double>? fonduDestination(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PorteeLiquide>()?.etat._fondu;

  @override
  State<IndicateurLiquide> createState() => _EtatIndicateurLiquide();
}

/// Les deux silhouettes du detachement : le bout arrondi de la pilule et le
/// disque du cercle, dans le repere de l'indicateur.
typedef _Disques = ({
  Offset cPilule,
  double rPilule,
  Offset cCercle,
  double rCercle,
  double ecart,
});

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
  // LIQUIDE-MATIERE : le decalage du cercle vers la pilule (en points), le
  // rebond du cercle (autour de 0), celui du bout de la pilule (autour de 0)
  // et le fondu de la couleur sur la destination.
  late final AnimationController _decalage = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _reception = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _bordPilule = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _fondu = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMouvement.apparition,
  );
  late final Listenable _toutPont = Listenable.merge(<Listenable>[
    _decalage,
    _reception,
    _bordPilule,
  ]);
  bool _mesure = false;
  bool _enMouvement = false;
  bool _pontActif = false;
  int? _ancien;

  // Le detachement en cours.
  bool _sortie = true;
  bool _lache = false;
  bool _rompu = false;
  int _pilule = 0;
  int _cercle = 1;
  double _ecartRepos = 0;
  double _cible = 0;

  /// Le sens, en x, du cercle vers la pilule (-1 : la pilule est a gauche).
  double _versPilule = -1;

  /// De combien le cercle entre dans la pilule : il en sort (vers le
  /// Compte), ou il y est absorbe (vers un onglet), plus profond.
  static const double _fusionSortie = 10;
  static const double _fusionAbsorption = 16;

  /// L'epaisseur du cou quand les deux silhouettes se touchent.
  static const double _couPlein = 0.5;

  /// Le cou le plus fin avant la rupture.
  static const double _couFin = 0.04;

  /// Au-dela de l'ecart de repos, de combien le cou s'etire avant de rompre.
  static const double _etirement = 1.5;

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
    _decalage
      ..addListener(_suivre)
      ..addStatusListener(_finDetachement);
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

  /// Les deux silhouettes du detachement, mesurees sur la mise en page (le
  /// decalage et le rebond du cercle compris).
  _Disques? _disques() {
    final List<Rect> z = zones;
    if (_pilule >= z.length || _cercle >= z.length) return null;
    final Rect p = z[_pilule];
    final Rect c = z[_cercle];
    final double rC = c.shortestSide / 2 * widget.rapportDisque;
    final double rP = p.shortestSide / 2;
    // Le bout arrondi de la pilule, du cote du cercle.
    final bool cercleADroite = c.center.dx > p.center.dx;
    final Offset cP = p.width <= p.height + 1
        ? p.center
        : Offset(cercleADroite ? p.right - rP : p.left + rP, p.center.dy);
    final Offset cC = c.center;
    return (
      cPilule: cP,
      rPilule: rP,
      cCercle: cC,
      rCercle: rC,
      ecart: (cC - cP).distance - rP - rC,
    );
  }

  /// L'epaisseur du cou pour un [ecart] entre les silhouettes : pleine quand
  /// elles se fondent, de plus en plus fine quand elles s'eloignent, nulle
  /// une fois rompu. A l'approche, il se forme avant le contact.
  double _cou(double ecart) {
    if (!_pontActif || _rompu) return 0;
    if (ecart <= 0) return _couPlein;
    if (!_lache) {
      final double attraction = _ecartRepos * 0.75;
      if (attraction <= 0 || ecart >= attraction) return 0;
      return _couPlein * (1 - ecart / attraction);
    }
    final double rupture = _ecartRepos + _etirement;
    if (ecart >= rupture) return 0;
    return math.max(
      _couFin,
      _couPlein * math.pow(1 - ecart / rupture, 0.8).toDouble(),
    );
  }

  void _suivre() {
    if (!_pontActif) return;
    if (!_lache && _decalage.value >= _cible - 0.5) {
      // Fondus : une seule forme. Le cercle est maintenant tire hors de la
      // pilule (ou rendu, apres son absorption), au ressort qui rebondit.
      _lache = true;
      if (!_sortie) {
        // Absorbe : la pilule le recoit d'un rebond, et la couleur gagne
        // l'onglet.
        _rebondir(_bordPilule);
        _fondu.forward(from: 0);
      }
      _decalage.animateWith(
        SpringSimulation(
          AppMouvement.ressortDetachement,
          _decalage.value,
          0,
          _decalage.velocity,
        ),
      );
      return;
    }
    if (_lache && !_rompu) {
      final _Disques? d = _disques();
      final bool auPlusLoin = _decalage.value < 0 && _decalage.velocity >= 0;
      if (d == null || d.ecart >= _ecartRepos + _etirement || auPlusLoin) {
        // Le cou se rompt d'un coup : les deux bords reprennent leur forme
        // d'un petit rebond.
        _rompu = true;
        _rebondir(_reception);
        if (_sortie) {
          _rebondir(_bordPilule);
          _fondu.forward(from: 0);
        }
      }
    }
  }

  void _rebondir(AnimationController c) => c.animateWith(
    SpringSimulation(
      AppMouvement.ressortReception,
      0,
      0,
      AppMouvement.elanReception,
    ),
  );

  void _finDetachement(AnimationStatus statut) {
    if (statut != AnimationStatus.completed &&
        statut != AnimationStatus.dismissed) {
      return;
    }
    if (_lache && !_decalage.isAnimating && _pontActif && mounted) {
      if (_fondu.value == 0 && !_fondu.isAnimating) _fondu.value = 1;
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

  /// Vrai si la zone [k] est ronde (le cercle).
  bool _ronde(int k) {
    final List<Rect> z = zones;
    return k < z.length && z[k].width <= z[k].height + 1;
  }

  /// Lance le detachement de la zone [de] vers la zone [vers] ; faux si ces
  /// zones ne sont pas une pilule et un cercle.
  bool _detacher(int de, int vers) {
    if (_ronde(de) == _ronde(vers)) return false;
    _sortie = _ronde(vers);
    _cercle = _sortie ? vers : de;
    _pilule = _sortie ? de : vers;
    if (!_pontActif) {
      // L'ecart de repos se mesure cercle a sa place.
      _decalage.value = 0;
      final _Disques? d = _disques();
      if (d == null) return false;
      _ecartRepos = d.ecart;
      _versPilule = d.cPilule.dx < d.cCercle.dx ? -1 : 1;
    }
    _lache = false;
    _rompu = false;
    _cible = _ecartRepos + (_sortie ? _fusionSortie : _fusionAbsorption);
    _fondu.value = 0;
    _decalage.animateWith(
      SpringSimulation(
        AppMouvement.ressortApproche,
        _decalage.value,
        _cible,
        _decalage.velocity,
      ),
    );
    setState(() {
      _enMouvement = false;
      _pontActif = true;
    });
    return true;
  }

  void _arreterDetachement() {
    _decalage
      ..stop()
      ..value = 0;
    _pontActif = false;
    _fondu.value = 1;
  }

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
    // goutte de couleur ne voyage : la goutte saute a sa place, et c'est le
    // cercle qui se detache de la pilule (ou y est absorbe).
    if (!sauter &&
        widget.matiere != null &&
        zoneAvant != null &&
        zoneApres != null &&
        zoneAvant != zoneApres) {
      _gauche.value = cible.left;
      _droite.value = cible.right;
      _haut.value = cible.top;
      _bas.value = cible.bottom;
      if (_detacher(zoneAvant, zoneApres)) return;
    }
    // Un saut, ou une goutte dans la pilule, arrete un detachement en cours.
    final bool pontEnCours = _pontActif;
    if (pontEnCours) _arreterDetachement();
    _fondu.value = 1;
    if (sauter) {
      _gauche.value = cible.left;
      _droite.value = cible.right;
      _haut.value = cible.top;
      _bas.value = cible.bottom;
      // Un saut arrete une goutte en vol : elle disparait aussitot.
      if (_enMouvement || pontEnCours) {
        setState(() => _enMouvement = false);
      }
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
    if (lance || pontEnCours) setState(() => _enMouvement = lance);
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
      _decalage,
      _reception,
      _bordPilule,
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
        // La couche du dessous : le cou de matiere entre les zones.
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

/// Le cercle (ou toute zone ronde) qui se detache de la pilule : il s'en
/// approche, s'y fond, puis en est tire, et reprend sa forme d'un petit
/// rebond (LIQUIDE-MATIERE, directeur, 11/11/2026). Pose autour de la zone,
/// sous un [IndicateurLiquide] ; ailleurs, l'enfant tel quel.
class ReceptionLiquide extends StatelessWidget {
  /// Cree la reception.
  const ReceptionLiquide({required this.child, super.key});

  /// La zone qui se detache (le cercle Compte).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeLiquide? portee = context
        .dependOnInheritedWidgetOfExactType<_PorteeLiquide>();
    if (portee == null) return child;
    final _EtatIndicateurLiquide etat = portee.etat;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        etat._reception,
        etat._decalage,
      ]),
      child: child,
      builder: (BuildContext _, Widget? enfant) => Transform.translate(
        offset: Offset(
          etat._pontActif ? etat._versPilule * etat._decalage.value : 0,
          0,
        ),
        child: Transform.scale(
          scale:
              1 +
              AppMouvement.amplitudeReception *
                  etat._reception.value.clamp(-1, 1).toDouble(),
          child: enfant,
        ),
      ),
    );
  }
}

/// La pilule dont le cercle se detache : son bout, du cote du cercle,
/// reprend sa forme d'un petit rebond (LIQUIDE-MATIERE). Pose autour de la
/// zone, sous un [IndicateurLiquide] ; ailleurs, l'enfant tel quel.
class BordLiquide extends StatelessWidget {
  /// Cree le bord.
  const BordLiquide({required this.child, super.key});

  /// La zone (la pilule).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeLiquide? portee = context
        .dependOnInheritedWidgetOfExactType<_PorteeLiquide>();
    if (portee == null) return child;
    final _EtatIndicateurLiquide etat = portee.etat;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => AnimatedBuilder(
        animation: etat._bordPilule,
        child: child,
        builder: (BuildContext _, Widget? enfant) {
          final double v = etat._bordPilule.value.clamp(-1, 1).toDouble();
          if (v == 0 || !c.hasBoundedWidth || c.maxWidth <= 0) return enfant!;
          // Le bout du cote du cercle bouge ; l'autre reste fixe.
          return Transform(
            // Le cercle est au bout de la rangee (a droite, a gauche en
            // arabe) : le debut de la pilule reste fixe.
            alignment: AlignmentDirectional.centerStart,
            transform: Matrix4.diagonal3Values(
              1 + AppMouvement.amplitudeBordPilule * v / c.maxWidth,
              1,
              1,
            ),
            child: enfant,
          );
        },
      ),
    );
  }
}

/// La couche du dessous : le cou de matiere entre la pilule et le cercle
/// (LIQUIDE-MATIERE). Il se peint SOUS les zones : seule sa part entre elles
/// se voit, de leur fond, sous leur ombre. Avec elles, il forme une seule
/// silhouette continue : deux arcs de Bezier tangents aux deux silhouettes.
class _PeintreLiquide extends CustomPainter {
  _PeintreLiquide({required this.etat, required Listenable repaint})
    : super(repaint: repaint);

  final _EtatIndicateurLiquide etat;

  @override
  void paint(Canvas canvas, Size size) {
    final Color? matiere = etat.widget.matiere;
    if (!etat._pontActif || matiere == null) return;
    final _Disques? d = etat._disques();
    if (d == null) return;
    final double v = etat._cou(d.ecart);
    if (v <= 0) return;
    final Path cou = pontMetaballe(
      d.cPilule,
      d.rPilule,
      d.cCercle,
      d.rCercle,
      v: v,
      portee: 4,
    );
    for (final BoxShadow o in etat.widget.ombres) {
      canvas.drawPath(
        cou.shift(o.offset),
        Paint()
          ..color = o.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, o.blurSigma),
      );
    }
    canvas.drawPath(cou, Paint()..color = matiere);
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
