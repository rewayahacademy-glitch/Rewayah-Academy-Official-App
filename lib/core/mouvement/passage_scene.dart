// RUBAN-ORDINATEUR (directeur, 11/11/2026 : « il faut que tout soit bien
// coordonne et ne pas agir comme des entites differentes. Pense aussi aux
// transitions ») : le passage d'un mode de la scene a l'autre
// (`docs/current/salle/MODES-AFFICHAGE.md` §5).
//
// - Classe vers Document ou Tableau : la grille des visages retrecit et
//   s'efface vers le bord du ruban (le panneau des Eleves, au bord de debut),
//   pendant que la page arrive en fondu ; les cadres du ruban grandissent en
//   fondu dans le meme temps (`panneau_eleves.dart`).
// - Document ou Tableau vers Classe : l'inverse, plus vite (les deux tiers).
// - Document et Tableau entre eux : un fondu court, sans que les deux se
//   superposent (comme [FonduAuChangement]) : la grille seule cohabite un
//   instant avec la page, jamais deux pages.
//
// Interruptible : un retour pendant le passage reprend la ou il en est (la
// grille qui partait revient de sa place, elle n'est pas reconstruite). Rien
// au premier montage (arrivee, reconnexion). « Reduire les animations » : un
// fondu seul, sans echelle ni glissement. Aucune animation sans fin. Rien ne
// change de taille : les deux contenus occupent la meme place, fixe.

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Le passage d'un mode de la scene a l'autre : [child] est le contenu du
/// mode [mode] ; [grille] dit si ce contenu est la grille des visages.
class PassageScene extends StatefulWidget {
  /// Cree le passage.
  const PassageScene({
    required this.mode,
    required this.grille,
    required this.child,
    super.key,
  });

  /// Le mode montre (compare par `==`).
  final Object mode;

  /// Vrai quand [child] est la grille des visages (mode Classe).
  final bool grille;

  /// Le contenu du mode.
  final Widget child;

  /// La part de sa taille que la grille garde a la fin de sa sortie : elle
  /// retrecit vers le ruban sans disparaitre en un point.
  static const double echelleRuban = 0.9;

  @override
  State<PassageScene> createState() => _EtatPassageScene();
}

class _Entree {
  _Entree({
    required this.mode,
    required this.grille,
    required this.child,
    required this.c,
  });

  final Object mode;
  final bool grille;
  Widget child;
  final AnimationController c;
}

class _EtatPassageScene extends State<PassageScene>
    with TickerProviderStateMixin {
  late _Entree _courant = _Entree(
    mode: widget.mode,
    grille: widget.grille,
    child: widget.child,
    c: AnimationController(vsync: this, value: 1),
  );
  _Entree? _sortant;

  @override
  void didUpdateWidget(PassageScene ancien) {
    super.didUpdateWidget(ancien);
    if (widget.mode == _courant.mode) {
      _courant.child = widget.child;
      return;
    }
    final bool reduit = AppMouvement.mouvementReduit(context);
    final _Entree avant = _courant;
    final bool avecGrille = avant.grille || widget.grille;
    // La grille revient pendant qu'elle partait : elle reprend de sa place.
    final _Entree? retour = _sortant;
    if (retour != null && retour.mode == widget.mode) {
      retour.child = widget.child;
      _courant = retour;
    } else {
      final _Entree? perdu = _sortant;
      _sortant = null;
      perdu?.c.dispose();
      _courant = _Entree(
        mode: widget.mode,
        grille: widget.grille,
        child: widget.child,
        c: AnimationController(vsync: this),
      );
    }
    // Vers la Classe : les deux tiers du temps (une sortie du ruban).
    final Duration entree = reduit
        ? AppMouvement.fonduEntree
        : !avecGrille
        ? AppMouvement.fonduEntree
        : widget.grille
        ? AppMouvement.deplacementSortieOrdinateur
        : AppMouvement.deplacementEntreeOrdinateur;
    if (avecGrille) {
      _sortant = avant;
      avant.c.duration = entree;
      avant.c.reverseDuration = reduit ? AppMouvement.fonduSortie : entree;
      avant.c.reverse().whenCompleteOrCancel(() => _oublier(avant));
    } else {
      // Deux pages : jamais l'une sur l'autre ; l'ancienne part d'un coup.
      if (!identical(avant, _courant)) avant.c.dispose();
      _sortant = null;
    }
    _courant.c.duration = entree;
    _courant.c.forward();
  }

  void _oublier(_Entree entree) {
    if (!mounted || !identical(_sortant, entree)) return;
    if (entree.c.status != AnimationStatus.dismissed) return;
    setState(() {
      _sortant = null;
      entree.c.dispose();
    });
  }

  @override
  void dispose() {
    _courant.c.dispose();
    _sortant?.c.dispose();
    super.dispose();
  }

  Widget _transition(BuildContext context, _Entree e) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    final double sens = Directionality.of(context) == TextDirection.rtl
        ? 1
        : -1;
    return AnimatedBuilder(
      animation: e.c,
      child: e.child,
      builder: (BuildContext _, Widget? enfant) {
        final double v = e.c.value;
        final double opacite = AppMouvement.courbeFondu.transform(v);
        if (!e.grille || reduit) {
          return Opacity(opacity: opacite, child: enfant);
        }
        // La grille glisse et retrecit vers le bord du ruban (debut).
        final double place = AppMouvement.ressortDeplacement.transform(v);
        final double echelle =
            PassageScene.echelleRuban + (1 - PassageScene.echelleRuban) * place;
        return Opacity(
          opacity: opacite,
          child: Transform.translate(
            offset: Offset(
              sens * AppMouvement.translationNavigation * (1 - place),
              0,
            ),
            child: Transform.scale(
              scale: echelle,
              alignment: AlignmentDirectional.centerStart.resolve(
                Directionality.of(context),
              ),
              child: enfant,
            ),
          ),
        );
      },
    );
  }

  // La meme structure pour ce qui arrive et ce qui part : une couche qui
  // change de role garde son etat (la grille qui revient n'est pas remontee).
  Widget _couche(BuildContext context, _Entree e, {required bool part}) =>
      KeyedSubtree(
        key: ObjectKey(e),
        // Ce qui part ne recoit ni geste ni lecture.
        child: IgnorePointer(
          ignoring: part,
          child: ExcludeSemantics(
            excluding: part,
            child: _transition(context, e),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final _Entree? sortant = _sortant;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (sortant != null) _couche(context, sortant, part: true),
        _couche(context, _courant, part: false),
      ],
    );
  }
}
