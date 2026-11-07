import 'package:flutter/material.dart';

/// Le seul `SelectionArea` de l'application (directeur, 07/11/2026) : tout le
/// texte se sélectionne et se copie, sans le déclarer écran par écran.
///
/// Posé une fois, dans le `builder` de `MaterialApp` (`RewayahApp`). À cet
/// endroit aucun `Overlay` n'existe encore au-dessus (celui du `Navigator` est
/// dans [child]) : le menu « Copier » n'aurait aucune couche où se poser. On
/// donne donc à la sélection sa propre couche.
///
/// Ce qui ne doit pas se copier se retire par `TexteProtege`, jamais par un
/// `SelectionContainer.disabled` écrit à la main.
class SelectionRacine extends StatefulWidget {
  /// Rend [child] sélectionnable.
  const SelectionRacine({required this.child, super.key});

  /// Toute l'application.
  final Widget child;

  @override
  State<SelectionRacine> createState() => _SelectionRacineState();
}

class _SelectionRacineState extends State<SelectionRacine> {
  late final OverlayEntry _entree = OverlayEntry(
    builder: (BuildContext _) => SelectionArea(child: widget.child),
  );

  @override
  void didUpdateWidget(SelectionRacine ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.child, widget.child)) _entree.markNeedsBuild();
  }

  @override
  void dispose() {
    _entree
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entree]);
}
