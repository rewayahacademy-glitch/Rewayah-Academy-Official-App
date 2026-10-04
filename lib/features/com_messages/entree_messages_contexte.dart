import 'package:flutter/widgets.dart';

import '../../core/communications/modeles_communication.dart';

/// L'emplacement d'entree des Messages metier dans une page existante
/// (Espace Classe du tuteur, Espace Classe enseignant, Mes classes, Ma classe
/// de l'eleve adulte) : **pose une fois par le socle (COM-F), rempli par la
/// voie COM-MSG** dans ce fichier, sans rouvrir la page hote
/// (`02_DECOUPAGE`, regle des fichiers 3).
///
/// **Vide tant que la voie ne le remplit pas** : il ne rend rien, n'occupe
/// aucune place et ne change pas le rendu de la page hote.
///
/// **Contrat d'ecart, fixe par le socle** : c'est la page hote qui dit, des
/// COM-F, de quel cote l'ecart se pose et lequel ([ecartAvant],
/// [ecartApres], un `Ecart.*` de la page, celui qui separe ses sections) ;
/// la voie COM-MSG les rend autour de son contenu, et seulement quand elle
/// rend quelque chose. Aucune voie n'a ainsi a rouvrir une page hote.
///
/// [type] et [objetId] disent de quoi parle l'entree (la Classe affichee) ;
/// tous deux nuls : l'entree generale d'une liste (Mes classes). Ce sont des
/// identifiants, jamais une autorisation : le port decidera (COM-BR).
class EntreeMessagesContexte extends StatelessWidget {
  /// Cree l'emplacement.
  const EntreeMessagesContexte({
    super.key,
    this.type,
    this.objetId,
    this.ecartAvant,
    this.ecartApres,
  }) : assert(
         (type == null) == (objetId == null),
         'Un objet lie porte son type et son identifiant, ou aucun des deux.',
       );

  /// La nature de l'objet de la page hote.
  final TypeObjetLie? type;

  /// L'identifiant de l'objet de la page hote.
  final String? objetId;

  /// L'ecart a poser avant le contenu (emplacement en fin de section), ou
  /// `null`. Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartAvant;

  /// L'ecart a poser apres le contenu (emplacement en tete), ou `null`.
  /// Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartApres;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
