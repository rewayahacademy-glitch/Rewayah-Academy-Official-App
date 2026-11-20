// VIVANT : tout ce qui se touche s'enfonce sous le doigt et revient en ressort.
import 'package:flutter/widgets.dart';

import '../widgets/pressable.dart';
import 'ressort.dart';

/// Une surface qui se touche : elle s'enfonce a l'appui, se souleve a peine au
/// survol, et revient en depassant un peu.
///
/// Le toucher lui-meme reste celui de [Pressable] (cible, focus, clavier,
/// lecteur d'ecran) : ce composant n'ajoute que le ressort.
class ToucherVivant extends StatefulWidget {
  /// Cree la surface.
  const ToucherVivant({
    required this.child,
    required this.onPress,
    super.key,
    this.libelleSemantique,
    this.arrondiFocus,
    this.enfoncement = 0.96,
  });

  /// Ce qui s'enfonce.
  final Widget child;

  /// Le geste.
  final VoidCallback? onPress;

  /// Ce que lit le lecteur d'ecran.
  final String? libelleSemantique;

  /// L'arrondi de l'anneau de focus.
  final BorderRadius? arrondiFocus;

  /// L'echelle au fond de l'appui.
  final double enfoncement;

  @override
  State<ToucherVivant> createState() => _EtatToucherVivant();
}

class _EtatToucherVivant extends State<ToucherVivant>
    with SingleTickerProviderStateMixin<ToucherVivant>, VieDesRessorts {
  final Ressort _echelle = Ressort(1, raideur: 420, frein: 14);

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_echelle];

  void _vers(double cible) {
    if (_echelle.cible == cible) return;
    _echelle.cible = cible;
    WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
  }

  @override
  Widget build(BuildContext context) => Pressable.selon(
    onPress: widget.onPress,
    libelleSemantique: widget.libelleSemantique,
    arrondiFocus: widget.arrondiFocus,
    respecterCibleTactile: false,
    constructeur: (BuildContext context, EtatPression etat) {
      _vers(
        etat.presse
            ? widget.enfoncement
            : etat.survole
            ? 1.015
            : 1,
      );
      return Transform.scale(scale: _echelle.x, child: widget.child);
    },
  );
}
