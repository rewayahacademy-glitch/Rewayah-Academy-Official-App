// LUMIERE-ACCUEILS (directeur, 09-10/11/2026) : poser la lumiere du halo
// autour d'une carte dont la taille n'est connue qu'a la mise en page.
//
// Aucune copie de la lumiere : c'est `HaloLumiere` (2a-bis de B), en rectangle
// arrondi, mesuree sur la carte qu'elle entoure. Elle est derriere la carte,
// ne prend aucune place et ne recoit aucun geste. Sous `ArbitreLumieres` (pose
// une fois par `NavShell`), une seule lumiere tourne par ecran.
library;

import 'package:flutter/widgets.dart';

import '../accessibilite/mode_accessibilite.dart';
import '../theme/app_radius.dart';
import 'halo_lumiere.dart';

/// La lumiere de [nature] autour de [child], ou [child] seul quand [nature]
/// est nul (aucun signal du serveur).
class LumiereAutour extends StatelessWidget {
  /// Pose la lumiere.
  const LumiereAutour({
    required this.nature,
    required this.child,
    this.arrondi = AppRadius.arrondiMd,
    this.apparition,
    super.key,
  });

  /// La lumiere, ou `null` : aucune.
  final NatureHalo? nature;

  /// La carte entouree.
  final Widget child;

  /// L'arrondi de la carte.
  final BorderRadius arrondi;

  /// Ce qui fait rejouer la lumiere quand il change (voir `HaloLumiere`).
  final Object? apparition;

  @override
  Widget build(BuildContext context) {
    final NatureHalo? n = nature;
    // Aucun signal, ou « Reduire les effets » : la carte seule.
    if (n == null || EffetsReduits.de(context)) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints c) => HaloLumiere(
              nature: n,
              forme: FormeHalo.rectangle,
              taille: c.biggest,
              arrondi: arrondi,
              apparition: apparition,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
