import 'package:flutter/widgets.dart';

import 'compte_page.dart';

// STUB PHASE 0 : propriété du lot E, à remplacer
//
// Route : `/tuteur/compte`, destination Compte. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot E n'a pas livre le Compte du tuteur, la destination rend
// l'ecran existant (`ComptePage`) : la deconnexion reste atteignable, sur
// telephone compris.

/// Le compte du tuteur.
class CompteTuteurPage extends StatelessWidget {
  /// Cree la page.
  const CompteTuteurPage({super.key});

  @override
  Widget build(BuildContext context) => const ComptePage();
}
