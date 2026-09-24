---
name: feedback_badges_cinq_niveaux_et_level_reserve_aux_eleves
description: "Rewayah : la politique de badges retenue compte CINQ niveaux, et student_profiles.level ne doit jamais porter le grade professionnel d'un enseignant"
metadata:
  node_type: memory
  type: feedback
  originSessionId: ac703dcf-56dc-4a00-be1c-cac6c196bdfd
  modified: 2026-09-22T11:52:35.271Z
---

Deux règles posées par l'opérateur le **22 septembre 2026**, à ne plus
enfreindre sur Rewayah :

1. **La politique de badges retenue compte CINQ niveaux** : **Certifié Rewayah,
   Bronze, Argent, Or, Platine**. Les huit grades de
   `docs/produit/badges-et-grades.md` sont une **PROPOSITION NON VALIDÉE**.
2. **`student_profiles.level` est le niveau ACADÉMIQUE d'un ÉLÈVE, et rien
   d'autre.** Il ne doit **jamais** servir de stockage au **grade professionnel
   d'un ENSEIGNANT**, qui appellera son propre modèle métier, sa propre table et
   ses propres droits.

**Aucun système de badges ne doit être implémenté** tant que son modèle métier
dédié et ses privilèges ne sont pas validés. Ne prendre aucune décision
supplémentaire à ce sujet : la nommer, c'est déjà la prendre.

**Why:** j'avais écrit, dans un document intitulé « badges et grades », la
recommandation « brancher les politiques existantes sur
`student_profiles.level` ». Elle visait les niveaux de programme d'un élève,
mais dans un document qui parle de grades elle se lit comme une autorisation
d'y ranger un grade d'enseignant. Un autre agent (Astra, Codex) l'aurait
implémentée sans le contexte. Un document de réflexion posé dans le dépôt est
lu comme une spécification s'il ne dit pas lui-même qu'il n'en est pas une.

**How to apply:** tout document de produit qui n'est pas validé porte une
**bannière de statut en tête** disant « PROPOSITION NON VALIDÉE — NE PAS
IMPLÉMENTER », et la retraction est écrite **à chaque endroit qui répétait la
recommandation**, pas seulement à la source — ici trois surfaces :
`badges-et-grades.md`, la ligne d'index dans `FABLE_ONBOARDING_CLASSES_REPORT.md`
et les deux renvois de `onboarding-questions-expliquees.md`. Même famille que
[[feedback_une_liste_de_roles_masques_est_recopiee_partout]] : corriger une
seule occurrence ne ferme rien.

Voir [[rewayah_onboarding_offres_vitrines_2026-09-22]].
