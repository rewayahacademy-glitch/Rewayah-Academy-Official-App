// VIVANT : Praxis, le personnage entier, dessine pour etre anime (directeur,
// 20/11/2026 ; amende `assets/brand/praxis/README.md` : l'image fixe reste
// celle des messages).
//
// **Ses yeux sont sa signature** (decision du directeur du 20/11/2026,
// PARCOURS-ENSEIGNANT/PLAN §18.6) : l'ovale d'encre de 26 sur 36 et sa pupille
// blanche de rayon 6, aux memes centres que le dessin d'origine. Ils ne
// changent jamais de forme : ils clignent et se ferment le long de leur propre
// ovale. Les expressions passent par la bouche, la tete, la toque, les mains
// et la posture. La toque est posee sur le crane : elle ne traverse jamais le
// visage.
//
// Un seul dessin (`CustomPainter`) : le corps (une boule lilas, en volume),
// la toque (calotte, plateau, cordon, gland en pendule), deux mains, deux
// pieds, une bouche. Il respire, cligne, balance les pieds, suit le pointeur
// des yeux ; apres vingt secondes sans geste il s'endort et plus aucune image
// n'est produite (PLAN §13.1, regle 5). Un geste le reveille.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_palette.dart';
import 'ressort.dart';

/// Les humeurs de Praxis.
enum HumeurPraxis {
  /// Au repos : un leger sourire.
  calme,

  /// Content : rien ne bloque. Grand sourire, les mains se levent.
  heureux,

  /// La tete penchee, une main au menton, la bouche en rond.
  curieux,

  /// Un blocage a signaler : la bouche tombe, la tete se baisse.
  soucieux,

  /// Les larmes partent des yeux et tombent sous le visage.
  pleure,

  /// La gene : un halo rose sur les joues.
  gene,

  /// Les yeux fermes.
  dort,
}

/// Praxis, vivant.
///
/// Ses couleurs sont les siennes (lilas du corps, encre), identiques en clair
/// et en sombre : elles viennent de la palette claire, jamais d'une couleur
/// posee ici. Purement decoratif : exclu de la semantique, la phrase qu'il
/// « dit » est un texte a cote de lui.
class PraxisVivant extends StatefulWidget {
  /// Cree Praxis.
  const PraxisVivant({
    super.key,
    this.humeur = HumeurPraxis.calme,
    this.taille = 120,
    this.tombe = true,
    this.assis = false,
    this.parle = false,
    this.regard,
  });

  /// Son humeur ; la changer l'anime.
  final HumeurPraxis humeur;

  /// Sa largeur ; sa hauteur vaut [hauteurPour] cette largeur.
  final double taille;

  /// Il arrive en tombant et rebondit, une fois.
  final bool tombe;

  /// Assis sur un bord : les pieds pendent sous la ligne d'assise
  /// ([assisePour]), les mains tiennent le bord.
  final bool assis;

  /// Il parle : sa bouche bat tant que c'est vrai.
  final bool parle;

  /// La position du pointeur (coordonnees globales) qu'il suit des yeux.
  final ValueListenable<Offset>? regard;

  /// Combien de temps il vit sans geste avant de s'endormir.
  static const double veille = 20;

  /// La hauteur du dessin pour une largeur de [taille].
  static double hauteurPour(double taille) => taille * _hauteur / _largeur;

  /// La ligne d'assise, mesuree depuis le haut du dessin : le bord sur
  /// lequel il est assis passe la.
  static double assisePour(double taille) => taille * _assise / _largeur;

  @override
  State<PraxisVivant> createState() => EtatPraxisVivant();
}

// Les unites du dessin : une boite de 200 sur 224 ; le corps est un disque de
// rayon 86 centre en (100, 108), comme le dessin d'origine.
const double _largeur = 200;
const double _hauteur = 224;
const double _assise = 176;
const Offset _centre = Offset(100, 108);
const double _rayon = 86;
const double _sol = 194;

/// L'etat de Praxis : ses gestes ([non], [cligner]) s'appellent par une cle.
class EtatPraxisVivant extends State<PraxisVivant>
    with SingleTickerProviderStateMixin<PraxisVivant>, VieDesRessorts {
  // Les yeux : l'ouverture seule (1 : le dessin d'origine).
  final Ressort _ouvert = Ressort(1, raideur: 320, frein: 24);
  final Ressort _gx = Ressort(0, raideur: 240, frein: 22);
  final Ressort _gy = Ressort(0, raideur: 240, frein: 22);
  // La bouche.
  final Ressort _sourire = Ressort(0.35, raideur: 220, frein: 16);
  final Ressort _ouvre = Ressort(0, raideur: 520, frein: 26);
  final Ressort _rond = Ressort(0, raideur: 260, frein: 18);
  final Ressort _large = Ressort(1, raideur: 220, frein: 16);
  // La tete et le corps.
  final Ressort _teteX = Ressort(0, raideur: 380, frein: 13);
  final Ressort _penche = Ressort(0, raideur: 160, frein: 11);
  final Ressort _ecrase = Ressort(0, raideur: 320, frein: 11);
  final Ressort _rouge = Ressort(0, raideur: 60, frein: 14);
  // La toque : elle se souleve (jamais ne descend), le gland pend.
  final Ressort _toque = Ressort(0, raideur: 240, frein: 9);
  final Ressort _gland = Ressort(0, raideur: 70, frein: 4.5);
  // Les mains, autour du corps (unites du dessin).
  final Ressort _mgx = Ressort(0, raideur: 150, frein: 14);
  final Ressort _mgy = Ressort(0, raideur: 150, frein: 14);
  final Ressort _mdx = Ressort(0, raideur: 150, frein: 14);
  final Ressort _mdy = Ressort(0, raideur: 150, frein: 14);
  // La vie : 1 eveille (il respire, balance les pieds), 0 endormi ou fige.
  final Ressort _vie = Ressort(0, raideur: 30, frein: 9);

  final math.Random _hasard = math.Random(7);
  double _y = 0;
  double _vy = 0;
  double _larme = -1;
  double _clin = 0;
  double _non = -1;
  double _prochainClin = 1.8;
  double _prochainEcart = 2.6;
  double _ecartX = 0;
  double _ecartY = 0;
  double _regardX = 0;
  double _regardY = 0;
  double _sansGeste = 0;
  double _ouvreRepos = 0;
  double _rondRepos = 0;
  bool _chute = false;
  bool _endormi = false;
  int _larmes = 0;
  bool _lance = false;

  /// Il dort (apres [PraxisVivant.veille] secondes sans geste) : plus aucune
  /// image n'est produite.
  bool get endormi => _endormi;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[
    _ouvert,
    _gx,
    _gy,
    _sourire,
    _ouvre,
    _rond,
    _large,
    _teteX,
    _penche,
    _ecrase,
    _rouge,
    _toque,
    _gland,
    _mgx,
    _mgy,
    _mdx,
    _mdy,
    _vie,
  ];

  // Eveille, il ne se tait pas : il respire. Endormi, il se tait des que
  // tout est pose.
  @override
  bool get finiAussi =>
      _endormi && !_chute && _larme < 0 && _clin <= 0 && _non < 0;

  @override
  void initState() {
    super.initState();
    widget.regard?.addListener(_regarder);
    _poserMains(saut: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.tombe && !effetsReduits) {
        _y = -_largeur * 2.2;
        _vy = 0;
        _chute = true;
      }
      _poser(widget.humeur);
    });
  }

  @override
  void didUpdateWidget(PraxisVivant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regard != widget.regard) {
      oldWidget.regard?.removeListener(_regarder);
      widget.regard?.addListener(_regarder);
    }
    final bool pose =
        oldWidget.humeur != widget.humeur || oldWidget.assis != widget.assis;
    if (pose || oldWidget.parle != widget.parle) {
      _sansGeste = 0;
      // Apres la construction : `reveil` redessine.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (pose || _endormi) {
          _poser(widget.humeur);
        } else {
          reveil();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.regard?.removeListener(_regarder);
    super.dispose();
  }

  void _regarder() {
    final RenderObject? b = context.findRenderObject();
    if (b is! RenderBox || !b.attached) return;
    final Offset d =
        widget.regard!.value - b.localToGlobal(b.size.center(Offset.zero));
    final double l = math.max(1, d.distance);
    final double f = math.min(1, l / 260);
    _regardX = d.dx / l * f;
    _regardY = d.dy / l * f;
    _sansGeste = 0;
    if (_endormi) {
      _poser(widget.humeur);
    } else {
      reveil();
    }
  }

  /// Ou vont les mains pour l'humeur [h] : gauche puis droite.
  (Offset, Offset) _mains(HumeurPraxis h) {
    // Assis : posees sur le bord, de part et d'autre du corps. Debout : le
    // long du corps.
    final Offset g = widget.assis
        ? const Offset(29, 163)
        : const Offset(17, 160);
    final Offset d = widget.assis
        ? const Offset(171, 163)
        : const Offset(183, 160);
    return switch (h) {
      HumeurPraxis.heureux => (const Offset(20, 112), const Offset(180, 112)),
      HumeurPraxis.curieux => (g, const Offset(134, 178)),
      HumeurPraxis.gene => (g, const Offset(176, 74)),
      HumeurPraxis.pleure => (const Offset(60, 150), const Offset(146, 150)),
      _ => (g, d),
    };
  }

  void _poserMains({bool saut = false}) {
    final (Offset g, Offset d) = _mains(widget.humeur);
    _mgx.cible = g.dx;
    _mgy.cible = g.dy;
    _mdx.cible = d.dx;
    _mdy.cible = d.dy;
    if (saut) {
      for (final Ressort r in <Ressort>[_mgx, _mgy, _mdx, _mdy]) {
        r.poser();
      }
    }
  }

  void _poser(HumeurPraxis h) {
    _endormi = false;
    double sourire = 0.35;
    double ouvre = 0;
    double rond = 0;
    double large = 1;
    double ouvert = 1;
    double penche = 0;
    switch (h) {
      case HumeurPraxis.calme:
        break;
      case HumeurPraxis.heureux:
        sourire = 1;
        large = 1.15;
        ouvre = 0.35;
      case HumeurPraxis.curieux:
        sourire = 0;
        rond = 0.8;
        ouvre = 0.3;
        penche = 0.12;
      case HumeurPraxis.soucieux:
        sourire = -0.6;
        large = 0.85;
        penche = -0.05;
      case HumeurPraxis.pleure:
        sourire = -0.8;
        large = 0.9;
      case HumeurPraxis.gene:
        sourire = 0.5;
        large = 0.75;
        penche = -0.07;
      case HumeurPraxis.dort:
        ouvert = 0;
        sourire = 0.5;
        large = 0.7;
    }
    _sourire.cible = sourire;
    _ouvreRepos = ouvre;
    _rondRepos = rond;
    _ouvre.cible = ouvre;
    _rond.cible = rond;
    _large.cible = large;
    _ouvert.cible = ouvert;
    _penche.cible = penche;
    _rouge.cible = h == HumeurPraxis.gene ? 1 : 0;
    _vie.cible = h == HumeurPraxis.dort ? 0 : 1;
    _poserMains();
    _gland.v += 5;
    if (h == HumeurPraxis.heureux) _toque.v -= 160;
    if (h == HumeurPraxis.pleure) {
      _larmes = 3;
      _larme = 0;
    }
    reveil();
  }

  void _endormir() {
    _endormi = true;
    _ouvert.cible = 0;
    _vie.cible = 0;
    _ouvre.cible = 0;
    _rond.cible = 0;
    _gx.cible = 0;
    _gy.cible = 0;
    _ecartX = 0;
    _ecartY = 0;
  }

  /// Un clin des deux yeux.
  void cligner() {
    _clin = 1;
    _sansGeste = 0;
    reveil();
  }

  /// Il dit « non » de la tete, puis revient au centre.
  void non() {
    _non = 0;
    _sansGeste = 0;
    reveil();
  }

  @override
  void surPoseSansMouvement() {
    _y = 0;
    _vy = 0;
    _chute = false;
    _larme = -1;
    _larmes = 0;
    _clin = 0;
    _non = -1;
    _endormi = false;
    // Fige : ni souffle ni balancement ; les yeux gardent leur dessin.
    _vie
      ..cible = 0
      ..poser();
    _teteX
      ..cible = 0
      ..poser();
  }

  @override
  void surPas(double dt) {
    if (_chute) {
      _vy += 2600 * dt;
      _y += _vy * dt;
      if (_y >= 0) {
        _y = 0;
        _ecrase.v += _vy * 0.004;
        _gland.v += _vy * 0.012;
        _toque.v -= _vy * 0.22;
        _vy = -_vy * 0.42;
        if (_vy.abs() < 60) {
          _vy = 0;
          _chute = false;
        }
      }
    }
    if (_non >= 0) {
      // Cinq poses de 0,13 s : gauche, droite, gauche, droite, centre.
      const List<double> poses = <double>[-1, 1, -0.7, 0.7, 0];
      _non += dt;
      final int rang = (_non / 0.13).floor();
      if (rang >= poses.length) {
        _teteX.cible = 0;
        _non = -1;
      } else {
        _teteX.cible = poses[rang];
      }
    }
    _gland.cible = -_teteX.v * 0.02 - _gx.v * 0.6;
    if (_clin > 0) _clin = math.max(0, _clin - dt * 7.5);
    if (_larme >= 0) {
      _larme += dt * 0.95;
      if (_larme > 1.3) {
        _larmes--;
        _larme = _larmes > 0 ? 0 : -1;
      }
    }
    if (_endormi) return;
    final bool sommeil = widget.humeur == HumeurPraxis.dort;
    // Vingt secondes sans geste : il s'endort, puis tout se tait.
    _sansGeste += dt;
    if (_sansGeste > PraxisVivant.veille || (sommeil && _vie.x < 0.02)) {
      _endormir();
      return;
    }
    if (sommeil) return;
    // Des clins irreguliers, parfois doubles.
    _prochainClin -= dt;
    if (_prochainClin <= 0) {
      _clin = 1;
      _prochainClin = _hasard.nextDouble() < 0.18
          ? 0.26
          : 1.6 + _hasard.nextDouble() * 4.2;
    }
    // Le regard : le pointeur, plus de petits ecarts d'attente.
    _prochainEcart -= dt;
    if (_prochainEcart <= 0) {
      final bool part = _ecartX == 0 && _ecartY == 0;
      _ecartX = part ? (_hasard.nextDouble() - 0.5) * 0.5 : 0;
      _ecartY = part ? (_hasard.nextDouble() - 0.5) * 0.3 : 0;
      _prochainEcart = part
          ? 0.5 + _hasard.nextDouble() * 0.9
          : 2.4 + _hasard.nextDouble() * 3.6;
    }
    _gx.cible = (_regardX + _ecartX).clamp(-1, 1);
    _gy.cible = (_regardY + _ecartY).clamp(-1, 1);
    // La bouche bat pendant qu'il parle.
    if (widget.parle) {
      _ouvre.cible =
          0.22 +
          0.55 *
              (0.5 + 0.5 * math.sin(temps * 17 + math.sin(temps * 5.3) * 2))
                  .abs();
      _rond.cible = 0.15 + 0.2 * math.sin(temps * 6).abs();
    } else {
      _ouvre.cible = _ouvreRepos;
      _rond.cible = _rondRepos;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ses couleurs propres, les memes dans les deux themes.
    final AppPalette propre = AppPalette.claire();
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.taille,
        height: PraxisVivant.hauteurPour(widget.taille),
        child: CustomPaint(
          painter: _PeintrePraxis(
            this,
            corps: propre.surfaceActionDouce.background,
            encre: propre.surfaceActionDouce.onBackground,
            reflet: propre.surfaceRaised.background,
            rose: propre.surfaceAlert.background,
            // La larme : l'accent du theme (lavande en sombre, jamais le
            // violet sur fond sombre).
            eau: palette.surfacePrimary.background,
          ),
        ),
      ),
    );
  }
}

class _PeintrePraxis extends CustomPainter {
  _PeintrePraxis(
    this.s, {
    required this.corps,
    required this.encre,
    required this.reflet,
    required this.rose,
    required this.eau,
  });

  final EtatPraxisVivant s;
  final Color corps;
  final Color encre;
  final Color reflet;
  final Color rose;
  final Color eau;

  /// Une boule en volume : un seul degrade, la lumiere vient d'en haut a
  /// gauche. La valeur seule change, du lilas clair au lilas ombre.
  void _boule(Canvas c, Offset o, double rx, double ry, Color base) {
    final Color clair = Color.lerp(base, reflet, 0.34)!;
    final Color mi = Color.lerp(base, encre, 0.10)!;
    final Color ombre = Color.lerp(base, encre, 0.24)!;
    c
      ..save()
      ..translate(o.dx, o.dy)
      ..scale(rx, ry)
      ..drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(-0.24, -0.40),
            1.78,
            <Color>[
              clair,
              Color.lerp(clair, base, 0.6)!,
              base,
              Color.lerp(base, mi, 0.6)!,
              mi,
              ombre,
            ],
            const <double>[0, 0.2, 0.40, 0.58, 0.76, 1],
          ),
      )
      ..restore();
  }

  @override
  void paint(Canvas c, Size t) {
    final double u = t.width / _largeur;
    final bool assis = s.widget.assis;
    final double vie = s._vie.x.clamp(0, 1);
    final double e = s._ecrase.x.clamp(-0.3, 0.3) + (assis ? 0.03 : 0);
    final double souffle = 1 + math.sin(s.temps * 2.1) * 0.012 * vie;
    final double dxTete = s._teteX.x * 14;
    final Paint noir = Paint()..color = encre;
    final Paint trait = Paint()
      ..color = encre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final Color pied = Color.lerp(corps, encre, 0.26)!;

    c
      ..save()
      ..scale(u)
      ..translate(0, s._y);

    // ───── Les pieds, derriere le corps ─────
    for (int i = 0; i < 2; i++) {
      final double cote = i == 0 ? -1 : 1;
      if (assis) {
        // Ils pendent sous le bord et se balancent, l'un apres l'autre.
        final double b = math.sin(s.temps * 1.7 + i * math.pi) * vie;
        final Offset hanche = Offset(100 + cote * 24, 186);
        final Offset p = Offset(100 + cote * 29 + b * 5, 208 - b.abs() * 2);
        c
          ..drawLine(
            hanche,
            p,
            Paint()
              ..color = pied
              ..strokeWidth = 10
              ..strokeCap = StrokeCap.round,
          )
          ..save()
          ..translate(p.dx, p.dy)
          ..rotate(-b * 0.22);
        _boule(c, Offset(cote * 2, 2), 15, 10.5, pied);
        c.restore();
      } else {
        _boule(c, Offset(100 + cote * 30, 197), 17, 7.5, pied);
      }
    }

    // ───── Le corps : ecrase au contact, qui respire ─────
    c
      ..save()
      ..translate(100 + dxTete, _sol)
      ..rotate(s._penche.x)
      ..scale(1 + e, (1 - e) * souffle)
      ..translate(-100, -_sol);
    _boule(c, _centre, _rayon, _rayon, corps);

    final Path disque = Path()
      ..addOval(Rect.fromCircle(center: _centre, radius: _rayon));
    c
      ..save()
      ..clipPath(disque);
    // Les joues.
    if (s._rouge.x > 0.01) {
      for (final double x in <double>[56, 148]) {
        c.drawCircle(
          Offset(x, 152),
          30,
          Paint()
            ..shader = ui.Gradient.radial(Offset(x, 152), 30, <Color>[
              rose.withValues(alpha: (0.5 * s._rouge.x).clamp(0, 1)),
              rose.withValues(alpha: 0),
            ]),
        );
      }
    }
    // Le visage suit un peu le regard.
    c
      ..save()
      ..translate(s._gx.x * 5, s._gy.x * 3);
    // Les yeux : le dessin d'origine, trait pour trait. Ils clignent et se
    // ferment le long de leur propre forme.
    final double clin = s._clin > 0
        ? math.sin(s._clin.clamp(0, 1) * math.pi)
        : 0;
    final double ouv = math.max(
      0.085,
      s._ouvert.x.clamp(0, 1.1) * (1 - clin * 0.93),
    );
    for (int i = 0; i < 2; i++) {
      c
        ..save()
        ..translate(i == 0 ? 84 : 122, 128)
        ..save()
        ..scale(1, ouv)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: 26, height: 36),
          noir,
        )
        ..restore();
      // La pupille disparait quand la paupiere passe.
      final double vue = ((ouv - 0.42) / 0.2).clamp(0, 1);
      if (vue > 0.01) {
        c.drawCircle(
          Offset(s._gx.x * 5.5, s._gy.x * 5.5 * ouv),
          6 * math.min(1, 0.55 + 0.45 * vue),
          Paint()..color = reflet.withValues(alpha: vue),
        );
      }
      c.restore();
    }
    // La bouche : fermee en trait, ouverte en forme pleine, ronde quand il
    // s'etonne.
    final double ro = s._rond.x.clamp(0, 1);
    final double ou = s._ouvre.x.clamp(0, 1.2);
    final double w = (34 * s._large.x) * (1 - ro) + (14 + 10 * ou) * ro;
    final double sm = s._sourire.x * 8.5 * (1 - ro);
    c
      ..save()
      ..translate(103, 163);
    if (ou < 0.06) {
      c.drawPath(
        Path()
          ..moveTo(-w / 2, -sm * 0.6)
          ..quadraticBezierTo(0, sm * 1.5, w / 2, -sm * 0.6),
        trait,
      );
    } else {
      final double h = 19 * ou;
      final double coin = -sm * 0.6;
      final double kx = 0.6 + 0.4 * ro;
      final double ky = 0.15 + 0.45 * ro;
      c.drawPath(
        Path()
          ..moveTo(-w / 2, coin)
          ..cubicTo(
            -w / 2 * kx,
            coin - h * ky,
            w / 2 * kx,
            coin - h * ky,
            w / 2,
            coin,
          )
          ..cubicTo(
            w / 2 * (0.9 + 0.1 * ro),
            coin + sm + h * (0.9 + 0.1 * ro),
            -w / 2 * (0.9 + 0.1 * ro),
            coin + sm + h * (0.9 + 0.1 * ro),
            -w / 2,
            coin,
          )
          ..close(),
        noir,
      );
    }
    c
      ..restore()
      ..restore();

    // ───── La toque : posee sur le crane, au-dessus des yeux ─────
    // Elle se souleve (un saut, une joie), jamais elle ne descend.
    final double leve = math.min(0, s._toque.x) * 0.7;
    c
      ..save()
      ..translate(0, leve);
    // La calotte epouse le haut du crane : son bord avant, puis la silhouette.
    const List<Offset> bord = <Offset>[
      Offset(37.8, 48.8),
      Offset(36.1, 52.4),
      Offset(38, 56.2),
      Offset(43.7, 59.4),
      Offset(52.8, 61.8),
      Offset(64.6, 63.1),
      Offset(78.5, 63.3),
      Offset(93.4, 62.4),
      Offset(108.3, 60.5),
      Offset(122.2, 57.6),
      Offset(134.2, 54),
      Offset(143.4, 50),
      Offset(149.2, 45.7),
      Offset(151.2, 41.5),
      Offset(149.8, 38.6),
    ];
    final Path calotte = Path()..moveTo(bord.first.dx, bord.first.dy);
    for (final Offset p in bord.skip(1)) {
      calotte.lineTo(p.dx, p.dy);
    }
    calotte
      ..arcToPoint(
        bord.first,
        radius: const Radius.circular(_rayon + 2),
        clockwise: false,
      )
      ..close();
    c
      ..drawPath(calotte, noir)
      ..restore()
      ..restore(); // fin du masque du disque

    // Le plateau : la tranche (encre), puis le dessus (lilas), le cordon et
    // le gland qui pend du coin de fin.
    c
      ..save()
      ..translate(0, leve);
    const List<Offset> coins = <Offset>[
      Offset(161.1, 21.2),
      Offset(75.3, 43.9),
      Offset(21.4, 26),
      Offset(107.2, 3.3),
    ];
    const Offset epaisseur = Offset(0.7, 6.7);
    final Path dessous = Path()
      ..addPolygon(<Offset>[for (final Offset o in coins) o + epaisseur], true);
    final Path dessus = Path()..addPolygon(coins, true);
    const Offset sommet = Offset(91.3, 23.6);
    c
      ..drawPath(dessous, noir)
      ..drawPath(dessous, trait)
      ..drawPath(
        dessus,
        Paint()
          ..shader = ui.Gradient.linear(
            coins[3],
            coins[1],
            <Color>[
              Color.lerp(corps, reflet, 0.4)!,
              corps,
              Color.lerp(corps, encre, 0.08)!,
            ],
            const <double>[0, 0.55, 1],
          ),
      )
      ..drawPath(dessus, trait)
      ..drawLine(sommet, Offset.lerp(sommet, coins[0], 0.94)!, trait)
      ..drawCircle(sommet, 4.2, noir)
      ..save()
      ..translate(coins[0].dx, coins[0].dy)
      ..rotate(s._gland.x.clamp(-1.2, 1.2))
      ..drawLine(Offset.zero, const Offset(0, 19), trait)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, 17, 12, 19),
          const Radius.circular(2.5),
        ),
        noir,
      )
      ..restore()
      ..restore()
      ..restore(); // fin du corps

    // ───── Les mains, devant le corps ─────
    final double respire = math.sin(s.temps * 2.1) * 1.5 * vie;
    for (final Offset m in <Offset>[
      Offset(s._mgx.x, s._mgy.x + (assis ? 0 : respire)),
      Offset(s._mdx.x, s._mdy.x + (assis ? 0 : respire)),
    ]) {
      // L'ombre de contact de la main sur le corps.
      if ((m - _centre).distance < _rayon + 6) {
        c.drawCircle(
          m + const Offset(2, 4),
          17,
          Paint()..color = encre.withValues(alpha: 0.14),
        );
      }
      _boule(c, m, 15, 15, corps);
    }

    // ───── Les larmes : elles quittent les yeux, coulent, tombent plus bas
    // et eclaboussent ─────
    if (s._larme >= 0) {
      final Paint goutte = Paint()..color = eau;
      for (final double x in <double>[84, 122]) {
        final double cote = x < 100 ? -1 : 1;
        final double xx = x + dxTete;
        if (s._larme < 1) {
          final double k = s._larme;
          final Offset p = Offset(
            xx + cote * 7 * math.sin(k * math.pi * 0.5),
            144 + 62 * k * k,
          );
          c.drawPath(
            Path()
              ..moveTo(p.dx, p.dy - 9)
              ..quadraticBezierTo(p.dx + 5.5, p.dy, p.dx, p.dy + 5)
              ..quadraticBezierTo(p.dx - 5.5, p.dy, p.dx, p.dy - 9),
            goutte,
          );
        } else {
          final double k = ((s._larme - 1) / 0.3).clamp(0, 1);
          for (int i = -1; i <= 1; i++) {
            c.drawCircle(
              Offset(
                xx + cote * 7 + i * 10 * k,
                212 - 12 * math.sin(k * math.pi),
              ),
              2.6 * (1 - k),
              goutte,
            );
          }
        }
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_PeintrePraxis ancien) => true;
}
