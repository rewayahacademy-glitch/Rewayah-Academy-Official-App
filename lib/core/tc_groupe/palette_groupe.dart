import 'package:flutter/widgets.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import 'group_summary_vm.dart';

/// La resolution d'un jeton de couleur de groupe en teinte affichable.
///
/// **La palette administree de la decision `D-18` existe desormais** :
/// `AppPalette.teintesIdentite`, 32 paires verifiees contraste (>= 4.5:1 AA)
/// et distinguabilite sous les trois formes courantes de dyschromatopsie
/// (plan d'integration Teaching Core section 9.2). Cette classe ne fait plus
/// que l'indexer par [AppPalette.teinteGroupe].
///
/// **Ce qui reste vrai : la couleur n'est jamais seule.** Toute surface qui
/// appelle [paire] affiche aussi le nom du groupe. C'est l'invariant `J7` du
/// depot, celui que `StatusPill` tient par construction.
abstract final class PaletteGroupe {
  /// La teinte d'un jeton.
  static AppColorPair paire(BuildContext context, JetonCouleurGroupe jeton) =>
      AppPalette.of(context).teinteGroupe(jeton.index);
}
