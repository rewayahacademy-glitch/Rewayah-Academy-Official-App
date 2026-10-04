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
/// aucune place et ne change pas le rendu de la page hote.
///
/// **Contrat d'ecart, fixe par le socle** : l'emplacement n'est pas pose au
/// meme endroit dans toutes les pages (en tete chez le tuteur, en fin de
/// section chez l'enseignant et l'eleve adulte). C'est donc la page hote qui
/// dit, des COM-F, de quel cote l'ecart se pose et lequel ([ecartAvant],
/// [ecartApres], un `Ecart.*` de la page) ; la voie COM-ANN les rend autour
/// de son contenu, et seulement quand elle rend quelque chose. Aucune voie
/// n'a ainsi a rouvrir une page hote.
class AnnoncesDeClasse extends StatelessWidget {
  /// Cree l'emplacement pour la Classe [classeId].
  const AnnoncesDeClasse({
    required this.classeId,
    super.key,
    this.ecartAvant,
    this.ecartApres,
  });

  /// La Classe affichee par la page hote. Un identifiant, jamais une
  /// autorisation.
  final String classeId;

  /// L'ecart a poser avant le contenu (emplacement en fin de section), ou
  /// `null`. Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartAvant;

  /// L'ecart a poser apres le contenu (emplacement en tete), ou `null`.
  /// Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartApres;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
