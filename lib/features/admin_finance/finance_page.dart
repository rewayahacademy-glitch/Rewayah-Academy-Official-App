import 'package:flutter/material.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'a_valider/a_valider_page.dart';
import 'politiques_commerciales.dart';
import 'reserve_delegation_page.dart';
import 'vue_globale_finance.dart';

/// Les trois onglets du domaine Finance, dans l'ordre de `ongletsFinance()`.
enum OngletFinance {
  /// Vue globale (`/admin/finance`, guide Finance V4 §5.6, FI-11a).
  vueGlobale,

  /// Politiques commerciales (`/admin/finance/politiques`, guide §5.7,
  /// FI-11b).
  politiques,

  /// Reserve et delegation (`/admin/finance/reserve-delegation`, Comptable
  /// V1 : spec Finance operationnelle §37, voie CPT-DIR).
  reserveDelegation,

  /// A valider (`/admin/finance/a-valider`, decision Q-8 = (a) du 05/10,
  /// CPT-VAL-1) : les demandes du Comptable a valider ou refuser.
  aValider,
}

/// Le domaine Finance de la direction (FI-1b) : quatre onglets, dans la vraie
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
/// - **Reserve et delegation** (Comptable V1, CPT-DIR-1) : les deux panneaux
///   `StrategicReservePolicyPanel` et `FinanceDelegationPolicyPanel`
///   ([ReserveDelegationPage]), lus par `PortPolitiqueReserve` (CPT-BR-12)
///   et `PortDelegationFinance` (CPT-BR-13).
/// - **A valider** (CPT-VAL-1, decision Q-8 = (a) du 05/10) : les demandes
///   du Comptable ([AValiderBloc]), lues par `PortValidationsFinance`
///   (CPT-BR-09). En production le port rend `CapaciteIndisponible` :
///   « Pas encore disponible », aucune decision possible.
///
/// **Ce fichier est gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`) :
/// la voie CPT-DIR ecrit dans `reserve_delegation_page.dart` et son dossier,
/// jamais ici.
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
        OngletFinance.reserveDelegation => const ReserveDelegationPage(),
        OngletFinance.aValider => const AValiderBloc(),
      },
    );
  }
}
