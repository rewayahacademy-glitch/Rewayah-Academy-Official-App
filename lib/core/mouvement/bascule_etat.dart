import 'package:flutter/widgets.dart';

import 'mouvement.dart';

/// Changement d'etat fluide (chargement, contenu, erreur) : un fondu court
/// entre deux enfants chaque fois que [etat] change. Duree nulle quand les
/// animations sont reduites.
class BasculeEtat extends StatelessWidget {
  /// Cree la bascule ; [etat] identifie l'etat affiche.
  const BasculeEtat({
    super.key,
    required this.etat,
    required this.child,
    this.duree = Mouvement.moyen,
  });

  /// Identifiant de l'etat courant (une enum, une chaine...).
  final Object etat;

  /// Le contenu de l'etat courant.
  final Widget child;

  /// Duree du fondu.
  final Duration duree;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedSwitcher(
      duration: Mouvement.duree(context, duree),
      switchInCurve: Mouvement.entree,
      switchOutCurve: Mouvement.sortie,
      layoutBuilder: _empiler,
      child: KeyedSubtree(key: ValueKey<Object>(etat), child: child),
    ),
  );

  static Widget _empiler(Widget? courant, List<Widget> precedents) => Stack(
    alignment: AlignmentDirectional.topStart,
    children: <Widget>[...precedents, ?courant],
  );
}
