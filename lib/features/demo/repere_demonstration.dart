// Mode demonstration tuteur (P2-07) : repere visible sur tous les ecrans.
//
// Un bandeau d'angle, pose par `RewayahApp.builder`, pour qu'aucune capture de
// l'apercu ne passe pour la production.

import 'package:flutter/material.dart';

/// Le libelle du repere. Volontairement en dur : le mode n'existe que sur
/// l'apercu, il n'entre pas dans les traductions du produit.
const String libelleRepereDemonstration = 'Démonstration';

/// Coiffe [child] d'un bandeau d'angle « Démonstration ».
class RepereDemonstration extends StatelessWidget {
  /// Cree le repere.
  const RepereDemonstration({super.key, required this.child});

  /// Le rendu de l'application.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    // Le bandeau est peint, donc muet pour un lecteur d'ecran : ce noeud
    // l'annonce (revue P2-10, constat 2), sans rien changer au rendu.
    return Semantics(
      container: true,
      label: 'Mode $libelleRepereDemonstration',
      child: Banner(
        message: libelleRepereDemonstration,
        location: BannerLocation.topEnd,
        textDirection: sens,
        layoutDirection: sens,
        color: Theme.of(context).colorScheme.tertiary,
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.onTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
