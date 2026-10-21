import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import 'controle_segmente.dart';
import 'selecteur_section.dart';

/// La sous-navigation d'un domaine admin qui a plusieurs fonctions pairs.
///
/// **Premier domaine a en avoir besoin : Pedagogie**, avec ses cinq
/// fonctions (Diagnostics, Progression, Evaluations, Programmes, Qualite).
/// Configuration en a trois ou quatre, Personnes et Securite et audit deux.
///
/// Se pose dans `PageShell.entete` -- « ce qui suit immediatement le titre
/// et ne defile pas ». Chaque section est une **route distincte**, pas un
/// panneau local : le choix passe par `GoRouter`, meme mecanique que
/// `_CoquilleAdmin.aller()` (`core/router/app_router.dart`).
///
/// **Ce n'est plus une rangee d'onglets qui defile** (revue du directeur,
/// 01/10/2026, ONGLETS-1) : le rendu est celui de [SelecteurSection], qui
/// choisit selon le nombre de sections et la largeur entre un controle
/// segmente (quatre au plus sur telephone, ou en ligne sur grand ecran) et un
/// menu deroulant qui affiche la section courante. Aucun defilement
/// horizontal, aucun onglet cache hors de la vue.
class SousNavigationDomaine extends StatelessWidget {
  /// Cree la sous-navigation.
  const SousNavigationDomaine({
    required this.onglets,
    required this.indexActif,
    super.key,
  });

  /// Les fonctions du domaine, dans l'ordre d'affichage impose.
  final List<({String libelle, String chemin})> onglets;

  /// L'index de l'ecran courant dans [onglets].
  final int indexActif;

  @override
  Widget build(BuildContext context) {
    return SelecteurSection<int>(
      libelle: t.commun.sections.page,
      valeur: indexActif,
      sections: <Segment<int>>[
        for (int i = 0; i < onglets.length; i++)
          Segment<int>(valeur: i, libelle: onglets[i].libelle),
      ],
      onChange: (int index) {
        if (index == indexActif) return;
        GoRouter.of(context).go(onglets[index].chemin);
      },
    );
  }
}
