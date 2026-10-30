import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Ce que la salle repond quand on veut la quitter sans passer par son
/// bouton « Quitter » : vrai, la route peut partir ; faux, on reste.
typedef DemandeSortieSalle = Future<bool> Function();

/// La garde du retour en salle (consigne du pilote du 30/10/2026, point 4).
///
/// Le geste ou le bouton « retour » du telephone (Android) et le bouton
/// retour du navigateur (PWA) faisaient quitter la seance : la route `/salle`
/// se demontait, et son `dispose` coupait l'appel. L'enseignant est ainsi
/// sorti et rentre quinze fois en une seance.
///
/// **Un seul point d'interception pour toutes les plateformes** :
/// `GoRoute.onExit`. go_router l'appelle quand la route est retiree par un
/// retour du systeme (`popRoute`) comme par un retour du navigateur
/// (`setNewRoutePath`) ; un `PopScope` ne voit pas le second. La route le
/// branche sur [autoriserSortie] ; la salle, tant qu'on y est, inscrit sa
/// question ([inscrire]) et la retire en partant ([retirer]).
///
/// La route vit dans le routeur, la salle dans une bibliotheque differee :
/// ce registre est le seul lien entre les deux, sans import de l'ecran.
final class GardeSortieSalle {
  GardeSortieSalle._();

  /// Le registre de l'application.
  static final GardeSortieSalle instance = GardeSortieSalle._();

  DemandeSortieSalle? _demande;

  /// La salle inscrit sa question tant qu'on y est.
  void inscrire(DemandeSortieSalle demande) => _demande = demande;

  /// La salle retire sa question, et seulement la sienne.
  void retirer(DemandeSortieSalle demande) {
    if (identical(_demande, demande)) _demande = null;
  }

  /// Le rappel de `GoRoute.onExit` pour `/salle`. Sans salle inscrite,
  /// rien ne retient la route.
  FutureOr<bool> autoriserSortie(BuildContext _, GoRouterState _) {
    final DemandeSortieSalle? demande = _demande;
    if (demande == null) return true;
    return demande();
  }
}
