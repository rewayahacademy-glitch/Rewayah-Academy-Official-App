import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../widgets/selection_si_visible.dart';

/// Une `GoRoute` dont le contenu n'offre pas son texte à la sélection tant que
/// la page est hors écran (`SelectionSiVisible`, directeur, 07/11/2026).
///
/// Seul constructeur de route du routeur : `go_router` construit des pages
/// sans transition (`NoTransitionPage`) pour cette application, donc aucun
/// thème de transition ne peut envelopper le contenu à un seul endroit.
class GoRouteSure extends GoRoute {
  /// Comme `GoRoute`, avec le contenu de `builder` enveloppé.
  GoRouteSure({
    required super.path,
    super.name,
    GoRouterWidgetBuilder? builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    super.metadata,
    super.onExit,
    super.caseSensitive,
    super.routes,
  }) : super(
         builder: builder == null
             ? null
             : (BuildContext contexte, GoRouterState etat) =>
                   SelectionSiVisible(child: builder(contexte, etat)),
       );
}
