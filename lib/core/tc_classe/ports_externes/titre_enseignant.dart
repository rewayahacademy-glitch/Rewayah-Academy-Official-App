// TC-STUB-PORT: canonique = lib/core/tc_groupe/group_summary_vm.dart (Agent A)
// Signature copiee A L'IDENTIQUE depuis le fichier canonique d'Agent A, lui meme
// conforme a TEACHING_CORE_CONTRACTS.md section 1.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// **Seul l'enum est repris, pas `EnseignantVM` ni `GroupSummaryVM`.** La chaine
// de types de la carte du Groupe est ouverte (`JetonCouleurGroupe`,
// `OccurrenceSeance`, `SessionClockVM`, `TypePublicGroupeVM`) : l'AMENDEMENT 2
// du contrat demande alors un slot, pas un stub. L'en-tete de la Classe Live
// recoit donc le titre, le nom et la photo en parametres -- voir
// `SessionLiveVM` -- et Agent Z branche `GroupSummaryVM` dessus.

/// Le titre d'un enseignant dans le contexte cours.
///
/// **Sayyid / Sayyida, jamais Ustaz** (decision D-02). Les deux formes arabes
/// vivent dans `docs/teaching-core/i18n/tc_i18n_A.json`.
enum TitreEnseignant {
  /// Titre masculin.
  sayyid('sayyid'),

  /// Titre feminin.
  sayyida('sayyida');

  const TitreEnseignant(this.valeurSql);

  /// La valeur telle que la base l'attendra.
  final String valeurSql;

  /// Lit un titre depuis sa valeur SQL. `null` sur valeur inconnue.
  static TitreEnseignant? depuisSql(String? valeur) {
    for (final TitreEnseignant titre in TitreEnseignant.values) {
      if (titre.valeurSql == valeur) {
        return titre;
      }
    }
    return null;
  }
}
