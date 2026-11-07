import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';

/// La ligne discrete en tete d'une page qui se confirme apres lecture
/// (accords, contrat) : « Lisez jusqu'en bas pour confirmer. »
///
/// Arbitrage du garde-cap du 07/11/2026 (PLAN-TROIS-SALLES §2) : l'action
/// reste en fin de texte, on confirme apres avoir lu ; en haut, une seule
/// ligne, jamais un bloc, jamais l'action repetee.
class LireJusquEnBas extends StatelessWidget {
  /// Cree la ligne.
  const LireJusquEnBas({super.key});

  /// La cle de la ligne.
  static const Key cle = ValueKey<String>('lire-jusqu-en-bas');

  @override
  Widget build(BuildContext context) => Text(
    t.accords.lireJusquEnBas,
    key: cle,
    style: AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle()),
  );
}
