import 'package:flutter/widgets.dart';

import 'compte_page.dart';

// STUB PHASE 0 : propriété du lot E, à remplacer
//
// Route : `/tuteur/compte/informations`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot E n'a pas livre l'ecran, il rend l'existant
// (`ProfilPersonnelPage`), qu'atteignait `/compte/profil`.

/// Les informations personnelles du titulaire.
class InformationsComptePage extends StatelessWidget {
  /// Cree la page.
  const InformationsComptePage({super.key});

  @override
  Widget build(BuildContext context) => const ProfilPersonnelPage();
}
