import 'package:flutter/widgets.dart';

import '../../core/tc_groupe/group_home_vm.dart' show RoleEspaceGroupe;
import '../tc_espace_groupe/espace_groupe_page.dart';

// STUB PHASE 0 : propriété du lot C, à remplacer
//
// Route : `/tuteur/classes/:classeId?eleve=`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot C n'a pas livre l'ecran Classe, elle rend l'Espace Groupe
// existant en role tuteur **explicite** (mapping des routes, section 2), sans
// « Rejoindre » : `/tc/classe` est refusee au tuteur. `/tc/groupes/:id`
// redirige ici le tuteur.

/// La classe d'un eleve du foyer, vue par le tuteur.
class ClasseTuteurPage extends StatelessWidget {
  /// Cree la page.
  const ClasseTuteurPage({required this.classeId, super.key, this.eleveId});

  /// La classe (groupe) affichee.
  final String classeId;

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context) =>
      EspaceGroupePage(groupeId: classeId, role: RoleEspaceGroupe.tuteur);
}
