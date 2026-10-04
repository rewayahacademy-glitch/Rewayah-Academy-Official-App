import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../mouvement/mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../widgets/pressable.dart';
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
/// TB-2 (VIS-01, plan V2 §4.1 et §18), ajouts sans copie : la souris qui
/// bouge les revele (sans clic) et le survol des commandes les retient ;
/// [maintenir] les retient (panneau ouvert, erreur critique) ; tant qu'un
/// contact est pose, rien ne se masque ; [libelleEntree] ouvre l'entree
/// clavier nommee (« Commandes de l'appel ») ; [margeLecture] reserve sous
/// le contenu la hauteur mesuree des commandes, sans relayout quand elles se
/// masquent. Le clavier ne compte qu'apres une touche pressee dans la zone, et
/// plus quand la derniere interaction y est la souris (mode de focus par
/// defaut d'un bureau) : la barre se masque alors comme au toucher, mais
/// jamais tant qu'une commande a le focus.
class CommandesMasquables extends StatefulWidget {
  const CommandesMasquables({
    required this.contenu,
    required this.commandes,
    this.delai = delaiParDefaut,
    this.effacerBarreBasse = false,
    this.maintenir = false,
    this.margeLecture = false,
    this.libelleEntree,
    super.key,
  });

  /// Vrai : les commandes restent visibles (panneau ouvert, erreur critique
  /// de connexion ; plan V2 §18.1).
  final bool maintenir;

  /// Vrai : le contenu s'arrete au-dessus des commandes (marge de lecture
  /// egale a leur hauteur mesuree, plan V2 §18.2) ; elles ne couvrent rien,
  /// et leur masquage ne change ni la taille ni le repere du contenu. Si
  /// cette marge depasse [partMaxMarge] de la hauteur, les commandes se
  /// posent par-dessus (texte agrandi sur petit ecran).
  final bool margeLecture;

  /// Le nom de l'entree clavier des commandes (Tab, plan V2 §18.3), ou
  /// `null` : pas d'entree, le groupe n'est pas un arret du parcours.
  final String? libelleEntree;

  /// La part maximale de la hauteur que la marge de lecture peut prendre.
  static const double partMaxMarge = 1 / 3;

  /// La marge de lecture mesuree sous le contenu (0 sans marge, ou hors de
  /// [CommandesMasquables]) : un panneau du contenu (feuille du telephone)
  /// peut s'en servir pour garder sa hauteur au-dessus des commandes.
  static double margeDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MargeCommandes>()?.marge ?? 0;

  /// La hauteur du contenu que les commandes recouvrent quand elles se
  /// posent par-dessus (marge de lecture au-dela de [partMaxMarge], texte
  /// agrandi sur petit ecran) ; 0 quand la marge les loge, ou hors de
  /// [CommandesMasquables]. Un panneau maintenu ouvert sous des commandes
  /// retenues (TB-3) s'arrete au-dessus d'elles au lieu d'etre recouvert.
  static double recouvrementDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_MargeCommandes>()
          ?.recouvrement ??
      0;

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

  /// La cle de l'entree clavier « Commandes de l'appel ».
  static const Key entreeKey = ValueKey<String>('commandes-masquables-entree');

  @override
  State<CommandesMasquables> createState() => _CommandesMasquablesState();
}

class _CommandesMasquablesState extends State<CommandesMasquables> {
  bool _visibles = true;
  Timer? _minuteur;

  /// Le controleur de la barre du bas, s'il est pilote.
  ControleurBarreBasse? _barre;

  /// Le dernier etat signale a la barre (evite les signaux repetes).
  bool _barreEffacee = false;

  /// TB-2 : le pointeur survole les commandes.
  bool _survol = false;

  /// TB-2 : le focus est dans les commandes (ou sur leur entree).
  bool _focusDedans = false;

  /// TB-2 : la derniere interaction dans la zone est un pointeur (souris ou
  /// doigt), pas le clavier. Vrai a l'entree : le parcours clavier ne compte
  /// qu'apres une touche pressee dans la zone ([_surTouche]). Sur un bureau
  /// ouvert a la souris, le mode de focus vaut deja `traditional` : sans
  /// cela, la barre ne se masquait jamais pour l'eleve qui regarde sans
  /// toucher la souris (UX-06, revue TB-2). Au clavier, la premiere touche
  /// la ramene et la garde (Quitter jamais masque au clavier).
  bool _pointeur = true;

  /// TB-2 : les contacts poses (un trait, un zoom) : rien ne se masque.
  final Set<int> _contacts = <int>{};

  /// La derniere marge de lecture mesuree (transmise au contenu).
  double _marge = 0;

  /// La hauteur du contenu recouverte par les commandes posees par-dessus.
  double _recouvrement = 0;

  /// Une marge mesuree differente : transmise au cadre suivant (une fois
  /// a l'ouverture ou quand le texte change de taille, jamais au masquage).
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

  /// L'entree clavier « Commandes de l'appel ».
  final FocusNode _entree = FocusNode(debugLabel: 'commandes-de-l-appel');

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_surModeFocus);
    HardwareKeyboard.instance.addHandler(_surTouche);
    _entree.addListener(_surEntree);
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
  void didUpdateWidget(CommandesMasquables ancien) {
    super.didUpdateWidget(ancien);
    if (widget.maintenir == ancien.maintenir) return;
    if (widget.maintenir) {
      // Panneau ouvert, erreur critique : les commandes reviennent.
      if (!_visibles) {
        _visibles = true;
        _synchroniserBarre(differe: true);
      }
    } else {
      _armer();
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    FocusManager.instance.removeHighlightModeListener(_surModeFocus);
    HardwareKeyboard.instance.removeHandler(_surTouche);
    _entree
      ..removeListener(_surEntree)
      ..dispose();
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

  /// Le parcours clavier : mode de focus clavier, et le clavier est la
  /// derniere interaction dans la zone.
  bool get _clavier =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
      !_pointeur;

  bool _toujoursVisibles(BuildContext context) =>
      MediaQuery.maybeAccessibleNavigationOf(context) == true ||
      _clavier ||
      widget.maintenir ||
      _survol ||
      _focusDedans;

  void _surModeFocus(FocusHighlightMode _) {
    if (mounted) _montrer();
  }

  /// Une touche du clavier : le parcours clavier reprend, les commandes
  /// reviennent. La touche n'est jamais consommee.
  bool _surTouche(KeyEvent evenement) {
    if (!mounted || evenement is! KeyDownEvent) return false;
    if (_pointeur) {
      _pointeur = false;
      _montrer();
    }
    return false;
  }

  void _surEntree() {
    if (mounted) setState(() {});
  }

  void _armer() {
    _minuteur?.cancel();
    _minuteur = Timer(widget.delai, () {
      if (!mounted || _toujoursVisibles(context) || _contacts.isNotEmpty) {
        return;
      }
      setState(() => _visibles = false);
      _synchroniserBarre();
    });
  }

  void _montrer() {
    if (!_visibles) setState(() => _visibles = true);
    _synchroniserBarre();
    _armer();
  }

  /// Un contact pose n'importe ou : les commandes reviennent ; le contact
  /// n'est pas consomme. La cible du geste est fixee a son debut : un geste
  /// commence sous des commandes masquees ne les atteint jamais (§18.2).
  void _surContact(PointerDownEvent evenement) {
    _pointeur = true;
    _contacts.add(evenement.pointer);
    _montrer();
  }

  /// Fin du geste : le delai repart.
  void _surFinContact(PointerEvent evenement) {
    _contacts.remove(evenement.pointer);
    if (_contacts.isEmpty) _armer();
  }

  /// La souris bouge dans la zone, sans clic : les commandes reviennent.
  void _surSurvolZone(PointerHoverEvent _) {
    final bool clavier = _clavier;
    _pointeur = true;
    if (!_visibles || clavier) {
      _montrer();
    } else {
      _armer();
    }
  }

  void _surFocus(bool focus) {
    final bool avant = _focusDedans;
    _focusDedans = focus;
    if (focus) {
      _montrer();
    } else {
      if (avant) setState(() {});
      _armer();
    }
  }

  void _surEntreeSurvol(PointerEnterEvent _) {
    _survol = true;
    _montrer();
  }

  void _surSortieSurvol(PointerExitEvent _) {
    _survol = false;
    _armer();
  }

  @override
  Widget build(BuildContext context) {
    final bool visibles = _visibles || _toujoursVisibles(context);
    final String? libelleEntree = widget.libelleEntree;
    Widget commandes = KeyedSubtree(
      key: CommandesMasquables.commandesKey,
      child: widget.commandes,
    );
    if (libelleEntree != null) {
      // L'entree clavier : un arret du parcours qui porte le nom du groupe ;
      // l'anneau de focus du core entoure les commandes.
      final bool anneau =
          _entree.hasPrimaryFocus &&
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
      commandes = Semantics(
        key: CommandesMasquables.entreeKey,
        container: true,
        explicitChildNodes: true,
        label: libelleEntree,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            commandes,
            if (anneau)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.arrondiLg,
                      border: Border.fromBorderSide(
                        AppPalette.of(context).inkAccent
                            .asBorderSide(width: Pressable.epaisseurFocus),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final Widget zoneCommandes = Focus(
      focusNode: libelleEntree == null ? null : _entree,
      canRequestFocus: libelleEntree != null,
      skipTraversal: libelleEntree == null,
      onFocusChange: _surFocus,
      child: MouseRegion(
        onEnter: _surEntreeSurvol,
        onExit: _surSortieSurvol,
        child: IgnorePointer(
          ignoring: !visibles,
          child: AnimatedOpacity(
            opacity: visibles ? 1 : 0,
            duration: Mouvement.reduit(context)
                ? Duration.zero
                : Mouvement.moyen,
            child: commandes,
          ),
        ),
      ),
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _surContact,
      onPointerUp: _surFinContact,
      onPointerCancel: _surFinContact,
      onPointerHover: _surSurvolZone,
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
              child: widget.contenu,
            ),
          ),
          LayoutId(id: _Partie.commandes, child: zoneCommandes),
        ],
      ),
    );
  }
}

enum _Partie { contenu, commandes }

/// Le contenu garde l'ecran ; les commandes, posees en bas sur toute la
/// largeur, gardent leur hauteur naturelle. Avec la marge de lecture, le
/// contenu s'arrete au-dessus d'elles, visibles ou masquees (aucun
/// relayout au masquage).
class _DispositionCommandes extends MultiChildLayoutDelegate {
  _DispositionCommandes({required this.margeLecture, required this.onMarge});

  final bool margeLecture;
  final void Function(double marge, double recouvrement) onMarge;

  @override
  void performLayout(Size size) {
    final Size barre = layoutChild(
      _Partie.commandes,
      // Hauteur libre, comme un enfant pose en bas d'une pile : les
      // commandes gardent leur hauteur naturelle.
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

/// La marge de lecture mesuree, pour le contenu ([CommandesMasquables.margeDe]).
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
