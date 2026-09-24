import 'package:flutter/widgets.dart';

import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot E, à remplacer
//
// Route : `/tuteur/seances/:seanceId/observations?eleve=`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// Le detail des visites d'observation d'une seance.
class DetailObservationsPage extends StatelessWidget {
  /// Cree la page.
  const DetailObservationsPage({
    required this.seanceId,
    super.key,
    this.eleveId,
  });

  /// La seance concernee.
  final String seanceId;

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-E');
}
