import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comptable/visibilite_montants.dart';
import '../../i18n/strings.g.dart';
import '../montant_sensible.dart';

/// Un pourcentage **derive d'un montant** (« 82 % atteint », « 29,2 % de la
/// tresorerie detenue »), masque avec les montants (Q-9 = a, decide par
/// delegation le 05/10 ; CPT-DIR-2).
///
/// Il suit la meme bascule que [MontantSensible] (`visibiliteMontantsProvider`)
/// et le meme rendu de masquage :
/// - le nombre est remplace par un masque de **longueur fixe**, fait du meme
///   point que celui des montants ([MontantSensible.point]) : « •• % atteint »
///   pour 8 % comme pour 100 %, jamais l'ordre de grandeur ;
/// - le lecteur d'ecran lit « Montant masque », comme pour un montant, jamais
///   le chiffre ;
/// - le texte garde son style dans les deux etats : la ligne ne bouge pas
///   quand on revele.
///
/// Un pourcentage de **regle** (la part fixee par la politique, le seuil
/// d'alerte) ne revele aucun montant : il reste affiche en clair et n'emploie
/// pas ce widget.
class PourcentageSensible extends ConsumerWidget {
  /// Cree le pourcentage.
  const PourcentageSensible({
    required this.valeur,
    required this.gabarit,
    super.key,
    this.style,
  });

  /// Le pourcentage ecrit, sans le signe (« 82 », « 29,2 »).
  final String valeur;

  /// La phrase qui porte le pourcentage, a partir du nombre ecrit (la cle
  /// traduite, par exemple `(v) => t.comptable.commun.atteint(pourcent: v)`).
  final String Function(String valeur) gabarit;

  /// Le style du texte, le meme dans les deux etats.
  final TextStyle? style;

  /// Le masque du nombre : deux points, quelle que soit la valeur.
  static const String masque =
      '${MontantSensible.point}${MontantSensible.point}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    if (affiche) return Text(gabarit(valeur), style: style);
    return Semantics(
      label: t.comptable.commun.montantMasque,
      excludeSemantics: true,
      child: Text(gabarit(masque), style: style),
    );
  }
}

/// La jauge d'un pourcentage derive d'un montant : remplie quand les montants
/// sont affiches, **vide** quand ils sont masques (la longueur remplie dirait
/// le pourcentage aussi surement que le chiffre ; decide par delegation le
/// 05/10, CPT-DIR-2). Lue comme [PourcentageSensible].
class JaugeSensible extends ConsumerWidget {
  /// Cree la jauge.
  const JaugeSensible({
    required this.fraction,
    required this.libelle,
    super.key,
  });

  /// La part remplie, entre 0 et 1, rendue par la source.
  final double fraction;

  /// Ce que lit le lecteur d'ecran quand les montants sont affiches.
  final String libelle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    return Semantics(
      label: affiche ? libelle : t.comptable.commun.montantMasque,
      excludeSemantics: true,
      child: LinearProgressIndicator(value: affiche ? fraction : 0),
    );
  }
}
