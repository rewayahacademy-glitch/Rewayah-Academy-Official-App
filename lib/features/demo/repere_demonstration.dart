// Mode demonstration tuteur (P2-07) : repere visible sur tous les ecrans.
//
// Un bandeau d'angle, pose par `RewayahApp.builder`, pour qu'aucune capture de
// l'apercu ne passe pour la production.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';

/// Le libelle du repere, traduit (K-41) : `commun.demonstration.repere`.
String get libelleRepereDemonstration => t.commun.demonstration.repere;

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
      label: t.commun.demonstration.repereLu,
      child: Banner(
        message: libelleRepereDemonstration,
        location: BannerLocation.topEnd,
        textDirection: sens,
        layoutDirection: sens,
        color: Theme.of(context).colorScheme.tertiary,
        // La famille vient du theme : un `TextStyle` nu laisse le bandeau
        // (peint, hors `DefaultTextStyle`) sans police, donc illisible
        // (revue AD-S). Couleurs inchangees.
        textStyle: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
            .copyWith(
              color: Theme.of(context).colorScheme.onTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1,
              // Le bandeau de `Banner` ne fait que 80 de long : sans
              // interlettrage et en 9, le mot y tient en entier.
              letterSpacing: 0,
            ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
