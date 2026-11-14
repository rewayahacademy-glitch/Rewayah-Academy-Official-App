// ESPACE-APPRENDRE (lot 5) : la route de l'espace Apprendre. Le routeur unique
// (`lib/core/router/app_router.dart`) ne recoit qu'une ligne d'inclusion, dans
// la branche Apprendre de la coquille eleve, **avant** le Coran : la premiere
// route d'une branche est sa destination. **Cette fonction ne construit
// jamais un `GoRouter`.**

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/go_route_sure.dart';
import '../../core/router/routes.dart';
import 'espace_apprendre_page.dart';

/// `/eleve/apprendre`, ouvert sur la Bibliotheque ; `?onglet=programme` ou
/// `?onglet=livret` ouvre un autre onglet.
List<GoRoute> routesApprendre() => <GoRoute>[
  GoRouteSure(
    path: Routes.eleveApprendre,
    builder: (BuildContext _, GoRouterState _) => const EspaceApprendrePage(),
  ),
];
