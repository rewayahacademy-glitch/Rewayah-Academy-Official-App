# Registre de conformite - Performance et maintenabilite non auditees en transverse (listes, listeners, caches, invalidations, SQL)

- SHA audite : 4a7aa2b (code). HEAD reel de la branche claude/nice-darwin-hael93 : ff01c087, dont le diff hors `docs/` avec 4a7aa2be est vide (voir `docs/audit-harmonisation/mesures-sur-head.md`, section "Precision sur le SHA"). Les preuves ci-dessous sont donc valables pour 4a7aa2b.
- Date : 14/10/2026 (mission), lecture faite le 16/10/2026.
- Auditeur : agent de revue en lecture seule (domaine complementaire PRF).
- Domaine : performance et maintenabilite hors salle (listes, listeners, caches, invalidations, SQL). La performance de la salle est portee par AUD-SAL-038 et n'est pas reprise.
- Regle de preuve : aucun test execute par moi. Les tests cites sont "lus, non executes". Aucun gain de performance n'est annonce (DM 656, DM 234).

## 1. Perimetre, sources lues, sources introuvables

Sources lues :
- Document maitre : DM 656-658 (20.3 metriques a mesurer), DM 232-236 (06.6), DM 93-104 (01.4), plage DBA/performance DM 609-622 ; prompt de mission lignes 196-213 (5.1 C).
- Depot : `lib/core/suivi/service_suivi.dart`, `lib/core/controle/service_controle.dart`, `lib/core/coran/service_coran.dart`, `lib/core/tc_coran/corpus_service_coran.dart`, `lib/core/tc_coran/navigation_coran.dart`, `lib/features/tc_mushaf/navigation_coran_feuille.dart`, `lib/core/presence/service_presence.dart`, `lib/core/tc_classe/roster_enseignant.dart`, `lib/core/tc_observation/port_annonce_observation.dart`, `lib/core/tc_observation/moteur_visite_observation.dart`, `lib/core/tc_realtime/service_realtime_pedagogique.dart`, `lib/core/tc_etat_partage/service_etat_partage.dart`, `lib/core/session/session_controleur.dart`, `lib/features/salle/salle_page.dart`, `lib/features/tc_classe_live/classe_live_page.dart`, `lib/features/tc_observation_ui/entree_observation_page.dart`, `lib/core/planning/service_planning.dart`, `lib/core/enseignant/service_enseignant.dart`, `lib/core/regles/service_regles.dart`, `lib/core/matching/service_matching.dart`, `lib/core/cache/` (arborescence), `supabase/migrations/0001`, `0005`, `0007`, `0030`, `0032`, `0043` (index), `.github/workflows/flutter-deploy.yml`.
- Registres existants : `docs/audit-harmonisation/mesures-sur-head.md` (mesures F1 a F6, B1 a B4, S1 a S5), `salle-bibliotheque-teaching-core.md` (AUD-SAL-038), `controleur-communications-recherche.md` (AUD-COM-031 a 034, ligne 202), `enseignant-pedagogie-evaluations.md` (ligne 468).
- Releves chiffres par grep sur 4a7aa2b : 14 appels `.listen(` dans 7 fichiers (aucun hors des fichiers listes en section 2) ; 93 occurrences `ref.invalidate`/`ref.refresh` dans `lib/` ; 4 `ListView(` non virtualises contre 4 constructions `builder`/`separated`/`Sliver` ; 5 appels `.limit(` (aucun `.range(`) ; 48 occurrences `.select(` dont la plupart sont des lectures PostgREST sans borne ; 0 occurrence `autoDispose` ou `keepAlive` ; 1 import `deferred as`.

Sources introuvables ou non lues :
- Aucun document du depot ne fixe un budget de bundle, un budget de memoire, un objectif de cold start ni un p95 de recherche. Non trouve par grep dans `docs/HANDOFF.md`, `docs/PROGRESS.md`, `docs/architecture/decisions.md` (mots cles "cold start", "Lighthouse", "p95").
- Aucun resultat `EXPLAIN` ni benchmark SQL dans le depot.
- PR draft Codex (#13, #17, #21, #29 et autres) : non lues pour ce domaine, aucune n'est citee comme portant une exigence de performance. Non demontre.
- Docs HANDOFF.md : lu par grep et plages (lignes 190, 338, 555-565, 622-643), jamais en entier.

## 2. Registre par exigence

| ID | Exigence et source | Role et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Ecart minimal | Priorite | Responsable | Tache existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-PRF-001 | Mesurer le cold start PWA, sans l'affirmer (DM 656, section 20.3) | Tous, ouverture de la PWA | Build web, `flutter-deploy.yml` | ABSENT | Aucune mesure de cold start dans `.github/workflows/flutter-deploy.yml` (grep "lighthouse", "cold" : 0) ; aucune dans HANDOFF (grep 0) | Instrumenter une mesure de cold start (temps jusqu'au premier ecran interactif) sur staging et publier le chiffre. Non demontre aujourd'hui | P1 | frontend, exploitation | aucune tache existante trouvee |
| AUD-PRF-002 | Mesurer le poids du bundle (DM 656) | Tous | `main.dart.js` | CONFORME_PARTIEL | Mesure ponctuelle dans HANDOFF.md:338 (4 401 919 octets) et :561 (3 833 921 vers 4 312 086, +12,5 % pour flutter_webrtc) ; garde plancher seulement dans `flutter-deploy.yml:170-171` (`-gt 1000000`) | La garde verifie un minimum, pas un maximum. Aucun budget ni alerte de regression. Un bundle qui double ne declenche rien | P1 | frontend, exploitation | aucune tache existante trouvee (mesures consignees dans HANDOFF, sans seuil) |
| AUD-PRF-003 | Une seule importation differee pour limiter le bundle initial (DM 93-104, client sans proliferation) | Tous | Imports `deferred as` | CONFORME_PARTIEL | 1 occurrence `deferred as` dans `lib/` (grep) ; bundle servi 4,3 Mo (HANDOFF.md:338) | Le module visio (flutter_webrtc, +12,5 %, HANDOFF.md:561) est charge pour tous les roles. Differer le module serait un gain suppose, non mesure | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-004 | Mesurer la memoire sur appareil bas de gamme (DM 656) | Eleve sur telephone modeste | Application | ABSENT | Aucune occurrence de profilage memoire dans `docs/` ni `.github/` (grep "memoire" sans resultat de mesure) | Une mesure sur un appareil reel est requise ; marquer NON TESTE tant qu'elle n'existe pas (DM 20.2) | P1 | frontend, exploitation | aucune tache existante trouvee |
| AUD-PRF-005 | Aucune fuite de listener dans la salle (prompt 5.1 C, "fuite memoire ou listeners persistants") | Eleve, enseignant, en salle | `salle_page.dart`, `classe_live_page.dart`, `entree_observation_page.dart` | IMPLÉMENTÉ_NON_PROUVÉ | Trois abonnements annules dans `dispose` : `salle_page.dart:97-109` (listen) et `:118-121` (cancel) ; `classe_live_page.dart:167-184` et `:193-196` ; `entree_observation_page.dart:105` et `:115-116` | Aucun test lu qui prouve l'annulation (grep test "cancel" : seul `q12_navigation_session_persistante_test.dart:9` documente `quitter()` dans `dispose`, sans asserter l'annulation). Code correct, preuve de test non demontree | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-006 | Aucun listener persistant dans les services | Tous | `session_controleur.dart`, `service_realtime_pedagogique.dart`, `service_etat_partage.dart`, `moteur_visite_observation.dart` | CONFORME_PARTIEL | `session_controleur.dart:67` et `:72` (`ref.onDispose` annule) ; `service_realtime_pedagogique.dart:106-108` (`onCancel` annule l'amont) ; `service_etat_partage.dart:118-131` (`onCancel`) et `:218-226` (annulation de la table `_abonnements`) ; `moteur_visite_observation.dart:242-243` et `:334-335` | Quatre services conformes en lecture. `service_etat_partage.dart:246` et `:266` stockent des abonnements dans une table : l'annulation de chaque session depend d'un appel explicite de `fermer`. Non demontre qu'il est toujours appele | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-007 | Les minuteries de page sont annulees (reconstructions et appels inutiles) | Enseignant, controleur, famille, eleve | `journee_page.dart`, `suivi_eleve_page.dart`, `accueil_famille_page.dart`, `planning_page.dart`, `suivi_foyer_page.dart`, `appairage_page.dart`, `accueil_eleve_page.dart` | CONFORME_PARTIEL | Sept `Timer.periodic` ont chacun un `cancel()` : `journee_page.dart:139` et `:147`, `suivi_eleve_page.dart:44` et `:53`, `accueil_famille_page.dart:160` et `:168`, `planning_page.dart:91` et `:106`, `suivi_foyer_page.dart:75` et `:87`, `appairage_page.dart:46` et `:54`, `accueil_eleve_page.dart:152` et `:160` | Je n'ai pas verifie que chaque `cancel()` est dans `dispose` (lignes proches mais non lues une a une). Aucun test d'absence de timer apres demontage | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-008 | Interrogation periodique de la presence bornee et annulee | Enseignant, controleur en salle | `service_presence.dart`, `presenceDeSeanceProvider` | IMPLÉMENTÉ_NON_PROUVÉ | `service_presence.dart:261` (`cadencePresence` 20 s), `:298-306` (minuterie annulee dans `ref.onDispose`), `:313-315` (premiere lecture immediate) | Pas de polling adaptatif ni de pause hors focus. Deux requetes `presence_seance_v` et `teacher_roster_v` sont reinterrogees toutes les 20 s par salle ouverte (`roster_enseignant.dart:279-282`). Aucune mesure du cout. Pas d'evitement de chevauchement si une lecture depasse 20 s : non demontre (verifier `lire()` sans garde) | P1 | frontend, backend | AUD-SAL-038 (salle), sinon aucune tache existante trouvee |
| AUD-PRF-009 | Annonces d'observation relues toutes les 10 s sans abonnement realtime | Parent ou observateur | `port_annonce_observation.dart` | IMPLÉMENTÉ_NON_PROUVÉ | `port_annonce_observation.dart:48-53` (`cadenceAnnonceObservation` 10 s) et `:99-102` (minuterie) | Choix de conception documente dans le fichier ; cout en requetes par observateur non mesure. Supabase Realtime n'est pas utilise (aucun `.channel(` dans `lib/`) | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-010 | Historique du foyer plafonne et declare tronque | Tuteur, controleur | `service_suivi.dart`, `vue_suivi_foyer.dart` | CONFORME_PARTIEL | `service_suivi.dart:16` (`plafondSuiviFoyer = 200`), `:62` et `:78` (`.limit`) ; `vue_suivi_foyer.dart:130` et `:116-140` (`tronquee`) ; test lu `test/suivi/vue_suivi_foyer_test.dart:326-350` ("TUT-06 : une lecture au plafond se declare tronquee"), non execute | Route atteignable non relue de bout en bout dans ce registre. Plafond de 200 sans pagination "voir plus" : la fenetre est coupee, pas paginee. Choix a arbitrer (voir CP-PRF-02) | P2 | frontend | TUT-06 (nom du test) |
| AUD-PRF-011 | Planning global du controleur plafonne | Controleur | `service_controle.dart`, `vue_planning.dart` | CONFORME_PARTIEL | `service_controle.dart:13` (`plafondPlanningGlobal = 200`) et `:57` (`.limit`) ; `vue_planning.dart:153` (plafond), `:116` et `:204` (`tronquee`) | Aucun test lu sur la troncature du planning (grep test "plafondPlanningGlobal" : 0). Meme remarque de pagination que PRF-010 | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-012 | Listes de seances de l'enseignant et du planning sans borne | Enseignant, planning | `service_planning.dart:298-305`, `:307-314`, `service_enseignant.dart:68-75` | ABSENT | `service_planning.dart:301-303` (`mes_seances_v` : `select()` puis `order`, sans `limit` ni `range`) ; `:309-312` (`mes_affectations_v`, idem) ; `service_enseignant.dart:70-74` (`mes_seances_enseignant_v`, idem) ; `service_enseignant.dart:88-93` (`mes_groupes_v`, idem) | Lectures de vues sans borne. Cardinalite non mesuree : non demontre que le volume reste faible. La borne cote serveur (limite de lignes PostgREST) n'a pas ete lue. L'historique d'un enseignant grossit avec le temps, a la difference du foyer (plafonne) | P1 | frontend, contrat partage | aucune tache existante trouvee |
| AUD-PRF-013 | Pagination des listes volumineuses (prompt 5.1 C, "listes, historiques et resultats de recherche volumineux") | Admin, enseignant | Services Supabase de `lib/core/` | ABSENT | Aucun `.range(` dans `lib/` (grep) ; 5 `.limit(` seulement : `service_suivi.dart:62`, `:78`, `service_controle.dart:57`, `service_coran.dart:336`, `:461` | Le depot ne contient aucune pagination par curseur ou par plage. Les ecrans admin lisent des listes entieres. Cardinalite cible non documentee : non demontre que c'est un risque a ce volume | P1 | frontend, backend | aucune tache existante trouvee |
| AUD-PRF-014 | Listes virtualisees (prompt 5.1 C) | Tous | `ListView(` sans builder | CONFORME_PARTIEL | 4 `ListView(` non virtualises : `roster_classe.dart:184`, `acces_agents_page.dart:222`, `panneau_enseignant.dart:359`, `qualite_page.dart:160` ; 4 usages virtualises (grep `ListView.builder`, `.separated`, `SliverList`, `GridView.builder`) | `roster_classe.dart:184` utilise `shrinkWrap: true` (cout lineaire a chaque mise en page) pour un roster borne par la classe. Pour les trois autres, cardinalite non lue. Aucun defaut demontre | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-015 | Index trigramme de la recherche Coran | Eleve, enseignant | `verset.texte_recherche` | CONFORME_PROUVÉ | `0030_tc_socle.sql:24` (`pg_trgm`), `:193-196` (colonne generee `texte_recherche`), `:198-199` (index GIN `verset_recherche_idx` en `gin_trgm_ops`) ; l'objet SQL est la preuve | Cette ligne atteste l'existence de l'index, pas son usage (voir PRF-016) | - | backend | aucune tache existante trouvee |
| AUD-PRF-016 | La recherche plein texte du Coran interroge l'index | Eleve, enseignant, recherche dans le Coran | `ServiceCoran.rechercher`, `CorpusServiceCoran.rechercher` | PRÉSENT_MAIS_NON_RACCORDÉ | `corpus_service_coran.dart:190-196` : "rien ici ne l'interroge : aucune RPC, aucun appel Dart" ; `navigation_coran.dart:105-106` (`rechercheRapide` appelle `corpus.rechercher` : sourates et pages seulement) ; `service_coran.dart:458` (`.ilike('texte', '%$requete%')`, colonne `texte`, pas `texte_recherche`) ; `ServiceCoran.rechercher` n'est appelee depuis aucun fichier de `lib/` (grep `rechercher` : seulement definitions) | Deux defauts : (a) la recherche de versets n'est pas branchee a l'ecran ; (b) si on la branchait telle quelle, `ilike '%x%'` sur `texte` ne peut pas utiliser l'index pose sur `texte_recherche` (balayage sequentiel sur tout le Coran). Voir CP-PRF-03. Hors scope : sens religieux du texte (non touche) | P1 | frontend, backend | AUD-COM-034 (recherche Coran) |
| AUD-PRF-017 | Anti-rebond et abandon de la reponse perimee dans la recherche | Eleve, enseignant | `navigation_coran_feuille.dart` | ABSENT | `navigation_coran_feuille.dart:62-73` (`_chercher` ne contient ni `Timer` ni jeton de generation) et `:93-94` (`onChanged: _chercher`) ; grep "debounce" dans `lib/features/tc_mushaf` : 0 | Une requete par frappe ; deux reponses qui arrivent dans le desordre peuvent ecraser la plus recente (`:69-72`). Aujourd'hui la recherche est locale (sourates et pages), le cout est faible ; le defaut devient reel des que la recherche de versets est branchee | P2 | frontend | AUD-COM-031 a 034 (recherche) |
| AUD-PRF-018 | p95 et p99 de la recherche : a mesurer, pas a annoncer (DM 656 ; `controleur-communications-recherche.md:202`) | Tous | Recherche | ABSENT | Aucune mesure : `docs/audit-harmonisation/controleur-communications-recherche.md:202` ("objectif non mesure") | Declarer NON MESURE. Aucun chiffre ne doit apparaitre dans l'interface ni la documentation | P2 | exploitation | AUD-COM-031 a 034 |
| AUD-PRF-019 | Politique d'invalidation des providers documentee (prompt 5.1 C, "strategies de cache et d'invalidation") | Admin, enseignant | `ref.invalidate` | ABSENT | 93 occurrences dans `lib/` ; concentration : `programmes_page.dart` (9), `groupes_page.dart` (9), `creneaux_page.dart` (5), `journee_page.dart` (4). Aucune regle ecrite dans `docs/architecture/decisions.md` (grep "invalidate" : sans regle) | Chaque ecran invalide a la main apres chaque ecriture. Risque de lecture obsolete si un ecran oublie un provider, et de rechargements en doublon. Pas de defaut demontre, pas de convention. Voir CP-PRF-04 | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-020 | Double invalidation apres une action | Enseignant | `journee_page.dart` | IMPLÉMENTÉ_NON_PROUVÉ | `journee_page.dart:721-722` (`cahiersEnRetardProvider` et `seancesEnseignantProvider` invalides ensemble) | Deux rechargements au lieu d'un si les deux providers lisent la meme vue. Non demontre | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-021 | Cycle de vie des providers : `autoDispose` et `keepAlive` | Tous | Providers Riverpod | À_ARBITRER | 0 occurrence de `autoDispose` ou `keepAlive` dans `lib/` (grep). Riverpod 3 est utilise (`import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily` dans `service_presence.dart:7`), version non lue dans `pubspec.yaml` | Avec Riverpod 3 le defaut des providers peut etre le nettoyage automatique ; non verifie. Decision requise sur la version et le defaut. Non demontre qu'un provider reste en memoire a tort | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-022 | `select()` demande uniquement les colonnes utiles | Tous | Services Supabase | CONFORME_PARTIEL | 48 `.select(` dans `lib/` ; avec colonnes : `service_offres.dart:113` (`'code, nom_humain'`), `service_acceptations.dart:89`, `source_session.dart:81` ; sans colonnes (`select()`) : `service_suivi.dart:60`, `service_planning.dart:266`, `service_enseignant.dart:73` | Majorite en `select()` sur vues : toutes colonnes renvoyees. Gain suppose, non mesure ; l'enjeu principal est la bande passante des vues larges (`teacher_roster_v`). Ne pas generaliser sans mesure | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-023 | Index SQL sur les chemins de lecture des seances | Enseignant, eleve | `sessions`, `session_participants` | CONFORME_PARTIEL | `0001_fondations.sql:1246-1261` : `sessions_teacher_time_ix (teacher_id, started_at)`, `session_participants_session_ix (session_id)`, `sessions_upcoming_participant_ix (profile_id, session_id)` | Index existants sur les colonnes d'acces principal. Aucun `EXPLAIN` dans le depot sur les vues `mes_seances_v` (`0014_acces_agent.sql:888`) et `presence_seance_v` (`0033_tc_vues_rpc.sql:47`) : plans non demontres | P1 | backend | aucune tache existante trouvee |
| AUD-PRF-024 | Politiques RLS sans reevaluation par ligne de `auth.uid()` | Tous | Policies RLS | CONFORME_PROUVÉ | Aucune occurrence de `auth.uid()` hors de `(select auth.uid())` dans `supabase/migrations/` (grep -v : 0) ; 216 occurrences de la forme `(select auth.uid())` | Prouve par contrainte lue dans le code SQL sur le motif `auth.uid()`. Ne couvre pas les fonctions `est_du_foyer` et semblables appelees par ligne dans les vues (voir PRF-025) | - | backend | aucune tache existante trouvee |
| AUD-PRF-025 | Cout des fonctions d'appartenance appelees par ligne dans les vues | Tuteur, enseignant | `presence_seance_v`, `teacher_roster_v` | IMPLÉMENTÉ_NON_PROUVÉ | `0033_tc_vues_rpc.sql:47` et `:184` (vues redefinies) ; `mesures-sur-head.md`, scenario `scenarios_agt01.sql` : `permission denied for function est_du_foyer` dans `presence_seance_v` | Une fonction appelee ligne par ligne peut multiplier les acces. Non mesure. L'echec de `scenarios_agt01.sql` (mesures B3, B4) est un sujet distinct, porte par le registre de securite | P1 | backend | aucune tache existante trouvee |
| AUD-PRF-026 | Contention des inscriptions et plafond d'un cours (DM 656, "contention des inscriptions") | Eleve, controleur | Inscription a une seance | ABSENT | Aucune mesure de concurrence dans le depot. `mesures-sur-head.md` signale `scenarios_ctr01.sql` : "C2 : un troisieme eleve a ete accepte dans un cours 1-to-1" (echec B3 et B4) | Le test de plafond en echec indique un risque de concurrence ou de regle, cause non identifiee. A traiter avec le registre de calendrier. Aucun test de charge | P0 | backend | aucune tache existante trouvee (voir CTR-01 dans les scenarios) |
| AUD-PRF-027 | Cache local borne et purge | Famille, enseignant | `lib/core/cache/db/app_database.dart`, `cache/media/cache_media.dart` | CONFORME_PARTIEL | Cinq tables Drift (`app_database.dart:11`, `:44`, `:75`, `:101`, `:118`) ; purge des photos decrite dans `cache_media.dart:8-58` ; tests lus `test/cache/purge_photos_test.dart` et `test/cache/file_rapports_test.dart`, non executes | Purge liee a la revocation des photos (ADR-012), pas a une taille maximale. Aucune borne globale de stockage local ni de nettoyage de `SessionsAVenir`. Non demontre | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-028 | Images chargees en reseau avec taille adaptee | Admin, tous (avatars) | `dossiers_page.dart:374`, `avatar_tile.dart:61` | IMPLÉMENTÉ_NON_PROUVÉ | `Image.network` aux deux emplacements (grep) ; aucun `cacheWidth` ni `cached_network_image` (grep : 0) | Les images sont decodees a leur taille source. Pour les pieces du dossier d'identite la page admin peut decoder de gros fichiers : non mesure. Aucune donnee d'identite n'est reproduite ici | P2 | frontend | aucune tache existante trouvee |
| AUD-PRF-029 | Gain de performance annonce seulement apres mesure (prompt 5.1 C ; DM 234) | Gouvernance | Documentation | CONFORME_PARTIEL | `controleur-communications-recherche.md:202`, `salle-bibliotheque-teaching-core.md` AUD-SAL-038 ("aucune cible chiffree n'est annoncee"), `enseignant-pedagogie-evaluations.md:468` | Les registres existants respectent la regle. Rien ne garantit qu'elle tienne pour le code : les commentaires de lib citent des "mesures" (par exemple `service_presence.dart:267-268`) sans lien vers un journal | P2 | gouvernance | aucune tache existante trouvee |
| AUD-PRF-030 | Echantillonnage de traces et confidentialite des alertes (DM 656, "sans journaliser requetes privees ni contenu des enfants") | Exploitation | Sentry | CONFORME_PARTIEL | `lib/core/observabilite/supervision.dart:59` (`tracesSampleRate = 0.0`) | Aucune trace de performance collectee : conforme a la confidentialite, mais aucune metrique d'echec orientee action non plus. Contenu des breadcrumbs non relu | P2 | frontend, exploitation | aucune tache existante trouvee |
| AUD-PRF-031 | Metriques metier du parcours (temps median du cahier, taux de missions accomplies, DM 656) | Enseignant | Cahier de transmission | ABSENT | Aucune instrumentation de duree ni de taux (grep `Stopwatch`, `analytics` sans usage metier dans `lib/features/cahier`). Non demontre au-dela du grep | Definir des evenements agreges, sans identifiant d'enfant. Decision de gouvernance requise | P2 | gouvernance, frontend | aucune tache existante trouvee |
| AUD-PRF-032 | CI : build web de production sans garde de poids maximal et sans execution de test de performance | Exploitation | `flutter-deploy.yml`, `ci.yml` | ABSENT | `flutter-deploy.yml:90-98` (build release) ; `:170-171` (plancher seul). Aucun test de performance dans `.github/workflows/ci.yml` (grep "benchmark", "perf" : 0) | Voir PRF-002. Un budget est une decision a prendre, pas une mesure | P2 | exploitation | aucune tache existante trouvee |
| AUD-PRF-033 | Reproductibilite de la suite SQL qui sert de base aux mesures de plan | Exploitation | Job `migrate-check` | RÉGRESSION | `mesures-sur-head.md` mesure B1 : `0030_tc_socle.sql` echoue (`relation "storage.buckets" does not exist`) sur le stub CI ; le job s'arrete a la migration 0030 | Sans base reconstruite par la CI, aucun benchmark SQL reproductible n'est possible. Cause attribuee au stub, non verifiee sous Postgres 17. Registre de reference : mesures-sur-head.md | P1 | backend, exploitation | aucune tache existante trouvee |
| AUD-PRF-034 | Fichier de migration en double numerotation et migrations non appliquees : dette de maintenabilite | Backend | `supabase/migrations/` | CONTRADICTOIRE | `mesures-sur-head.md` S3 : numeros en double 0030, 0032, 0033, trous 0039 a 0042 ; `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` | Risque d'ordre d'application ambigu pour un index ou une vue. Cote perf, un index pose dans une migration non appliquee n'existe pas en production : non verifie (appels distants interdits) | P1 | backend | aucune tache existante trouvee |
| AUD-PRF-035 | Etat des index sur les nouvelles tables de l'offre | Famille, controleur | `0043_offres_horaires_et_intentions.sql` | IMPLÉMENTÉ_NON_PROUVÉ | `0043_offres_horaires_et_intentions.sql:349-353`, `:413-416`, `:461` (index uniques et partiels) | Index pose sur les cles d'unicite et de filtrage visible dans la migration. Aucun plan d'execution ; aucune confirmation d'application en environnement | P2 | backend | aucune tache existante trouvee |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Perimetre | Decision la plus recente applicable | Statut | Consequence |
|---|---|---|---|---|---|---|
| CTR-PRF-01 | `corpus_service_coran.dart:190-196` : l'index trigramme sur `texte_recherche` existe et n'est interroge par aucun code | `service_coran.dart:445-461` : une methode de recherche existe mais filtre `texte` avec `ilike` | Recherche de versets | Aucune decision ecrite sur l'usage de `texte_recherche`. Le commentaire du 21/09/2026 dans le corpus dit explicitement "rien ici ne l'interroge" | ouvert | La recherche de versets est coupee de l'ecran, et la methode existante ne sert pas l'index. Voir CP-PRF-03 |
| CTR-PRF-02 | `mesures-sur-head.md`, chiffres du HANDOFF (729 tests, 684/691) | Mesure du 15/10/2026 : 1762 tests, 0 echec | Chiffres de non-regression | La mesure plus recente (15/10/2026) | obsolete | Les budgets de non-regression chiffres du HANDOFF ne servent plus de reference. Repris du registre des mesures |
| CTR-PRF-03 | `service_suivi.dart:16` et `service_controle.dart:13` : plafond de 200 lignes | `service_planning.dart:298-314`, `service_enseignant.dart:68-93` : lectures sans plafond de lignes similaires (`mes_seances_v`) | Lecture des seances | Aucune decision ecrite. Le plafond du foyer est documente (ADR non lu pour ce point) | ouvert | Memes vues, bornes differentes selon l'appelant. Voir CP-PRF-02 |
| CTR-PRF-04 | Commentaire de `service_presence.dart:267` : "Un StreamProvider qui propagerait l'erreur laisserait l'ecran sur..." | `roster_enseignant.dart:245-246` : "La meme cadence que la presence" pour deux etats dependants du temps | Interrogation periodique | Aucune decision ecrite hors commentaires | ouvert | Une seule constante (20 s) commande deux lectures. Changer la cadence pour l'une change l'autre. Non mesure |

## 4. Devoir de regard - contre-propositions

Situation : decision tranchee + implementation defectueuse = D ; decision tranchee + risque nouveau = R ; contradiction reelle entre sources actives = C.

### CP-PRF-01 - Poser un budget de performance mesure (cold start, bundle, memoire)
1. Identifiant : CP-PRF-01. 2. Source : DM 656 (20.3) ; prompt de mission 196-213.
3. Constat : aucune mesure de cold start ni de memoire (AUD-PRF-001, 004) ; le bundle est mesure ponctuellement (HANDOFF.md:338, :561) et la CI ne controle qu'un plancher (`flutter-deploy.yml:170-171`).
4. Risque : une regression de poids ou de memoire passe inapercue, surtout sur telephone modeste. Situation R.
5. Gravite et priorite : moyenne, P1.
6. Regle actuelle : plancher de 1 000 000 octets.
7. Contre-proposition : consigner dans un journal date une mesure de reference (taille de `main.dart.js`, temps jusqu'au premier ecran, memoire apres 5 minutes) sur un appareil nomme, puis proposer un plafond de regression (par exemple une alerte au depassement de 10 % sur la reference). Le seuil exact est une decision, pas une recommandation fermee.
8. Options : (a) seulement la taille du bundle dans la CI ; (b) mesure manuelle trimestrielle ; (c) mesure automatisee en CI. 
9. Consequences : (a) simple, partiel ; (c) demande un appareil ou emulateur stable.
10. Perimetre : frontend, exploitation.
11. Dependances : staging distinct, PR #26 (aperçus staging) non lue pour ce point.
12. Criteres d'acceptation : trois chiffres consignes avec date, SHA et appareil.
13. Tests et preuves : journal date, sortie CI.
14. Decision requise : valider le seuil et l'appareil de reference (direction).

### CP-PRF-02 - Harmoniser les bornes de lecture des seances et choisir pagination ou plafond
1. CP-PRF-02. 2. Source : prompt 5.1 C ("listes, historiques et resultats de recherche volumineux") ; AUD-PRF-010 a 013.
3. Constat : le foyer et le controleur sont plafonnes a 200 (`service_suivi.dart:16`, `service_controle.dart:13`), l'enseignant et le planning non (`service_enseignant.dart:70-74`, `service_planning.dart:301-303`) ; aucun `.range(`.
4. Risque : lenteur et bande passante croissantes avec l'historique d'un enseignant. Situation C (CTR-PRF-03).
5. Gravite : moyenne a haute selon volume reel, P1.
6. Regle actuelle : plafond fixe, tronque et declare (test TUT-06).
7. Contre-proposition : mesurer d'abord la cardinalite par role sur staging ; si un historique depasse 200, ajouter une fenetre glissante (a venir plus N derniers) cote vue SQL, sans nouvel ecran.
8. Options : (a) plafond partout ; (b) pagination par curseur ; (c) fenetre temporelle.
9. Consequences : (a) simple, perte d'historique ; (b) etat d'ecran en plus (chargement de la page suivante).
10. Perimetre : frontend et contrat partage (les vues sont backend).
11. Dependances : proprietaire backend des vues ; aucune modification de vue sans accord.
12. Criteres : chaque lecture de liste a une borne documentee et un etat "tronque" visible.
13. Tests : extension du test de troncature aux services concernes ; releve de cardinalite.
14. Decision requise : plafond ou pagination, choix du proprietaire produit.

### CP-PRF-03 - Brancher la recherche de versets sur l'index existant
1. CP-PRF-03. 2. Source : DM 93-104 ("PostgreSQL et index existants comme premiere strategie") ; CTR-PRF-01.
3. Constat : index GIN present (`0030_tc_socle.sql:198-199`), non utilise (`corpus_service_coran.dart:190-196`) ; la methode `ServiceCoran.rechercher` filtre `texte` avec `ilike` (`service_coran.dart:458`), colonne sans index.
4. Risque : si la methode est branchee telle quelle, balayage sequentiel, lent au fur et a mesure. Situation R.
5. Gravite : moyenne, P1.
6. Regle actuelle : seules les sourates et les pages sont cherchees.
7. Contre-proposition : si la recherche de versets est voulue, interroger `texte_recherche` avec un terme normalise de la meme facon que la colonne (retrait des diacritiques), puis relire avec `EXPLAIN` sur staging. Ne pas toucher au texte source (licence rappelee `0030_tc_socle.sql:191-192`). Point a valider par le referent academique : la normalisation des diacritiques ne doit pas changer le sens affiche.
8. Options : (a) RPC dediee ; (b) filtre PostgREST sur `texte_recherche` ; (c) ne pas offrir la recherche de versets.
9. Consequences : (c) supprime le code mort `ServiceCoran.rechercher`.
10. Perimetre : frontend, backend (RPC eventuelle), contenu academique (normalisation).
11. Dependances : AUD-COM-034.
12. Criteres : plan `EXPLAIN` utilisant `verset_recherche_idx` ; resultat borne.
13. Tests : test de service avec faux client ; plan lu sur staging.
14. Decision requise : offrir ou non la recherche de versets (produit) et valider la normalisation (referent academique).

### CP-PRF-04 - Ecrire la convention d'invalidation des providers
1. CP-PRF-04. 2. Source : prompt 5.1 C ("strategies de cache et d'invalidation").
3. Constat : 93 invalidations manuelles, aucune regle (AUD-PRF-019, 020, 021).
4. Risque : lecture obsolete ou rechargement double. Situation R.
5. Gravite : faible, P2.
6. Regle actuelle : implicite.
7. Contre-proposition : un court paragraphe dans `decisions.md` qui dit qui invalide quoi apres une ecriture (le service d'ecriture expose la liste des providers a invalider), puis relever les doublons. Pas de refonte.
8. Options : (a) convention ecrite seule ; (b) helper partage.
9. Consequences : (b) ajoute une abstraction, a eviter sans besoin prouve.
10. Perimetre : frontend, gouvernance.
11. Dependances : aucune.
12. Criteres : un paragraphe d'ADR, une revue des quatre fichiers les plus charges.
13. Tests : un test de non-regression pour un ecran admin (invalidation apres ecriture).
14. Decision requise : valider la convention (responsable technique).

### CP-PRF-05 - Prouver par test l'absence de listener persistant
1. CP-PRF-05. 2. Source : prompt 5.1 C ("fuite memoire ou listeners persistants") ; AUD-PRF-005 a 009.
3. Constat : code d'annulation present partout ou lu, aucun test d'annulation lu.
4. Risque : regression silencieuse, notamment avec la persistance de la salle (`q12_navigation_session_persistante_test.dart:9`). Situation R.
5. Gravite : moyenne, P2.
6. Regle actuelle : revue manuelle.
7. Contre-proposition : un test generique qui monte puis demonte chaque page et verifie que les flux sources n'ont plus d'ecouteur (`hasListener` faux) et que `fakeAsync` n'a plus de minuterie en attente.
8. Options : (a) test par page ; (b) test generique sur la liste des ecrans.
9. Consequences : (b) coute moins a maintenir.
10. Perimetre : frontend.
11. Dependances : aucune.
12. Criteres : un test echoue si une minuterie ou un abonnement survit au demontage.
13. Tests : `fakeAsync` et `StreamController.hasListener`.
14. Decision requise : aucune, a planifier.

### CP-PRF-06 - Rendre la cadence de presence adaptable sans la promettre
1. CP-PRF-06. 2. Source : prompt 5.1 C ("appels inutiles") ; AUD-PRF-008, CTR-PRF-04.
3. Constat : 20 s fixes, deux lectures par salle (`service_presence.dart:261`, `roster_enseignant.dart:279-282`), pas de garde de chevauchement lue.
4. Risque : charge proportionnelle au nombre de salles ouvertes. Situation R.
5. Gravite : moyenne, P1.
6. Regle actuelle : constante unique.
7. Contre-proposition : (a) ne pas relancer `lire()` si la precedente est en vol ; (b) mettre en pause quand l'onglet est cache ; (c) mesurer le nombre de requetes par minute avant de changer 20 s. Aucun gain n'est annonce.
8. Options : (a) seul garde de chevauchement ; (b) a + pause hors focus ; (c) Realtime.
9. Consequences : (c) change le modele de securite et d'architecture : hors proposition.
10. Perimetre : frontend ; backend si Realtime.
11. Dependances : AUD-SAL-038.
12. Criteres : un seul appel en vol par flux, mesure du nombre de requetes.
13. Tests : `fakeAsync` avec reponse lente.
14. Decision requise : accepter (a) et (b) sans decision metier ; (c) a arbitrer.

### CP-PRF-07 - Remettre la CI SQL en etat avant tout benchmark
1. CP-PRF-07. 2. Source : DM 609-622 (relecteur DBA) ; AUD-PRF-033, 034.
3. Constat : `migrate-check` s'arrete a 0030 sur le stub (`mesures-sur-head.md` B1) ; numeros de migrations en double.
4. Risque : impossible de mesurer un plan SQL de maniere reproductible. Situation C (CI et schema).
5. Gravite : haute pour l'exploitation, P1.
6. Regle actuelle : stub commun sans schema `storage`.
7. Contre-proposition : ajouter un stub `storage` minimal dans `supabase/tests/`, comme dans l'experience B3 ; ne rien appliquer a distance.
8. Options : (a) stub ; (b) base Supabase locale.
9. Consequences : (b) demande Docker, non disponible ici.
10. Perimetre : backend, exploitation.
11. Dependances : PR #25 (ledger migrations lot A) non lue pour ce point.
12. Criteres : `migrate-check` vert sur Postgres 17.
13. Tests : run CI.
14. Decision requise : proprietaire backend.

## 5. Etats d'ecran et applicabilite

| Etat | Constat | Statut |
|---|---|---|
| Chargement | Hors perimetre de ce domaine (transverse). Non verifie ici pour chaque ecran de liste | non demontre |
| Contenu | Les listes plafonnees se declarent tronquees (`vue_suivi_foyer.dart:116-140`) | present pour le foyer et le planning controleur, absent pour les autres lectures sans borne (AUD-PRF-012) |
| Vide | Non verifie pour les listes admin lues ici | non demontre |
| Erreur | Les services de presence et de suivi attrapent l'exception et affichent "inconnu" (`service_suivi.dart:78-90`, `service_presence.dart:232-240`) : etat d'erreur absorbe sans panne d'ecran | present |
| Hors ligne | Cache Drift avec rapports en attente (`depot_cahiers.dart:27`, `file_rapports.dart`) ; pas de borne de taille | partiel |
| Session expiree | `session_controleur.dart:67-72` ecoute les etats et annule | present (sans test d'annulation lu) |
| Acces refuse | Non applicable a ce domaine, porte par les registres de securite | non applicable |
| Reprise | Interrogation periodique reprend seule apres erreur (`service_presence.dart:298`) ; la reprise apres mise en veille n'est pas verifiee | non demontre |

## 6. Non verifie et limites de la preuve

- Aucun test execute par moi. Les mesures F1 a F6 du fichier `mesures-sur-head.md` (1762 tests passes, 15/10/2026) sont reprises sans les rejouer.
- Cold start, memoire, p95 et p99, plans SQL, contention : aucune mesure existe ; rien n'est annonce.
- Nombre de lignes reel des vues (`mes_seances_v`, `mes_seances_enseignant_v`, `mes_groupes_v`) non connu : aucune base distante interrogee.
- Limite de lignes par defaut de PostgREST et son effet sur les lectures sans `limit` : non lue.
- Version de Riverpod et defaut de nettoyage des providers : `pubspec.yaml` non lu.
- Les comptes (14 `.listen(`, 93 invalidations, 4 `ListView(`) viennent de grep sur 4a7aa2b et peuvent omettre des appels formates sur plusieurs lignes.
- Chaque `cancel()` de minuterie a ete localise par numero de ligne, mais son appartenance a `dispose` n'a pas ete lue ligne a ligne pour les sept pages.
- PR draft Codex : non lues pour ce domaine. Aucune exigence PRF n'y a ete identifiee, ce qui ne prouve pas qu'il n'y en a pas.
- Les migrations 0035 a 0037 sont notees non appliquees (`LISEZ-MOI-0035-0037-non-appliquees.md`) : l'etat des index en production n'a pas ete verifie.
