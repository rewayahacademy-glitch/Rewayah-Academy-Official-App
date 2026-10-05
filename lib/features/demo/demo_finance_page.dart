// Le domaine Finance en demonstration : /demo/finance (hors production,
// FI-1b).
//
// `?ecran=vueGlobale|politiques|reserveDelegation` (Vue globale par defaut) : la VRAIE coquille
// admin (`AdminShell`, domaine Finance actif) sur la VRAIE page Finance. La
// Vue globale lit le port de la direction, surcharge ici par la
// demonstration (`FinanceDirectionDemo`, FI-11a) ; Politiques lit
// `PolitiquesCommercialesDemo` (FI-11b), dont la publication reste
// indisponible. Les autres vues (tuteur, enfant, adulte, enseignant)
// arrivent avec leurs ecrans.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/comptable/visibilite_montants.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../admin_finance/finance_page.dart';
import '../admin_finance/politiques_commerciales.dart';
import '../admin_finance/vue_globale_finance.dart';
import 'comptable/direction_demo.dart';
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
        portPolitiquesCommercialesProvider.overrideWithValue(
          const PolitiquesCommercialesDemo(),
        ),
        politiquesCommercialesProvider.overrideWith(
          (Ref _) => lirePolitiques(const PolitiquesCommercialesDemo()),
        ),
        // Reserve et delegation (Comptable V1, CPT-F) : la politique de la
        // Reserve et la delegation de la demonstration Direction.
        ...surchargesDemoDirection(),
        // Les montants de Reserve et delegation partent masques (R-FIN-01)
        // sans lire la session : la demonstration ne depend d'aucun
        // service (CPT-FUS ; sinon `MontantSensible` echoue hors Supabase).
        visibiliteMontantsProvider.overrideWith(_MontantsMasquesDemo.new),
        // Le lien d'une alerte ouvre une page de Personnes ou d'Operations,
        // domaines sans demonstration ici : il reste en place (K-28), comme
        // `onAller` plus bas, au lieu de sortir vers une route reelle gardee.
        ouvrirCibleAlerteFinanceProvider.overrideWithValue(
          (BuildContext _, CibleAlerteFinance _) {},
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

/// La visibilite des montants de la demonstration Finance : masques au
/// depart, basculables, sans lien avec la session.
class _MontantsMasquesDemo extends VisibiliteMontants {
  @override
  bool build() => false;
}
