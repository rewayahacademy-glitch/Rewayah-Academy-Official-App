# Migrations à appliquer sur la base de test (staging), liste du 23/10/2026

Inventaire pour le feu vert du directeur (`CLAUDE.md` : aucune migration distante sans
inventaire, sauvegarde et feu vert explicite sur la liste précise ; `CAND-Q02` : le module
des candidatures est autorisé sur la base de test seulement, jamais en production sans un
nouveau feu vert).

- Base visée : **staging** (`xldmmlrnxyabdtvxqbyy`). Jamais la production.
- État lu le 23/10/2026 (`list_migrations`, lecture seule) : dernière version appliquée
  `20261019124206 avis_publics`.
- Les 15 migrations ci-dessous sont sur la branche `claude/lucid-mccarthy-qpk6yq`, testées
  localement (rejeu complet : 122 scénarios verts sur 123, le rouge `avis_*` est antérieur),
  jamais appliquées ailleurs.
- **Ordre obligatoire** : celui du tableau. Chaque ligne dépend des précédentes.
- **Mots DELETE, DROP ou TRUNCATE** : le serveur Supabase demande une seconde confirmation
  qui n'apparaît pas dans l'app, et l'application par Claude est annulée
  (`docs/orchestration/LECONS-MIGRATIONS-STAGING.md`). Pour ces fichiers, le directeur colle
  le fichier dans l'éditeur SQL de staging, puis Claude vérifie. Les autres peuvent être
  appliqués par Claude après le feu vert.
- **Sauvegarde** : avant la première migration, un instantané de staging (ou la
  confirmation que la restauration à un instant est active) ; à défaut, le directeur le dit.

| # | Fichier | DELETE/DROP/TRUNCATE | Qui l'applique |
|---|---|---|---|
| 1 | `20261019130000_fac_e_03_paie_47_pour_cent.sql` | 1 | directeur (éditeur SQL) |
| 2 | `20261021200000_cand_l1_socle_candidatures.sql` | 9 | directeur (éditeur SQL) |
| 3 | `20261021210000_ens_l8_langues_par_code.sql` | 0 | Claude |
| 4 | `20261021210100_c11bis_affectation_verifiee.sql` | 0 | Claude |
| 5 | `20261021210200_creer_groupe_predicat_affectation.sql` | 0 | Claude |
| 6 | `20261021210300_fi_devises_decimales_iso4217.sql` | 0 | Claude |
| 7 | `20261021210400_pe_code_conduite_avant_activation.sql` | 0 | Claude |
| 8 | `20261021220000_cand_l1b_forme_compte_candidat.sql` | 0 | Claude |
| 9 | `20261021220100_cand_l6_referentiel_paiement.sql` | 14 | directeur (éditeur SQL) |
| 10 | `20261022000000_cand_l2a1_moteur_salle_examen.sql` | 10 | directeur (éditeur SQL) |
| 11 | `20261022000100_cand_l2a2_gestes_direction.sql` | 2 | directeur (éditeur SQL) |
| 12 | `20261022000200_classes_plafond_par_enseignant.sql` | 3 | directeur (éditeur SQL) |
| 13 | `20261022000300_cand_classes_souhaitees_suit_le_plafond.sql` | 0 | Claude |
| 14 | `20261022000400_classes_affectation_couvre_toute_la_duree.sql` | 0 | Claude |
| 15 | `20261022000500_cand_autres_competences.sql` | 11 | directeur (éditeur SQL) |

Le décompte des mots compte aussi les commentaires et les droits (`REVOKE ... DELETE`,
`ON DELETE CASCADE`) : il dit seulement quel chemin passe sans seconde confirmation.

Après chaque fichier, Claude vérifie en lecture (`list_migrations`, présence des tables et
fonctions, droits) avant le suivant. Une erreur arrête la suite ; rien n'est réessayé à
l'aveugle.

## Ce que la base de test permettra ensuite

L'aperçu Vercel `staging` (il naît d'une pull request vers `main`, qui demande elle aussi le feu vert du directeur) pourra montrer les écrans
du module avec des comptes de test : Salle d'examen, carte de partage, « Vos autres
talents », liste et fiche des candidatures, réglage du plafond de Classes. Aucune personne
réelle des formulaires n'y est importée.
