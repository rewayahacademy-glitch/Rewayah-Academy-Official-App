// VIVANT : le niveau d'eau d'une case. Le seul mouvement qui dure : une
// surface d'eau respire tant qu'elle est a l'ecran.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'ressort.dart';

/// Remplit son cadre d'eau jusqu'a [niveau] (0 vide, 1 plein).
///
/// Le niveau monte en ressort ; la surface ondule doucement. Sous « Reduire
/// les effets », l'eau est posee a son niveau, immobile. Un dessin simple
/// (deux traces pleins), sans flou. A poser dans un cadre deja decoupe.
class NiveauEau extends StatefulWidget {
  /// Cree le niveau.
  const NiveauEau({required this.niveau, required this.couleur, super.key});

  /// La part remplie, de 0 a 1.
  final double niveau;

  /// La couleur de l'eau.
  final Color couleur;

  @override
  State<NiveauEau> createState() => _EtatNiveauEau();
}

class _EtatNiveauEau extends State<NiveauEau>
    with SingleTickerProviderStateMixin<NiveauEau>, VieDesRessorts {
  final Ressort _niveau = Ressort(0, raideur: 22, frein: 6);
  bool _lance = false;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_niveau];

  @override
  bool get toujours => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_lance) {
      _lance = true;
      _niveau.cible = widget.niveau.clamp(0, 1);
      WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
    }
  }

  @override
  void didUpdateWidget(NiveauEau ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.niveau != widget.niveau) {
      _niveau.cible = widget.niveau.clamp(0, 1);
      reveil();
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PeintreEau(_niveau.x.clamp(0, 1), temps, widget.couleur),
      child: const SizedBox.expand(),
    ),
  );
}

class _PeintreEau extends CustomPainter {
  _PeintreEau(this.niveau, this.temps, this.couleur);

  final double niveau;
  final double temps;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size s) {
    if (niveau <= 0) return;
    final double y0 = s.height * (1 - niveau);
    Path vague(double phase, double ampleur, double dy) {
      final Path p = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width + 6; x += 6) {
        p.lineTo(
          x,
          y0 +
              dy +
              math.sin(x / 90 + phase) * ampleur +
              math.sin(x / 37 - phase * 1.4) * ampleur * 0.4,
        );
      }
      return p
        ..lineTo(s.width, s.height)
        ..close();
    }

    canvas
      ..drawPath(
        vague(temps * 0.9, 4, -5),
        Paint()..color = couleur.withValues(alpha: couleur.a * 0.35),
      )
      ..drawPath(vague(-temps * 1.3, 3, 0), Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintreEau ancien) =>
      ancien.niveau != niveau ||
      ancien.temps != temps ||
      ancien.couleur != couleur;
}
