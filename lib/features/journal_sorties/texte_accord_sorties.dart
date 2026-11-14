import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// HORS-SALLE-2 : le texte de l'accord du journal des sorties, **mot pour
/// mot** celui de `docs/current/TEXTES-VALIDES/ACCORD-JOURNAL-SORTIES.md`
/// (PROPOSITION, a valider par le directeur ; le journal reste eteint tant
/// qu'il ne l'est pas). Une seule carte : ce qui est note, pourquoi, qui le
/// lit, le retrait, et ce qui se passe sans accord.
class TexteAccordSorties extends StatelessWidget {
  /// Cree le texte. [adulte] : la version de l'eleve adulte autonome, qui
  /// decide pour lui-meme.
  const TexteAccordSorties({required this.adulte, super.key});

  /// Vrai pour la version de l'eleve adulte.
  final bool adulte;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Traductions$journalSorties$texte$fr texte = t.journalSorties.texte;
    final List<String> paragraphes = adulte
        ? <String>[
            texte.adulte.quoi,
            texte.adulte.pourquoi,
            texte.adulte.qui,
            texte.adulte.retrait,
            texte.adulte.sansAccord,
          ]
        : <String>[
            texte.parent.quoi,
            texte.parent.pourquoi,
            texte.parent.qui,
            texte.parent.retrait,
            texte.parent.sansAccord,
          ];
    return AppCard(
      key: const ValueKey<String>('texte-accord-sorties'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              texte.titre,
              style: AppPalette.of(context).inkStrong
                  .applyTo(textes.titleMedium ?? const TextStyle()),
            ),
          ),
          for (final String p in paragraphes) Text(p, style: textes.bodyLarge),
        ],
      ),
    );
  }
}
