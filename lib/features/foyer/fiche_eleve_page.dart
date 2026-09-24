import 'package:flutter/widgets.dart';

import '../compte/compte_page.dart';

// STUB PHASE 0 : propriété du lot B, à remplacer
//
// Route : `/tuteur/foyer/:eleveId`. Posee par le coordinateur en phase 0c2 (chantier Tuteur
// V1) pour que la route, sa garde et ses tests existent avant le lot : le
// lot remplace le contenu de ce fichier sans toucher au routeur. Aucun STUB
// ne doit subsister a la fin du chantier.
//
// Tant que le lot B n'a pas livre la fiche, elle rend la lecture existante
// (`ProfilEnfantPage`, lot E), qu'atteignait `/compte/profils/:id`, desormais
// redirige ici pour le tuteur.

/// La fiche d'un profil eleve du foyer.
class FicheElevePage extends StatelessWidget {
  /// Cree la page.
  const FicheElevePage({required this.eleveId, super.key});

  /// L'eleve affiche. Un identifiant de chemin, jamais une autorisation : la
  /// RLS decide.
  final String eleveId;

  @override
  Widget build(BuildContext context) => ProfilEnfantPage(profilId: eleveId);
}
