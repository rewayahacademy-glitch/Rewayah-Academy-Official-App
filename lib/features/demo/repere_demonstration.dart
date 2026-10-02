// Mode demonstration tuteur (P2-07) : repere visible sur tous les ecrans.
//
// Un bandeau d'angle, pose par `RewayahApp.builder`, pour qu'aucune capture de
// l'apercu ne passe pour la production.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/offline_banner.dart' show ReserveCoinFin;

/// Le libelle du repere. Volontairement en dur : le mode n'existe que sur
/// l'apercu, il n'entre pas dans les traductions du produit.
const String libelleRepereDemonstration = 'Démonstration';

/// L'emprise du ruban le long du bord superieur, depuis le coin de fin : la
/// geometrie du `Banner` de Flutter (bas du ruban a 40 du coin, a 45 degres),
/// soit 40 x racine de 2. Le bandeau hors ligne garde son texte en deca.
const double empriseRepereDemonstration = 40 * math.sqrt2;

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
        // La police du theme (K-42 : captures lisibles) : un `TextStyle` nu
        // retombait sur la police de test et le ruban se peignait en blocs.
        textStyle: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
            .copyWith(
              color: Theme.of(context).colorScheme.onTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
        child: ReserveCoinFin(
          largeur: empriseRepereDemonstration,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
