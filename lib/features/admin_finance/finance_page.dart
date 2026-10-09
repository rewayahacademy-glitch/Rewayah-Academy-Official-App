import 'package:flutter/material.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'politiques_commerciales.dart';
import 'vue_globale_finance.dart';

/// Les deux onglets du domaine Finance, dans l'ordre de `ongletsFinance()`.
enum OngletFinance {
  /// Vue globale (`/admin/finance`, guide Finance V4 §5.6, FI-11a).
  vueGlobale,

  /// Politiques commerciales (`/admin/finance/politiques`, guide §5.7,
  /// FI-11b).
  politiques,
}

/// Le domaine Finance de la direction (FI-1b) : deux onglets, dans la vraie
/// coquille admin.
///
/// - **Vue globale** (FI-11a) : lit `PortFinanceDirection`
///   ([VueGlobaleFinanceBloc]). En production le port rend
///   `CapaciteIndisponible` (FI-BR-12) : l'onglet dit honnetement « Pas
///   encore disponible », sans chiffre ; la demonstration le surcharge.
/// - **Politiques commerciales** (FI-11b) : lit `PortPolitiquesCommerciales`
///   ([PolitiquesCommercialesBloc]). En production le port rend
///   `CapaciteIndisponible` (FI-BR-01) : « Pas encore disponible », sans
///   chiffre ; la demonstration le surcharge.
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
      child: switch (onglet) {
        OngletFinance.vueGlobale => const VueGlobaleFinanceBloc(),
        OngletFinance.politiques => const PolitiquesCommercialesBloc(),
      },
    );
  }
}
