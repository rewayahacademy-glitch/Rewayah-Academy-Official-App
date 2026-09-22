import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';

/// Le rappel calme de la piece d'identite, pour un eleve ou un tuteur.
///
/// **Propose, jamais impose** (contrat du sprint, section 5.1) : le KYC des
/// familles est non bloquant. Le rappel dit ce que la piece permet et ou elle
/// se depose ; « Faire plus tard » est un vrai bouton, pas une case cachee.
/// Aucun vocabulaire menacant.
class RappelKyc extends StatelessWidget {
  /// Cree le rappel.
  const RappelKyc({required this.onDeposer, super.key, this.onPlusTard});

  /// Ouvre le depot de la piece.
  final VoidCallback onDeposer;

  /// Remet la piece a plus tard. `null` : le rappel se lit sans bouton.
  final VoidCallback? onPlusTard;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return AppCard(
      surface: palette.washAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.classes.kyc.rappelTitre,
            style: textes.titleMedium ?? const TextStyle(),
          ),
          Ecart.vSm,
          Text(
            t.classes.kyc.rappelDetail,
            style: textes.bodyMedium ?? const TextStyle(),
          ),
          Ecart.vLg,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ActionPrincipale(
                libelle: t.classes.kyc.rappelAction,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: onDeposer,
              ),
              if (onPlusTard != null)
                ActionPrincipale(
                  libelle: t.classes.kyc.plusTard,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: onPlusTard,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
