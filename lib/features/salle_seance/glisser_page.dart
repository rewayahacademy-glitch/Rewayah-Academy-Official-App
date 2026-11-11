// Constat de la salle, defaut S-1 (11/11/2026) : au telephone, l'enseignant
// ne pouvait pas tourner la page (ni fleche, ni geste). Tourner la page au
// doigt est le geste de tout lecteur (Quran.com, Tarteel, le lecteur de
// l'application hors salle) ; il manquait dans la salle.
//
// Le geste ne vaut que pour qui a le droit de tourner la page (les deux
// rappels viennent des actions de la salle : absents chez l'eleve) et tant
// qu'aucun outil n'est retenu : avec le Pointeur ou l'ecriture, le doigt
// montre ou ecrit, il ne tourne pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_outils/etat_outils.dart';
import '../../core/theme/app_mouvement.dart';

/// Tourne la page d'un glissement horizontal du doigt.
///
/// [droiteAGauche] dit le sens de lecture **du support**, pas celui de
/// l'interface : dans un mushaf, la page suivante est a gauche, on l'amene
/// donc en glissant le doigt vers la droite, que l'application soit en
/// francais ou en arabe. Un support qui se lit de gauche a droite inverse le
/// geste.
class GlisserPage extends ConsumerStatefulWidget {
  /// Cree la zone de glissement autour de [child].
  const GlisserPage({
    required this.child,
    required this.onPrecedente,
    required this.onSuivante,
    this.droiteAGauche = true,
    super.key,
  });

  /// La page.
  final Widget child;

  /// Va a la page precedente ; `null` au debut du support.
  final VoidCallback? onPrecedente;

  /// Va a la page suivante ; `null` a la fin du support.
  final VoidCallback? onSuivante;

  /// Le support se lit de droite a gauche (mushaf, livre de lecture arabe).
  final bool droiteAGauche;

  /// La part de la largeur a parcourir pour tourner la page sans elan.
  static const double seuilDistance = 0.18;

  /// L'elan (points par seconde) qui tourne la page meme sur un geste court.
  static const double seuilElan = 320;

  /// La part du deplacement du doigt que la page suit pendant le geste.
  static const double suivi = 0.35;

  @override
  ConsumerState<GlisserPage> createState() => _GlisserPageEtat();
}

class _GlisserPageEtat extends ConsumerState<GlisserPage> {
  double _decalage = 0;
  bool _enGeste = false;

  /// La largeur de la page, lue pendant le geste (jamais pendant la
  /// construction : la taille n'y est pas encore connue).
  double _largeur = 0;

  /// Le rappel qu'un glissement de signe [versLaDroite] declenche.
  VoidCallback? _action({required bool versLaDroite}) =>
      versLaDroite == widget.droiteAGauche
      ? widget.onSuivante
      : widget.onPrecedente;

  void _suivre(DragUpdateDetails d) {
    _largeur = context.size?.width ?? 0;
    final double voulu = _decalage + (d.primaryDelta ?? 0);
    // La page ne suit pas le doigt vers un cote ou il n'y a rien.
    final bool permis = _action(versLaDroite: voulu > 0) != null;
    setState(() {
      _enGeste = true;
      _decalage = permis ? voulu : 0;
    });
  }

  void _lacher(DragEndDetails d) {
    final double largeur = _largeur;
    final double elan = d.primaryVelocity ?? 0;
    final bool assezLoin =
        largeur > 0 && _decalage.abs() >= largeur * GlisserPage.seuilDistance;
    final bool assezVite =
        elan.abs() >= GlisserPage.seuilElan &&
        (elan > 0) == (_decalage > 0) &&
        _decalage != 0;
    final VoidCallback? action = assezLoin || assezVite
        ? _action(versLaDroite: _decalage > 0)
        : null;
    setState(() {
      _enGeste = false;
      _decalage = 0;
    });
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool outilRetenu = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif != null),
    );
    final bool actif =
        !outilRetenu &&
        (widget.onPrecedente != null || widget.onSuivante != null);
    if (!actif) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _suivre,
      onHorizontalDragEnd: _lacher,
      onHorizontalDragCancel: () => setState(() {
        _enGeste = false;
        _decalage = 0;
      }),
      child: AnimatedSlide(
        // Pendant le geste la page suit le doigt sans delai ; lachee, elle
        // revient a sa place (ou laisse la place a la suivante).
        duration: _enGeste
            ? Duration.zero
            : AppMouvement.duree(context, AppMouvement.navigation),
        curve: AppMouvement.entree,
        offset: Offset(
          _largeur <= 0 ? 0 : _decalage * GlisserPage.suivi / _largeur,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}
