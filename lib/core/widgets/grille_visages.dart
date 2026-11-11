// SCENE-CLASSE (directeur, 11/11/2026 : « il faut juste des carres comme sur
// Zoom, et pense a les rendre esthetiques ») : la grille des visages de la
// salle, en mode Classe. La regle : `docs/current/salle/MODES-AFFICHAGE.md`
// §3 ; la revue : `docs/current/UX_REVIEW_SCENE-CLASSE.md`.
//
// Deux pieces separees : le CALCUL ([calculerGrille], [rectsGrille]),
// fonction pure et testee, et le WIDGET ([GrilleVisages]), qui pose les
// cadres aux places calculees et anime les arrivees, les departs et les
// glissements. Le composant ne connait ni LiveKit ni Riverpod : il recoit des
// cadres ([EntreeGrille]) deja construits (`CadreVisage`).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_spacing.dart';
import 'barre_precedent_suivant.dart';

/// La forme d'un cadre de la grille, largeur sur hauteur, pour la place
/// donnee : **carre** sur un telephone en portrait (`Gabarit.mobile`), **4/3**
/// partout ailleurs (tablette, ordinateur, telephone couche). Jamais plus haut
/// que large, jamais plus large que 4/3 (MODES-AFFICHAGE §3).
///
/// `[RESPONSIVE]` La forme vient du gabarit et de l'orientation, jamais
/// d'une largeur comparee a un nombre (seul `AppGabarit` le fait).
double rapportCadre(Gabarit gabarit, Orientation orientation) =>
    gabarit == Gabarit.mobile && orientation == Orientation.portrait
    ? 1
    : 4 / 3;

/// La forme d'un cadre pour l'ecran de [context] ([rapportCadre]).
double rapportCadreDe(BuildContext context) =>
    rapportCadre(AppGabarit.de(context), MediaQuery.orientationOf(context));

/// Ce que [calculerGrille] decide : combien de colonnes et de rangees, la
/// taille d'un cadre, et le decoupage en pages quand la place manque.
@immutable
class DispositionGrille {
  /// Cree une disposition.
  const DispositionGrille({
    required this.colonnes,
    required this.rangees,
    required this.cadre,
    required this.parPage,
    required this.pages,
  });

  /// Aucune personne : rien a poser.
  static const DispositionGrille vide = DispositionGrille(
    colonnes: 0,
    rangees: 0,
    cadre: Size.zero,
    parPage: 0,
    pages: 0,
  );

  /// Le nombre de colonnes d'une page pleine.
  final int colonnes;

  /// Le nombre de rangees d'une page pleine.
  final int rangees;

  /// La taille d'un cadre (la meme pour tous, a la forme demandee).
  final Size cadre;

  /// Le nombre de cadres par page.
  final int parPage;

  /// Le nombre de pages (1 quand tout tient).
  final int pages;

  @override
  String toString() =>
      'DispositionGrille($colonnes x $rangees, '
      '${cadre.width.toStringAsFixed(0)} x '
      '${cadre.height.toStringAsFixed(0)}, $parPage par page, $pages pages)';
}

/// La largeur maximale d'un cadre : **480 points** (sept respirations et
/// demie). A deux ou trois dans une fenetre de 1440, la grille ne remplit pas
/// l'ecran pour le remplir : 480 x 360 a 4/3, c'est un visage a taille
/// naturelle a un bras de distance (la taille d'une vignette de Meet en
/// grand) ; au-dela, l'image d'une webcam de 720 lignes s'etale et l'oeil doit
/// balayer d'un visage a l'autre. Justification : `UX_REVIEW_SCENE-CLASSE.md`.
const double largeurMaxCadre = AppSpacing.respiration * 7.5;

/// Le plus petit cote qu'un cadre de grille peut avoir : **96 points**. En
/// dessous, la grille passe en pages entieres (jamais des cadres
/// minuscules) ; 96 garde le nom et le signe du micro lisibles.
const double coteMinCadre = AppSpacing.respiration * 1.5;

/// La hauteur reservee a la barre des pages, quand il y en a plusieurs.
const double hauteurBarrePages = AppSpacing.respiration;

/// La taille du plus grand cadre de forme [rapport] quand [n] cadres se
/// posent sur [colonnes] colonnes dans [place].
Size _taillePour(
  int n,
  int colonnes,
  Size place, {
  required double rapport,
  required double ecart,
  required double largeurMax,
}) {
  final int rangees = (n + colonnes - 1) ~/ colonnes;
  final double parLargeur = (place.width - ecart * (colonnes - 1)) / colonnes;
  final double parHauteur =
      (place.height - ecart * (rangees - 1)) / rangees * rapport;
  // Arrondi vers le bas : une fraction de point en trop ferait deborder la
  // derniere rangee.
  final double largeur = math
      .max(0, math.min(math.min(parLargeur, parHauteur), largeurMax))
      .floorToDouble();
  return Size(largeur, (largeur / rapport).floorToDouble());
}

/// Le meilleur nombre de colonnes pour [n] cadres dans [place] : celui qui
/// donne les plus grands cadres (le calcul de Zoom et de Meet). A taille
/// egale (la borne atteinte), la grille prend la forme de la place : plus de
/// colonnes dans une place large, plus de rangees dans une place haute.
(int, Size) _meilleur(
  int n,
  Size place, {
  required double rapport,
  required double ecart,
  required double largeurMax,
}) {
  int meilleures = 1;
  Size taille = Size.zero;
  final bool large = place.width >= place.height;
  for (int c = 1; c <= n; c++) {
    final Size essai = _taillePour(
      n,
      c,
      place,
      rapport: rapport,
      ecart: ecart,
      largeurMax: largeurMax,
    );
    final bool plusGrand = essai.width > taille.width;
    // A egalite (la borne atteinte), dans une place large, la colonne de
    // plus l'emporte si elle retire une rangee.
    final bool egalPlusLarge =
        essai.width == taille.width &&
        large &&
        (n + c - 1) ~/ c < (n + meilleures - 1) ~/ meilleures;
    if (plusGrand || egalPlusLarge) {
      meilleures = c;
      taille = essai;
    }
  }
  return (meilleures, taille);
}

/// SCENE-CLASSE : la disposition de [n] cadres de forme [rapport] dans
/// [place], separes de [ecart], chacun au plus de [largeurMax] de large.
///
/// Quand le plus petit cote d'un cadre tomberait sous [coteMin], la grille
/// passe en **pages entieres** : autant de cadres par page que possible a
/// [coteMin] au moins, la place des pages ([hauteurBarrePages]) retiree.
DispositionGrille calculerGrille(
  int n,
  Size place, {
  required double rapport,
  double ecart = AppSpacing.lg,
  double largeurMax = largeurMaxCadre,
  double coteMin = coteMinCadre,
}) {
  assert(rapport >= 1 && rapport <= 4 / 3 + 0.0001, 'forme hors bornes');
  if (n <= 0 || place.width <= 0 || place.height <= 0) {
    return DispositionGrille.vide;
  }
  final (int colonnes, Size cadre) = _meilleur(
    n,
    place,
    rapport: rapport,
    ecart: ecart,
    largeurMax: largeurMax,
  );
  if (cadre.height >= coteMin || n == 1) {
    return DispositionGrille(
      colonnes: colonnes,
      rangees: (n + colonnes - 1) ~/ colonnes,
      cadre: cadre,
      parPage: n,
      pages: 1,
    );
  }
  // La place manque : des pages entieres, la barre des pages dessous.
  final Size reste = Size(
    place.width,
    math.max(0, place.height - hauteurBarrePages),
  );
  for (int k = n - 1; k >= 1; k--) {
    final (int c, Size t) = _meilleur(
      k,
      reste,
      rapport: rapport,
      ecart: ecart,
      largeurMax: largeurMax,
    );
    if (t.height >= coteMin || k == 1) {
      return DispositionGrille(
        colonnes: c,
        rangees: (k + c - 1) ~/ c,
        cadre: t,
        parPage: k,
        pages: (n + k - 1) ~/ k,
      );
    }
  }
  return DispositionGrille.vide;
}

/// Les places des [nombre] cadres d'une page (au plus `parPage`) dans
/// [place] : la grille **centree** en largeur et en hauteur, la derniere
/// rangee incomplete **centree** elle aussi. L'ordre suit le sens de lecture
/// ([sens] : en arabe, le premier cadre est a droite).
List<Rect> rectsGrille(
  DispositionGrille d,
  int nombre,
  Size place, {
  double ecart = AppSpacing.lg,
  TextDirection sens = TextDirection.ltr,
}) {
  if (nombre <= 0 || d.colonnes == 0) return const <Rect>[];
  final int colonnes = math.min(d.colonnes, nombre);
  final int rangees = (nombre + colonnes - 1) ~/ colonnes;
  final double w = d.cadre.width;
  final double h = d.cadre.height;
  final double hauteurGrille = rangees * h + (rangees - 1) * ecart;
  final double haut = ((place.height - hauteurGrille) / 2).floorToDouble();
  final List<Rect> rects = <Rect>[];
  for (int i = 0; i < nombre; i++) {
    final int rangee = i ~/ colonnes;
    final int dansRangee = rangee == rangees - 1
        ? nombre - rangee * colonnes
        : colonnes;
    final int colonne = i % colonnes;
    final double largeurRangee = dansRangee * w + (dansRangee - 1) * ecart;
    final double debut = ((place.width - largeurRangee) / 2).floorToDouble();
    final double dx = debut + colonne * (w + ecart);
    final double x = sens == TextDirection.rtl
        ? place.width - dx - w
        : dx;
    rects.add(Rect.fromLTWH(x, haut + rangee * (h + ecart), w, h));
  }
  return rects;
}

/// Un cadre de la grille : sa cle stable (une par personne) et son widget.
@immutable
class EntreeGrille {
  /// Cree une entree.
  const EntreeGrille({
    required this.cle,
    required this.cadre,
    this.attendreAuDepart = true,
  });

  /// La cle stable de la personne (son identite).
  final Key cle;

  /// Le cadre (`CadreVisage`).
  final Widget cadre;

  /// Vrai : quand la personne disparait, son cadre attend
  /// [AppMouvement.graceDepartVisage] avant de partir (une reconnexion
  /// rapide ne fait pas danser la grille). Faux : il part aussitot (sa propre
  /// image quand on coupe sa camera).
  final bool attendreAuDepart;
}

/// SCENE-CLASSE : la grille des visages (MODES-AFFICHAGE §3 et §5).
///
/// - le plus grand cadre possible a la forme donnee ([rapportCadreDe]),
///   borne a [largeurMaxCadre] ; grille centree, derniere rangee centree,
///   ecart de 16 ;
/// - **arrivee** : le cadre grandit en fondu ; **depart** : il retrecit en
///   fondu, puis les autres glissent a leur nouvelle place sur le ressort sans
///   rebond ([AppMouvement.ressortDeplacement]) ; une taille de fenetre qui
///   change ne s'anime pas (la grille suit la fenetre) ;
/// - **reconnexion** : une personne qui disparait garde sa place, attenuee,
///   pendant [AppMouvement.graceDepartVisage] ; revenue a temps, rien ne
///   bouge ;
/// - « Reduire les animations » : fondu seul, les cadres sautent a leur place ;
/// - trop de monde pour des cadres de 96 au moins : des pages entieres, la
///   barre precedent / suivant dessous (et le glisser du doigt).
class GrilleVisages extends StatefulWidget {
  /// Cree la grille.
  const GrilleVisages({
    required this.cadres,
    super.key,
    this.rapport,
    this.ecart = AppSpacing.lg,
    this.largeurMax = largeurMaxCadre,
  });

  /// Les cadres, dans l'ordre de lecture.
  final List<EntreeGrille> cadres;

  /// La forme des cadres ; `null` : celle de l'ecran ([rapportCadreDe]).
  final double? rapport;

  /// L'ecart entre deux cadres.
  final double ecart;

  /// La largeur maximale d'un cadre.
  final double largeurMax;

  /// La cle de la grille (tests, captures).
  static const Key cle = ValueKey<String>('grille-visages');

  /// La cle de la barre des pages.
  static const Key clePages = ValueKey<String>('grille-visages-pages');

  /// L'echelle d'un cadre au debut de son arrivee (et a la fin de son
  /// depart) : il grandit de 85 % a 100 %.
  static const double echelleArrivee = 0.85;

  @override
  State<GrilleVisages> createState() => _GrilleVisagesEtat();
}

/// Un cadre pose, et ce qui l'anime.
class _Pose {
  _Pose(this.cle, this.cadre, {required this.attendre});

  final Key cle;
  Widget cadre;
  bool attendre;

  /// L'arrivee en cours, ou `null`.
  AnimationController? arrivee;

  /// Le depart en cours (attente puis fondu), ou `null`.
  AnimationController? depart;

  void liberer() {
    arrivee?.dispose();
    depart?.dispose();
    arrivee = null;
    depart = null;
  }
}

class _GrilleVisagesEtat extends State<GrilleVisages>
    with TickerProviderStateMixin {
  late List<_Pose> _poses = <_Pose>[
    for (final EntreeGrille e in widget.cadres)
      _Pose(e.cle, e.cadre, attendre: e.attendreAuDepart),
  ];

  /// La derniere place connue : quand elle change, rien ne s'anime.
  Size? _dernierePlace;

  /// La page affichee, quand il y en a plusieurs.
  int _page = 0;
  final PageController _pages = PageController();

  @override
  void didUpdateWidget(GrilleVisages ancien) {
    super.didUpdateWidget(ancien);
    final Map<Key, _Pose> existantes = <Key, _Pose>{
      for (final _Pose p in _poses) p.cle: p,
    };
    final Set<Key> voulues = <Key>{
      for (final EntreeGrille e in widget.cadres) e.cle,
    };
    final List<_Pose> suite = <_Pose>[];
    for (final EntreeGrille e in widget.cadres) {
      final _Pose? deja = existantes[e.cle];
      if (deja != null) {
        deja
          ..cadre = e.cadre
          ..attendre = e.attendreAuDepart;
        // Revenue pendant son attente : elle reprend sa place, sans bruit.
        if (deja.depart != null) {
          deja.depart!.dispose();
          deja.depart = null;
        }
        suite.add(deja);
      } else {
        final _Pose nouvelle = _Pose(
          e.cle,
          e.cadre,
          attendre: e.attendreAuDepart,
        );
        nouvelle.arrivee = _controleur(AppMouvement.fonduEntree, () {
          nouvelle.arrivee?.dispose();
          nouvelle.arrivee = null;
        });
        suite.add(nouvelle);
      }
    }
    // Les partantes gardent leur place le temps de partir.
    for (int i = 0; i < _poses.length; i++) {
      final _Pose p = _poses[i];
      if (voulues.contains(p.cle)) continue;
      p.arrivee?.dispose();
      p.arrivee = null;
      p.depart ??= _controleur(
        p.attendre
            ? AppMouvement.graceDepartVisage + AppMouvement.fonduSortie
            : AppMouvement.fonduSortie,
        () {
          p.liberer();
          _poses.remove(p);
        },
      );
      suite.insert(math.min(i, suite.length), p);
    }
    _poses = suite;
  }

  /// Un controleur qui part tout de suite et appelle [fin] (dans un
  /// `setState`) quand il a fini.
  AnimationController _controleur(Duration duree, VoidCallback fin) {
    final AnimationController c = AnimationController(
      vsync: this,
      duration: duree,
    );
    c.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) setState(fin);
    });
    c.forward();
    return c;
  }

  @override
  void dispose() {
    for (final _Pose p in _poses) {
      p.liberer();
    }
    _pages.dispose();
    super.dispose();
  }

  /// Le cadre [p], avec son arrivee ou son depart.
  Widget _anime(_Pose p, {required bool reduit}) {
    final AnimationController? arrivee = p.arrivee;
    final AnimationController? depart = p.depart;
    final Widget cadre = p.cadre;
    // La meme structure avec ou sans animation : le cadre (et sa video)
    // n'est jamais reconstruit quand son arrivee finit.
    final Animation<double> anim =
        arrivee ?? depart ?? const AlwaysStoppedAnimation<double>(1);
    return AnimatedBuilder(
      animation: anim,
      child: cadre,
      builder: (BuildContext _, Widget? enfant) {
        double opacite = 1;
        double echelle = 1;
        if (arrivee == null && depart == null) {
          // Au repos.
        } else if (arrivee != null) {
          final double v = AppMouvement.courbeFondu.transform(arrivee.value);
          opacite = v;
          echelle = GrilleVisages.echelleArrivee +
              (1 - GrilleVisages.echelleArrivee) * v;
        } else {
          final Duration total = depart!.duration ?? Duration.zero;
          final double part = total == Duration.zero
              ? 0
              : 1 -
                    AppMouvement.fonduSortie.inMicroseconds /
                        total.inMicroseconds;
          final double t = depart.value;
          // Attente (reconnexion) : la place est gardee, le cadre attenue.
          const double attenue = 1 - AppMouvement.opaciteVoile;
          if (t < part) {
            opacite = attenue;
            echelle = 1;
          } else {
            final double v = AppMouvement.sortie.transform(
              part >= 1 ? 1 : (t - part) / (1 - part),
            );
            opacite = (p.attendre ? attenue : 1) * (1 - v);
            echelle = 1 - (1 - GrilleVisages.echelleArrivee) * v;
          }
        }
        return Opacity(
          opacity: opacite.clamp(0, 1),
          child: Transform.scale(scale: reduit ? 1 : echelle, child: enfant),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    final double rapport = widget.rapport ?? rapportCadreDe(context);
    final TextDirection sens = Directionality.of(context);
    return LayoutBuilder(
      key: GrilleVisages.cle,
      builder: (BuildContext contexte, BoxConstraints c) {
        final Size place = c.biggest;
        // La fenetre change de taille : la grille la suit, sans animation.
        final bool suit = _dernierePlace != null && _dernierePlace != place;
        _dernierePlace = place;
        final DispositionGrille d = calculerGrille(
          _poses.length,
          place,
          rapport: rapport,
          ecart: widget.ecart,
          largeurMax: widget.largeurMax,
        );
        if (d.pages <= 1) {
          final List<Rect> rects = rectsGrille(
            d,
            _poses.length,
            place,
            ecart: widget.ecart,
            sens: sens,
          );
          final Duration duree = suit || reduit
              ? Duration.zero
              : AppMouvement.deplacementEntree;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < _poses.length && i < rects.length; i++)
                AnimatedPositioned.fromRect(
                  key: _poses[i].cle,
                  rect: rects[i],
                  duration: duree,
                  curve: AppMouvement.ressortDeplacement,
                  child: _anime(_poses[i], reduit: reduit),
                ),
            ],
          );
        }
        return _paginee(contexte, d, place, sens, reduit: reduit);
      },
    );
  }

  /// Plus de monde que de place : des pages entieres et leur barre.
  Widget _paginee(
    BuildContext context,
    DispositionGrille d,
    Size place,
    TextDirection sens, {
    required bool reduit,
  }) {
    final int page = _page.clamp(0, d.pages - 1);
    final Size zone = Size(
      place.width,
      math.max(0, place.height - hauteurBarrePages),
    );
    final Duration duree = AppMouvement.duree(
      context,
      AppMouvement.deplacementEntree,
    );
    void aller(int p) {
      setState(() => _page = p);
      if (duree == Duration.zero) {
        _pages.jumpToPage(p);
      } else {
        unawaited(
          _pages.animateToPage(
            p,
            duration: duree,
            curve: AppMouvement.ressortDeplacement,
          ),
        );
      }
    }

    final String position = t.commun.formats.pageSur(
      page: '${page + 1}',
      total: '${d.pages}',
    );
    return Column(
      children: <Widget>[
        SizedBox.fromSize(
          size: zone,
          child: PageView(
            controller: _pages,
            onPageChanged: (int p) => setState(() => _page = p),
            children: <Widget>[
              for (int p = 0; p < d.pages; p++)
                Builder(
                  builder: (BuildContext _) {
                    final int debut = p * d.parPage;
                    final int fin = math.min(_poses.length, debut + d.parPage);
                    final List<Rect> rects = rectsGrille(
                      d,
                      fin - debut,
                      zone,
                      ecart: widget.ecart,
                      sens: sens,
                    );
                    return Stack(
                      children: <Widget>[
                        for (int i = debut; i < fin; i++)
                          Positioned.fromRect(
                            key: _poses[i].cle,
                            rect: rects[i - debut],
                            child: _anime(_poses[i], reduit: reduit),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        SizedBox(
          height: hauteurBarrePages,
          child: Center(
            child: BarrePrecedentSuivant(
              key: GrilleVisages.clePages,
              etendue: false,
              position: position,
              positionSemantique: position,
              libellePrecedent: t.salle.scene.precedents,
              libelleSuivant: t.salle.scene.suivants,
              onPrecedent: page > 0 ? () => aller(page - 1) : null,
              onSuivant: page < d.pages - 1 ? () => aller(page + 1) : null,
            ),
          ),
        ),
      ],
    );
  }
}
