import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../enseignant_classes/classes_enseignant_page.dart';
import '../tuteur_classes/classes_foyer_page.dart';

/// Les chemins ajoutes par le sprint noyau 24 h, cote frontend.
///
/// **Sous le prefixe de leur role, et c'est le point** : `deciderRedirection`
/// renvoie chez lui tout chemin hors prefixe. `/enseignant/classes` et
/// `/tuteur/classes` traversent donc la porte sans qu'une ligne de
/// `redirection.dart` change.
abstract final class CheminsCore24 {
  /// Mes classes et Classes disponibles, cote enseignant.
  static const String enseignantClasses = '/enseignant/classes';

  /// Les Classes du foyer et celles qui restent ouvertes, cote tuteur. Un
  /// eleve adulte autonome est son propre tuteur (ADR-009) : le meme ecran le
  /// sert.
  static const String tuteurClasses = '/tuteur/classes';

  /// L'eleve autonome retrouve ses Classes sous son propre prefixe de role.
  static const String eleveClasses = '/eleve/classes';
}

/// Les routes du sprint noyau 24 h.
///
/// **Cette fonction ne construit jamais un `GoRouter`.** Elle en **retourne**
/// les routes, comme `routesTcA()` : `tool/verifier_jetons.dart` fait echouer
/// la CI si un second fichier de `lib/` en construit un, et `app_router.dart`
/// appartient a l'integrateur. Deux poses hors coquille, comme
/// `Routes.enseignantBienvenue` : chaque ecran porte son propre retour.
///
/// A l'integration : `...routesCore24()` dans la liste `routes` de
/// `app_router.dart`, et rien d'autre (`docs/core24/CONTRACT_REQUEST_FABLE.md`).
List<RouteBase> routesCore24() => <RouteBase>[
  GoRoute(
    path: CheminsCore24.enseignantClasses,
    builder: (BuildContext _, GoRouterState _) => const ClassesEnseignantPage(),
  ),
  GoRoute(
    path: CheminsCore24.tuteurClasses,
    builder: (BuildContext _, GoRouterState _) => const ClassesFoyerPage(),
  ),
  GoRoute(
    path: CheminsCore24.eleveClasses,
    builder: (BuildContext _, GoRouterState _) => const ClassesFoyerPage(),
  ),
];
