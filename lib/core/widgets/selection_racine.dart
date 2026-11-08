import 'package:flutter/foundation.dart';
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
  // Le noeud de focus de la selection ne se laisse pas prendre : sans cela,
  // chaque appui sur l'ecran lui donnerait le focus clavier, au detriment du
  // bouton qui l'avait (visionneuse de piece : le focus reste sur « Fermer »).
  final FocusNode _focus = FocusNode(
    debugLabel: 'selection-racine',
    canRequestFocus: false,
    skipTraversal: true,
  );

  late final OverlayEntry _entree = OverlayEntry(
    builder: (BuildContext _) => SelectionArea(
      focusNode: _focus,
      contextMenuBuilder: _menu,
      child: widget.child,
    ),
  );

  /// Le menu « Copier » / « Tout sélectionner » dans la police de
  /// l'application. Le bouton Material du menu natif pose un style sans
  /// famille : la police par défaut du système, au lieu de celle du thème
  /// (l'arabe y perd `NotoSansArabic`). Sur iOS et macOS, le menu natif reste.
  static Widget _menu(BuildContext contexte, SelectableRegionState region) {
    final List<ContextMenuButtonItem> boutons = region.contextMenuButtonItems;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: region.contextMenuAnchors,
          buttonItems: boutons,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        final TextStyle? style = Theme.of(contexte).textTheme.bodyMedium;
        return AdaptiveTextSelectionToolbar(
          anchors: region.contextMenuAnchors,
          children: <Widget>[
            for (int i = 0; i < boutons.length; i++)
              TextSelectionToolbarTextButton(
                padding: TextSelectionToolbarTextButton.getPadding(
                  i,
                  boutons.length,
                ),
                onPressed: boutons[i].onPressed,
                child: Text(
                  AdaptiveTextSelectionToolbar.getButtonLabel(
                    contexte,
                    boutons[i],
                  ),
                  style: style,
                ),
              ),
          ],
        );
    }
  }

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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entree]);
}
