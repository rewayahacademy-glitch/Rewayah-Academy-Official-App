// CANDIDATS-FLUX (06/11/2026) : la route de l'import des formulaires de
// candidature (ADM-23, portee de la PR 50), sous Personnes > Candidatures.
//
// **Aucun `GoRouter` n'est construit ici** (un seul routeur,
// `lib/core/router/app_router.dart`) : ce fichier rend une route, que le
// routeur monte d'une ligne (G8). La coquille de la direction lui est passee
// par le routeur, qui seul la connait.
//
// La route se declare AVANT `Routes.adminPersonnesCandidature`
// (`/admin/personnes/candidatures/:reference`, contrainte R5) : sinon
// « import » serait lu comme une reference `CAND-...`.
//
// Une vraie route et non une page empilee : le robot du 06/11 a montre qu'une
// page posee par `Navigator.push` restait au-dessus quand la direction allait
// ailleurs par l'adresse.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'import_formulaires_page.dart';

/// Les chemins du lot.
abstract final class RoutesCandidatsFlux {
  /// L'import des formulaires de candidature (super administrateur, double
  /// verification demandee au geste ; le serveur reste la barriere).
  static const String importFormulaires =
      '/admin/personnes/candidatures/import';
}

/// Les routes du lot ; [coquille] habille la page comme les autres pages de
/// la direction.
List<RouteBase> routesCandidatsFlux(Widget Function(Widget page) coquille) =>
    <RouteBase>[
      GoRoute(
        path: RoutesCandidatsFlux.importFormulaires,
        builder: (BuildContext _, GoRouterState _) =>
            coquille(const ImportFormulairesPage()),
      ),
    ];
