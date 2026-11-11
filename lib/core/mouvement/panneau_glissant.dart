// TRANSITIONS-SALLE (directeur, 11/11/2026) : les panneaux et les feuilles
// de la salle s'ouvrent dans le langage du reste de l'application.
//
// - Ce qui se deplace suit un ressort sans rebond
//   ([AppMouvement.ressortDeplacement]) ; le contenu, lui, apparait en fondu
//   ([AppMouvement.courbeFondu]).
// - La sortie est plus rapide que l'entree (les deux tiers).
// - Interruptible : un nouveau geste reprend le mouvement la ou il est.
// - Rien ne se joue au montage d'un panneau deja ouvert (arrivee, retour,
//   reconnexion) : seul un changement voulu s'anime.
// - « Reduire les animations » : le panneau est la, ou n'est pas, sans
//   mouvement.

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Le bord d'ou un panneau de cote arrive.
enum BordPanneau {
  /// Le bord de debut de lecture (gauche en francais, droite en arabe).
  debut,

  /// Le bord de fin de lecture.
  fin,
}

/// Un panneau de cote de l'ordinateur qui s'ouvre en glissant depuis son
/// bord.
///
/// Sa largeur suit le ressort : la page voisine (un `Expanded`) change de
/// taille sur le MEME ressort, sans saut. Le contenu garde sa largeur
/// entiere pendant le mouvement (rien ne se recompose a chaque image) : il
/// est devoile depuis le bord du panneau, et apparait en fondu. Ferme et
/// immobile, le panneau ne laisse rien dans l'arbre.
class PanneauGlissant extends StatefulWidget {
  /// Cree le panneau.
  const PanneauGlissant({
    required this.ouvert,
    required this.largeur,
    required this.child,
    this.bord = BordPanneau.debut,
    this.ecart = 0,
    super.key,
  });

  /// Vrai quand le panneau doit etre ouvert.
  final bool ouvert;

  /// La largeur du panneau ouvert, sans l'[ecart].
  final double largeur;

  /// L'ecart entre le panneau et la page, compris dans le mouvement : il
  /// s'ouvre et se ferme avec le panneau (aucun saut de 16 points).
  final double ecart;

  /// Le bord d'ou le panneau arrive.
  final BordPanneau bord;

  /// Le contenu, ou `null` quand il n'y a rien a montrer (le dernier contenu
  /// reste alors pendant la fermeture).
  final Widget? child;

  @override
  State<PanneauGlissant> createState() => _EtatPanneauGlissant();
}

class _EtatPanneauGlissant extends State<PanneauGlissant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: widget.ouvert ? 1 : 0,
    duration: AppMouvement.deplacementEntreeOrdinateur,
    reverseDuration: AppMouvement.deplacementSortieOrdinateur,
  );
  late final CurvedAnimation _place = CurvedAnimation(
    parent: _c,
    curve: AppMouvement.ressortDeplacement,
    reverseCurve: AppMouvement.ressortDeplacement.flipped,
  );
  late final CurvedAnimation _fondu = CurvedAnimation(
    parent: _c,
    curve: AppMouvement.courbeFondu,
    reverseCurve: AppMouvement.courbeFondu.flipped,
  );

  /// Le dernier contenu montre, garde pendant la fermeture.
  Widget? _dernier;

  @override
  void initState() {
    super.initState();
    _dernier = widget.child;
    _c.addStatusListener(_statut);
  }

  void _statut(AnimationStatus s) {
    // Ferme et immobile : plus rien dans l'arbre.
    if (s == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(PanneauGlissant ancien) {
    super.didUpdateWidget(ancien);
    if (widget.child != null) _dernier = widget.child;
    if (ancien.ouvert == widget.ouvert) return;
    if (AppMouvement.mouvementReduit(context)) {
      _c.value = widget.ouvert ? 1 : 0;
    } else if (widget.ouvert) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _place.dispose();
    _fondu.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? contenu = widget.child ?? _dernier;
    if (contenu == null || (!widget.ouvert && _c.isDismissed)) {
      return const SizedBox.shrink();
    }
    final bool debut = widget.bord == BordPanneau.debut;
    final double plein = widget.largeur + widget.ecart;
    // L'ecart vit du cote de la page.
    final Widget interieur = Padding(
      padding: debut
          ? EdgeInsetsDirectional.only(end: widget.ecart)
          : EdgeInsetsDirectional.only(start: widget.ecart),
      child: FadeTransition(opacity: _fondu, child: contenu),
    );
    return AnimatedBuilder(
      animation: _place,
      child: interieur,
      builder: (BuildContext context, Widget? enfant) => SizedBox(
        width: plein * _place.value.clamp(0.0, 1.0),
        child: ClipRect(
          child: OverflowBox(
            // Devoile depuis le bord d'arrivee : on voit d'abord le cote du
            // panneau tourne vers la page.
            alignment: debut
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            minWidth: plein,
            maxWidth: plein,
            child: enfant,
          ),
        ),
      ),
    );
  }
}

/// Une feuille du telephone qui monte du bas a son arrivee (tiroir des
/// commandes, feuille des eleves).
///
/// Elle monte **dans sa propre place** (le mouvement est rogne a ses bords) :
/// elle ne passe jamais par-dessus la pilule de l'appel, posee sous elle. Le
/// contenu apparait en fondu. Jouee une fois, au montage ; sous « reduire
/// les animations », la feuille est la d'emblee.
class MonteeDuBas extends StatefulWidget {
  /// Cree la montee.
  const MonteeDuBas({required this.child, super.key});

  /// La feuille.
  final Widget child;

  @override
  State<MonteeDuBas> createState() => _EtatMonteeDuBas();
}

class _EtatMonteeDuBas extends State<MonteeDuBas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMouvement.deplacementEntree,
  );
  late final CurvedAnimation _place = CurvedAnimation(
    parent: _c,
    curve: AppMouvement.ressortDeplacement,
  );
  late final CurvedAnimation _fondu = CurvedAnimation(
    parent: _c,
    curve: AppMouvement.courbeFondu,
  );
  bool _parti = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parti) return;
    _parti = true;
    if (AppMouvement.mouvementReduit(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _place.dispose();
    _fondu.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _place,
      child: FadeTransition(opacity: _fondu, child: widget.child),
      builder: (BuildContext context, Widget? enfant) => FractionalTranslation(
        translation: Offset(0, 1 - _place.value),
        child: enfant,
      ),
    ),
  );
}
