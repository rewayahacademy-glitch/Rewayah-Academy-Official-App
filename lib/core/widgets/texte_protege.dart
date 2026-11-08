import 'package:flutter/widgets.dart';

/// Texte hors de la sélection de l'application (directeur, 07/11/2026).
///
/// Tout le texte de l'application se sélectionne et se copie : un seul
/// `SelectionArea` à la racine (`RewayahApp`). Ce widget est le **seul**
/// moyen d'en retirer un morceau ; on ne recopie jamais
/// `SelectionContainer.disabled` à la main.
///
/// À poser autour de ce qui ne doit pas sortir de l'écran par un copier :
/// la salle de cours, les codes et secrets (code personnel, appairage,
/// invitation, vérification, jeton ou lien d'accès), les coordonnées
/// bancaires et de versement, les pièces d'identité, et les coordonnées
/// personnelles d'autrui (la direction les garde en copie).
///
/// Il protège aussi, sans qu'on le pose à la main, tout ce qui se touche :
/// `Pressable` (donc boutons, liens, lignes et cartes cliquables). Sous la
/// sélection, un texte prend le curseur de copie ; un élément cliquable doit
/// garder la flèche (CURSEUR-CLIC, directeur, 08/11/2026).
///
/// Le Mushaf n'en relève pas : il garde sa propre sélection.
class TexteProtege extends StatelessWidget {
  /// Protège [child] de la sélection.
  const TexteProtege({required this.child, super.key});

  /// Le contenu dont rien ne se sélectionne.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SelectionContainer.disabled(child: child);
}
