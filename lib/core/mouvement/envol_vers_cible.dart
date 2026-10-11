import 'package:flutter/widgets.dart';

import 'mouvement.dart';

/// Une copie visuelle qui rejoint sa cible puis s'efface (TB-9, plan V2 §3
/// « Ranger reellement ») : elle se reduit du rectangle de depart vers le
/// centre du rectangle d'arrivee, en gardant ses proportions, en
/// [Mouvement.moyen] (220 ms).
///
/// **Un agrement, jamais l'etat.** L'appelant change son etat sans attendre
/// la copie ; elle est posee dans l'overlay, hors de l'arbre de l'ecran,
/// sans geste ni semantique : rien ne bouge dans la mise en page (commandes,
/// coordonnees), et un lecteur d'ecran ne la voit pas.
///
/// **Mouvement reduit : transition immediate.** Rien n'est monte ; le
/// changement d'etat suffit.
abstract final class EnvolVersCible {
  /// La cle de la copie montee pendant le mouvement.
  static const Key cle = ValueKey<String>('envol-vers-cible');

  /// Lance la copie de l'element [depart] vers l'element [arrivee] (leurs
  /// rectangles a l'ecran, transformations comprises). Rend `false` quand
  /// rien n'est monte : mouvement reduit, aucun overlay, element absent.
  static bool lancer(
    BuildContext context, {
    required GlobalKey depart,
    required GlobalKey arrivee,
    required Widget copie,
  }) {
    if (Mouvement.reduit(context)) return false;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final RenderObject? boite = overlay?.context.findRenderObject();
    if (overlay == null || boite is! RenderBox || !boite.hasSize) return false;
    final Rect? debut = _rectangle(depart, boite);
    final Rect? cible = _rectangle(arrivee, boite);
    if (debut == null || cible == null || debut.isEmpty || cible.isEmpty) {
      return false;
    }
    final Rect fin = _reduitDans(debut.size, cible);
    late final OverlayEntry entree;
    entree = OverlayEntry(
      builder: (BuildContext _) => _Envol(
        debut: debut,
        fin: fin,
        copie: copie,
        onFin: () {
          if (entree.mounted) entree.remove();
        },
      ),
    );
    overlay.insert(entree);
    return true;
  }

  /// Le rectangle de l'element [cle] dans le repere de l'overlay [repere].
  static Rect? _rectangle(GlobalKey cle, RenderBox repere) {
    final RenderObject? boite = cle.currentContext?.findRenderObject();
    if (boite is! RenderBox || !boite.hasSize || !boite.attached) return null;
    return MatrixUtils.transformRect(
      boite.getTransformTo(repere),
      Offset.zero & boite.size,
    );
  }

  /// La copie a l'arrivee : la taille de depart reduite pour tenir dans
  /// [cible], centree, proportions gardees (jamais ecrasee en bouton).
  static Rect _reduitDans(Size taille, Rect cible) {
    final FittedSizes tailles = applyBoxFit(BoxFit.contain, taille, cible.size);
    return Alignment.center.inscribe(tailles.destination, cible);
  }
}

class _Envol extends StatefulWidget {
  const _Envol({
    required this.debut,
    required this.fin,
    required this.copie,
    required this.onFin,
  });

  final Rect debut;
  final Rect fin;
  final Widget copie;
  final VoidCallback onFin;

  @override
  State<_Envol> createState() => _EnvolState();
}

class _EnvolState extends State<_Envol> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: Mouvement.moyen,
  );

  /// La position suit la courbe accentuee ; l'opacite part dans la seconde
  /// moitie (la copie arrive, puis disparait dans sa cible).
  late final Animation<double> _trajet = CurvedAnimation(
    parent: _controleur,
    curve: Mouvement.accentuee,
  );
  late final Animation<double> _opacite = Tween<double>(begin: 1, end: 0)
      .animate(
        CurvedAnimation(
          parent: _controleur,
          curve: const Interval(0.5, 1, curve: Mouvement.sortie),
        ),
      );

  @override
  void initState() {
    super.initState();
    _controleur.addStatusListener((AnimationStatus etat) {
      if (etat == AnimationStatus.completed) widget.onFin();
    });
    _controleur.forward();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controleur,
    builder: (BuildContext _, Widget? enfant) => Positioned.fromRect(
      rect: Rect.lerp(widget.debut, widget.fin, _trajet.value)!,
      child: Opacity(opacity: _opacite.value, child: enfant),
    ),
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: KeyedSubtree(key: EnvolVersCible.cle, child: widget.copie),
      ),
    ),
  );
}
