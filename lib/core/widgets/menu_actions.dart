import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Une action rare proposee par un [MenuActions].
@immutable
class EntreeAction {
  /// Cree une entree.
  const EntreeAction({
    required this.libelle,
    required this.onChoix,
    this.destructif = false,
  });

  /// Le libelle affiche.
  final String libelle;

  /// Ce qui se passe quand l'action est choisie.
  final VoidCallback onChoix;

  /// Vrai pour une action qui retire ou cloture : rendue en ton alerte.
  final bool destructif;
}

/// Le menu contextuel des actions rares d'un objet (une ligne de liste, une
/// carte), sur la meme base technique que [MenuFiltre] -- `PopupMenuButton`
/// et non un bouton par action, puisque ces actions n'appellent pas un geste
/// courant.
///
/// **Pourquoi ce composant existe** : la mission de reclassement des ecrans
/// operationnels et des personnes demande que les actions rares vivent dans
/// le menu contextuel de l'objet, jamais dans la barre laterale ni comme
/// bouton permanent d'une ligne. Aucun menu de ce type n'existait avant lui.
class MenuActions extends StatelessWidget {
  /// Cree un menu d'actions.
  const MenuActions({
    required this.actions,
    this.tooltip,
    this.points = false,
    this.fermetureNette = false,
    super.key,
  });

  /// Vrai : le menu s'ouvre et disparait d'un coup, sans fondu (le fondu de
  /// sortie dure environ 200 ms, pendant lesquelles il resterait par-dessus).
  /// Pour une action qui anime l'ecran juste derriere le menu (TB-RC n.17 :
  /// la copie du support range ne vole plus sous un menu qui s'efface
  /// encore). L'action part aussitot, comme avant.
  final bool fermetureNette;

  /// Vrai pour le declencheur « ... » (trois points horizontaux, image CLV-07)
  /// au lieu de l'icone de menu : le menu d'un panneau.
  final bool points;

  /// Les actions proposees.
  final List<EntreeAction> actions;

  /// Le libelle parle du bouton qui ouvre le menu.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return PopupMenuButton<int>(
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      popUpAnimationStyle: fermetureNette ? AnimationStyle.noAnimation : null,
      onSelected: (int index) => actions[index].onChoix(),
      itemBuilder: (BuildContext _) => <PopupMenuEntry<int>>[
        for (int i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Text(
              actions[i].libelle,
              style: actions[i].destructif
                  ? palette.inkAlert.applyTo(
                      Theme.of(context).textTheme.bodyMedium ??
                          const TextStyle(),
                    )
                  : null,
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox(
          width: AppMetriques.of(context).cibleTactile,
          height: AppMetriques.of(context).cibleTactile,
          // K-54 : le declencheur est centre dans sa cible.
          child: Center(
            child: points
                ? _TroisPoints(
                    couleur: palette.inkStrong
                        .asIconTheme(size: AppSpacing.xs)
                        .color,
                  )
                : Icon(AppIcons.menu.repos),
          ),
        ),
      ),
    );
  }
}

/// Trois points horizontaux, a l'encre forte : le declencheur d'un menu de
/// panneau.
class _TroisPoints extends StatelessWidget {
  const _TroisPoints({required this.couleur});

  final Color? couleur;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.xs,
    children: <Widget>[
      for (int i = 0; i < 3; i++)
        SizedBox.square(
          dimension: AppSpacing.xs,
          child: DecoratedBox(
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
        ),
    ],
  );
}
