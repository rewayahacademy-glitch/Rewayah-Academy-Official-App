import 'package:flutter/material.dart';

import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';

/// Le style [base] porte dans l'encre de ce que l'on a sous les yeux.
///
/// `PageImmersive` pose une paire (fond, encre) par `DefaultTextStyle`, et
/// c'est cette encre-la que lit [encreDuFond]. Un style du theme
/// (`textTheme.bodyMedium`, ...) porte, lui, l'encre du fond creme : pose tel
/// quel sur le fond sombre de la salle en theme clair, il ecrit sombre sur
/// sombre (CLASSE-LIVE-ENCRE-1). Aucune couleur n'est creee ici : c'est celle
/// de la paire du registre, ou, dans une feuille, celle de la feuille.
TextStyle styleDuFond(BuildContext context, TextStyle? base) =>
    (base ?? const TextStyle()).copyWith(color: encreDuFond(context));

/// L'encre que le fond courant donne a ses textes.
Color? encreDuFond(BuildContext context) =>
    DefaultTextStyle.of(context).style.color;

/// La mention permanente se lit sur le fond de la salle (meme motif que
/// SALLE-CORR-4 m10 dans `salle_page.dart`).
///
/// `PermanentNotice` n'a aucun parametre (ADR-011) et ecrit en `inkMuted`,
/// l'encre secondaire des surfaces claires : grise, peu lisible sur le fond
/// de la salle. On ne touche pas a son API : la classe lui prete, pour ses
/// descendants seulement, une palette dont l'encre secondaire est celle du
/// registre `salle` (`surfaceInverse`). Aucune couleur nouvelle.
class EncreDeLaSalle extends StatelessWidget {
  /// Cree l'enveloppe.
  const EncreDeLaSalle({required this.child, super.key});

  /// Le widget qui lit `inkMuted`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final List<ThemeExtension<ThemeExtension<dynamic>>> extensions =
        <ThemeExtension<ThemeExtension<dynamic>>>[
          ...theme.extensions.values
              .where((ThemeExtension<dynamic> e) => e is! AppPalette)
              .cast<ThemeExtension<ThemeExtension<dynamic>>>(),
          palette.copyWith(
            inkMuted: AppInkColor(palette.surfaceInverse.onBackground),
          ),
        ];
    return Theme(
      data: theme.copyWith(extensions: extensions),
      child: child,
    );
  }
}
