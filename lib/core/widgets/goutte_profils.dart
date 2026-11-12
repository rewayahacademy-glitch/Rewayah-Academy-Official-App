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
//    haut du contenu, puis rupture). Le contenu n'est JAMAIS retarde
//    (DECISION-FLUIDITE-2026-11-07) : au changement de profil, le nouveau
//    contenu est la tout de suite (des que ses donnees le sont) et la goutte se
//    joue sur lui.
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';
import 'liaison_liquide.dart';

/// GOUTTE-COUPEE (directeur, 11/11/2026, relaye par le garde-cap) : le
/// directeur refuse le dessin de la goutte (« immonde ») ; elle ne peint plus
/// rien, ni cou, ni goutte, ni nappe. La selection et le contenu changent tout
/// de suite. [GoutteProfils], [RondGoutte], [ItemGoutte] et [ContenuGoutte]
/// restent en place pour une refonte future (base : la branche
/// `claude/goutte-nappe-travail`) ; remettre ce drapeau a `true` ne se fait
/// que sur decision datee du directeur.
const bool goutteActive = false;

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

  /// La chute du contenu en cours au-dessus de [context], ou `null` au repos
  /// (tests) : l'avancement de 0 a 1.
  @visibleForTesting
  static ({double avancement})? chuteDe(BuildContext context) {
    final _EtatGoutteProfils? e = context
        .getInheritedWidgetOfExactType<_PorteeGoutte>()
        ?.etat;
    final _ChuteEnCours? c = e?._chute;
    if (c == null) return null;
    return (avancement: c.valeur());
  }

  /// Pour les tests : le haut du disque d'ou part le cou du contenu du profil
  /// [id], et le bas de son item (rond et libelle), dans le repere de la
  /// portee. Le cou ne traverse le libelle que si le premier est au-dessus du
  /// second.
  @visibleForTesting
  static ({double hautDuDepart, double basDeLItem})? departContenuDe(
    BuildContext context,
    String id,
  ) {
    final _EtatGoutteProfils? e = context
        .getInheritedWidgetOfExactType<_PorteeGoutte>()
        ?.etat;
    final ({Offset centre, double rayon})? d = e?._departContenu(id);
    final Rect? item = e?._rectItem(id);
    if (d == null || item == null) return null;
    return (hautDuDepart: d.centre.dy - d.rayon, basDeLItem: item.bottom);
  }

  @override
  State<GoutteProfils> createState() => _EtatGoutteProfils();
}

/// Le contenu qui tombe, vu par la portee pour peindre son cou.
class _ChuteEnCours {
  _ChuteEnCours({
    required this.valeur,
    required this.idRond,
    required this.cleContenu,
    required this.ancre,
    required this.echelle,
  });

  /// L'avancement, de 0 a 1.
  final double Function() valeur;

  /// Le rond d'ou le contenu tombe.
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
  final Map<String, GlobalKey> _clesItems = <String, GlobalKey>{};
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

  Timer? _fin;
  bool _actif = false;
  bool _rompu = false;
  bool _arrive = false;
  String? _de;
  String? _vers;
  _ChuteEnCours? _chute;

  GlobalKey cle(String id) => _cles.putIfAbsent(id, GlobalKey.new);

  /// La cle de l'item entier d'un profil (rond et libelle).
  GlobalKey cleItem(String id) => _clesItems.putIfAbsent(id, GlobalKey.new);

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
    if (!goutteActive || AppMouvement.mouvementReduit(context)) {
      _finir();
      return;
    }
    // Les ronds ne sont mesurables qu'apres la mise en page de la selection.
    WidgetsBinding.instance.addPostFrameCallback((_) => _lancer(de, vers));
  }

  void _lancer(String de, String vers) {
    if (!mounted) return;
    // Une seule goutte : la precedente s'acheve sur-le-champ.
    if (_actif) _finir();
    if (_disque(de) == null || _disque(vers) == null) {
      // Un rond hors ecran : pas de cou.
      return;
    }
    _de = de;
    _vers = vers;
    _rompu = false;
    _arrive = false;
    _fondu.value = 0;
    _p.value = 0;
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
      _p.stop();
      _rebondir(_rebondQuitte);
      _rebondir(_rebondChoisi);
      _fondu.forward(from: 0);
      // Le mouvement entier tient sous le plafond : la goutte s'acheve au bout
      // du rebond, sans attendre que le ressort se pose.
      _fin?.cancel();
      _fin = Timer(AppMouvement.rebondGouttePro, () {
        if (mounted && _actif) _finir();
      });
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
    _fin?.cancel();
    _p.stop();
    _fondu.value = 1;
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

  /// Le disque d'ou part le cou du contenu : tangent par le haut au bas de
  /// l'item (sous le libelle), a l'aplomb du rond. `null` sans mesure de
  /// l'item.
  ({Offset centre, double rayon})? _departContenu(String id) {
    final ({Offset centre, double rayon})? rond = _disque(id);
    final Rect? item = _rectItem(id);
    if (rond == null || item == null) return null;
    final double rayon = rond.rayon * _PeintreGoutte._rapportDepartContenu;
    return (
      centre: Offset(
        rond.centre.dx,
        math.max(item.bottom, rond.centre.dy) + rayon,
      ),
      rayon: rayon,
    );
  }

  /// La boite de l'item entier de [id] (rond et libelle), ou `null`.
  Rect? _rectItem(String id) {
    final GlobalKey? cle = _clesItems[id];
    return cle == null ? null : _rect(cle);
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
    _fin?.cancel();
    for (final AnimationController c in <AnimationController>[
      _p,
      _fondu,
      _rebondQuitte,
      _rebondChoisi,
    ]) {
      c.dispose();
    }
    _tick.dispose();
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

/// L'item entier d'un profil (rond ET libelle), declare a la portee : le cou
/// du contenu part du BAS de l'item, jamais du rond, pour ne jamais traverser
/// le libelle (garde-cap, 11/11/2026). Hors portee, l'enfant tel quel.
class ItemGoutte extends StatelessWidget {
  /// Declare l'item de [id].
  const ItemGoutte({required this.id, required this.child, super.key});

  /// Le profil.
  final String id;

  /// L'item (rond et libelle).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _PorteeGoutte? portee = GoutteProfils._portee(context);
    if (portee == null) return child;
    return KeyedSubtree(key: portee.etat.cleItem(id), child: child);
  }
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
/// carte, tout de suite, au changement de profil. Hors portee, ou sous
/// « reduire les animations », l'enfant tel quel.
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

enum _Phase { repos, tombe }

class _EtatContenuGoutte extends State<ContenuGoutte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  final GlobalKey _cleContenu = GlobalKey();
  _Phase _phase = _Phase.repos;
  int _generation = 0;
  _EtatGoutteProfils? _scope;

  @override
  void didUpdateWidget(ContenuGoutte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.profilId == widget.profilId) return;
    if (!goutteActive ||
        GoutteProfils._portee(context) == null ||
        AppMouvement.mouvementReduit(context)) {
      _terminer();
      return;
    }
    // DECISION-FLUIDITE (07/11/2026) : changer de profil est une action
    // courante, le nouveau contenu est la tout de suite ; la goutte se joue
    // SUR lui, jamais avant. Il ne vient que quand ses donnees sont la (la
    // porte unique de l'Accueil) ; la lecture, elle, part au toucher.
    _tomber();
  }

  void _terminer() {
    _generation++;
    _c.stop();
    if (_phase != _Phase.repos) setState(() => _phase = _Phase.repos);
    _depublier();
  }

  /// La chute : le contenu, deja en place, s'etale du rond choisi.
  void _tomber() {
    final int g = ++_generation;
    setState(() => _phase = _Phase.tombe);
    _c.duration = AppMouvement.chuteContenu;
    _c.forward(from: 0).whenComplete(() {
      if (!mounted || g != _generation) return;
      setState(() => _phase = _Phase.repos);
      _depublier();
    });
    _publier();
  }

  /// Dit a la portee quel cou peindre.
  void _publier() {
    final _EtatGoutteProfils? e = GoutteProfils._portee(context)?.etat;
    if (e == null) return;
    _scope = e;
    e._chute = _ChuteEnCours(
      valeur: () => _c.value,
      idRond: widget.profilId,
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
    final ({Offset centre, double rayon})? rond = e?._disque(widget.profilId);
    if (contenu == null || rond == null) return Offset.zero;
    return Offset(
      rond.centre.dx.clamp(contenu.left, contenu.right).toDouble(),
      contenu.top,
    );
  }

  double _echelle() => _phase == _Phase.tombe
      ? _lerp(
          AppMouvement.echelleGouttePro,
          1,
          AppMouvement.entree.transform(_c.value),
        )
      : 1;

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
    return KeyedSubtree(
      key: _cleContenu,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (BuildContext _, Widget? enfant) {
          if (_phase == _Phase.repos) return enfant!;
          final double t = _c.value.clamp(0, 1).toDouble();
          final double echelle = _echelle();
          // Il apparait tout de suite : plein des la moitie de la chute.
          final double opacite = (t / 0.5).clamp(0, 1).toDouble();
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

  /// Le rayon de la goutte qui part du bas de l'item, rapporte a celui du rond.
  static const double _rapportDepartContenu = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    if (!goutteActive) return;
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
    final ({Offset centre, double rayon})? rondDuProfil = etat._disque(
      c.idRond,
    );
    final Rect? plein = etat._rect(c.cleContenu);
    if (rondDuProfil == null || plein == null) return;
    // Le cou part du BAS de l'item (sous le libelle), a l'aplomb du rond : il
    // ne traverse jamais le prenom ni l'etat. Sans mesure de l'item, du rond.
    final ({Offset centre, double rayon}) rond =
        etat._departContenu(c.idRond) ?? rondDuProfil;
    final double t = c.valeur().clamp(0, 1).toDouble();
    // Le cou : plein puis de plus en plus fin jusqu'a la rupture.
    const double rupture = AppMouvement.ruptureChuteContenu;
    if (t >= rupture) return;
    final double v = _plein - (_plein - _fin) * (t / rupture);
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
