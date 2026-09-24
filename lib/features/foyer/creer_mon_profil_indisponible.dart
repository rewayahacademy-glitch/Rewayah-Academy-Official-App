import 'package:flutter/widgets.dart';

import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';

// STUB PHASE 0 : propriété du lot B, à remplacer
//
// Route : `/tuteur/foyer/ajouter?pour=moi`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.

/// La creation du profil eleve du titulaire, indisponible tant que DB-FOY-01 manque.
class CreerMonProfilIndisponible extends StatelessWidget {
  /// Cree la page.
  const CreerMonProfilIndisponible({super.key});

  @override
  Widget build(BuildContext context) =>
      const PageEtat(nature: NatureEtat.indisponible, dependance: 'LOT-B');
}
