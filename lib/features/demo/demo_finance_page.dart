// Le domaine Finance en demonstration : /demo/finance (hors production,
// FI-1b).
//
// `?ecran=vueGlobale|politiques` (Vue globale par defaut) : la VRAIE coquille
// admin (`AdminShell`, domaine Finance actif) sur la VRAIE page Finance. Aucun
// port n'est appele : la page n'en lit aucun tant que FI-1c ne les a pas
// poses. Les autres vues (tuteur, enfant, adulte, enseignant) arrivent avec
// leurs ecrans (FI-1c et suivantes).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../admin_finance/finance_page.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les routes de la demonstration Finance : AUCUNE en production, ni quand
/// l'environnement n'est pas declare (`environnementAutoriseDemo`).
List<RouteBase> routesDemoFinance(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoFinance,
      builder: (BuildContext _, GoRouterState etat) => DemoFinancePage(
        onglet: OngletFinance.values.firstWhere(
          (OngletFinance o) => o.name == etat.uri.queryParameters['ecran'],
          orElse: () => OngletFinance.vueGlobale,
        ),
      ),
    ),
  ];
}

/// L'adresse d'un onglet de la demonstration.
String adresseDemoFinance(OngletFinance onglet) => Uri(
  path: Routes.demoFinance,
  queryParameters: <String, String>{'ecran': onglet.name},
).toString();

/// La coquille admin de demonstration sur l'onglet Finance [onglet].
class DemoFinancePage extends StatelessWidget {
  /// Cree la page.
  const DemoFinancePage({required this.onglet, super.key});

  /// L'onglet affiche.
  final OngletFinance onglet;

  @override
  Widget build(BuildContext context) {
    final List<({String libelle, String chemin})> reels = ongletsFinance();
    return RepereDemonstration(
      child: AdminShell(
        domaines: domainesAdmin(voitDirection: false),
        domaineActif: AdminDomaine.finance,
        // Seul Finance mene quelque part : les autres domaines n'ont pas de
        // demonstration ici et restent en place (K-28, meme regle que
        // `espaces_controleur_demo.dart`). La demonstration complete de la
        // direction reste le pont `?demo=admin`.
        onAller: (String chemin) {
          if (chemin == Routes.adminFinance) {
            context.go(adresseDemoFinance(OngletFinance.vueGlobale));
          }
        },
        onCompte: () {},
        child: FinancePage(
          onglet: onglet,
          onglets: <({String libelle, String chemin})>[
            for (final OngletFinance o in OngletFinance.values)
              (libelle: reels[o.index].libelle, chemin: adresseDemoFinance(o)),
          ],
        ),
      ),
    );
  }
}
