import 'package:flutter/widgets.dart';

import '../../core/communications/modeles_communication.dart';

/// L'emplacement d'entree des Messages metier dans une page existante
/// (Espace Classe du tuteur, Espace Classe enseignant, Mes classes, Ma classe
/// de l'eleve adulte) : **pose une fois par le socle (COM-F), rempli par la
/// voie COM-MSG** dans ce fichier, sans rouvrir la page hote
/// (`02_DECOUPAGE`, regle des fichiers 3).
///
/// **Vide tant que la voie ne le remplit pas** : il ne rend rien, n'occupe
/// aucune place et ne change pas le rendu de la page hote. Quand il rendra
/// quelque chose, il portera lui-meme son ecart d'en-tete (16, `Ecart.vLg`),
/// la page hote ne pose aucun ecart pour lui.
///
/// [type] et [objetId] disent de quoi parle l'entree (la Classe affichee) ;
/// tous deux nuls : l'entree generale d'une liste (Mes classes). Ce sont des
/// identifiants, jamais une autorisation : le port decidera (COM-BR).
class EntreeMessagesContexte extends StatelessWidget {
  /// Cree l'emplacement.
  const EntreeMessagesContexte({super.key, this.type, this.objetId})
    : assert(
        (type == null) == (objetId == null),
        'Un objet lie porte son type et son identifiant, ou aucun des deux.',
      );

  /// La nature de l'objet de la page hote.
  final TypeObjetLie? type;

  /// L'identifiant de l'objet de la page hote.
  final String? objetId;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
