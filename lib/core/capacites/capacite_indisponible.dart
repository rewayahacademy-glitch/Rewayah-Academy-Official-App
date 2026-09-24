/// Une capacite que l'ecran demande et que rien ne sert encore.
///
/// **Ni un echec, ni un succes.** Un echec se reessaye (reseau, refus
/// ponctuel) ; une capacite indisponible ne se reessaye pas : elle manque, et
/// l'ecran le dit en clair (`NatureEtat.indisponible`, contrat K5) au lieu de
/// rendre une liste vide trompeuse ou un faux succes. Un port dont la source
/// n'existe pas encore leve cette exception depuis son implementation de
/// production, jamais une fixture.
///
/// [dependance] nomme ce qui manque, pour la trace et les tests, **jamais pour
/// l'affichage** (aucun code technique a l'ecran, mandat section 8). Deux
/// familles d'identifiants seulement :
///
/// - `DB-xxx` : une dependance du registre des dependances backend du chantier
///   Tuteur V1 (`00_DEPENDANCES_BACKEND.md`, dossier de pilotage, hors depot),
///   par exemple `DB-CPT-03` pour les paiements ;
/// - `LOT-x` : la source reelle existe deja, seul manque l'adaptateur frontend
///   que le lot `x` ecrit (`00_OWNERSHIP.md` section 3), par exemple `LOT-E`
///   pour l'identite du titulaire.
class CapaciteIndisponible implements Exception {
  /// Cree l'exception pour une dependance donnee.
  const CapaciteIndisponible(this.dependance);

  /// L'identifiant de ce qui manque : `DB-xxx` ou `LOT-x`.
  final String dependance;

  @override
  String toString() => 'CapaciteIndisponible($dependance)';
}
