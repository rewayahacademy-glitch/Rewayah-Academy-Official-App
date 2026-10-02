import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';

/// Un emplacement d'evaluation par eleve (K-45, point 3) : la performance,
/// choix unique, ou les faiblesses, choix multiple (N1, directeur 27/09).
///
/// Un titre, puis le choix par cartes partage (`ChoiceCardGroup`, ADR-013) :
/// aucun widget recopie (K-10). Sans [echelle], l'emplacement ne rend rien,
/// jamais un titre seul.
class EmplacementEvaluation extends StatelessWidget {
  /// Cree un emplacement.
  const EmplacementEvaluation({
    required this.titre,
    required this.onChange,
    this.echelle,
    this.valeursInitiales = const <String>{},
    this.selectionMultiple = false,
    super.key,
  });

  /// Le titre de l'emplacement, affiche seulement avec une echelle.
  final String titre;

  /// L'echelle ou la liste proposee.
  final List<OptionChoix>? echelle;

  /// Les valeurs deja retenues (preremplies depuis la seance precedente).
  final Set<String> valeursInitiales;

  /// Vrai pour plusieurs reponses (les faiblesses).
  final bool selectionMultiple;

  /// Appele avec les valeurs retenues, vide si rien ne l'est.
  final ValueChanged<Set<String>> onChange;

  /// Vrai quand l'emplacement a quelque chose a montrer.
  bool get renseigne => echelle?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final List<OptionChoix>? options = echelle;
    if (options == null || options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vSection,
        Text(titre, style: Theme.of(context).textTheme.titleSmall),
        Ecart.vMd,
        ChoiceCardGroup(
          options: options,
          autoriserSaisieLibre: false,
          selectionMultiple: selectionMultiple,
          valeurInitiale: valeursInitiales.isEmpty
              ? null
              : ReponseChoix(valeurs: valeursInitiales),
          onChange: (ReponseChoix r) => onChange(r.valeurs),
        ),
      ],
    );
  }
}
