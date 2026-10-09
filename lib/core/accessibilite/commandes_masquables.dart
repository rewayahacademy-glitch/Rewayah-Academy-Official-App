import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mouvement/mouvement.dart';
import 'effacement_barre_basse.dart';

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
///
/// Avec [effacerBarreBasse] (lecteur du Coran, finition de MA-CMD-1), la
/// barre du bas de `NavShell` s'efface et revient avec elles.
///
/// **SUPERPOS-1** (05/10/2026, decide par delegation : un element flottant
/// ne reste jamais par-dessus un contenu a lire ; il prend sa place dans le
/// flux, ou se ferme). Avec [placeReservee] (lecteur du Coran), quand les
/// commandes sont toujours visibles (lecteur d'ecran, clavier), elles ne se
/// ferment jamais : elles passent alors SOUS le contenu, dans le flux, et
/// ne recouvrent plus le bas du Mushaf. Au toucher, MA-CMD-1 reste tel quel :
/// les commandes passent par-dessus quelques secondes puis se ferment. La
/// salle (voie TB) ne le demande pas encore.
class CommandesMasquables extends StatefulWidget {
  const CommandesMasquables({
    required this.contenu,
    required this.commandes,
    this.delai = delaiParDefaut,
    this.effacerBarreBasse = false,
    this.placeReservee = false,
    super.key,
  });

  /// Vrai : quand les commandes sont toujours visibles (lecteur d'ecran,
  /// clavier), elles se posent sous le contenu au lieu de le recouvrir.
  final bool placeReservee;

  /// Vrai : la barre du bas de `NavShell` suit les commandes (effacee quand
  /// elles se masquent, revenue a la meme touche, toujours visible avec
  /// lecteur d'ecran ou clavier).
  final bool effacerBarreBasse;

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

  /// Garde l'etat du contenu quand il passe du recouvrement au flux.
  final GlobalKey _cleContenu = GlobalKey();

  /// Le controleur de la barre du bas, s'il est pilote.
  ControleurBarreBasse? _barre;

  /// Le dernier etat signale a la barre (evite les signaux repetes).
  bool _barreEffacee = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_surModeFocus);
    _armer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ControleurBarreBasse? barre = widget.effacerBarreBasse
        ? EffacementBarreBasse.de(context)
        : null;
    if (!identical(barre, _barre)) {
      _signalerDiffere(_barre, effacee: false);
      _barre = barre;
      _barreEffacee = false;
    }
    // Lecteur d'ecran active pendant que tout est masque : tout revient.
    if (!_visibles && _toujoursVisibles(context)) {
      _visibles = true;
      _synchroniserBarre(differe: true);
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    FocusManager.instance.removeHighlightModeListener(_surModeFocus);
    // La barre revient quand le lecteur se ferme ; differe : l'arbre est
    // verrouille pendant la fermeture.
    _signalerDiffere(_barre, effacee: false);
    super.dispose();
  }

  void _signalerDiffere(ControleurBarreBasse? barre, {required bool effacee}) {
    if (barre == null) return;
    SchedulerBinding.instance.addPostFrameCallback(
      (Duration _) => barre.signaler(effacee: effacee),
    );
  }

  /// Aligne la barre du bas sur les commandes.
  void _synchroniserBarre({bool differe = false}) {
    final ControleurBarreBasse? barre = _barre;
    if (barre == null) return;
    final bool effacee = !_visibles;
    if (effacee == _barreEffacee) return;
    _barreEffacee = effacee;
    if (differe) {
      _signalerDiffere(barre, effacee: effacee);
    } else {
      barre.signaler(effacee: effacee);
    }
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
      _synchroniserBarre();
    });
  }

  void _montrer() {
    if (!_visibles) setState(() => _visibles = true);
    _synchroniserBarre();
    _armer();
  }

  @override
  Widget build(BuildContext context) {
    final bool toujours = _toujoursVisibles(context);
    final bool visibles = _visibles || toujours;
    if (widget.placeReservee && toujours) {
      // Jamais fermees : dans le flux, sous le contenu (SUPERPOS-1).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: KeyedSubtree(key: _cleContenu, child: widget.contenu),
          ),
          KeyedSubtree(
            key: CommandesMasquables.commandesKey,
            child: widget.commandes,
          ),
        ],
      );
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent _) => _montrer(),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: KeyedSubtree(key: _cleContenu, child: widget.contenu),
          ),
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
