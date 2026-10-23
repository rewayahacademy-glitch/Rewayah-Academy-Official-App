# Migrations à appliquer sur la base de test (staging), liste du 23/10/2026

> **Fait le 23/10/2026, testé sur staging.** Feu vert du directeur dans la conversation. Les 15
> fichiers ont été collés par le directeur dans l'éditeur SQL de staging : 1 à 3 tels quels, puis,
> après l'échec du fichier 4 (fins de ligne de Windows, sans écriture) et la normalisation
> `normalisation_fins_de_ligne_editeur_sql` appliquée par Claude, 4 à 15 enveloppés
> (`tool/envelopper_pour_editeur_sql.py`). Vérification de Claude : 143 fonctions identiques au
> dépôt (texte, commentaire F86, droits), 25 tables nouvelles toutes sous RLS, catalogue de 25
> compétences, aucun retour chariot restant ; versions inscrites par
> `historique_15_migrations_editeur_sql`. Sauvegarde : le directeur a poursuivi sans la signaler.
> Leçon : `docs/orchestration/LECONS-MIGRATIONS-STAGING.md`, deuxième partie. Production : rien.

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

## Prochaine livraison sur la base de test (pas encore appliquée)

Ajoutée le 23/10/2026, après l'installation des quinze ci-dessus. Rien n'est appliqué sans un
nouveau feu vert du directeur sur cette liste précise ; le collage passe par la page de collage
(`tool/page_migrations/generer.py`, règle du 23/10/2026). Rejeu complet local avec ces fichiers :
124 scénarios verts sur 125 (le rouge `avis_*` est antérieur).

| # | Fichier | DELETE/DROP/TRUNCATE | Qui l'applique |
|---|---|---|---|
| 16 | `20261022000600_cand_l3_inscription_import_rapprochement.sql` | 6 | directeur (éditeur SQL) |
| 17 | `20261023000000_classes_duree_bout_en_bout.sql` | 0 | directeur (page de collage), détail ci-dessous |
| 18 | `20261024000000_cand_nom_latin.sql` | 0 | directeur (page de collage), détail ci-dessous |

Après chaque fichier, Claude vérifie en lecture (`list_migrations`, présence des tables et
fonctions, droits) avant le suivant. Une erreur arrête la suite ; rien n'est réessayé à
l'aveugle.

### Détail du fichier 18 (le nom en lettres latines)

- Ajouté le 23/10/2026 pour la décision « Les noms dans une seule écriture sur les listes »
  (`DECISION-CANDIDATURES-2026-10-21.md`). Décompte par `grep -ciw 'delete\|drop\|truncate'` (commentaires
  compris) : **0**. Le fichier passe donc sans la seconde confirmation du serveur ; il garde `BEGIN;` et
  `COMMIT;` : à coller par la page de collage (enveloppe contre les fins de ligne de Windows), comme la règle du
  23/10.
- **Ce qu'elle fait** : deux colonnes sur `candidatures` (`nom_latin`, `nom_latin_confirme_le`, nulles ensemble) ;
  une aide privée `private.nom_est_latin` (aucun compte ne l'exécute) ; `private.cand_ligne_json` rend deux clés de
  plus (`nomLatin`, `nomLatinAConfirmer`) ; deux RPC pour le titulaire d'une candidature (`lire_nom_latin`,
  `confirmer_nom_latin`) ; `lister_candidatures` redéfinie (la recherche porte aussi sur le nom latin, le tri par nom
  suit le nom latin). Aucune table nouvelle, aucune policy touchée, aucune donnée existante modifiée.
- **Ordre** : après le 17 ; elle ne dépend que du 16 (`private.candidature_du_titulaire`, `lister_candidatures` du
  fichier `20261022000500`, déjà posé avant le 16).
- **Rejeu local** : scénario `supabase/tests/scenarios_cand_nom_latin.sql` (59 contrôles), rouge sans la migration ;
  rejeu complet avec les 18 fichiers : 126 scénarios verts sur 127 (le rouge est `scenarios_af_liste_blanche_volatiles`,
  pour les quatre fonctions `avis_*`, antérieur ; `confirmer_nom_latin` y est déclarée). Deux scénarios antérieurs
  (`scenarios_cand_l1_socle`, `scenarios_cand_autres_competences`) comptaient les clés d'une ligne de liste : mis à
  vingt et une clés.
- **Vérification de Claude après application** : les deux colonnes présentes, les trois fonctions de `public` à
  l'empreinte F86 du dépôt (commentaire `md5_functiondef` à jour), aucune fonction nouvelle exécutable par `anon`,
  `service_role` ni `agent_ro`, `private.nom_est_latin` exécutable par personne, `lister_candidatures` rend une
  ligne à 21 clés.
- **Liste blanche des volatiles** : `confirmer_nom_latin(text)` est ajoutée à
  `supabase/tests/scenarios_af_liste_blanche_volatiles.sql` (garde positive sur la candidature du titulaire).

## Ce que la base de test permettra ensuite

L'aperçu Vercel `staging` (il naît d'une pull request vers `main`, qui demande elle aussi le feu vert du directeur) pourra montrer les écrans
du module avec des comptes de test : Salle d'examen, carte de partage, « Vos autres
talents », liste et fiche des candidatures, réglage du plafond de Classes. Aucune personne
réelle des formulaires n'y est importée.

### Détail du fichier 17 (durée des Classes de bout en bout)

- Décompte par `grep -ciE '\b(delete from|drop |truncate)\b'` (commentaires compris) : **0**, et 0 aussi avec
  le motif large `\b(delete|drop|truncate)\b`. Les seuls mots proches sont la colonne `deleted_at`. Le fichier
  passe donc sans la seconde confirmation du serveur : Claude peut l'appliquer après le feu vert (retirer
  `BEGIN;` et `COMMIT;`, ou l'envelopper avec `tool/envelopper_pour_editeur_sql.py` si les fins de ligne de
  Windows sont en jeu ; la règle du 23/10 veut une page de collage pour ce que le directeur colle).
- **Ce qu'elle fait** : `materialiser_seances_groupe` prend la durée de la Classe ; les séances à venir non
  commencées sont alignées sur la durée de leur Classe, **une fois, dans la migration** ; deux déclencheurs
  (`groupes`, `groupe_creneaux`) repassent le prédicat d'affectation (et refusent un horaire que des séances déjà
  matérialisées de l'enseignant occupent) quand l'horaire d'une Classe qui a son enseignant change ; un déclencheur
  `BEFORE` sur `groupe_creneaux` ordonne les verrous (pas d'interblocage) ; un déclencheur sur `app_config` refuse un
  réglage de durée hors de 15 à 240 minutes ; `enseignants_pour_classe`, `enseignants_pour_public` et
  `transferer_eleve` comptent la durée de la Classe. Neuf fonctions nouvelles de `app_private`, aucune exécutable par
  un client ; aucune table, aucune colonne, aucune policy touchée.
- **À savoir avant le feu vert** : la migration **s'arrête et annule tout** si le rallongement d'une séance
  d'adultes en chevauche une autre (même enseignant, remplaçant désigné ou même élève) ; le message donne le
  nombre et les identifiants (séance, Classe, début, autre séance). **Avant** de la coller, lancer le contrôle en
  lecture seule `tool/controle_avant_migration_duree.sql` dans l'éditeur SQL de staging : aucune ligne rendue =
  la migration passera ; une ligne par chevauchement = elle s'arrêterait (déplacer ou annuler l'une des deux
  séances, puis relancer le contrôle). Les séances d'adultes rallongées sont payées 1 h 30 au lieu de 1 h, ce qui est
  conforme à la décision du 19/10 (`DECISION-TARIFS-2026-10-18.md` : 1,57 $ par élève présent et par heure, 3 x 90
  min) : la paie se calcule à la minute et n'est pas modifiée.
- **Ordre** : après le 15 ; elle ne dépend que du 14 (`app_private.duree_seance_minutes`) et du 12
  (`verifier_affectation_enseignant_base`).
- **Vérification de Claude après application** : les neuf fonctions et les quatre déclencheurs présents, les quatre
  fonctions de `public` à l'empreinte F86 du dépôt, aucune fonction nouvelle exécutable par `anon`, `authenticated`
  ni `agent_ro`, `select count(*) from app_private.seances_a_venir_a_realigner()` = 0.
