// VIVANT : une pile de cartes qu'on feuillette du doigt.
//
// La carte du dessus suit le doigt, penche, puis part si on la lache assez
// loin ou assez vite ; elle passe sous la pile et la suivante monte en
// ressort. Lachee trop pres, elle revient. Feuilleter ne decide rien : c'est
// la carte, touchee, qui ouvre son objet (contrat de navigation §2).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'ressort.dart';

/// Une pile de [nombre] cartes ; trois se voient, celle du dessus se glisse.
class PileFeuilletee extends StatefulWidget {
  /// Cree la pile.
  const PileFeuilletee({
    required this.nombre,
    required this.constructeur,
    super.key,
    this.onDessus,
    this.debord = 24,
  });

  /// Le nombre de cartes.
  final int nombre;

  /// Construit la carte de rang [index] ; [dessus] : c'est celle qui se
  /// touche (les autres, dessous, sont un decor).
  final Widget Function(BuildContext context, int index, {required bool dessus})
  constructeur;

  /// Appele quand la carte du dessus change.
  final ValueChanged<int>? onDessus;

  /// La place gardee en haut et au bord de fin pour les cartes du dessous.
  final double debord;

  /// La distance (en points) au-dela de laquelle une carte lachee part.
  static const double seuil = 110;

  /// La vitesse (points par seconde) au-dela de laquelle elle part aussi.
  static const double elan = 700;

  @override
  State<PileFeuilletee> createState() => EtatPileFeuilletee();
}

/// L'etat de la pile : [suivante] et [precedente] s'appellent par une cle.
class EtatPileFeuilletee extends State<PileFeuilletee>
    with SingleTickerProviderStateMixin<PileFeuilletee>, VieDesRessorts {
  final Ressort _dx = Ressort(0, raideur: 240, frein: 17);
  final Ressort _saut = Ressort(0, raideur: 260, frein: 9);
  // Le rang des cartes pendant un passage : 1 (elles viennent d'un rang plus
  // bas), -1 (d'un rang plus haut), 0 au repos.
  final Ressort _rang = Ressort(0, raideur: 200, frein: 16);
  int _dessus = 0;
  int _part = 0;

  // La largeur d'une carte, mesuree au moment du geste (jamais pendant la
  // construction : la pile vit dans des rangs a hauteur intrinseque).
  double _largeur = 300;

  void _mesurer() => _largeur = math.max(120, context.size?.width ?? 300);

  /// Le rang de la carte du dessus.
  int get dessus => _dessus;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_dx, _saut, _rang];

  @override
  bool get finiAussi => _part == 0;

  @override
  void didUpdateWidget(PileFeuilletee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nombre <= 0) {
      _dessus = 0;
    } else if (_dessus >= widget.nombre) {
      _dessus = widget.nombre - 1;
    }
  }

  void _arriver() {
    _part = 0;
    _dessus = (_dessus + 1) % widget.nombre;
    _dx
      ..x = 0
      ..v = 0
      ..cible = 0
      ..raideur = 240;
    _rang
      ..x = 1
      ..v = 0
      ..cible = 0;
    _saut.v += 3.2;
    widget.onDessus?.call(_dessus);
  }

  void _partir(int sens) {
    if (_part != 0 || widget.nombre < 2) return;
    _mesurer();
    _part = sens;
    _dx
      ..cible = sens * _largeur * 1.5
      ..raideur = 120;
    reveil();
  }

  /// La carte du dessus passe sous la pile, la suivante monte.
  void suivante() =>
      _partir(Directionality.of(context) == TextDirection.rtl ? 1 : -1);

  /// La carte passee revient sur le dessus.
  void precedente() {
    if (_part != 0 || widget.nombre < 2) return;
    final int sens = Directionality.of(context) == TextDirection.rtl ? 1 : -1;
    _mesurer();
    _dessus = (_dessus - 1 + widget.nombre) % widget.nombre;
    _dx
      ..x = sens * _largeur * 1.2
      ..v = 0
      ..cible = 0
      ..raideur = 240;
    _rang
      ..x = -1
      ..v = 0
      ..cible = 0;
    widget.onDessus?.call(_dessus);
    reveil();
  }

  @override
  void surPoseSansMouvement() {
    if (_part != 0) _arriver();
    _rang.poser();
    _dx.poser();
    _saut
      ..v = 0
      ..poser();
  }

  @override
  void surPas(double dt) {
    if (_part != 0 && _dx.x.abs() >= _largeur * 1.2) _arriver();
  }

  void _glisse(DragUpdateDetails d) {
    if (_part != 0) return;
    _mesurer();
    _dx
      ..x += d.delta.dx
      ..cible = _dx.x
      ..v = 0;
    setState(() {});
  }

  void _lache(DragEndDetails d) {
    if (_part != 0) return;
    final double v = d.velocity.pixelsPerSecond.dx;
    if (widget.nombre > 1 &&
        (_dx.x.abs() > PileFeuilletee.seuil || v.abs() > PileFeuilletee.elan)) {
      _partir(_dx.x + v * 0.1 > 0 ? 1 : -1);
    } else {
      _dx
        ..cible = 0
        ..v = v;
      reveil();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int n = widget.nombre;
    if (n <= 0) return const SizedBox.shrink();
    final double sensFin = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    final double penche = (_dx.x / (_largeur * 1.5)).clamp(-1, 1);
    // Une carte de dessous, au rang [r] (1 ou 2, fractionnaire en passage).
    Widget dessous(int index, double r) {
      final double rr = r.clamp(0, 3);
      return Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: FractionalTranslation(
              translation: Offset(0.04 * rr * sensFin, -0.055 * rr),
              child: Transform.rotate(
                angle: 0.05 * rr * (index.isOdd ? 1 : -1),
                child: Transform.scale(
                  scale: 1 - 0.06 * rr,
                  child: Opacity(
                    opacity: (1 - 0.18 * rr).clamp(0, 1),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topCenter,
                        maxHeight: double.infinity,
                        child: widget.constructeur(
                          context,
                          index,
                          dessus: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final double passage = _rang.x;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: widget.debord,
        end: widget.debord,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = math.min(2, n - 1); i >= 1; i--)
            dessous((_dessus + i) % n, i + passage),
          Transform.translate(
            offset: Offset(_dx.x, -_saut.x * 10 + penche.abs() * 10),
            child: Transform.rotate(
              angle: penche * 0.32,
              child: Transform.scale(
                // Elle monte du rang d'en dessous.
                scale: 1 - 0.06 * passage.clamp(0, 1),
                child: GestureDetector(
                  onHorizontalDragUpdate: _glisse,
                  onHorizontalDragEnd: _lache,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_dessus),
                    child: widget.constructeur(context, _dessus, dessus: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
