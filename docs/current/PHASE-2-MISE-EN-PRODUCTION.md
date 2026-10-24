# Phase 2 : mettre en production l'application et sa base (plan du 23/10/2026)

Choix du directeur, 23/10/2026 : mise en production « en deux temps ». Phase 1 = le site public seul
(PR 47, `claude/site-public-prod`, depuis `main`). Phase 2 = tout le reste, **après** la fin de la session
Recrutement (`claude/lucid-mccarthy-qpk6yq`, encore active le 23/10).

Statut : `spécifié`. Rien n'est appliqué en production.

## 1. Constat mesuré (lecture seule, 23/10/2026)

| | Production `gggmtelinlpseweouyav` | Staging `xldmmlrnxyabdtvxqbyy` | Dépôt (`claude/admiring-brown-r6ai72`) |
| :--- | :--- | :--- | :--- |
| Migrations | 50, dernière `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte` (21/09) | 278 (dont `courriels_sortants`) | 255 fichiers |
| À appliquer en production | 210 fichiers, de `0043_offres_horaires_et_intentions.sql` à `20261023120000_courriels_sortants.sql` | | |
| Avec `DELETE`, `DROP` ou `TRUNCATE` | 56 des 210 (le serveur demande une seconde confirmation) | | |

Conséquence : fusionner la branche dans `main` sans la base déploierait l'application et les fonctions
Edge (`deploy.yml` les envoie à chaque poussée) sur une base d'un mois de retard. **Jamais la fusion avant
la base.**

## 2. Ordre de la phase 2

1. **Gel** : la session Recrutement a fini ; sa branche est refusionnée dans `claude/admiring-brown-r6ai72` ;
   la suite Flutter, la séquence SQL de la CI et les tests du site sont verts sur la branche réunie. Restent
   rouges au 23/10, déjà sur la branche des candidatures seule : `duree_insecable_4/5`,
   `com_rc7_lot_l_arabe`, `tb_recette/synchronisation`, `etat_sans_donnees`, `creation_classe_refusee`.
2. **Répétition** sur une copie de la production (branche Supabase de la production, ou restauration d'une
   sauvegarde dans un projet jetable) : les 210 fichiers dans l'ordre, chacun vérifié ; noter la durée et
   tout fichier qui échoue sur des données réelles (staging a des données de test, pas celles des familles).
3. **Sauvegarde** de la production juste avant (PITR ou sauvegarde manuelle, heure notée).
4. **Application** des 210 fichiers. Le garde-fou interdit à un agent toute écriture sur la production :
   soit le directeur lance `deploy.yml` (« Run workflow », case « appliquer les migrations ») après avoir
   aligné l'historique des versions, soit il colle les fichiers par lots depuis une page de collage
   (`tool/page_migrations/generer.py`, règle du 23/10). Le choix se fait après la répétition, sur ses
   chiffres.
5. **Contrôles** en lecture : tables, fonctions DEFINER et droits (`has_function_privilege`), tâche
   `courriels-envoi`, conseiller Supabase (sécurité, performance).
6. **Secrets** (`docs/current/COURRIELS.md` §3) : SMTP Workspace, `COURRIELS_ENVOI_SECRET`, coffre
   (`courriels_envoi_url`, `courriels_envoi_secret`), Supabase Auth SMTP et modèles.
7. **Fusion** de la branche dans `main` par le directeur : application, fonctions Edge, workflows.
8. **Recette** sur `app.rewayahacademy.com` : connexion par lien (e-mail reçu depuis support@), un e-mail
   de chaque catégorie vers une boîte Gmail et une boîte Outlook (en-têtes `dkim=pass spf=pass dmarc=pass`),
   désinscription, écran E-mails de la direction.
9. **Signatures Gmail** posées (page de collage), si ce n'est pas déjà fait après la phase 1.

## 3. Ce que la phase 1 laisse en place

`app.rewayahacademy.com` sert l'application du 22/09 sur sa base du 21/09 (cohérentes entre elles) ; le site
public est sur `rewayahacademy.com`. La phase 2 ne change aucun nom de domaine.
