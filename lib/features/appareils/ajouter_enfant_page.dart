import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/offres/service_offres.dart' show parcoursFoyerProvider;
import '../../core/router/routes.dart';
import '../accueil_inscrits/accueil_inscrits_page.dart';
import '../foyer/formulaire_profil_eleve.dart';

/// L'ajout d'un profil eleve (`/tuteur/foyer/ajouter`), ouvert depuis le
/// Foyer, l'Accueil, le Compte et la fin de l'admission : un seul flux, le
/// formulaire commun du contrat K3 (`FormulaireProfilEleve`).
///
/// Le fichier garde son chemin (le routeur l'importe, `00_OWNERSHIP.md`
/// section 6) ; il ne fait que relier le formulaire a la navigation :
///
/// - quitter ramene au Foyer, par son adresse ;
/// - un profil cree ouvre son Parcours (questions puis horaires, NIV1) quand
///   la relecture du foyer l'a retrouve, sinon le Foyer, ou il apparait ;
/// - « Voir le foyer » apres une reponse perdue ramene au Foyer.
///
/// L'age reste derive **en base** vers l'affichage et la camera de depart
/// (ADR-009), jamais ici : le seuil est un reglage d'academie.
class AjouterEnfantPage extends ConsumerWidget {
  /// Cree l'ecran d'ajout.
  const AjouterEnfantPage({super.key, this.depuisAccueilInscrits});

  /// IMM-ACCUEIL-FRONT : l'ajout part de l'accueil d'une famille deja
  /// inscrite. Le prenom importe est prerempli, et la fin (ou l'abandon)
  /// ramene a cet accueil.
  final AjoutDepuisAccueilInscrits? depuisAccueilInscrits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le routeur se lit au geste, pas au montage : l'ecran se rend aussi
    // hors routeur (preuve RTL et 200 %, `test/accessibilite`).
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    final AjoutDepuisAccueilInscrits? accueil = depuisAccueilInscrits;
    if (accueil != null) {
      void revenir() => aller(Routes.tuteurInscriptionReprise);
      return FormulaireProfilEleve(
        prenomInitial: accueil.prenom,
        onAbandon: revenir,
        onVoirFoyer: () => aller(Routes.tuteurFoyer),
        onCree: (String? _) => revenir(),
      );
    }
    return FormulaireProfilEleve(
      onAbandon: () => aller(Routes.tuteurFoyer),
      onVoirFoyer: () => aller(Routes.tuteurFoyer),
      // NIV1 (pilote, 03/11/2026, option a) : le profil cree ouvre tout de
      // suite son Parcours, qui saute l'age (cohorte deja posee par
      // `creer_profil_enfant`), pose langue, niveau et objectif une seule
      // fois, puis montre les horaires. Plus de questions cachees dans les
      // reglages de la fiche.
      // La liste des parcours a ete lue avant la creation : relue, sinon le
      // Parcours dirait « Ce profil eleve est introuvable » (robot NIV1).
      onCree: (String? eleveId) {
        if (eleveId == null) {
          aller(Routes.tuteurFoyer);
          return;
        }
        ref.invalidate(parcoursFoyerProvider);
        aller(Routes.parcoursPour(eleveId));
      },
    );
  }
}
