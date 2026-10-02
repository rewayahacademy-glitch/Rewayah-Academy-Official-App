import 'dart:async';

import 'package:flutter/material.dart';

import '../mouvement/mouvement.dart';

/// MA-CMD-1 (02/10/2026, commentaires du directeur sur la planche MA) : en
/// Mode Accessibilite, les commandes de la salle et du lecteur du Coran sont
/// des icones seules, compactes, posees en bas **par-dessus** le contenu
/// (support partage, video, Mushaf), qui garde tout l'ecran.
///
/// Elles se masquent au bout de [delai] et reviennent d'une touche n'importe
/// ou sur l'ecran (le toucher n'est pas consomme : il atteint aussi le
/// contenu) ou des que l'une d'elles recoit le focus. Elles restent
/// **toujours visibles** quand le lecteur d'ecran
/// (`MediaQuery.accessibleNavigation`) ou l'acces clavier
/// (`FocusHighlightMode.traditional`) est actif : aucun geste cache pour
/// Quitter.
class CommandesMasquables extends StatefulWidget {
  const CommandesMasquables({
    required this.contenu,
    required this.commandes,
    this.delai = delaiParDefaut,
    super.key,
  });

  /// Le contenu qui garde l'ecran.
  final Widget contenu;

  /// La rangee de commandes, posee en bas.
  final Widget commandes;

  /// Le temps avant que les commandes se masquent.
  final Duration delai;

  /// Quelques secondes, comme le lecteur standard.
  static const Duration delaiParDefaut = Duration(seconds: 4);

  /// La cle de la zone des commandes (tests, captures).
  static const Key commandesKey = ValueKey<String>('commandes-masquables');

  @override
  State<CommandesMasquables> createState() => _CommandesMasquablesState();
}

class _CommandesMasquablesState extends State<CommandesMasquables> {
  bool _visibles = true;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_surModeFocus);
    _armer();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    FocusManager.instance.removeHighlightModeListener(_surModeFocus);
    super.dispose();
  }

  bool get _clavier =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  bool _toujoursVisibles(BuildContext context) =>
      MediaQuery.maybeAccessibleNavigationOf(context) == true || _clavier;

  void _surModeFocus(FocusHighlightMode _) {
    if (mounted) _montrer();
  }

  void _armer() {
    _minuteur?.cancel();
    _minuteur = Timer(widget.delai, () {
      if (!mounted || _toujoursVisibles(context)) return;
      setState(() => _visibles = false);
    });
  }

  void _montrer() {
    if (!_visibles) setState(() => _visibles = true);
    _armer();
  }

  @override
  Widget build(BuildContext context) {
    final bool visibles = _visibles || _toujoursVisibles(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent _) => _montrer(),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: widget.contenu),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (bool focus) {
                if (focus) _montrer();
              },
              child: IgnorePointer(
                ignoring: !visibles,
                child: AnimatedOpacity(
                  opacity: visibles ? 1 : 0,
                  duration: Mouvement.reduit(context)
                      ? Duration.zero
                      : Mouvement.moyen,
                  child: KeyedSubtree(
                    key: CommandesMasquables.commandesKey,
                    child: widget.commandes,
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
