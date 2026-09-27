import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../foyer/formulaire_profil_eleve.dart';

/// L'ajout d'un profil eleve (`/tuteur/foyer/ajouter`), ouvert depuis le
/// Foyer, l'Accueil, le Compte et la fin de l'admission : un seul flux, le
/// formulaire commun du contrat K3 (`FormulaireProfilEleve`).
///
/// Le fichier garde son chemin (le routeur l'importe, `00_OWNERSHIP.md`
/// section 6) ; il ne fait que relier le formulaire a la navigation :
///
/// - quitter ramene au Foyer, par son adresse ;
/// - un profil cree ouvre sa fiche quand la relecture du foyer l'a retrouve,
///   sinon le Foyer, ou il apparait ;
/// - « Voir le foyer » apres une reponse perdue ramene au Foyer.
///
/// L'age reste derive **en base** vers l'affichage et la camera de depart
/// (ADR-009), jamais ici : le seuil est un reglage d'academie.
class AjouterEnfantPage extends StatelessWidget {
  /// Cree l'ecran d'ajout.
  const AjouterEnfantPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Le routeur se lit au geste, pas au montage : l'ecran se rend aussi
    // hors routeur (preuve RTL et 200 %, `test/accessibilite`).
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    return FormulaireProfilEleve(
      onAbandon: () => aller(Routes.tuteurFoyer),
      onVoirFoyer: () => aller(Routes.tuteurFoyer),
      onCree: (String? eleveId) => aller(
        eleveId == null ? Routes.tuteurFoyer : Routes.ficheElevePour(eleveId),
      ),
    );
  }
}
