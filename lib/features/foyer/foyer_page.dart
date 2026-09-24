import 'package:flutter/widgets.dart';

import '../appareils/appareils_page.dart';

// STUB PHASE 0 : propriété du lot B, à remplacer
//
// Route : `/tuteur/foyer`, destination Foyer. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot B n'a pas livre l'ecran Foyer, la destination rend l'ecran
// qu'elle rendait deja (`AppareilsPage`, lot D, aussi branche a
// `/tuteur/foyer/appareils`) : aucune fonction existante n'est perdue par le
// changement de coquille.

/// Le Foyer : les profils eleves du tuteur et leurs acces.
class FoyerPage extends StatelessWidget {
  /// Cree la page.
  const FoyerPage({super.key});

  @override
  Widget build(BuildContext context) => const AppareilsPage();
}
