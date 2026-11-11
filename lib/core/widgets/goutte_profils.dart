// GOUTTE D'HUILE DES PROFILS (directeur, 11/11/2026, relayee par le
// garde-cap) : entre deux profils, et entre un profil et son contenu.
//
// 1. D'un profil a l'autre : le rond de depart s'etire vers le rond choisi. Un
//    cou concave (le meme calcul que la barre, `pontMetaballe`) relie les deux
//    silhouettes, s'amincit et se rompt pres du rond choisi, qui recoit la
//    goutte d'un leger rebond et prend la selection (la couleur d'accent). Le
//    detachement se fait toujours depuis le profil d'ou l'on part : dans les
//    deux sens, et en miroir en arabe (les positions sont mesurees sur la
//    mise en page).
// 2. Entre le profil et son contenu : une goutte tombe du rond choisi et
//    s'etale en devenant la carte de contenu (un cou entre le rond et le bord
//    haut du contenu, puis rupture). Au changement de profil, l'ancien contenu
//    est d'abord aspire vers son rond, puis le nouveau tombe du nouveau rond.
//
// Regles : « reduire les animations » = changement immediat, sans goutte ;
// aucun retard au toucher (la selection est prise tout de suite, c'est
// l'animation qui suit) ; une seule goutte a la fois ; durees et courbes dans
// `AppMouvement` ; meme matiere que les ronds, sans contour.
//
// Un composant du core : `GoutteProfils` pose la portee ; les ronds se
// declarent par [RondGoutte] ; le contenu par [ContenuGoutte]. Hors d'une
// portee, rien ne change (l'Historique garde son selecteur tel quel).
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';
import 'liaison_liquide.dart';

/// La portee de la goutte : au-dessus du selecteur de profils et de son
/// contenu. Elle mesure les ronds, peint les cous sous eux, et commande le
/// fondu de la couleur de selection du rond choisi.
class GoutteProfils extends StatefulWidget {
  /// Cree la portee.
  const GoutteProfils({
    required this.selectionId,
    required this.matiere,
    required this.matiereContenu,
    required this.rayonContenu,
    required this.child,
    super.key,
  });

  /// Le profil choisi. Il change au toucher : la selection est prise tout de
  /// suite, la goutte suit.
  final String? selectionId;

  /// La matiere de la goutte entre les ronds : la couleur de la selection (le
  /// bord d'accent des ronds).
  final Color matiere;

  /// La matiere du contenu : la couleur de ses cartes. Le cou entre le rond et
  /// le contenu va de [matiere] a celle-ci.
  final Color matiereContenu;

  /// Le rayon des coins du contenu.
  final double rayonContenu;

  /// Le selecteur et son contenu.
  final Widget child;

  static _PorteeGoutte? _portee(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PorteeGoutte>();

  /// Le fondu de la couleur de selection du rond [id], ou `null` hors
  /// goutte (le rond suit alors sa seule taille) : constant a 1 pour le rond
  /// qu'on quitte (sa couleur suit sa taille), de 0 a 1 pour le rond choisi
  /// (la couleur arrive a la rupture du cou).
  static Animation<double>? fonduRond(BuildContext context, String id) {
    final _PorteeGoutte? p = _portee(context);
    if (p == null || !p.actif) return null;
    if (id == p.de) return kAlwaysCompleteAnimation;
    if (id == p.vers) return p.etat._fondu;
    return null;
  }

  /// La goutte en cours au-dessus de [context], ou `null` au repos (tests) :
  /// l'avancement, et si le cou est rompu.
  @visibleForTesting
  static ({double avancement, bool rompu, String de, String vers})? goutteDe(
    BuildContext context,
  ) {
    final _EtatGoutteProfils? e = context
        .getInheritedWidgetOfExactType<_PorteeGoutte>()
        ?.etat;
    if (e == null || !e._actif) return null;
    return (
      avancement: e._p.value,
      rompu: e._rompu,
      de: e._de!,
      vers: e._vers!,
    );
  }

  /// La chute ou l'aspiration du contenu en cours au-dessus de [context], ou
  /// `null` au repos (tests) : l'avancement de 0 a 1, et si c'est une
  /// aspiration.
  @visibleForTesting
  static ({double avancement, bool aspiration})? chuteDe(BuildContext context) {
    final _EtatGoutteProfils? e = context
        .getInheritedWidgetOfExactType<_PorteeGoutte>()
        ?.etat;
    final _ChuteEnCours? c = e?._chute;
    if (c == null) return null;
    return (avancement: c.valeur(), aspiration: c.aspiration);
  }

  @override
  State<GoutteProfils> createState() => _EtatGoutteProfils();
}

/// Le contenu qui tombe ou est aspire, vu par la portee pour peindre son cou.
class _ChuteEnCours {
  _ChuteEnCours({
    required this.valeur,
    required this.aspiration,
    required this.idRond,
    required this.cleContenu,
    required this.ancre,
    required this.echelle,
  });

  /// L'avancement, de 0 a 1.
  final double Function() valeur;
  final bool aspiration;

  /// Le rond d'ou le contenu tombe, ou vers lequel il est aspire.
  final String idRond;
  final GlobalKey cleContenu;

  /// Le point du bord haut du contenu qui reste fixe (repere de la portee).
  final Offset Function() ancre;

  /// L'echelle courante du contenu.
  final double Function() echelle;
}

class _EtatGoutteProfils extends State<GoutteProfils>
    with TickerProviderStateMixin {
  final Map<String, GlobalKey> _cles = <String, GlobalKey>{};
  final Map<String, double> _rapports = <String, double>{};

  // 0 a 1 : la goutte du rond quitte vers le rond choisi. Sans borne.
  late final AnimationController _p = AnimationController.unbounded(
    vsync: this,
  );
  // Le fondu de la couleur de selection sur le rond choisi.
  late final AnimationController _fondu = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMouvement.apparition,
  );
  // Les rebonds des deux ronds a la rupture (autour de 0).
  late final AnimationController _rebondQuitte = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _rebondChoisi = AnimationController.unbounded(
    vsync: this,
  );
  // Ticks de la chute du contenu : repeint seulement.
  final _Tic _tick = _Tic();

  late final Listenable _tout = Listenable.merge(<Listenable>[_p, _tick]);

  /// Vrai tant que le cou entre deux ronds n'est pas rompu : le contenu
  /// n'engage pas sa chute avant (une seule goutte a la fois).
  final ValueNotifier<bool> occupe = ValueNotifier<bool>(false);

  bool _actif = false;
  bool _rompu = false;
  bool _arrive = false;
  String? _de;
  String? _vers;
  _ChuteEnCours? _chute;

  GlobalKey cle(String id) => _cles.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _p.addStatusListener(_statut);
    _p.addListener(_suivre);
  }

  @override
  void didUpdateWidget(GoutteProfils ancien) {
    super.didUpdateWidget(ancien);
    final String? de = ancien.selectionId;
    final String? vers = widget.selectionId;
    if (de == null || vers == null || de == vers) return;
    if (AppMouvement.mouvementReduit(context)) {
      _finir();
      return;
    }
    // Occupe des maintenant : le contenu, qui decide dans la meme image,
    // attend la rupture du cou. Les ronds ne sont mesurables qu'apres la mise
    // en page de la selection.
    occupe.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _lancer(de, vers));
  }

  void _lancer(String de, String vers) {
    if (!mounted) return;
    // Une seule goutte : la precedente s'acheve sur-le-champ.
    if (_actif) _finir();
    occupe.value = true;
    if (_disque(de) == null || _disque(vers) == null) {
      // Un rond hors ecran : pas de cou, le contenu peut commencer.
      occupe.value = false;
      return;
    }
    _de = de;
    _vers = vers;
    _rompu = false;
    _arrive = false;
    _fondu.value = 0;
    _p.value = 0;
    occupe.value = true;
    setState(() => _actif = true);
    _p.animateWith(SpringSimulation(AppMouvement.ressortGouttePro, 0, 1, 0));
  }

  void _suivre() {
    if (!_actif) return;
    final double p = _p.value;
    if (!_arrive && p >= AppMouvement.arriveeGouttePro) _arrive = true;
    if (!_rompu && p >= AppMouvement.ruptureGouttePro) {
      // Le cou se rompt : les deux ronds reprennent leur forme d'un petit
      // rebond, et le rond choisi prend la selection.
      _rompu = true;
      occupe.value = false;
      _rebondir(_rebondQuitte);
      _rebondir(_rebondChoisi);
      _fondu.forward(from: 0);
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

  void _statut(AnimationStatus statut) {
    if (statut != AnimationStatus.completed &&
        statut != AnimationStatus.dismissed) {
      return;
    }
    if (_actif && !_p.isAnimating && _p.value >= 0.99) _finir();
  }

  /// Termine la goutte : plus de cou, la selection est celle du rond choisi.
  void _finir() {
    _p.stop();
    _fondu.value = 1;
    occupe.value = false;
    if (_actif && mounted) setState(() => _actif = false);
    _actif = false;
  }

  /// Le disque d'un rond dans le repere de la portee, ou `null` s'il n'est pas
  /// mesurable (hors ecran, pas construit).
  ({Offset centre, double rayon})? _disque(String? id) {
    if (id == null) return null;
    final RenderObject? moi = context.findRenderObject();
    final RenderObject? lui = _cles[id]?.currentContext?.findRenderObject();
    if (moi is! RenderBox || lui is! RenderBox || !lui.hasSize) return null;
    final Rect r = MatrixUtils.transformRect(
      lui.getTransformTo(moi),
      Offset.zero & lui.size,
    );
    final double rapport = _rapports[id] ?? 1;
    return (centre: r.center, rayon: r.shortestSide / 2 * rapport);
  }

  /// Le point du bord haut de [cle] (repere de la portee) ; `null` si absent.
  Rect? _rect(GlobalKey cle) {
    final RenderObject? moi = context.findRenderObject();
    final RenderObject? lui = cle.currentContext?.findRenderObject();
    if (moi is! RenderBox || lui is! RenderBox || !lui.hasSize) return null;
    return MatrixUtils.transformRect(
      lui.getTransformTo(moi),
      Offset.zero & lui.size,
    );
  }

  @override
  void dispose() {
    for (final AnimationController c in <AnimationController>[
      _p,
      _fondu,
      _rebondQuitte,
      _rebondChoisi,
    ]) {
      c.dispose();
    }
    _tick.dispose();
    occupe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PorteeGoutte(
    etat: this,
    actif: _actif,
    de: _actif ? _de : null,
    vers: _actif ? _vers : null,
    selectionId: widget.selectionId,
    child: CustomPaint(
      // Sous le selecteur et le contenu : seule la part des cous qui sort des
      // ronds se voit.
      painter: _PeintreGoutte(etat: this, repaint: _tout),
      child: widget.child,
    ),
  );
}

/// Un notificateur qui ne sert qu'a repeindre.
class _Tic extends ChangeNotifier {
  void tic() => notifyListeners();
}

class _PorteeGoutte extends InheritedWidget {
  const _PorteeGoutte({
    required this.etat,
    required this.actif,
    required this.de,
    required this.vers,
    required this.selectionId,
    required super.child,
  });

  final _EtatGoutteProfils etat;
  final bool actif;
  final String? de;
  final String? vers;
  final String? selectionId;

  @override
  bool updateShouldNotify(_PorteeGoutte ancien) =>
      ancien.actif != actif ||
      ancien.de != de ||
      ancien.vers != vers ||
      ancien.selectionId != selectionId ||
      ancien.etat != etat;
}

/// Le rond d'un profil, declare a la portee : mesure par elle, et il reprend
/// sa forme d'un petit rebond a la rupture du cou. Hors portee, l'enfant tel
/// quel.
class RondGoutte extends StatelessWidget {
  /// Declare le rond de [id]. [rapport] : le rond de repos rapporte a la boite
  /// du rond (le disque que le cou doit rejoindre).
  const RondGoutte({
    required this.id,
    required this.child,
    this.rapport = 1,
    super.key,
  });

  /// Le profil.
  final String id;

  /// Le rond de repos sur sa boite (0 a 1).
  final double rapport;

  /// Le rond.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeGoutte? portee = GoutteProfils._portee(context);
    if (portee == null) return child;
    final _EtatGoutteProfils etat = portee.etat;
    etat._rapports[id] = rapport;
    return KeyedSubtree(
      key: etat.cle(id),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          etat._rebondQuitte,
          etat._rebondChoisi,
        ]),
        child: child,
        builder: (BuildContext _, Widget? enfant) {
          final AnimationController? rebond = !portee.actif
              ? null
              : id == portee.de
              ? etat._rebondQuitte
              : id == portee.vers
              ? etat._rebondChoisi
              : null;
          final double v = rebond == null
              ? 0
              : rebond.value.clamp(-1, 1).toDouble();
          if (v == 0) return enfant!;
          return Transform.scale(
            scale: 1 + AppMouvement.amplitudeReception * v,
            child: enfant,
          );
        },
      ),
    );
  }
}

/// Le contenu d'un profil : il tombe du rond choisi et s'etale en devenant la
/// carte ; au changement de profil, l'ancien contenu est d'abord aspire vers
/// son rond. Hors portee, ou sous « reduire les animations », l'enfant tel
/// quel.
///
/// [profilId] est le profil dont [child] montre le contenu : il ne change que
/// quand les nouvelles donnees sont la (la porte unique de l'Accueil), jamais
/// au toucher.
class ContenuGoutte extends StatefulWidget {
  /// Cree le contenu.
  const ContenuGoutte({required this.profilId, required this.child, super.key});

  /// Le profil dont le contenu s'affiche.
  final String profilId;

  /// Le contenu.
  final Widget child;

  @override
  State<ContenuGoutte> createState() => _EtatContenuGoutte();
}

/// `attente` : l'ancien contenu reste affiche, immobile, tant qu'un cou entre
/// deux ronds tient (une seule goutte a la fois).
enum _Phase { repos, attente, aspire, tombe }

class _EtatContenuGoutte extends State<ContenuGoutte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  final GlobalKey _cleContenu = GlobalKey();
  _Phase _phase = _Phase.repos;
  Widget? _ancien;
  String? _idAncien;
  bool _initialise = false;
  int _generation = 0;
  _EtatGoutteProfils? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialise) return;
    _initialise = true;
    // La premiere apparition est aussi une chute : la goutte tombe du rond
    // choisi (sans portee ou en mouvement reduit, rien).
    if (GoutteProfils._portee(context) != null &&
        !AppMouvement.mouvementReduit(context)) {
      _phase = _Phase.tombe;
      _c.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tomber());
    }
  }

  @override
  void didUpdateWidget(ContenuGoutte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.profilId == widget.profilId) return;
    if (GoutteProfils._portee(context) == null ||
        AppMouvement.mouvementReduit(context)) {
      _terminer();
      return;
    }
    // L'ancien contenu reste affiche le temps d'etre aspire vers son rond.
    final bool enCours = _phase == _Phase.aspire || _phase == _Phase.attente;
    _ancien = enCours ? _ancien : ancien.child;
    _idAncien = enCours ? _idAncien : ancien.profilId;
    _aspirer();
  }

  void _terminer() {
    _generation++;
    _c.stop();
    _ancien = null;
    _idAncien = null;
    if (_phase != _Phase.repos) setState(() => _phase = _Phase.repos);
  }

  void _aspirer() {
    final int g = ++_generation;
    // Une seule goutte a la fois : l'aspiration attend la rupture du cou entre
    // les ronds (l'ancien contenu reste affiche, immobile).
    setState(() => _phase = _Phase.attente);
    _quandLibre(g, () {
      setState(() => _phase = _Phase.aspire);
      _c.duration = AppMouvement.aspirationContenu;
      _c.forward(from: 0).whenComplete(() {
        if (mounted && g == _generation) _tomber();
      });
      _publier();
    });
  }

  /// Appelle [fait] des qu'aucun cou entre deux ronds n'est en cours, si la
  /// generation [g] est encore la courante.
  void _quandLibre(int g, VoidCallback fait) {
    final _EtatGoutteProfils? e = GoutteProfils._portee(context)?.etat;
    if (e == null || !e.occupe.value) {
      fait();
      return;
    }
    void attendre() {
      if (e.occupe.value) return;
      e.occupe.removeListener(attendre);
      if (mounted && g == _generation) fait();
    }

    e.occupe.addListener(attendre);
  }

  /// La chute commence quand aucun cou entre deux ronds n'est en cours.
  void _tomber() {
    if (!mounted) return;
    final int attendue = _generation;
    _quandLibre(attendue, () {
      final int g = ++_generation;
      setState(() {
        _ancien = null;
        _idAncien = null;
        _phase = _Phase.tombe;
      });
      _c.duration = AppMouvement.chuteContenu;
      _c.forward(from: 0).whenComplete(() {
        if (!mounted || g != _generation) return;
        setState(() => _phase = _Phase.repos);
        _depublier();
      });
      _publier();
    });
  }

  /// Dit a la portee quel cou peindre.
  void _publier() {
    final _EtatGoutteProfils? e = GoutteProfils._portee(context)?.etat;
    if (e == null) return;
    _scope = e;
    final bool aspire = _phase == _Phase.aspire;
    final String id = aspire ? (_idAncien ?? widget.profilId) : widget.profilId;
    e._chute = _ChuteEnCours(
      valeur: () => _c.value,
      aspiration: aspire,
      idRond: id,
      cleContenu: _cleContenu,
      ancre: _ancre,
      echelle: _echelle,
    );
    _c.removeListener(e._tick.tic);
    _c.addListener(e._tick.tic);
  }

  void _depublier() {
    final _EtatGoutteProfils? e = GoutteProfils._portee(context)?.etat;
    if (e == null) return;
    _c.removeListener(e._tick.tic);
    e._chute = null;
    e._tick.tic();
  }

  /// Le centre du bord haut du contenu qui reste fixe : a l'aplomb du rond.
  Offset _ancre() {
    final _EtatGoutteProfils? e = GoutteProfils._portee(context)?.etat;
    final Rect? contenu = e?._rect(_cleContenu);
    final String id = _phase == _Phase.aspire
        ? (_idAncien ?? widget.profilId)
        : widget.profilId;
    final ({Offset centre, double rayon})? rond = e?._disque(id);
    if (contenu == null || rond == null) return Offset.zero;
    return Offset(
      rond.centre.dx.clamp(contenu.left, contenu.right).toDouble(),
      contenu.top,
    );
  }

  double _echelle() {
    final double t = _c.value;
    return switch (_phase) {
      _Phase.aspire => _lerp(
        1,
        AppMouvement.echelleGouttePro,
        Curves.easeIn.transform(t),
      ),
      _Phase.tombe => _lerp(
        AppMouvement.echelleGouttePro,
        1,
        Curves.easeOutCubic.transform(t),
      ),
      _Phase.repos || _Phase.attente => 1,
    };
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    final _EtatGoutteProfils? e = _scope;
    if (e != null) {
      _c.removeListener(e._tick.tic);
      e._chute = null;
    }
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _PorteeGoutte? portee = GoutteProfils._portee(context);
    if (portee == null) return widget.child;
    final bool ancienAffiche =
        (_phase == _Phase.aspire || _phase == _Phase.attente) &&
        _ancien != null;
    final Widget corps = ancienAffiche
        ? IgnorePointer(child: _ancien)
        : widget.child;
    return KeyedSubtree(
      key: _cleContenu,
      child: AnimatedBuilder(
        animation: _c,
        child: corps,
        builder: (BuildContext _, Widget? enfant) {
          if (_phase == _Phase.repos || _phase == _Phase.attente) {
            return enfant!;
          }
          final double t = _c.value.clamp(0, 1).toDouble();
          final double echelle = _echelle();
          final double opacite = _phase == _Phase.aspire
              ? 1 - math.pow(t, 1.5).toDouble()
              : (t / 0.5).clamp(0, 1).toDouble();
          // Le contenu reste accroche a l'aplomb du rond, par son bord haut.
          final Rect? r = portee.etat._rect(_cleContenu);
          final Offset a = _ancre();
          final double ax = r == null || r.width <= 0
              ? 0
              : ((a.dx - r.left) / r.width * 2 - 1).clamp(-1, 1).toDouble();
          return Opacity(
            opacity: opacite,
            child: Transform.scale(
              scale: echelle,
              alignment: Alignment(ax, -1),
              child: enfant,
            ),
          );
        },
      ),
    );
  }
}

/// Le peintre de la portee : le cou entre deux ronds, et celui entre un rond
/// et le contenu. Sous le selecteur et le contenu.
class _PeintreGoutte extends CustomPainter {
  _PeintreGoutte({required this.etat, required Listenable repaint})
    : super(repaint: repaint);

  final _EtatGoutteProfils etat;

  /// L'epaisseur du cou quand les silhouettes se touchent, et le plus fin
  /// avant la rupture (comme la barre).
  static const double _plein = 0.5;
  static const double _fin = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    _peindreRonds(canvas);
    _peindreContenu(canvas);
  }

  void _peindreRonds(Canvas canvas) {
    if (!etat._actif || etat._rompu) return;
    final ({Offset centre, double rayon})? a = etat._disque(etat._de);
    final ({Offset centre, double rayon})? b = etat._disque(etat._vers);
    if (a == null || b == null) return;
    final double p = etat._p.value;
    const double arrivee = AppMouvement.arriveeGouttePro;
    const double rupture = AppMouvement.ruptureGouttePro;
    // La pointe du rond quitte : elle part vers le rond choisi, s'amincit en
    // route, puis se fond en lui.
    final double s = (p / arrivee).clamp(0, 1).toDouble();
    final Offset pointe = Offset.lerp(a.centre, b.centre, s)!;
    final double rPointe = a.rayon * (1 - 0.3 * math.sin(math.pi * s));
    // Le cou : plein au depart, de plus en plus fin ; une fois la pointe dans
    // le rond choisi, il s'amincit jusqu'a la rupture.
    final double v = p < arrivee
        ? _plein * (1 - 0.5 * s)
        : _plein * 0.5 -
              (_plein * 0.5 - _fin) *
                  ((p - arrivee) / (rupture - arrivee)).clamp(0, 1).toDouble();
    final Paint peinture = Paint()..color = etat.widget.matiere;
    canvas.drawPath(
      pontEntreSilhouettes(
        SilhouetteLiquide.disque(a.centre, a.rayon),
        SilhouetteLiquide.disque(pointe, rPointe),
        v: v,
        portee: 4,
      ),
      peinture,
    );
    canvas.drawCircle(pointe, rPointe, peinture);
  }

  void _peindreContenu(Canvas canvas) {
    final _ChuteEnCours? c = etat._chute;
    if (c == null) return;
    final ({Offset centre, double rayon})? rond = etat._disque(c.idRond);
    final Rect? plein = etat._rect(c.cleContenu);
    if (rond == null || plein == null) return;
    final double t = c.valeur().clamp(0, 1).toDouble();
    // Le cou : a la chute, plein puis de plus en plus fin jusqu'a la rupture ;
    // a l'aspiration, il se forme a mesure que le contenu approche du rond.
    final double v;
    if (c.aspiration) {
      v = _fin + (_plein - _fin) * t;
    } else {
      const double rupture = AppMouvement.ruptureChuteContenu;
      if (t >= rupture) return;
      v = _plein - (_plein - _fin) * (t / rupture);
    }
    // Le contenu, a l'echelle courante, accroche par son bord haut a l'aplomb
    // du rond.
    final double e = c.echelle();
    final Offset a = c.ancre();
    final Rect visible = Rect.fromLTRB(
      a.dx + (plein.left - a.dx) * e,
      plein.top,
      a.dx + (plein.right - a.dx) * e,
      plein.top + plein.height * e,
    );
    final Path cou = pontEntreSilhouettes(
      SilhouetteLiquide.disque(rond.centre, rond.rayon),
      SilhouetteLiquide.rectangle(visible, etat.widget.rayonContenu),
      v: v,
      portee: 6,
    );
    if (cou.getBounds().isEmpty) return;
    // La goutte devient la carte : du bord d'accent du rond a la matiere de la
    // carte.
    canvas.drawPath(
      cou,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[etat.widget.matiere, etat.widget.matiereContenu],
        ).createShader(cou.getBounds()),
    );
  }

  @override
  bool shouldRepaint(_PeintreGoutte ancien) => true;
}
