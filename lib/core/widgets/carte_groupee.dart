import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Le filet fin qui separe deux sections d'une meme carte : une ligne
/// `contourCarte` sans marge propre. La carte reste UN rectangle.
class FiletCarte extends StatelessWidget {
  /// Cree le filet.
  const FiletCarte({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: palette.contourCarte.asBorderSide()),
        ),
        child: const SizedBox(width: double.infinity),
      ),
    );
  }
}

/// UNE grande carte pour des contenus lies : les [sections] sont separees par
/// un filet fin ([FiletCarte]) et un espace `Ecart.vLg` de chaque cote, jamais
/// par des cartes jointives (K-55).
///
/// Elle rend une [AppCard] : meme rayon, meme surface, meme ombre que toutes
/// les cartes du produit. Pour des rubriques de reglage a icone, on garde
/// `GroupeReglages`, qui porte ses propres lignes et ses filets en retrait.
class CarteGroupee extends StatelessWidget {
  /// Cree la carte.
  const CarteGroupee({
    required this.sections,
    super.key,
    this.marge,
    this.dominante = false,
  });

  /// Les sections, de haut en bas.
  final List<Widget> sections;

  /// Marge interne de la carte ; celle du mode courant par defaut.
  final double? marge;

  /// Voir `AppCard.dominante`.
  final bool dominante;

  @override
  Widget build(BuildContext context) => AppCard(
    marge: marge,
    dominante: dominante,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          if (i > 0) ...<Widget>[Ecart.vLg, const FiletCarte(), Ecart.vLg],
          sections[i],
        ],
      ],
    ),
  );
}
