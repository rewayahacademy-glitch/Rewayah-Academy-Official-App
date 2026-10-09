import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';

/// La zone de marque du tunnel d'entree.
///
/// **Aucun asset de logo n'existe dans le depot** au lot R0 (11 septembre
/// 2026) : la marque est portee par le nom du produit seul, en `inkAccent` sur
/// le fond general -- le meme registre que l'icone de `AttentePage`, qui pose
/// deja `inkAccent` directement sur la page sans passer par une surface. Le
/// jour ou un asset existe, il remplace ce texte ici et nulle part ailleurs.
class MarquePage extends StatelessWidget {
  /// Cree la zone de marque.
  const MarquePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Le mot-marque est un titre : DM Sans (`titleLarge`, 22/28, 600). **Il est
    // toujours plus petit que le titre de l'ecran qu'il surmonte** (HIER-1,
    // revue du directeur du 01/10 : « Rewayah Academy » et « Apprendre le
    // Coran... » etaient a la meme taille) : le titre d'ecran prend un
    // `headline*`, la marque un cran en dessous. `display*` porte les valeurs
    // chiffrees en Jakarta tabulaire (revue phase 0, jetons D6).
    //
    // Aucun mot coupe a 320 px, texte x2 (PUB-1 : la marque partage sa ligne
    // avec la croix de la presentation) : le mot le plus long se reduit juste
    // assez pour tenir ; a l'echelle 1, rien ne change.
    return Semantics(
      header: true,
      child: TexteSansCoupure(
        t.commun.marque,
        textAlign: TextAlign.center,
        style: palette.inkAccent.applyTo(
          textes.titleLarge ?? const TextStyle(),
        ),
      ),
    );
  }
}
