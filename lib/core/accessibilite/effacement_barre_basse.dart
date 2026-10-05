import 'package:flutter/widgets.dart';

/// MA-CMD-1 (finition, 02/10/2026, directeur : « le header qui prend
/// l'autre [moitie], le support partage n'a plus de place pour s'afficher ») :
/// pendant la lecture du Coran en Mode Accessibilite, la barre du bas de
/// `NavShell` s'efface avec les commandes de [CommandesMasquables] et revient
/// a la meme touche.
///
/// `NavShell` pose ce controleur au-dessus de son contenu ; un descendant qui
/// le demande (`CommandesMasquables(effacerBarreBasse: true)`) y signale si
/// ses commandes sont visibles. Hors de `NavShell`, rien n'est pose et rien
/// ne change. Un widget de l'arbre, pas un fournisseur Riverpod : le lecteur
/// du Coran vit parfois dans un conteneur isole.
class ControleurBarreBasse extends ValueNotifier<bool> {
  /// Cree le controleur : la barre est visible.
  ControleurBarreBasse() : super(false);

  bool _libere = false;

  /// Vrai : la barre du bas est effacee. Sans effet apres [dispose] (un
  /// signal differe peut arriver apres la fermeture de la coquille).
  void signaler({required bool effacee}) {
    if (!_libere) value = effacee;
  }

  @override
  void dispose() {
    _libere = true;
    super.dispose();
  }
}

/// Transmet le [ControleurBarreBasse] de `NavShell` a ses descendants.
class EffacementBarreBasse extends InheritedWidget {
  /// Pose le controleur.
  const EffacementBarreBasse({
    required this.controleur,
    required super.child,
    super.key,
  });

  /// Le controleur de la coquille.
  final ControleurBarreBasse controleur;

  /// Le controleur le plus proche, ou nul hors de `NavShell`.
  static ControleurBarreBasse? de(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EffacementBarreBasse>()?.controleur;

  @override
  bool updateShouldNotify(EffacementBarreBasse oldWidget) =>
      controleur != oldWidget.controleur;
}
