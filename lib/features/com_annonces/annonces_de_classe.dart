import 'package:flutter/widgets.dart';

/// L'emplacement des annonces d'une Classe dans sa page (Espace Classe du
/// tuteur et de l'enseignant, Ma classe de l'eleve adulte) : **pose une fois
/// par le socle (COM-F), rempli par la voie COM-ANN** dans ce fichier, sans
/// rouvrir la page hote (`02_DECOUPAGE`, regle des fichiers 3).
///
/// Lecture pour la famille et l'eleve adulte ; pour l'enseignant, l'entree
/// « Publier une annonce » (`Routes.publierAnnoncePour`), seulement avec la
/// capacite rendue par le port, jamais par un test de role.
///
/// **Vide tant que la voie ne le remplit pas** : il ne rend rien, n'occupe
/// aucune place et ne change pas le rendu de la page hote. Quand il rendra
/// quelque chose, il portera lui-meme son ecart (16, `Ecart.vLg`).
class AnnoncesDeClasse extends StatelessWidget {
  /// Cree l'emplacement pour la Classe [classeId].
  const AnnoncesDeClasse({required this.classeId, super.key});

  /// La Classe affichee par la page hote. Un identifiant, jamais une
  /// autorisation.
  final String classeId;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
