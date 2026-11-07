// « Lisez jusqu'en bas pour confirmer » : la ligne discrete, en tete des
// accords et du contrat (arbitrage du garde-cap, PLAN-TROIS-SALLES-2026-11-07
// §2) : l'action reste a la fin du texte (on confirme apres avoir lu), sans
// bouton repete en haut et sans bloc ; une seule ligne, une fois, pour les deux
// ecrans.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';

/// La ligne qui dit de lire jusqu'en bas avant de confirmer.
class LigneLireJusquEnBas extends StatelessWidget {
  /// Cree la ligne.
  const LigneLireJusquEnBas({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Text(
      t.commun.lireJusquEnBas,
      style: palette.inkMuted.applyTo(
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
      ),
    );
  }
}
