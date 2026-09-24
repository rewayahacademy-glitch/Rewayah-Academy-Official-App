import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
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
// d'apparence reste atteignable. La route est une tache focalisee
// (`Routes.estTacheFocalisee`) : sur telephone, la barre basse s'efface, et le
// disque retour ramene au Compte (revue phase 0, routes D4).

/// Les preferences du titulaire.
class PreferencesComptePage extends StatelessWidget {
  /// Cree la page.
  const PreferencesComptePage({super.key});

  @override
  Widget build(BuildContext context) => ReglagesComptePage(
    onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
  );
}
