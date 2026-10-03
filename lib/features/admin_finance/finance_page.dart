import 'package:flutter/material.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// Les deux onglets du domaine Finance, dans l'ordre de `ongletsFinance()`.
enum OngletFinance {
  /// Vue globale (`/admin/finance`, guide Finance V4 §5.6, FI-11a).
  vueGlobale,

  /// Politiques commerciales (`/admin/finance/politiques`, guide §5.7,
  /// FI-11b).
  politiques,
}

/// Le domaine Finance de la direction (FI-1b) : un onglet, dans la vraie
/// coquille admin.
///
/// **Page neutre honnete** : aucun port Finance n'existe encore (ils
/// arrivent en FI-1c, branches en BR-1), donc l'onglet dit « Pas encore
/// disponible » (`NatureEtat.indisponible`), sans chiffre, sans bouton qui
/// ne mene nulle part. Le contenu des ecrans viendra en FI-11a et FI-11b.
class FinancePage extends StatelessWidget {
  /// Cree l'onglet [onglet].
  const FinancePage({required this.onglet, this.onglets, super.key});

  /// L'onglet affiche.
  final OngletFinance onglet;

  /// Les onglets et leurs adresses ; `ongletsFinance()` par defaut. La
  /// demonstration (`/demo/finance`) y met ses propres adresses pour ne
  /// jamais quitter la demonstration.
  final List<({String libelle, String chemin})>? onglets;

  @override
  Widget build(BuildContext context) {
    final List<({String libelle, String chemin})> liste =
        onglets ?? ongletsFinance();
    return PageShell(
      titre: liste[onglet.index].libelle,
      entete: SousNavigationDomaine(onglets: liste, indexActif: onglet.index),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        dependance: switch (onglet) {
          OngletFinance.vueGlobale => 'FI-1c, FI-11a, FI-BR-12',
          OngletFinance.politiques => 'FI-1c, FI-11b, FI-BR-02',
        },
      ),
    );
  }
}
