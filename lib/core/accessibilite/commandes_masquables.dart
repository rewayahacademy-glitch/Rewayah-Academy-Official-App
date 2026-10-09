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
/// MA-CORAN-X2-1 (05/10/2026) : avec [margeLecture], le contenu s'arrete
/// au-dessus de la hauteur mesuree des commandes (un etat sans texte du
/// lecteur, texte x2 : son titre et « Reessayer » ne passent plus dessous).
/// Meme contrat que la marge de lecture de TB-2 (`ui/supports-tableau-v1`) :
/// [margeDe], [recouvrementDe], [partMaxMarge].
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
    this.margeLecture = false,
    this.placeReservee = false,
    super.key,
  });

  /// Vrai : le contenu s'arrete au-dessus des commandes (marge de lecture
  /// egale a leur hauteur mesuree) ; elles ne couvrent rien, et leur
  /// masquage ne change ni la taille ni le repere du contenu. Si cette marge
  /// depasse [partMaxMarge] de la hauteur, les commandes se posent
  /// par-dessus et [recouvrementDe] dit la hauteur recouverte.
  final bool margeLecture;

  /// La part maximale de la hauteur que la marge de lecture peut prendre.
  static const double partMaxMarge = 1 / 3;

  /// La marge de lecture mesuree sous le contenu (0 sans marge, ou hors de
  /// [CommandesMasquables]).
  static double margeDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MargeCommandes>()?.marge ?? 0;

  /// La hauteur du contenu que les commandes recouvrent quand elles se
  /// posent par-dessus malgre la marge de lecture (au-dela de
  /// [partMaxMarge]) ; 0 quand la marge les loge, sans marge de lecture, ou
  /// hors de [CommandesMasquables]. Un etat sans texte s'en ecarte d'autant.
  static double recouvrementDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_MargeCommandes>()
          ?.recouvrement ??
      0;

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

  /// La derniere marge de lecture mesuree (transmise au contenu).
  double _marge = 0;

  /// La hauteur du contenu recouverte par les commandes posees par-dessus.
  double _recouvrement = 0;

  /// Une marge mesuree differente : transmise au cadre suivant (a
  /// l'ouverture ou quand le texte change de taille, jamais au masquage).
  void _surMarge(double marge, double recouvrement) {
    if (marge == _marge && recouvrement == _recouvrement) return;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && (marge != _marge || recouvrement != _recouvrement)) {
        setState(() {
          _marge = marge;
          _recouvrement = recouvrement;
        });
      }
    });
  }

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
      child: CustomMultiChildLayout(
        delegate: _DispositionCommandes(
          margeLecture: widget.margeLecture,
          onMarge: _surMarge,
        ),
        children: <Widget>[
          LayoutId(
            id: _Partie.contenu,
            child: _MargeCommandes(
              marge: _marge,
              recouvrement: _recouvrement,
              // Meme cle que dans le flux de SUPERPOS-1 : le contenu garde
              // son etat quand les commandes changent de place.
              child: KeyedSubtree(key: _cleContenu, child: widget.contenu),
            ),
          ),
          LayoutId(
            id: _Partie.commandes,
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

enum _Partie { contenu, commandes }

/// Le contenu garde l'ecran ; les commandes, posees en bas sur toute la
/// largeur, gardent leur hauteur naturelle (comme un enfant pose en bas
/// d'une pile). Avec la marge de lecture, le contenu s'arrete au-dessus
/// d'elles, visibles ou masquees (aucun relayout au masquage).
class _DispositionCommandes extends MultiChildLayoutDelegate {
  _DispositionCommandes({required this.margeLecture, required this.onMarge});

  final bool margeLecture;
  final void Function(double marge, double recouvrement) onMarge;

  @override
  void performLayout(Size size) {
    final Size barre = layoutChild(
      _Partie.commandes,
      BoxConstraints(minWidth: size.width, maxWidth: size.width),
    );
    positionChild(_Partie.commandes, Offset(0, size.height - barre.height));
    final double marge =
        margeLecture &&
            barre.height <= size.height * CommandesMasquables.partMaxMarge
        ? barre.height
        : 0;
    onMarge(marge, margeLecture ? barre.height - marge : 0);
    layoutChild(
      _Partie.contenu,
      BoxConstraints.tight(Size(size.width, size.height - marge)),
    );
    positionChild(_Partie.contenu, Offset.zero);
  }

  @override
  bool shouldRelayout(_DispositionCommandes ancien) =>
      ancien.margeLecture != margeLecture;
}

/// La marge de lecture mesuree, pour le contenu.
class _MargeCommandes extends InheritedWidget {
  const _MargeCommandes({
    required this.marge,
    required this.recouvrement,
    required super.child,
  });

  final double marge;
  final double recouvrement;

  @override
  bool updateShouldNotify(_MargeCommandes ancien) =>
      ancien.marge != marge || ancien.recouvrement != recouvrement;
}
