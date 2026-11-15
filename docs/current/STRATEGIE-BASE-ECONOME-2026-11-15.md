# Stratégie « base économe » : tenir des milliers de personnes sans disque infini

Rédigée le 15/11/2026, après la panne de la production du même jour. **Statut : proposée, en attente
de validation du directeur.** Tant qu'elle n'est pas validée, aucune ligne de ce document n'est une
règle ; une fois validée, ce document devient la source unique sur la charge de la base.

Demande du directeur (15/11/2026) : « c'est quoi la stratégie exacte pour optimiser la base, pour
qu'elle fonctionne bien, qu'elle économise ses données et ses ressources […] les standards de 2026
[…] Supabase, Google, Firebase […] comme ça on applique la stratégie une fois ».

## 0. Ce qui est faux, bloqué ou non prouvé (à lire en premier)

- **La production tourne sur le plan gratuit, machine Nano** (capture du tableau de bord, 15/11).
  Débit disque de base : 5 Mo/s et 250 opérations par seconde une fois la petite rafale du jour
  épuisée (documentation Supabase, *Compute and Disk*). Le 15/11, de 05 h 30 à au moins 11 h 20 UTC,
  la connexion échouait pour 83 % puis 100 % des requêtes, et les courriels ne partaient plus.
- **Le plan gratuit avait été signalé** (07/09, `MISE-EN-SERVICE` archivé ; 07/10, blueprint BR0B
  l.60), et le directeur avait demandé d'écrire la montée en charge : « 500, 1 000 puis 10 000
  élèves » (10/10, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`), « pense aussi à scalabilité »
  (27/10, consigne A11), « les utilisateurs se compteront par milliers » (11/11, `CAHIER-SALLE.md`).
  **Les preuves exigées le 10/10 (2 000 demandes, rafale de 300 jetons et 300 rappels) n'ont jamais
  été produites. Aucun essai de charge n'a jamais été fait** (aucun fichier k6 ou équivalent dans le
  dépôt). Le blueprint du 07/10 recommandait déjà Broadcast au lieu de Postgres Changes et l'attente
  progressive au hasard : ce n'a pas été appliqué.
- Aucun texte du dépôt ne date la demande « des milliers en simultané » du premier jour (mi-août) :
  l'historique git visible commence le 04/11. Ce n'est pas une preuve qu'elle n'a pas été faite.
- **Aucune capacité n'est prouvée.** Les nombres de personnes de ce document sont des objectifs ;
  ils ne deviennent vrais qu'après l'essai de charge de l'étape 6.

## 1. Pourquoi la base a lâché, et pourquoi le tableau de bord était vert

Le tableau « Free plan usage » mesure des **volumes** (base 186 / 500 Mo, 143 utilisateurs sur
50 000) : tout y était loin de la limite. Ce qui a lâché, c'est le **débit du disque** de la machine,
qui n'apparaît pas sur cette page (métrique « Disk IO » dans *Observability*). Une petite machine
peut dépasser son débit de base pendant une courte rafale chaque jour ; une fois la rafale épuisée,
elle retombe au débit de base, et tout ralentit : connexion, données, tâches planifiées, courriels.

Ce qui consomme ce débit dans l'application aujourd'hui (audit du dépôt, 15/11) :

| # | Source | Mesure dans le code | Pourquoi ça coûte |
| :-- | :-- | :-- | :-- |
| 1 | Veille temps réel ouverte partout | `lib/core/fraicheur/veille_supabase.dart` : 5 tables écoutées **sans filtre** par chaque personne connectée (`lib/app.dart:73`) ; 2 `.stream()` sans filtre sur `demande_evenements` | Supabase vérifie la RLS **une fois par abonné** pour chaque changement, sur un seul fil ; puis chaque client relance ses lectures, tous en même temps |
| 2 | RLS évaluée ligne par ligne | 41 policies avec `auth.uid()` nu ; `app_account_valid()` (lit `profiles`) appelée 985 fois, 22 enveloppées | La fonction est rejouée pour chaque ligne lue, à chaque lecture et à chaque événement temps réel |
| 3 | Relectures à intervalle fixe | 9 minuteries sans décalage ni recul, dont 5 s (`port_politique_observation.dart:253`), 3 s (`appairage_page.dart:323`), 20 s (présence en salle) ; l'outil `SondageRegulier` existe mais n'est utilisé qu'à 4 endroits | 300 élèves à 18 h relisent à la même seconde, et redoublent quand le serveur sature |
| 4 | Travail de chaque minute | `tache-minute` enchaîne 7 tâches toutes les minutes. **Correction du 15/11 (lu en production)** : les trois appels réseau (`courriels-envoi`, `push-envoi`, `observation-coupure`) ne partent déjà que s'il y a du travail (`WHERE EXISTS`). Reste à mesurer : les quatre tâches SQL, et `courriels-envoi` appelé chaque minute alors que le plafond horaire (40 par heure) est atteint, tant que la file n'est pas vide | À mesurer sur quelques heures de `pg_stat_statements` (remis à zéro par le changement de machine du 15/11) |
| 5 | Aucun mode dégradé | Aucun message « beaucoup de monde », aucune coupure du non-essentiel | Quand la base sature, tout l'écran échoue et les gens réessaient, ce qui l'enfonce |

## 2. Ce que font les grandes applications (standards relevés le 15/11/2026)

Une application qui tient des milliers de personnes simultanées n'a pas un disque infini : elle
**demande moins à la base**. Les cinq principes communs aux sources officielles :

1. **Pousser au lieu de demander.** On ne relit pas « au cas où » toutes les 20 s ; le serveur
   prévient seulement ceux que ça concerne, puis on relit une seule ligne. Supabase : « We recommend
   using Broadcast for most use cases » (*Subscribing to Database Changes*) ; Postgres Changes
   autorise chaque événement une fois par abonné, sur un seul fil, et ne grandit presque pas avec la
   machine (*Postgres Changes*, section limites). Firebase : un écouteur ne paie que les changements,
   une requête répétée relit des données inchangées (*Real-time queries at scale*).
2. **Rendre chaque lecture bon marché.** Index sur chaque colonne des policies ;
   `(select auth.uid())` au lieu de `auth.uid()` (Supabase mesure 179 ms → 9 ms) ; fonctions
   enveloppées dans `(select …)` (178 000 ms → 12 ms) ; filtre explicite dans la requête du client ;
   pagination par clé plutôt que par décalage (*RLS performance and best practices* ;
   use-the-index-luke.com/no-offset).
3. **Étaler les pics.** Décalage au hasard et recul exponentiel (départ 1 s, ×2, plafond 30 à 60 s,
   3 tentatives au plus, uniquement les requêtes rejouables sans effet double) : Google Cloud
   *Retry strategy*, Google SRE *Handling overload*. Ouvrir par vagues (Firebase, règle « 500/50/5 »).
4. **Se dégrader au lieu de tomber.** Refuser tôt et proprement, servir ce qui est en cache, couper
   d'abord le non-essentiel, dire « réessayez dans une minute » et ne pas réessayer en boucle
   (Google SRE *Addressing cascading failures*).
5. **Mesurer avant d'ouvrir, et être prévenu avant la panne.** Essai de charge sur staging (k6 :
   charge moyenne, pic, endurance, point de rupture), lecture de `pg_stat_statements`, Performance
   Advisor, alerte sur le débit disque et sur le taux d'erreurs (Supabase *Production checklist* ;
   Google SRE *Alerting on SLOs* ; Grafana k6 *Test types*).

Et Anthropic, pour que la règle tienne dans le temps : une règle qui doit s'appliquer à chaque fois
va dans un **contrôle automatique** (hook, CI, outil de vérification), pas seulement dans CLAUDE.md,
car une consigne écrite peut être oubliée par un agent, un contrôle non (*Claude Code best
practices*, code.claude.com/docs/en/best-practices).

## 3. La machine et l'abonnement

| Choix | Coût mensuel (doc Supabase) | Débit disque de base | Connexions temps réel |
| :-- | :-- | :-- | :-- |
| Gratuit, Nano (aujourd'hui) | 0 $ | 5 Mo/s, 250 op/s | 200 |
| Pro, Micro | 25 $ (Micro couvert par le crédit de 10 $) | 11 Mo/s, 500 op/s | 500 |
| **Pro, Small (proposé)** | 25 + 15 − 10 = **30 $** | 22 Mo/s, 1 000 op/s | 500 |
| Pro, Medium | 25 + 60 − 10 = 75 $ | 39 Mo/s, 2 000 op/s | 500 |
| Pro, Large | 25 + 110 − 10 = 125 $ | 79 Mo/s, 3 600 op/s | 500 (10 000 sans plafond de dépense) |

- STAGING compte comme un second projet : **+10 $** s'il reste dans la même organisation payante.
  Le déplacer dans une organisation gratuite garde le total à 30 $.
- Pro apporte aussi : plus de mise en pause après une semaine sans activité, une sauvegarde par jour
  gardée 7 jours, le plafond de dépense (qui ne plafonne pas la machine elle-même).
- **Règle proposée : on ne monte d'un palier que sur une mesure** (étape 6 ou alerte de l'étape 7),
  jamais par peur, et jamais au-delà de Large sans nouvelle décision du directeur. Les machines à
  410 $ et 960 $ ne concernent pas une application de cette taille quand les étapes 1 à 5 sont faites.

## 4. Le plan, une étape une PR (ordre d'impact)

| Étape | Lot | Ce qui change | Preuve de fin |
| :-- | :-- | :-- | :-- |
| 0 | MACHINE (directeur) | Pro, PROD en Small ; STAGING dans une organisation gratuite | Tableau de bord : « Small », erreurs de connexion à 0 |
| 1 | CRON-ECONOME | Après mesure : `courriels-envoi` ne réveille plus la fonction quand le plafond horaire est atteint ; les tâches SQL qui écrivent sans travail sont arrêtées ou espacées ; purge écrite de `net._http_response` | Nombre d'écritures par heure avant/après, lu dans `pg_stat_statements` |
| 2 | RLS-ECONOME | Envelopper `auth.uid()`, `app_account_valid()`, `app_role()` dans `(select …)` dans toutes les policies ; index sur les colonnes des policies et les clés étrangères signalées par le Performance Advisor | Advisor « auth_rls_initplan » et « unindexed_foreign_keys » à 0 ; temps des 10 requêtes les plus chères avant/après |
| 3 | VEILLE-BROADCAST | La veille globale et les deux `.stream()` passent à Broadcast privé ciblé (`realtime.broadcast_changes` dans un déclencheur, un sujet par personne, par classe ou par foyer) ; on relit seulement la ligne concernée ; veille suspendue quand l'application passe en arrière-plan | Plus aucun `onPostgresChanges` ni `.stream(` dans `lib/` ; publication `supabase_realtime` vidée |
| 4 | SONDAGE-UNIQUE | Les 9 minuteries passent par `SondageRegulier` (décalage, recul, arrêt en arrière-plan) ; 3 s et 5 s remplacées par Broadcast ; les lectures « toutes les pages en boucle » des écrans de direction paginées à la demande | Plus aucun `Timer.periodic` qui appelle Supabase hors `SondageRegulier` |
| 5 | MODE-DEGRADE | Dans `lib/core/` une fois : sur saturation (503, délai dépassé), arrêt des relectures non essentielles, cache affiché, phrase « Beaucoup de monde en ce moment, réessayez dans une minute », 3 tentatives au plus | Essai sur staging avec la base coupée : l'écran reste lisible, aucune boucle de réessai |
| 6 | ESSAI-CHARGE | Scénarios k6 sur STAGING, dans `tool/charge/` : candidats (connexion, portail, dépôt), familles, entrée en classe de 300 élèves à 18 h, puis 1 000 et 2 000 personnes ; les preuves du 10/10 enfin produites | Un tableau « palier → débit disque, temps p95, taux d'erreurs » ; capacité prouvée de Small |
| 7 | ALERTES | Alerte Supabase sur le débit disque (dès 1 % de budget consommé) et sur le taux d'erreurs auth / API ; relevé hebdomadaire de `pg_stat_statements` dans ce document | Une alerte reçue par le directeur lors d'un essai |

Les étapes 1 et 2 sont du serveur (migrations, installées par le pilote) ; 3 à 5 touchent `lib/core/`
et les adaptateurs `*_supabase.dart` ; 6 et 7 sont de l'outillage.

## 4 bis. Avancement

- **15/11, 12 h UTC** : étape 0 faite par le directeur (Pro, PROD en Micro, STAGING en pause). Fin de la panne mesurée à 11 h 45 UTC (aucune erreur de connexion depuis).
- **15/11** : étape 2 écrite, migration `20261127000000_rls_econome.sql` : 67 policies réécrites sur 188 (public et private), 0 appel nu restant, rejouable (0 au second passage). Testée localement sur Postgres nu : les 496 migrations, puis les 202 scénarios de la CI (tous verts après adaptation d'un test qui comparait le texte exact) et 111 scénarios hors CI (3 échecs, tous identiques sans la migration ou dus à l'ordre des scénarios). **Non installée.** Restent de l'étape 2 : les index des clés étrangères utiles (246 signalées, à trier : un index de trop coûte aussi en écriture) et les 100 tables à plusieurs policies permissives.
- **Réglage trouvé par l'Advisor, à faire par le directeur** : le service de connexion (Auth) est bridé à 10 connexions fixes ; le passer en pourcentage (*Authentication*, *Settings*, connexions) pour qu'il profite de la nouvelle machine.

## 5. Comment on s'assure qu'elle est appliquée cette fois

Une consigne écrite a déjà été perdue (blueprint du 07/10, décision du 10/10). Ce qui change :

1. **Un contrôle automatique, pas une phrase.** Outil `tool/verifier_charge.dart`, lancé avec les
   autres vérifications de CLAUDE.md, qui refuse :
   - tout nouveau `onPostgresChanges` ou `.stream(primaryKey` dans `lib/` ;
   - tout `Timer.periodic`, `Stream.periodic` ou boucle `Future.delayed` dans un fichier
     `*_supabase.dart` hors `SondageRegulier` ;
   - toute nouvelle policy de migration qui écrit `auth.uid()`, `app_account_valid()` ou `app_role()`
     sans `(select …)` ;
   - toute nouvelle tâche `cron.schedule` à la minute (elle doit passer par `tache-minute`).
   Comme `verifier_branchement`, une liste des exceptions existantes, qui ne fait que rétrécir.
   L'ajout de l'outil à la CI (`.github/`) relève du pilote, sur feu vert du directeur.
2. **Une ligne dans CLAUDE.md**, une fois ce document validé, pointant ici pour toute lecture,
   écriture, temps réel, tâche planifiée ou nouvelle table.
3. **Une ligne par étape dans `REGISTRE-LOTS.md`**, avec son statut et sa preuve, pour qu'aucune
   étape ne se perde.
4. **La preuve, c'est la mesure** : une étape n'est « faite » qu'avec son chiffre avant/après lu en
   production ou sur staging, jamais sur un test vert.

## Sources

- Supabase : guides/platform/compute-and-disk ; guides/troubleshooting/exhaust-disk-io ;
  guides/deployment/going-into-prod ; guides/realtime/limits ; guides/realtime/postgres-changes ;
  guides/realtime/subscribing-to-database-changes ; guides/realtime/broadcast ;
  guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv ; guides/cron/quickstart ;
  guides/database/extensions/pg_net ; guides/platform/manage-your-usage/compute ; pricing.
- Firebase : firestore/real-time_queries_at_scale ; firestore/best-practices.
- Google : sre.google/sre-book/addressing-cascading-failures ; sre.google/sre-book/handling-overload ;
  sre.google/workbook/alerting-on-slos ; cloud.google.com/storage/docs/retry-strategy ;
  cloud.google.com/sql/docs/postgres/best-practices.
- Grafana k6 : docs/k6/latest/testing-guides/test-types.
- Anthropic : code.claude.com/docs/en/best-practices.
- Non vérifié sur une page officielle : la durée exacte de la rafale disque par jour (« 30 minutes »
  n'est vu que dans un extrait du tableau de bord).
