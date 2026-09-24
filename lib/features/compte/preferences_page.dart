import 'package:flutter/widgets.dart';

import 'compte_page.dart';

// STUB PHASE 0 : propriété du lot E, à remplacer
//
// Route : `/tuteur/compte/preferences`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot E n'a pas livre l'ecran, il rend l'existant
// (`ReglagesComptePage`), qu'atteignait `/compte/reglages` : le choix
// d'apparence reste atteignable.

/// Les preferences du titulaire.
class PreferencesComptePage extends StatelessWidget {
  /// Cree la page.
  const PreferencesComptePage({super.key});

  @override
  Widget build(BuildContext context) => const ReglagesComptePage();
}
