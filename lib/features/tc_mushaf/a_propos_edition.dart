import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';

/// La feuille « A propos de cette edition » (MUSHAF-15L).
///
/// Les credits, les licences et les sources de l'edition ne sont pas rendus en
/// permanence : un element rarement utile n'occupe pas l'ecran principal
/// (decision du directeur du 11/10/2026). Ils restent **accessibles et
/// visibles depuis le lecteur**, par son menu : l'attribution Tanzil et
/// l'attribution CC-BY-4.0 de la mise en page sont ainsi tenues.
class FeuilleAProposEdition extends StatelessWidget {
  /// Cree la feuille.
  const FeuilleAProposEdition({super.key});

  /// La cle du contenu (tests).
  static const Key contenuKey = ValueKey<String>('mushaf-a-propos');

  /// Ouvre la feuille.
  static Future<void> ouvrir(BuildContext context) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.tc.coran.mushaf.page15.aProposTitre,
        constructeur: (BuildContext context) => const FeuilleAProposEdition(),
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle courant = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    return Column(
      key: contenuKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.eleve.coran.edition, style: fort),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${t.eleve.coran.source} . ${t.eleve.coran.sourceLien}',
          style: courant,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(t.tc.coran.mushaf.page15.aProposTanzil, style: courant),
        const SizedBox(height: AppSpacing.md),
        Text(t.tc.coran.mushaf.page15.creditMiseEnPage, style: courant),
        const SizedBox(height: AppSpacing.xs),
        Text(t.tc.coran.mushaf.page15.aProposPolice, style: courant),
        const SizedBox(height: AppSpacing.md),
        Text(t.tc.coran.mushaf.page15.aProposLicences, style: courant),
      ],
    );
  }
}
