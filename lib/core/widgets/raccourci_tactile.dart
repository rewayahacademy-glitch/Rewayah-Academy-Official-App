import 'package:flutter/material.dart';

import 'pressable.dart';

/// Rend un contenu tactile en **doublon** d'un controle qui existe deja a
/// l'ecran : toucher la photo ouvre le meme choix que le lien « Choisir une
/// photo » pose dessous (PHOTO-LIEN-1, K-56).
///
/// C'est un raccourci du doigt et de la souris, rien d'autre : le controle
/// d'origine reste le seul que le clavier atteigne et que le lecteur d'ecran
/// annonce. Ici, le contenu est donc exclu de l'arbre de focus et de
/// l'arbre semantique : ni deux arrets de tabulation, ni deux boutons de meme
/// nom. Le retour tactile (echelle, survol) reste celui de [Pressable], la
/// cible reste d'au moins 48 sur 48.
class RaccourciTactile extends StatelessWidget {
  /// Cree un raccourci tactile.
  const RaccourciTactile({
    required this.child,
    required this.onPress,
    super.key,
  });

  /// Le contenu touchable (une photo).
  final Widget child;

  /// L'action, la meme que celle du controle d'origine. `null` : le contenu
  /// reste affiche, sans reagir.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ExcludeFocus(
      child: Pressable(onPress: onPress, child: child),
    ),
  );
}
