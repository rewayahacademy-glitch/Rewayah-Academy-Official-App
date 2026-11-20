// VIVANT : Praxis, dessine pour etre anime (directeur, 20/11/2026 ; amende
// `assets/brand/praxis/README.md` : l'image fixe reste celle des messages).
//
// Un seul dessin (`CustomPainter`), des ressorts pour les paupieres, le
// regard, la tete, la corde du bonnet ; une chute, un « non », des larmes.
// Il bouge quand on le lui demande, se pose, puis se tait.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_palette.dart';
import 'ressort.dart';

/// Les humeurs de Praxis.
enum HumeurPraxis {
  /// Au repos.
  calme,

  /// Content : rien ne bloque.
  heureux,

  /// Un oeil plus grand que l'autre, la tete penchee.
  curieux,

  /// Un blocage a signaler.
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
    this.regard,
  });

  /// Son humeur ; la changer l'anime.
  final HumeurPraxis humeur;

  /// Sa largeur ; sa hauteur vaut 1,18 fois sa largeur.
  final double taille;

  /// Il arrive en tombant et rebondit, une fois.
  final bool tombe;

  /// La position du pointeur (coordonnees globales) qu'il suit des yeux.
  final ValueListenable<Offset>? regard;

  @override
  State<PraxisVivant> createState() => EtatPraxisVivant();
}

/// L'etat de Praxis : ses gestes ([non], [cligner]) s'appellent par une cle.
class EtatPraxisVivant extends State<PraxisVivant>
    with SingleTickerProviderStateMixin<PraxisVivant>, VieDesRessorts {
  final List<Ressort> _haut = <Ressort>[Ressort(0), Ressort(0)];
  final List<Ressort> _pente = <Ressort>[Ressort(0), Ressort(0)];
  final List<Ressort> _bas = <Ressort>[Ressort(0), Ressort(0)];
  final List<Ressort> _oeil = <Ressort>[Ressort(1), Ressort(1)];
  final Ressort _gx = Ressort(0, raideur: 300, frein: 26);
  final Ressort _gy = Ressort(0, raideur: 300, frein: 26);
  final Ressort _teteX = Ressort(0, raideur: 380, frein: 13);
  final Ressort _penche = Ressort(0, raideur: 160, frein: 11);
  final Ressort _ecrase = Ressort(0, raideur: 320, frein: 11);
  final Ressort _corde = Ressort(0, raideur: 70, frein: 4.5);
  final Ressort _rouge = Ressort(0, raideur: 60, frein: 14);
  double _y = 0;
  double _vy = 0;
  double _larme = -1;
  double _clin = 0;
  double _non = -1;
  bool _chute = false;
  int _larmes = 0;
  bool _lance = false;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[
    ..._haut,
    ..._pente,
    ..._bas,
    ..._oeil,
    _gx,
    _gy,
    _teteX,
    _penche,
    _ecrase,
    _corde,
    _rouge,
  ];

  @override
  bool get finiAussi => !_chute && _larme < 0 && _clin <= 0 && _non < 0;

  @override
  void initState() {
    super.initState();
    widget.regard?.addListener(_regarder);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.tombe && !effetsReduits) {
        _y = -widget.taille * 2.2;
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
    if (oldWidget.humeur != widget.humeur) _poser(widget.humeur);
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
    _gx.cible = d.dx / l * f;
    _gy.cible = d.dy / l * f;
    reveil();
  }

  void _poser(HumeurPraxis h) {
    for (int i = 0; i < 2; i++) {
      final double s = i == 0 ? -1 : 1;
      double ph = 0;
      double pe = 0;
      double pb = 0;
      double ta = 1;
      switch (h) {
        case HumeurPraxis.calme:
          break;
        case HumeurPraxis.heureux:
          pb = 0.52;
        case HumeurPraxis.curieux:
          ta = i == 0 ? 1.22 : 0.9;
          ph = i == 0 ? 0 : 0.22;
        case HumeurPraxis.soucieux:
          ph = 0.36;
          pe = 0.3 * s;
        case HumeurPraxis.pleure:
          ph = 0.4;
          pe = 0.34 * s;
        case HumeurPraxis.gene:
          ph = 0.3;
        case HumeurPraxis.dort:
          ph = 1.1;
      }
      _haut[i].cible = ph;
      _pente[i].cible = pe;
      _bas[i].cible = pb;
      _oeil[i].cible = ta;
    }
    _penche.cible = h == HumeurPraxis.curieux ? 0.12 : 0;
    _rouge.cible = h == HumeurPraxis.gene ? 1 : 0;
    _corde.v += 5;
    if (h == HumeurPraxis.pleure) {
      _larmes = 3;
      _larme = 0;
    }
    reveil();
  }

  /// Un clin des deux yeux.
  void cligner() {
    _clin = 1;
    reveil();
  }

  /// Il dit « non » de la tete, puis revient au centre.
  void non() {
    _non = 0;
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
        _corde.v += _vy * 0.012;
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
    _corde.cible = -_teteX.v * 0.02 - _gx.v * 0.6;
    if (_clin > 0) _clin -= dt * 6;
    if (_larme >= 0) {
      _larme += dt * 0.95;
      if (_larme > 1.3) {
        _larmes--;
        _larme = _larmes > 0 ? 0 : -1;
      }
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
        height: widget.taille * 1.18,
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

  @override
  void paint(Canvas c, Size t) {
    final double u = t.width / 200;
    c
      ..save()
      ..translate(0, t.height - 200 * u)
      ..scale(u);
    final double e = s._ecrase.x.clamp(-0.35, 0.35);
    final double dxTete = s._teteX.x * 14;
    c
      ..save()
      ..translate(100 + dxTete, 194 + s._y)
      ..rotate(s._penche.x)
      ..scale(1 + e, 1 - e)
      ..translate(-100, -194)
      ..drawCircle(const Offset(100, 108), 86, Paint()..color = corps);
    if (s._rouge.x > 0.01) {
      for (final double x in <double>[56, 148]) {
        c.drawCircle(
          Offset(x, 150),
          30,
          Paint()
            ..shader = ui.Gradient.radial(Offset(x, 150), 30, <Color>[
              rose.withValues(alpha: (0.5 * s._rouge.x).clamp(0, 1)),
              rose.withValues(alpha: 0),
            ]),
        );
      }
    }
    c.translate(s._gx.x * 5, s._gy.x * 3);
    final Paint noir = Paint()..color = encre;
    final Paint trait = Paint()
      ..color = encre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Le bonnet : la calotte, le plateau, la corde et son gland.
    c.drawPath(
      Path()
        ..moveTo(61, 79)
        ..lineTo(96, 78)
        ..lineTo(128, 63)
        ..lineTo(135, 95)
        ..quadraticBezierTo(101, 60, 67, 110)
        ..close(),
      noir,
    );
    final Path plateau = Path()
      ..moveTo(41, 76)
      ..lineTo(90, 51)
      ..lineTo(146, 53)
      ..lineTo(96, 78)
      ..close();
    c
      ..drawPath(plateau, Paint()..color = corps)
      ..drawPath(plateau, trait)
      ..drawLine(const Offset(93, 65), const Offset(138, 57), trait)
      ..save()
      ..translate(139, 56)
      ..rotate(s._corde.x.clamp(-1.2, 1.2))
      ..drawLine(Offset.zero, const Offset(3, 13), trait)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, 12, 12, 19),
          const Radius.circular(2),
        ),
        noir,
      )
      ..restore();
    final double clin = s._clin > 0
        ? math.sin(s._clin.clamp(0, 1) * math.pi)
        : 0;
    for (int i = 0; i < 2; i++) {
      c
        ..save()
        ..translate(i == 0 ? 84 : 122, 128)
        ..scale(s._oeil[i].x);
      final Rect oeil = Rect.fromCenter(
        center: Offset.zero,
        width: 26,
        height: 36,
      );
      final double ph = math.max(s._haut[i].x, clin * 1.1);
      if (ph > 1.0) {
        c.drawPath(
          Path()
            ..moveTo(-11, 3)
            ..quadraticBezierTo(0, 11, 11, 3),
          trait,
        );
      } else {
        final Paint peau = Paint()..color = corps;
        c
          ..save()
          ..clipPath(Path()..addOval(oeil))
          ..drawOval(oeil, noir)
          ..drawCircle(
            Offset(s._gx.x * 5.5, s._gy.x * 5.5 - s._bas[i].x * 9),
            6,
            Paint()..color = reflet,
          )
          ..save()
          ..rotate(s._pente[i].x)
          ..drawRect(Rect.fromLTWH(-30, -64 + ph * 38, 60, 46), peau)
          ..restore()
          ..drawCircle(Offset(0, 46 - s._bas[i].x * 36), 26, peau)
          ..restore();
      }
      c.restore();
    }
    c.restore();
    // Les larmes quittent les yeux, coulent le long du visage, tombent plus
    // bas et eclaboussent.
    if (s._larme >= 0) {
      final Paint goutte = Paint()..color = eau;
      for (final double x in <double>[84, 122]) {
        final double cote = x < 100 ? -1 : 1;
        final double xx = x + dxTete;
        if (s._larme < 1) {
          final double k = s._larme;
          final Offset p = Offset(
            xx + cote * 7 * math.sin(k * math.pi * 0.5),
            144 + 84 * k * k,
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
                230 - 12 * math.sin(k * math.pi),
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
