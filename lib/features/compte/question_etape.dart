import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Le titre d'une etape et sa phrase, en tete du contenu d'une `PageEtape` du
/// Compte : S03-S04 « Recharger » et S09-S10 « Arreter l'acces ». Un seul
/// fichier pour les deux (constat 17 de la revue LT) ; reste dans le Compte
/// tant qu'aucun autre parcours n'en a besoin.
class QuestionEtape extends StatelessWidget {
  /// Cree la question.
  const QuestionEtape({required this.titre, required this.phrase, super.key});

  /// La question, lue comme un titre.
  final String titre;

  /// La phrase qui la precise.
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(titre, style: textes.headlineSmall),
          ),
          Ecart.vSm,
          Text(phrase, style: textes.bodyMedium),
        ],
      ),
    );
  }
}
