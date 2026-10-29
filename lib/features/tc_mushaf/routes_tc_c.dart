import 'package:go_router/go_router.dart';

import '../../core/router/page_differee.dart';
import 'mushaf_page.dart' deferred as d_mushaf_page;

/// Les chemins du moteur Coran, sous le prefixe reserve `/tc/`.
abstract final class RoutesCoran {
  /// Le moteur Coran, hors classe.
  static const String mushaf = '/tc/mushaf';
}

/// Les routes du moteur Coran.
///
/// **Cette fonction ne construit jamais un `GoRouter`, elle en retourne les
/// routes** (decision D-04). `lib/core/router/app_router.dart` est PROTECTED,
/// et `tool/verifier_jetons.dart` fait echouer la CI sur tout second `GoRouter`
/// construit dans `lib/`. Agent Z appelle cette fonction depuis `app_router`,
/// promeut la constante dans `routes.dart` et ajuste `redirection.dart` --
/// sans quoi la route sera redirigee vers la racine du role.
///
/// **Une route sans entree de navigation n'existe pas.** L'entree reste a
/// arbitrer : `nav_shell.dart` est PROTECTED et plafonne a quatre destinations
/// par assertion, et le Coran en a deja une (`/eleve/coran`). Le detail est
/// dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_C.md`.
List<RouteBase> routesTcC() => <RouteBase>[
  GoRoute(
    path: RoutesCoran.mushaf,
    // Charge a la demande (lot ouverture rapide, 29/10/2026).
    builder: (_, _) => PageDifferee(
      cle: 'routes_tc_c.d_mushaf_page',
      charger: d_mushaf_page.loadLibrary,
      construire: () => d_mushaf_page.MushafPage(),
    ),
  ),
];
