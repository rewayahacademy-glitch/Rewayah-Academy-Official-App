import 'package:flutter/widgets.dart';

import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot C, à remplacer
//
// Route : `/tuteur/classes/catalogue?eleve=`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// Le choix d'une classe pour un profil eleve (decision P1).
class CatalogueClassesPage extends StatelessWidget {
  /// Cree la page.
  const CatalogueClassesPage({super.key, this.eleveId});

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-C');
}
