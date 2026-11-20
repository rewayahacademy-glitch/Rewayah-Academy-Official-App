import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ce qui se lit, et seulement cela, se sélectionne et se copie (PE-D11,
/// directeur, 19/11/2026) : le texte d'une bulle de message, un document, un
/// contrat, le cadre, un texte long de lecture.
///
/// Remplace le `SelectionArea` global d'avant (cause prouvée, PLAN §14.1) :
/// posé autour de toute l'application, il ajoutait un appui long à chaque
/// toucher, boutons compris, et ouvrait « Tout sélectionner » au moindre
/// doigt posé ; son nœud de focus ne se laissait pas prendre, si bien
/// qu'une sélection ne s'effaçait jamais. Ici la zone est petite, son nœud
/// de focus est l'ordinaire : toucher ailleurs efface la sélection.
///
/// Il se pose sous le `Navigator` (dans une page) : le menu « Copier » prend
/// la couche de la page. Le menu est celui de l'application
/// ([menuSelection]).
class TexteSelectionnable extends StatelessWidget {
  /// Rend [child] sélectionnable.
  const TexteSelectionnable({required this.child, super.key});

  /// Le texte à lire.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SelectionArea(contextMenuBuilder: menuSelection, child: child);
}

/// Le menu « Copier » / « Tout sélectionner » dans la police de
/// l'application. Le bouton Material du menu natif pose un style sans
/// famille : la police par défaut du système, au lieu de celle du thème
/// (l'arabe y perd `NotoSansArabic`). Sur iOS et macOS, le menu natif reste.
Widget menuSelection(BuildContext contexte, SelectableRegionState region) {
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

/// L'ancienne sélection de toute l'application (directeur, 07/11/2026).
///
/// **Plus posée par `RewayahApp` depuis PE-D11** (19/11/2026) : voir
/// [TexteSelectionnable]. Elle ne sert plus qu'aux hôtes de test et à la
/// galerie qui éprouvent `TexteProtege` sur un écran entier ; ne pas la
/// reposer à la racine.
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
      contextMenuBuilder: menuSelection,
      child: widget.child,
    ),
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entree]);
}
