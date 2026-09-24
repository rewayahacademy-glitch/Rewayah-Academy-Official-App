import 'package:flutter/widgets.dart';

import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot E, à remplacer
//
// Route : `/admin/securite-audit/observations`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// L'historique des observations, cote administration.
class ObservationsAdminPage extends StatelessWidget {
  /// Cree la page.
  const ObservationsAdminPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-E');
}
