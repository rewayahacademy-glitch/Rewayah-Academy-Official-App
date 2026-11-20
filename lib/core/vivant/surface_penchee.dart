// VIVANT : une surface qui penche vers le pointeur au survol.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'ressort.dart';

/// Penche son contenu vers le pointeur, puis le redresse en ressort.
///
/// Souris seulement : au doigt, rien ne survole, donc rien ne penche. Une
/// transformation seule, sans flou ni ombre animee.
class SurfacePenchee extends StatefulWidget {
  /// Cree la surface.
  const SurfacePenchee({required this.child, super.key, this.force = 0.03});

  /// Ce qui penche.
  final Widget child;

  /// L'angle au bord, en radians.
  final double force;

  @override
  State<SurfacePenchee> createState() => _EtatSurfacePenchee();
}

class _EtatSurfacePenchee extends State<SurfacePenchee>
    with SingleTickerProviderStateMixin<SurfacePenchee>, VieDesRessorts {
  final Ressort _rx = Ressort(0, raideur: 160, frein: 14);
  final Ressort _ry = Ressort(0, raideur: 160, frein: 14);
  final Ressort _haut = Ressort(0, raideur: 200, frein: 18);

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_rx, _ry, _haut];

  void _survol(PointerHoverEvent e) {
    final Size s = context.size ?? const Size(1, 1);
    _ry.cible = (e.localPosition.dx / s.width - 0.5) * widget.force * 2;
    _rx.cible = -(e.localPosition.dy / s.height - 0.5) * widget.force * 2;
    _haut.cible = 1;
    reveil();
  }

  void _sortie(PointerExitEvent _) {
    _rx.cible = 0;
    _ry.cible = 0;
    _haut.cible = 0;
    reveil();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onHover: _survol,
    onExit: _sortie,
    child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(_rx.x)
        ..rotateY(_ry.x)
        ..translateByDouble(0, -4 * _haut.x, 0, 1),
      child: widget.child,
    ),
  );
}
