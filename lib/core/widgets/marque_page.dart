import 'package:flutter/material.dart';

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

    return Semantics(
      header: true,
      child: Text(
        t.commun.marque,
        textAlign: TextAlign.center,
        style: palette.inkAccent.applyTo(
          textes.displaySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}
