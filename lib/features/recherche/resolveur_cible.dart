import '../../core/recherche/modeles_recherche.dart';
import '../../core/router/routes.dart';
import '../tc_catalogue/routes_tc_b.dart';
import '../tc_mes_groupes/chemins_tc_a.dart';

/// Ce qu'un resultat ouvre, pour un espace : une route **reelle** du routeur
/// unique, ou `null`.
///
/// Un resultat dont la route manque n'est jamais cliquable « vers le neant »
/// (spec RECH-03 §10.3) : l'ecran le montre sans geste. La cible est une
/// liste blanche (`KindCible`) et sa reference opaque est encodee comme un
/// segment ; rien de ce que la base renvoie n'est une adresse (SEC-R12). La
/// destination reautorise l'objet a l'ouverture (spec §13.1).
///
/// Table verifiee sur les routes du depot (RECH-1, 10/10/2026). Ajouter une
/// destination, c'est d'abord qu'elle existe dans `app_router.dart` et que la
/// redirection l'ouvre a cet espace.
String? cheminPourCible(CibleRecherche cible, EspaceRecherche espace) {
  final String ref = Uri.encodeComponent(cible.reference);
  if (cible.reference.isEmpty) return null;
  switch (cible.kind) {
    case KindCible.classe:
      return switch (espace) {
        EspaceRecherche.famille => Routes.classePour(cible.reference),
        EspaceRecherche.eleve ||
        EspaceRecherche.eleveGuide => CheminsTcA.espaceGroupe(ref),
        // L'enseignant et l'administration n'ont pas de fiche de classe par
        // identifiant : leur liste, qui existe, est la destination.
        EspaceRecherche.enseignant => Routes.enseignantClasses,
        EspaceRecherche.administration => Routes.adminOperationsGroupes,
        EspaceRecherche.controleur || EspaceRecherche.comptable => null,
      };
    case KindCible.support:
      return switch (espace) {
        EspaceRecherche.famille ||
        EspaceRecherche.eleve ||
        EspaceRecherche.eleveGuide => RoutesTcB.versRessource(ref),
        // L'enseignant ouvre ses supports depuis le dock de la salle ; la
        // Bibliotheque `/tc/` ne lui est pas ouverte par le routeur.
        _ => null,
      };
    case KindCible.eleve:
      return espace == EspaceRecherche.famille
          ? Routes.ficheElevePour(cible.reference)
          : null;
    case KindCible.remplacement:
      return espace == EspaceRecherche.enseignant
          ? Routes.enseignantRemplacements
          : null;
    case KindCible.operation:
      return espace == EspaceRecherche.comptable
          ? Routes.comptableEncaissementPour(cible.reference)
          : null;
    case KindCible.fil:
      return switch (espace) {
        EspaceRecherche.famille => Routes.tuteurFilPour(cible.reference),
        EspaceRecherche.enseignant => Routes.enseignantFilPour(cible.reference),
        EspaceRecherche.administration => Routes.adminFilPour(cible.reference),
        _ => null,
      };
    case KindCible.canal:
      return espace == EspaceRecherche.administration
          ? Routes.canalStudioPour(cible.reference)
          : null;
    case KindCible.enseignant:
    case KindCible.mission:
      return null;
  }
}
