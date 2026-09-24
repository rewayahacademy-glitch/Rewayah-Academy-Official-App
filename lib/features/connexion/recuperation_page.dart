import 'package:flutter/widgets.dart';

import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot A, à remplacer
//
// Route : `/connexion/recuperation` (publique). Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// La recuperation d'acces : un nouveau lien de connexion, jamais un mot de passe.
class RecuperationPage extends StatelessWidget {
  /// Cree la page.
  const RecuperationPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-A');
}
