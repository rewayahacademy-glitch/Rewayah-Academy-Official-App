import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Une pile de cartes independantes : l'ecart des jetons entre chacune, jamais
/// moins que [AppSpacing.lg] (K-55, revue du directeur du 01/10).
///
/// **Cartes jamais collees.** Un contenu independant a sa propre carte,
/// detachee des autres par `Ecart.vLg` (16), l'ecart des ecrans du tuteur.
/// Pour des contenus lies, on ne rapproche pas des cartes : on les met dans UNE
/// seule carte, `CarteGroupee` (sections a filets) ou `GroupeReglages`
/// (rubriques a filets).
///
/// Le composant impose l'ecart : un ecran qui empile des cartes ne choisit
/// pas la distance, il passe ses enfants. `tool/verifier_revue.dart`
/// (`cartes-collees`) refuse toute liste de cartes sans ecart minimum ; ce
/// composant est la parade.
class PileCartes extends StatelessWidget {
  /// Cree une pile verticale (ou horizontale avec [axe]).
  const PileCartes({
    required this.children,
    super.key,
    this.ecart = AppSpacing.lg,
    this.axe = Axis.vertical,
    this.alignement = CrossAxisAlignment.stretch,
  }) : assert(
         ecart >= AppSpacing.lg,
         'Deux cartes se separent de 16 au moins (K-55).',
       );

  /// Les cartes, dans l'ordre d'affichage.
  final List<Widget> children;

  /// L'espace entre deux cartes : 16 au moins.
  final double ecart;

  /// Le sens de la pile.
  final Axis axe;

  /// L'alignement dans l'autre sens : toute la largeur par defaut.
  final CrossAxisAlignment alignement;

  @override
  Widget build(BuildContext context) => Flex(
    direction: axe,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: alignement,
    spacing: ecart,
    children: children,
  );
}
