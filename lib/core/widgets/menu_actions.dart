import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';

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
  const MenuActions({required this.actions, this.tooltip, super.key});

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
          child: Icon(AppIcons.menu.repos),
        ),
      ),
    );
  }
}
