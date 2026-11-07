import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Une page que l'on ne voit pas n'offre pas son texte à la sélection.
///
/// Le `SelectionArea` racine (`SelectionRacine`) couvre le `Navigator` : toutes
/// les routes y inscrivent leur texte, y compris celles que la navigation garde
/// construites sous une page opaque. Une telle route est hors écran (entrée
/// « offstage » de l'`Overlay`, `TickerMode` coupé) et n'est parfois **jamais
/// mise en page** : les conteneurs de sélection qui trient leurs textes lisent
/// alors la géométrie d'un `RenderBox` sans taille (assertion `hasSize`,
/// constatée sur le détail d'un dossier de la direction), et « Tout
/// sélectionner » copierait l'écran caché avec l'écran visible.
///
/// Cette enveloppe donne à la page un registre de sélection muet tant que son
/// entrée est hors écran. Sa structure ne change jamais (même
/// `SelectionRegistrarScope`) : l'état de la page est conservé quand elle
/// redevient visible, et son texte se réinscrit.
///
/// À poser sur le contenu de **chaque route** : `routeSure` et les coquilles
/// du routeur (`app_router.dart`), `pageGlissee` (`transitions.dart`).
class SelectionSiVisible extends StatelessWidget {
  /// Enveloppe [child], le contenu d'une route.
  const SelectionSiVisible({required this.child, super.key});

  /// Le contenu de la route.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool visible = TickerMode.valuesOf(context).enabled;
    final SelectionRegistrar? parent = SelectionContainer.maybeOf(context);
    return SelectionRegistrarScope(
      registrar: visible && parent != null ? parent : _RegistreMuet.instance,
      child: child,
    );
  }
}

/// Un registre qui n'inscrit rien.
class _RegistreMuet implements SelectionRegistrar {
  const _RegistreMuet();

  static const _RegistreMuet instance = _RegistreMuet();

  @override
  void add(Selectable selectable) {}

  @override
  void remove(Selectable selectable) {}
}
