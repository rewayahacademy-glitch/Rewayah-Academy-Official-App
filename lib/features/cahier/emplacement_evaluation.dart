import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';

/// Un emplacement d'evaluation par eleve (K-45, point 3) : performance ou
/// faiblesses.
///
/// **Le directeur n'a donne ni l'echelle ni la liste.** Tant que [echelle]
/// est nulle, l'emplacement ne rend rien : aucun libelle, aucune valeur
/// inventee. Le jour ou l'echelle arrive (fournie par l'academie ou le
/// serveur), elle se branche ici, sans toucher au cahier : un titre, puis le
/// choix par cartes partage (`ChoiceCardGroup`, ADR-013).
class EmplacementEvaluation extends StatelessWidget {
  /// Cree un emplacement. [echelle] nulle : rien n'est affiche.
  const EmplacementEvaluation({
    required this.titre,
    required this.onChange,
    this.echelle,
    this.valeurInitiale,
    super.key,
  });

  /// Le titre de l'emplacement, affiche seulement avec une echelle.
  final String titre;

  /// L'echelle fournie. Nulle tant que le directeur ne l'a pas donnee.
  final List<OptionChoix>? echelle;

  /// La valeur deja retenue, s'il y en a une.
  final String? valeurInitiale;

  /// Appele avec la valeur retenue, ou nul si rien ne l'est.
  final ValueChanged<String?> onChange;

  /// Vrai quand l'emplacement a quelque chose a montrer.
  bool get renseigne => echelle?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final List<OptionChoix>? options = echelle;
    if (options == null || options.isEmpty) {
      return const SizedBox.shrink();
    }
    final String? initiale = valeurInitiale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vSection,
        Text(titre, style: Theme.of(context).textTheme.titleSmall),
        Ecart.vMd,
        ChoiceCardGroup(
          options: options,
          autoriserSaisieLibre: false,
          valeurInitiale: initiale == null
              ? null
              : ReponseChoix(valeurs: <String>{initiale}),
          onChange: (ReponseChoix r) =>
              onChange(r.valeurs.isEmpty ? null : r.valeurs.first),
        ),
      ],
    );
  }
}
