import 'package:flutter/widgets.dart';

import '../../../core/router/page_etat.dart';
import '../../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot B, à remplacer
//
// Route : `/tuteur/foyer/:eleveId/informations`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// Les informations et la photo d'un profil eleve.
class InformationsElevePage extends StatelessWidget {
  /// Cree la page.
  const InformationsElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-B');
}
