---
name: feedback_rls_borne_les_lignes_pas_les_colonnes_motif_litige
description: Ne jamais stocker un motif de litige ou toute donnee sensible dans une colonne d une table dont la RLS donne le select a la partie concernee
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fdb00ca8-c853-4e97-b470-cf9ab4128757
  modified: 2026-09-21T03:14:08.351Z
---

Avant d'ajouter une colonne à une table existante, lire **qui a le `select` sur cette table** — pas seulement qui a le droit d'écrire.

Cas réel (Rewayah, 21/09/2026) : j'avais ajouté `session_recordings.legal_hold_reason` pour porter le motif d'un gel de conservation. Les deux policies de `0001` donnent le `select` à **l'enseignant de la séance** et au **foyer d'un participant**, sur la ligne entière. Un motif tel que « plainte de la famille X contre l'enseignant Y » aurait donc été lisible par l'enseignant mis en cause, à la requête suivante.

**Why :** la RLS borne les LIGNES, jamais les COLONNES. Une colonne ajoutée à une table lisible est lisible par tous ceux qui lisent cette table, quelle que soit la sensibilité de son contenu. C'est la même leçon que PISI avait déjà payée, mais elle se represente sous une forme neuve à chaque nouvelle colonne.

**How to apply :** une donnée sensible qui accompagne un fait ne va pas dans la table du fait. Elle va dans le journal d'audit (`audit_logs` chez Rewayah : réservé à l'administration, append-only, chaîné par empreinte). La ligne ne garde que le fait lui-même — ici `legal_hold_since`, une date que tout le monde peut voir sans dommage.

Lié : [[rewayah_r2_integration_2026-09-21]], [[feedback_porte_sql_exigence_positive]].
