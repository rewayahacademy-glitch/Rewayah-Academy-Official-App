// Le domaine Finance en demonstration : /demo/finance (hors production,
// FI-1b).
//
// `?ecran=vueGlobale|politiques` (Vue globale par defaut) : la VRAIE coquille
// admin (`AdminShell`, domaine Finance actif) sur la VRAIE page Finance. La
// Vue globale lit le port de la direction, surcharge ici par la
// demonstration (`FinanceDirectionDemo`, FI-11a) ; Politiques reste neutre
// jusqu'a FI-11b. Les autres vues (tuteur, enfant, adulte, enseignant)
// arrivent avec leurs ecrans.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../admin_finance/finance_page.dart';
import '../admin_finance/vue_globale_finance.dart';
import 'finance_demo.dart';
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
    // Le port ET son lecteur derive : sans declaration de dependances, le
    // lecteur vivrait dans le conteneur racine et lirait le vrai port
    // (Riverpod, portee imbriquee).
    return ProviderScope(
      overrides: <Override>[
        portFinanceDirectionProvider.overrideWithValue(
          const FinanceDirectionDemo(),
        ),
        vueGlobaleFinanceProvider.overrideWith(
          (Ref _) => const FinanceDirectionDemo().vueGlobale(),
        ),
      ],
      child: RepereDemonstration(
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
                (
                  libelle: reels[o.index].libelle,
                  chemin: adresseDemoFinance(o),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
