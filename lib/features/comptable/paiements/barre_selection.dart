// `PayoutBatchBar` (spec §14.2, §39, §41 ; CPT-PAY-1 pour la barre,
// CPT-PAY-2 pour « Payer la selection ») : collee en bas de W02 des qu'une
// ligne est retenue. Elle dit combien de paiements sont retenus, jamais un
// total : le total d'un lot est **rendu par le preflight** de la source
// (FI6, §41), l'ecran n'additionne rien.

import 'package:flutter/material.dart';

import '../../../core/capacites/port_export_rapports.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../graphiques/action_export.dart';

/// La barre de selection de W02.
class BarreSelection extends StatelessWidget {
  /// Cree la barre.
  const BarreSelection({
    required this.nombre,
    required this.onVider,
    this.onPayer,
    this.horsLigne = false,
    this.identifiants = const <String>[],
    super.key,
  });

  /// Les identifiants retenus, pour « Exporter la selection ».
  final List<String> identifiants;

  /// Le nombre de paiements retenus.
  final int nombre;

  /// Relache toute la selection.
  final VoidCallback onVider;

  /// Ouvre le preflight et la confirmation du lot (CPT-PAY-2).
  final VoidCallback? onPayer;

  /// Vrai hors ligne : « Payer la selection » cede la place a une phrase.
  final bool horsLigne;

  /// La cle du bouton « Payer la selection ».
  static const Key clePayer = ValueKey<String>('barre-selection-payer');

  /// La cle de la barre.
  static const Key cleBarre = ValueKey<String>('barre-selection');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.comptable.paiements;
    final VoidCallback? payer = onPayer;
    return Semantics(
      key: cleBarre,
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            p.selection(n: nombre),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            horsLigne ? p.horsLigne : p.selectionPhrase,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          // COMPTA-GRAPH-1 : l'export de la selection, par un port ; sans
          // capacite, une phrase le dit a la place de l'action.
          ActionExport(
            perimetre: PerimetreExport.selection,
            identifiants: identifiants,
          ),
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: <Widget>[
              ActionPrincipale(
                libelle: p.actions.viderSelection,
                niveau: NiveauAction.tertiaire,
                onPress: onVider,
              ),
              if (payer != null && !horsLigne)
                ActionPrincipale(
                  key: clePayer,
                  libelle: p.actions.payerSelection,
                  onPress: payer,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
