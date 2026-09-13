import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Le numero d'un verset, dans la rosace qui le porte sur un mushaf.
///
/// **Dessine, jamais tire d'un glyphe de la police.** Unicode reserve U+06DD
/// (`ARABIC END OF AYAH`) exactement a cet usage, et c'est la solution la plus
/// courte -- mais toutes les polices ne le portent pas, et un carre vide au
/// milieu du texte coranique serait pire que tout. Un cercle et un chiffre se
/// rendent partout, avec la meme police que le texte.
///
/// **Les chiffres sont arabo-indiens**, ceux du mushaf imprime : un « 255 » en
/// chiffres latins au milieu d'une page uthmanie se verrait immediatement.
///
/// Le composant est **muet pour les technologies d'assistance** : c'est un
/// repere de mise en page, pas du texte a lire. Un lecteur d'ecran doit lire le
/// verset, pas epeler son numero au milieu de la phrase -- c'est a l'ecran qui
/// l'emploie de l'envelopper dans un `ExcludeSemantics`, ou de porter lui-meme
/// la reference dans son etiquette.
class RosaceVerset extends StatelessWidget {
  /// Cree la rosace d'un numero de verset.
  const RosaceVerset({required this.numero, super.key, this.echelle = 1});

  /// Le rang du verset dans sa sourate.
  final int numero;

  /// Le grossissement courant du texte, pour que la rosace suive.
  ///
  /// Une rosace de taille fixe au milieu d'un texte grossi deux fois se
  /// verrait comme une coquille, et briserait la ligne de base.
  final double echelle;

  /// Les chiffres arabo-indiens, de zero a neuf.
  static const List<String> _chiffres = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  /// Ecrit un entier positif en chiffres arabo-indiens.
  static String enChiffresArabes(int valeur) {
    if (valeur < 0) {
      return '';
    }
    final StringBuffer sortie = StringBuffer();
    for (final int unite in valeur.toString().codeUnits) {
      final int rang = unite - 0x30;
      sortie.write(rang >= 0 && rang <= 9 ? _chiffres[rang] : '');
    }
    return sortie.toString();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double diametre = AppSpacing.xl * echelle;

    return Container(
      constraints: BoxConstraints(minWidth: diametre, minHeight: diametre),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(palette.borderResting.asBorderSide()),
      ),
      child: Text(
        enChiffresArabes(numero),
        textAlign: TextAlign.center,
        style: palette.inkMuted.applyTo(
          AppTypography.document(taille: 12 * echelle, interligne: 1.1),
        ),
      ),
    );
  }
}
