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
/// l'affichage** (aucun code technique a l'ecran, mandat section 8). Cinq
/// familles d'identifiants seulement :
///
/// - `DB-xxx` : une dependance du registre des dependances backend du chantier
///   Tuteur V1 (`00_DEPENDANCES_BACKEND.md`, dossier de pilotage, hors depot),
///   par exemple `DB-CPT-03` pour les paiements ;
/// - `LOT-x` : la source reelle existe deja, seul manque l'adaptateur frontend
///   que le lot `x` ecrit (`00_OWNERSHIP.md` section 3), par exemple `LOT-E`
///   pour l'identite du titulaire ;
/// - `AD-BR-nn` : un besoin serveur de la vague Admin, une ligne de
///   `11_admin/AD-BR.md` (K-28) ;
/// - `COM-BR-nn` : un contrat serveur du chantier Communications V1, une
///   ligne de `19_communications/COM-BR.md` (K-28), par exemple `COM-BR-06`
///   pour la moderation ou `COM-BR-16` pour les capacites Communications ;
/// - `CAND-BR-nn` : un besoin serveur du module des candidatures
///   (`docs/current/CANDIDATURES/DEPENDANCES_BACKEND.md`), par exemple
///   `CAND-BR-10` pour le questionnaire de la Salle d'examen.
class CapaciteIndisponible implements Exception {
  /// Cree l'exception pour une dependance donnee.
  const CapaciteIndisponible(this.dependance);

  /// L'identifiant de ce qui manque : `DB-xxx`, `LOT-x`, `AD-BR-nn` ou
  /// `COM-BR-nn`.
  final String dependance;

  @override
  String toString() => 'CapaciteIndisponible($dependance)';
}
