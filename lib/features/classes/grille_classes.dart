import 'package:flutter/material.dart';

import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';

/// La disposition des cartes de Classe selon la largeur disponible.
///
/// **Decidee par contraintes, jamais par plateforme.** Une colonne sur
/// telephone, deux sur tablette, trois sur bureau : au dela, une carte
/// s'etirerait sans rien apprendre de plus, et un bouton primaire de 1400
/// points n'est plus un bouton. La colonne de page est deja bornee a 1200 par
/// `PageShell` ; ici c'est la largeur **reellement recue** qui decide, ce qui
/// vaut aussi pour un panneau plus etroit que la page.
///
/// Le seuil vient d'`AppGabarit`, le seul fichier du depot autorise a comparer
/// une largeur a un nombre.
class GrilleClasses extends StatelessWidget {
  /// Cree une grille.
  const GrilleClasses({required this.cartes, super.key});

  /// Les cartes, dans l'ordre de lecture.
  final List<Widget> cartes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        // [RESPONSIVE]
        final int colonnes = switch (AppGabarit.pour(contraintes.maxWidth)) {
          Gabarit.mobile => 1,
          Gabarit.tablette => 2,
          Gabarit.desktop => 3,
        };
        if (colonnes == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final Widget carte in cartes) ...<Widget>[carte, Ecart.vLg],
            ],
          );
        }
        final List<Widget> lignes = <Widget>[];
        for (int i = 0; i < cartes.length; i += colonnes) {
          lignes.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int c = 0; c < colonnes; c++) ...<Widget>[
                  if (c > 0) Ecart.hLg,
                  Expanded(
                    child: i + c < cartes.length
                        ? cartes[i + c]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
          lignes.add(Ecart.vLg);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: lignes,
        );
      },
    );
  }
}
