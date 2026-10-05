import 'package:flutter/widgets.dart';

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
