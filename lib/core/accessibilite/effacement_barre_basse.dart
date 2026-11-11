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
  bool _commandes = false;
  int _feuilles = 0;

  /// Vrai : la barre du bas est effacee. Sans effet apres [dispose] (un
  /// signal differe peut arriver apres la fermeture de la coquille).
  void signaler({required bool effacee}) {
    _commandes = effacee;
    _maj();
  }

  /// BANDE-BARRE (11/11/2026) : la barre flotte sur la page ; une feuille
  /// du bas ouverte par la page monte depuis le bord de l'ecran, la ou est
  /// la barre. La barre s'efface donc tant que la feuille est ouverte. Rend
  /// la fonction qui la fait revenir (sans effet au second appel).
  VoidCallback effacerPourUneFeuille() {
    _feuilles++;
    _maj();
    bool rendue = false;
    return () {
      if (rendue) return;
      rendue = true;
      _feuilles--;
      _maj();
    };
  }

  void _maj() {
    if (!_libere) value = _commandes || _feuilles > 0;
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
