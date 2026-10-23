import 'package:flutter/widgets.dart';

import 'mouvement.dart';

/// Fondu et leger glisse vers le haut a l'entree, **une seule fois** : une
/// reconstruction ne relance rien. Neutralise quand les animations sont
/// reduites (l'enfant est rendu tel quel).
class ApparitionDouce extends StatelessWidget {
  /// Cree une apparition, eventuellement retardee de [delai].
  const ApparitionDouce({
    super.key,
    required this.child,
    this.delai = Duration.zero,
    this.duree = Mouvement.moyen,
  });

  /// Le contenu qui apparait.
  final Widget child;

  /// Attente avant le debut du mouvement (echelonnement).
  final Duration delai;

  /// Duree du mouvement lui-meme.
  final Duration duree;

  @override
  Widget build(BuildContext context) {
    final int total = delai.inMicroseconds + duree.inMicroseconds;
    if (Mouvement.reduit(context) || total <= 0) {
      return child;
    }
    final double debut = delai.inMicroseconds / total;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(microseconds: total),
        curve: Interval(debut, 1, curve: Mouvement.entree),
        child: child,
        builder: (BuildContext _, double t, Widget? enfant) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * Mouvement.glisse),
            child: enfant,
          ),
        ),
      ),
    );
  }
}

/// Un element de liste qui apparait en decale : les
/// [Mouvement.maxEchelonnes] premiers rangs s'echelonnent de
/// [Mouvement.echelon], les suivants s'affichent sans animation.
class ElementEchelonne extends StatelessWidget {
  /// Cree l'element de rang [index].
  const ElementEchelonne({super.key, required this.index, required this.child});

  /// Rang de l'element dans la liste, a partir de zero.
  final int index;

  /// Le contenu de l'element.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= Mouvement.maxEchelonnes) {
      return child;
    }
    return ApparitionDouce(delai: Mouvement.echelon * index, child: child);
  }
}

/// Une colonne dont les premiers enfants apparaissent en decale.
class ListeEchelonnee extends StatelessWidget {
  /// Cree la colonne echelonnee.
  const ListeEchelonnee({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// Les elements, dans l'ordre d'apparition.
  final List<Widget> children;

  /// Alignement transversal de la colonne.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: <Widget>[
      for (int i = 0; i < children.length; i++)
        ElementEchelonne(index: i, child: children[i]),
    ],
  );
}
