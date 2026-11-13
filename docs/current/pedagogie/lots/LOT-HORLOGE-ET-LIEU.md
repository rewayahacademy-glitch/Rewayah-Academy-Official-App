# LOT HORLOGE-ET-LIEU : relevé de l'existant, risques, plan de construction

## Ordre d'installation, à lire avant toute autre ligne (13/11/2026)

**1. Mettre l'application à jour, et recharger tous les onglets ouverts. 2. Installer les migrations, dans l'ordre des numéros (`20261123940000` à `20261123943100`). Entre les deux, ne modifier aucun horaire** (ni créneau, ni jour ou heure d'une classe). Un horaire modifié entre les deux est au mieux refusé, jamais enregistré faux (états a et b ci-dessous).

Ce que fait le logiciel aujourd'hui dans les trois états, dit sans enjoliver :

- **(a) Application à jour, serveur pas encore migré : le logiciel fait juste.** Les fonctions avec fuseau sont absentes du serveur (`PGRST202` ou `42883`) : le client retombe sur l'ancienne fonction seulement si l'heure saisie est celle de la classe (encore Europe/Paris), donc lue au bon fuseau ; l'horaire est enregistré à la bonne heure. Dans le cas, pratiquement inatteignable dans cet état, où l'heure saisie serait dans un autre fuseau que celui de la classe, le client refuse lui-même, sans rien envoyer : « Ce changement d'horaire n'est pas encore disponible : réessayez dans quelques minutes. » Prouvé par `test/core/admin/creneaux_classe_supabase_test.dart` et `test/core/admin/service_groupes_supabase_test.dart` (vrai client, faux serveur HTTP local).
- **(b) Ancienne application (onglet ou PWA pas rechargé), serveur migré : le logiciel refuse sans rien modifier, mais la phrase de l'ancien client est inexacte, et on ne peut pas la corriger : ce client est déjà distribué.** La garde (migration `20261123940300`, erreur `P0001` « RechargerPourModifierUnHoraire ») refuse tout appel sans fuseau qui déplace une heure d'une classe à l'heure de La Mecque ; renommer, changer un seuil ou la durée d'un créneau sans le déplacer reste accepté. L'ancien client affiche, dans les feuilles du créneau et des réglages de la classe : « Le créneau n'est pas confirmé : il est possible que la demande ne soit pas parvenue jusqu'à Rewayah. Réessayez dans un instant. » (faux : réessayer refusera toujours) ; dans la feuille du nom ou du seuil, si l'appel déplace une heure : « le serveur a refusé cette action sans en dire la raison. Vérifiez vos choix, puis pressez de nouveau. » Rien n'est écrit en base. Remède : recharger l'application. **Décision de l'architecte (13/11) : la garde est gardée ; un refus à phrase inexacte vaut mieux qu'un horaire faux.** Le nouveau client, lui, dit la bonne phrase : « Rechargez l'application pour modifier un horaire. »
- **(c) Application à jour, serveur migré : le fuseau de l'heure saisie part avec l'appel, le serveur convertit vers le fuseau de la classe, et l'écran montre l'équivalent à l'heure de La Mecque avant l'envoi.**

Non prouvé : aucune de ces installations n'a été faite sur staging ni en production ; tout est local (Postgres 16 nu, vrai client contre faux serveur).

### Migrations de ce lot, dans l'ordre (13 fichiers, plage `20261123940000` à `20261123943200`)

`940000` horloge_lieu, `940100` horloge_annonces, `940200` villes_schema, `940300` horloge_correctifs_a (contrôle d'entrée par empreinte des cinq fonctions remplacées, relevées en production le 13/11), `942100` à `942150` villes_donnees_1 à 6 (environ 500 Ko chacune, 0,1 à 0,2 s par fichier en local, un fichier par requête), `942200` villes_controle, `943000` lieux, `943100` apercu_offre, `943200` lieux_correctifs. Aucune instruction `DROP`, `DELETE` ni `TRUNCATE` ; trois `ON DELETE CASCADE` dans `943000` (le mot apparaît) ; les `DELETE` de l'anonymisation sont dans la fonction `private.cpt_anonymiser`, pas dans la migration.

### Revue du 13/11/2026 (tête `d85f9ac0c`), corrections

1. **Le candidat enseignant en `pending_kyc` enregistre sa ville** (`943200`) : le seul rôle `teacher`, pour son propre lieu ; le tuteur en attente, le compte désactivé ou supprimé et le jeton « teacher » sur un autre profil restent refusés. L'adulte « pour moi » est un `guardian` avec son foyer d'une personne : il passe par la branche du tuteur. Preuve : `supabase/tests/scenarios_horloge_lieu_c.sql` (vrai candidat par `inviter_enseignant` puis `inscrire_enseignant_invite`, recherche puis enregistrement ; le scénario échoue exactement là avec l'ancienne fonction) et `test/features/candidature/ville_etape_serveur_test.dart` (adaptateur réel, aucun faux port).
2. **Suppression de compte** : `private.cpt_anonymiser` efface le lieu du profil, le rappel de report, et la ligne du foyer quand le dernier tuteur actif part (`943200`, scénario).
3. **Refus de conversion** : la direction reçoit un avis propre (cause fermée `proche`, `demi_heure`, `autre`, sans texte SQL ni identifiant), un courriel dédié dans les cinq langues avec le lien `/admin/operations/planning` (`940300`, `outils.ts`, `modeles_*.ts`) ; tests Deno écrits, non exécutés.
4. **`940300`** : contrôle d'entrée par empreinte md5 avant de remplacer les cinq fonctions déjà en base.
5. **Repli de la classe** (`accueil_famille/bloc_seance.dart`) : « Heure de La Mecque : 21:00 », jamais « Riyadh ».
6. **Liste blanche** : `scenarios_af_liste_blanche_volatiles.sql` est aussi modifié par la prière et le calendrier ; à fusionner en gardant l'union des listes quand la prière sera sur `main`.

> Statut : **TEMPS 1 (relevé et plan), en attente de l'accord de l'architecte pédagogique.** Aucune migration ni aucun code n'est écrit. Décision source : `docs/current/pedagogie/HORLOGE-ET-LIEU.md` (H1 à H7). Branche : `claude/horloge-lieu`, posée sur `origin/main` `25f3ed787` (PR 448). Date du relevé : 12/11/2026.

## 0. Niveau de preuve de ce relevé

- **Vérifié par moi** : la production en lecture seule (select uniquement, projet `gggmtelinlpseweouyav`, vérifié par `get_project_url`) ; la définition de `instant_creneau`, `instant_creneau_reference`, `materialiser_seances_groupe`, `private.fuseau_info`, `mon_horloge`, `mon_fuseau`, `transitions_fuseau_a_venir`, `private.notifier_classe_groupes` et `private.notifier_classe_creneaux` ; la liste des déclencheurs et des CHECK de `groupes`, `groupe_creneaux`, `sessions` ; les règles réelles de `.claude/hooks/garde.py` ; le téléchargement et la mesure de GeoNames.
- **Relevé par lecture du dépôt par trois lecteurs, non rejoué** : tout le reste (chemins et lignes ci-dessous). Une ligne marquée « non vérifié » n'a pas été lue jusqu'au bout.
- **Rien n'a été exécuté contre un Postgres local** à ce stade (temps 1).

## 1. D'abord : ce qui est risqué, inconnu, faux ou bloqué

1. **Risque n°1 : installer la conversion préviendrait toutes les familles.** Mettre à jour `groupes.weekday / hour_local / timezone_iana` déclenche `notifications_classe_groupes`, dont la fonction `private.notifier_classe_groupes` envoie `creneau_change` à tout changement du triplet (vérifié en production). Même chose pour `groupe_creneaux` (`private.notifier_classe_creneaux`). Cela contredirait H4 (« personne ne voit un changement »). Il faudra un drapeau de transaction lu par ces deux fonctions, et un test qui prouve qu'aucune notification n'est créée.
2. **Risque n°2 : une conversion qui change un instant crée des doublons ou une erreur d'exclusion.** `tc_materialiser_apres_creation_groupe` rappelle `materialiser_seances_groupe` à chaque UPDATE de ces colonnes, sans jamais annuler les anciennes séances ; `sessions_no_teacher_overlap` (EXCLUDE) refuse les chevauchements. Si l'instant de chaque occurrence est conservé (H4), la séance existante est reconnue par `started_at` et rien n'est dupliqué. Si une seule occurrence est décalée, c'est un doublon ou une erreur. La migration doit donc **s'arrêter** (et ne rien convertir) si, après calcul, une séance à venir d'une classe vivante ne tombe pas exactement sur une occurrence calculée à Riyad.
3. **Le délai joue contre nous au printemps.** Les séances sont générées 4 semaines à l'avance (`matching_horizon_weeks`, vu en production : dernière séance au 10/12/2026). Si l'installation tombait dans les 4 semaines qui précèdent le changement d'heure de Paris (dimanche 28/03/2027), des séances générées à l'ancienne heure d'été ne correspondraient plus aux occurrences de Riyad. Aujourd'hui (novembre) ce n'est pas le cas ; la garde du risque 2 couvre l'oubli.
4. **« Europe/Paris » est une valeur par défaut, pas un choix.** `households.timezone` et `teacher_profiles.timezone_iana` sont `NOT NULL DEFAULT 'Europe/Paris'`. Le client n'envoie jamais de fuseau à `inscrire_titulaire` : chaque foyer naît à Paris. En production, les 5 foyers sont à Paris et l'unique enseignant est « Guinée / Europe/Paris » : **aucune de ces valeurs ne prouve un choix de la personne.** On ne peut donc pas détecter « ville manquante » par un NULL : il faut un marqueur explicite (la ligne de lieu elle-même).
5. **Les heures de prière ne devront pas dépendre d'une valeur inventée.** Les coordonnées n'existent aujourd'hui que dans `prayer_settings` (zone PRIERE-1, que je ne touche pas). Mon lot crée la source propre ; le lot PRIERE-1 devra la lire : **à coordonner par l'architecte** (voir question Q6).
6. **Le garde-fou est plus étroit que ce que dit le rappel de démarrage.** `.claude/hooks/garde.py:22-27` n'interdit que `.github/`, `vercel.json`, `pubspec.yaml` et `.claude/settings*`/`hooks/`. Les dossiers `supabase/`, les adaptateurs `*_supabase.dart` et `parcours_offres` ne sont **pas** refusés (contrairement au message de démarrage). Mon lot n'a besoin d'aucune modification de `pubspec.yaml` : la liste des villes vit côté serveur.
7. **L'application n'a aucune base de fuseaux** (ni `timezone`, ni `intl` déclaré dans `pubspec.yaml`, aucun paquet géo). Toute heure affichée est « instant + décalage rendu par le serveur » (`private.fuseau_info`, `mon_horloge`). Conséquence heureuse : afficher La Mecque (décalage fixe) est simple ; conséquence contraignante : toute logique de changement d'heure se fait côté serveur.
8. **`hour_local` est un entier d'heure pleine (0 à 23).** Une classe à 21 h à La Mecque tombe à une heure pleine pour Paris, mais à une **demi-heure pour l'Inde et l'Iran, un trois-quarts d'heure pour le Népal**. C'est acceptable, mais l'affichage doit montrer les minutes partout (à vérifier : `FuseauVu.heureA` rend-il les minutes ? non vérifié).
9. **Une partie du message annoncé n'existe pas dans l'application.** La phrase « heure de La Mecque » n'apparaît à aucun écran. Les alertes `tc.groupe.dst.j30/j7/j1` existent dans les textes, mais **aucun rappel de séance de classe n'existe en SQL ni en fonction Edge** (relevé de lecture ; les seuls rappels « demain » concernent des entretiens de candidats). L'annonce du changement d'heure est donc une construction neuve complète.
10. **Aucune liste de villes, aucune coordonnée de ville** n'existe dans le dépôt. Aucun contrôle de cohérence pays/fuseau n'existe, ni côté serveur ni côté direction.
11. **Non vérifié** : facturation `fac_*` (hors `fuseau_comptable`) ; corps de `remplacement_candidat` ; si `FuseauVu.heureA` rend les minutes ; les 111 fichiers de test Dart et les 225 scénarios SQL qui contiennent un nom de fuseau (la plupart par le simple défaut Paris) : leur dépendance réelle à Paris n'est connue que pour la courte liste du §6.

## 2. Ce que la production contient (lecture seule, 12/11/2026, comptes et valeurs agrégées)

| Objet | Valeur |
|---|---|
| Classes | 21 au total, **2 vivantes** (sans date de fin), 19 terminées. Toutes les 21 ont `etat = 'active'` : le vrai critère de vie est `ended_at IS NULL`. Les 21 sont à `Europe/Paris`. |
| Créneaux hebdomadaires des classes vivantes | **3** : classe adultes : mercredi 19 h (75 min) et jeudi 18 h (75 min) ; classe enfants : vendredi 19 h (90 min). Tous à Paris. |
| Séances à venir (non supprimées) | 60 lignes, dont **12 au statut prévu** (toutes dans les deux classes vivantes, dernière le 10/12/2026), 3 annulées dans ces classes ; les 45 autres lignes appartiennent à des classes terminées (statut non relevé). Aucune séance sans classe. |
| Foyers | **5**, tous `Europe/Paris` (valeur par défaut, voir §1.4) |
| Enseignants | **1** : pays « Guinée », fuseau `Europe/Paris` (le cas connu, H6) |
| Candidatures | 2, fuseau non renseigné (NULL) |
| Profils | 17 au total (tous rôles) |
| `weekly_availability` | **168 lignes**, un seul fuseau (`Europe/Paris`) : la grille complète 7 jours × 24 heures d'un seul compte, sans trou |
| Offres horaires | 1 (`Europe/Paris`) |
| Règles de récurrence, affectations individuelles | 0 et 0 |
| `app_config` | table clé / valeur JSON (`key, value, updated_by, updated_at`) : on y pose le réglage |
| `prayer_settings` | colonnes `latitude, longitude, timezone_iana, place_label` (zone PRIERE-1, seulement listées) |

### Ce que devient chaque classe vivante à l'heure de La Mecque (instant conservé, calculé en production)

| Classe | Aujourd'hui (Paris, hiver) | À La Mecque | Jour change ? | Première séance dont l'heure de Paris change (si le créneau reste fixe à La Mecque) |
|---|---|---|---|---|
| Adultes, créneau 1 | mercredi 19 h | **mercredi 21 h** | non | mercredi 31/03/2027 : 19 h devient 20 h |
| Adultes, créneau 2 | jeudi 18 h | **jeudi 20 h** | non | jeudi 01/04/2027 : 18 h devient 19 h |
| Enfants | vendredi 19 h | **vendredi 21 h** | non | vendredi 02/04/2027 : 19 h devient 20 h |

Le changement d'heure de Paris est le dimanche 28/03/2027. Annonce à 14 jours : le 14/03/2027 ; la veille : le 27/03/2027. Aucune des trois conversions ne passe minuit (le jour de la semaine ne change pas). Les anciens créneaux annulés du jeudi 19 h (3 séances annulées, jusqu'au 03/12) restent tels quels.

## 3. Relevé de l'existant

### 3.1 Où vit le fuseau d'une classe et d'une séance

- **Une classe porte UN fuseau**, pas un par créneau : `groupes.timezone_iana` (`supabase/migrations/0017:22`, `NOT NULL DEFAULT 'Europe/Paris'`, sans CHECK). `groupes.weekday` et `hour_local` sont l'**ancre** ; `groupe_creneaux` (`0043:452`, `duree_minutes` ajouté par `20261030100000:72`) porte les N créneaux ; le déclencheur `groupe_creneau_ancre` (`20261030100000:558`) recopie l'ancre. **Convertir une classe = convertir son fuseau, son ancre ET chacun de ses créneaux.**
- **Une séance est un instant** : `sessions.started_at / ended_at` (`timestamptz`), aucun fuseau, aucune heure locale. Les séances ne portent donc aucune conversion.
- **Génération** : `materialiser_seances_groupe` (dernière définition `20261025030000:17`) boucle sur `groupe_creneaux` × `matching_horizon_weeks` (4) et calcule l'instant par `instant_creneau(weekday, hour, groupes.timezone_iana, i)` (`20261012133000:6,42`). Elle ne recrée jamais une séance supprimée et rattache seulement les membres à une séance existante du même `started_at`. Déclencheurs : après INSERT/UPDATE de `groupes` (`0055`), après adhésion (`0033:408`), la cloche nocturne `private.materialiser_classes_actives` (`20261025000000:24`, tâche `pg_cron` `seances_cloche` à 02:17 UTC), et `seance_a_rejoindre` (`20261025040000:169`).
- **Déclencheurs sur `groupes`** (vérifiés en production) : `groupes_creneau_ancre`, `groupes_horaire_verifie_enseignant` (revérifie l'affectation de l'enseignant quand le triplet change), `notifications_classe_groupes`, `tc_materialiser_apres_creation_groupe`. Sur `groupe_creneaux` : `groupe_creneaux_a_verrou_classe`, `groupe_creneaux_verifie_enseignant`, `notifications_classe_creneaux`.

### 3.2 Qui lit ou écrit l'heure d'une classe, et ce qui casserait si toutes les classes passaient à `Asia/Riyadh`

| Zone | Chemin | Casse ? | Conséquence et réponse |
|---|---|---|---|
| Défauts « Paris » à la création | `creer_groupe` (`20261021210200:319`), `modifier_groupe` (`0045:74`), `creer_classe_creneaux_admin` (`20261030100000:336`), `publier_groupe_depuis_offre` (`0043:1214`) : `coalesce(p_timezone_iana, 'Europe/Paris')` | **oui** | Le défaut devient le fuseau de l'académie ; si un client envoie un autre fuseau avec une heure murale, **le serveur convertit** (jamais d'erreur, jamais d'heure fausse). |
| Création depuis un regroupement | `creer_classe_depuis_regroupement` (`20261012100000:4`) : la classe prend le fuseau et l'heure de la **première demande** (celle de la famille) | **oui** | Convertir à Riyad au moment de créer la classe. |
| Clés de regroupement | `c11bis_cle_regroupement` (`20261011121958:140`), `cle_horaire_utc` (`0075:39`) : clé `type\|langue\|décalages\|jj:hh\|genre\|niveau` | à vérifier | Les clés viennent déjà de décalages UTC ; elles regroupent des demandes de fuseaux différents. Je ne les modifie pas ; test à écrire (Q3). |
| Offres | `offres_horaires.fuseau_iana` (`0043:319`), index unique incluant le fuseau ; `offres_compatibles` (`0043:682`), `choisir_offre_horaire` (`0050:207`) convertissent vers le fuseau de **vue** de la famille | **oui** | Offres stockées à Riyad ; la vue famille garde sa conversion. `intentions_horaire` et `demandes_horaires_famille` restent la preuve de ce que la famille a vu : non touchées. |
| Unicité et chevauchement | `sessions_no_teacher_overlap` (EXCLUDE sur instants, `20261109800000:236`), `guard_session_overlap` (`0033:1504`), `verifier_affectation_enseignant_base` (`20261022000400:152`, rejoue 52 semaines par ligne dans son fuseau), `verifier_horaire_contre_seances_planifiees`, `creneaux_recurrents_se_chevauchent_durees` | **non** (tout en instants) | Après conversion, l'effet des heures d'été disparaît : c'est le gain de H1. Index uniques : `groupe_creneaux_unique (groupe_id, weekday, hour_local)` ; rien d'unique sur l'horaire (R1 de la décision du 10/10). |
| Disponibilités de l'enseignant | `weekly_availability` (`0005:380`) : fuseau **par ligne**, défaut Paris, unique `(profil, weekday, hour_local)` ; `creneau_couvert_par_disponibilites` (`20261023000000:179`) convertit chaque heure dans le fuseau de la ligne | **non**, mais | Les lignes restent lues dans leur fuseau : tant que l'enseignant ne change pas de ville, rien ne bouge. Quand il change de ville, la question « convertir ou garder » (FUSEAU-CHANGE-PLAGES) se pose : proposition au §5 (convertir, instants conservés, comme H4). |
| Remplacements | `remplacement_auto_passer` (`20261102500000:628`), `remplacant_libre_a_l_heure`, `remplacement_rang` : seuils en minutes relatifs à `started_at` ; seule l'alerte à la direction formate une heure (`20261105700000:189-223`, fuseau de l'administrateur) | **non** | Rien à faire. |
| Notifications, courriels | `private.notifier_classe` (`20261108100000:41`) rend `debut_local` et `prochaine_local` au fuseau de la personne (foyer, sinon enseignant, sinon classe) ; mêmes principes dans `20261103600000`, `20261106500000`, `20261021210100:157`, `0078:126`, `0076:93`, `20261011183000` ; fonction Edge `courriels-envoi` (`_shared/courriel/outils.ts:142`) lit `debut_local` déjà local | **non** pour l'exactitude ; **à compléter** pour H2 | La seconde ligne « à La Mecque » est à ajouter à ces textes. Les messages push n'ont ni date ni heure (`_shared/push/textes.ts`) : inchangés. |
| Paie et mois | `private.bf1_fuseau_comptable()` (`20261017160000:33`) lit `app_config.fuseau_comptable` = `Europe/Paris` ; `remuneration_due_seance`, `releve_paie_*`, `mes_revenus_*` | **non** | Le mois de paie est indépendant du fuseau des classes. **Je n'y touche pas** (non demandé). Deux endroits codés en dur sur Paris restent hors lot : `20261019130000:38`, `20261019120000:185`. |
| Semaine du cahier | `cahier_semaine_couvert` (`20261110620000:67`) et voisines : semaine découpée au fuseau de la classe | **non**, mais | La frontière de semaine d'une classe convertie se déplace de quelques heures (lundi 00 h Riyad au lieu de lundi 00 h Paris). À vérifier par un scénario avant installation. |
| Fonctions de fuseau | `mon_fuseau` (`0005:407`, repli Paris), `mon_horloge` (`20261109900000:122`, sans repli), `private.fuseau_info`, `horloge_interlocuteurs` (`20261109500000:94`), `horloge_classe` (`20261025040000:27`), `horloge_seance` (`0033:427`) | **non** | À étendre : `mon_horloge` rendra aussi l'horloge de l'académie. |
| `transitions_fuseau_a_venir` | `20261012115000:3` : direction seulement ; lit `groupes.timezone_iana` ; rend `(groupe, fuseau, transition, heure_avant, heure_après, jours_restants)` | **oui, elle devient vide** | Une classe à Riyad n'a plus de changement d'heure. Il faut une **nouvelle** fonction par personne (§4, étape 4). |
| Contrôle d'unicité des élèves | `guard_session_overlap` (`0033:1504`) | non | Instants. |

### 3.3 Où vit le fuseau des personnes, `mon_horloge`, HEURES-PROFIL

- **Foyer** : `households.timezone` (`0001:65`, `NOT NULL DEFAULT 'Europe/Paris'`). **Aucune RPC d'écriture pour le tuteur** : le seul `UPDATE households SET timezone` est un effet de bord de `enregistrer_profil_apprentissage` (`0043:585-645`, exige un élève décrit). L'écran `Informations` du tuteur n'écrit rien (`informations_page.dart:36-38`).
- **Enseignant** : `teacher_profiles.timezone_iana` (`0005:400`, défaut Paris) et `teacher_profiles.country` (**texte libre**, nom français, `0001:92`) ; écriture par `maj_profil_enseignant(p_country, p_languages, p_timezone)` (`20261021220000:533`) ou `valider_piece_candidat` (`20261108300000:298`, copie fuseau et langues). **Le pays ISO de la candidature (`candidatures.pays_residence`) n'est jamais recopié vers `country`.**
- **Candidat** : `candidatures.fuseau_iana` (NULL en production), `pays_residence` (ISO), réponses du questionnaire (`fuseauIana`, `paysResidence` obligatoires, `20261022000000:622,629`). Étape existante `fuseau_etape.dart` (appareil, confirmation, recherche).
- **Jeton** : le hook ne porte que `role` et `household_id` (`0038:50-100`) : ni fuseau ni ville.
- **`mon_horloge()`** : rend `{maintenant, moi}` pour l'appelant seul (foyer, sinon enseignant), `moi` = `fuseau_info` (décalage, prochain changement, décalage après, changement suivant), sans repli sur Paris, compte valide exigé. **Le candidat n'a pas de fuseau servi** (compte non valide).
- **HEURES-PROFIL H1 à H5 sont dans `main`** (branches `claude/heures-profil-h1…h5-travail` et `heures-accueil-enseignant-travail` : ancêtres de `origin/main`, 0 commit d'avance, vérifié) : toutes les heures des écrans famille, élève, enseignant, direction, comptable, contrôleur, suivi foyer et semaines du planning sont rendues au fuseau du profil par `chezMoi / heureChezMoi / jourChezMoi / instantChezMoi` (`lib/core/tc_horloge/mon_horloge.dart:57-88`), 63 fichiers hors démonstration. **H2 est donc déjà fait à environ 90 % ; il manque la seconde ligne « La Mecque ».** Flutter seul, aucune migration.
- **Défauts connus de ces lots** (à corriger dans mon lot, étape 3) : `journee_page.dart:1466` et `:1722` (jour pris à l'appareil, heure prise au profil) ; `observations_admin_page.dart:797,800` (non vérifié) ; `suivi_foyer_page.dart:334` (phrase de lecteur d'écran seulement) ; limite HEURE-PROFIL-PARTOUT du registre (un écran qui n'écoute pas `monHorlogeProvider`).
- **Trois listes de fuseaux non alignées** : `parcours_offres/libelles_parcours.dart:116` (8 fuseaux, sans Riyad), `admin_offres/offres_libelles.dart:16-25` (8, avec Riyad), `profil_enseignant/declaration_choix.dart:40` (19 pays, aucun du Golfe). Ces trois listes disparaissent au profit de la liste des villes.

### 3.4 Le parcours d'inscription et où poser la ville

- **Foyer et adulte « pour moi »** : questionnaire public `/commencer` (`questionnaire_inscription.dart`, avant le compte), puis `/inscription/…` : usage, identité, genre, (téléphone pour l'enseignant), récapitulatif (`brouillon_inscription.dart:46-53 etapesPour`). La création se fait au récapitulatif (`recapitulatif_etape.dart:142,414` → `ServiceDossierSupabase.creerProfil`, `service_dossier.dart:119`). **Le fuseau n'est demandé qu'après, au Parcours** (`/tuteur/parcours`, `parcours_offres_page.dart:93-112`).
- **Candidat enseignant** : `inscrire_candidat`, puis salle d'examen ; étape `fuseau_etape.dart` (détection de l'appareil sur le web seulement, `lib/core/candidature/fuseau_appareil.dart`).
- **Enseignant invité** : `inscrire_enseignant_invite`, né à Paris, `country` NULL.
- **Pour les inscrits** : `deciderRedirection` (`lib/core/router/redirection.dart:37`), appelé par `app_router.dart:436-455`. **Point d'insertion** : `case PorteAcces.actif` (`redirection.dart:197`), après le bloc de resignature (`:217-224`) et avant la double authentification (`:230`). Modèle réutilisable : `resignatureContratEnseignantProvider` (`lib/core/dossier/resignature_contrat.dart:52`) → paramètre booléen de `deciderRedirection` → route unique, « jamais bloqué hors ligne » (lecture en échec = faux). **Aucun mécanisme « reportable » n'existe** : tous bloquent ou sont à usage unique ; le report (3 fois) est à construire.
- **Listes existantes** : `lib/core/i18n/pays_iso.dart` (249 pays, `code|fr|ar`, recherche), miroir serveur `private.pays_iso_3166`, drapeaux `assets/flags/` (flag-icons 7.5.0, MIT), `lib/core/i18n/villes_fuseau.dart` (une ville par fuseau pour l'affichage), `app_private.fuseaux_connus` (914 noms IANA, serveur seul). **Aucune liste de villes.**
- **Liste et recherche réutilisables** : `DataCollection`, `ChampRecherche` ; modèles de RPC de recherche : `lister_candidatures` (`20261024000000:188`, pages de 50), `rech_d1_rechercher_classes` (`20261012130003:111`, curseur).

### 3.5 Direction : vérification et signalements

- Vue des enseignants : `lib/features/admin_comptes/comptes_page.dart:1165-1195`, alimentée par `comptes_admin_par_role()` (`20261101100000:37`, `teacher_country`, aucun fuseau).
- **Aucune source d'anomalie de données n'existe** : les alertes de la direction sont les signalements d'enseignants (`signalements_ouverts_direction()`), l'Espace de traitement n'a que dossiers et demandes. À créer (étape 6).
- Confidentialité : ENS-PAYS-1 montre le pays de l'enseignant (jamais une ville ni une adresse : `20261109400000:12-13`). **Les coordonnées et la ville d'un enseignant ne doivent jamais entrer dans ces vues.**

### 3.6 L'affichage à deux heures existe déjà : on le réutilise (fait signalé par l'architecte, revérifié)

Chaîne complète, de la base à l'écran (vérifiée par lecture, pas exécutée) :
- **Serveur** : `public.horloge_seance(p_session_id)` (`0033_tc_vues_rpc.sql:427`, seule définition) rend `tz_utilisateur`, `heure_utilisateur`, `tz_groupe`, `heure_groupe` (jour et date aussi). `tz_utilisateur` vient de `mon_fuseau()` **avec repli sur Paris** ; `tz_groupe` vient de `groupes.timezone_iana`. Mêmes colonnes dans `public.horloge_classe` (`20261025040000:27`, `heure_groupe` ligne 144) et `prochaine_seance_groupe` (`20261016102000:26`).
- **Adaptateur** : `lib/core/tc_horloge/horloge_supabase.dart:56` (`heure_utilisateur`) et `:65` (`heure_groupe`) → `SessionClockVM` (`horlogeUtilisateur`, `horlogeContrepartie`).
- **Affichage** : `lib/core/tc_horloge/heure_double.dart` (`HeureDouble`, `lignesInterlocuteurs`), texte `tc.groupe.horloges.heureGroupe` = « Heure de la classe » et `chezVous` (`fr.i18n.json:9487-9492`). Employé par `tc_espace_groupe/carte_session.dart`, `tc_espace_groupe/bloc_cartes_classe.dart`, `tc_mes_groupes/carte_groupe.dart`, `accueil_famille/bloc_seance.dart`, `classe_tuteur/planning_classe_page.dart`, `classe_tuteur/carte_seance_classe.dart`.
- **Ce qui change avec le lot** : après l'étape 1, `tz_groupe` vaut `Asia/Riyadh` sans toucher à ces fonctions, donc `heure_groupe` est déjà l'heure de La Mecque ; seul le sens du libellé change (« Heure de la classe » devient « Heure de La Mecque », en second). **Aucun second composant n'est créé** : on améliore `HeureDouble`.
- **Deux faits à traiter dans l'étape 3** : (1) la salle, le chrono et la pause ne lisent ni `timezone_iana` ni `hour_local`, seulement des instants rendus à l'heure de la personne (`heureChezMoi`) : rien à y changer, et ces zones ne sont pas touchées ; (2) `horloge_seance` donne « mon heure » par `mon_fuseau()` (repli Paris) alors que `mon_horloge()` n'a pas de repli : deux sources pour « mon heure ». Le lot les aligne sur le lieu de la personne (sans lieu, la ligne « chez vous » est omise et l'on dit « heure de cet appareil », comme `mon_horloge` le fait déjà), sans modifier `mon_fuseau()` qui sert d'autres appelants.

## 4. La source des villes : proposition précise

**Fichier : GeoNames `cities15000`.** Mesuré aujourd'hui (téléchargement réussi depuis cet environnement, `download.geonames.org`) :

| Mesure | Valeur |
|---|---|
| Villes de plus de 15 000 habitants | **34 215** |
| Pays couverts | 244 |
| Fuseaux IANA distincts | 356 (aucune ville sans fuseau) |
| Poids brut du texte compact (nom, pays, région, latitude, longitude, fuseau, population) | **2,2 Mo** ; **0,7 Mo** compressé |
| Villes de `Asia/Riyadh` | 98 (La Mecque, Médine, Riyad y sont) |
| Noms homonymes (même nom, plusieurs villes) | 1 312 : la région doit être affichée à côté du nom |
| Villes avec un nom arabe détectable (par la graphie) | 12 378 ; dans les pays arabes : 1 036 sur 1 617 |
| Licence | **Creative Commons Attribution 4.0** (mention « Données : GeoNames, CC BY 4.0 » obligatoire dans l'application ; l'écran des mentions et crédits reste à situer, non relevé) |

**Où la mettre : en table serveur** `public.villes_ref`, pas en ressource de l'application. Raisons : (1) le client ne pourrait de toute façon pas valider des coordonnées : le serveur copie lui-même nom, pays, fuseau et coordonnées depuis la ligne choisie, un client ne peut pas écrire des coordonnées inventées ; (2) aucune modification de `pubspec.yaml` (interdite) ni aucune ressource de 2 Mo dans le paquet web ; (3) aucun service externe appelé avec la position de l'utilisateur (seule une chaîne de recherche tapée est envoyée à notre propre base) ; (4) les trois listes de fuseaux actuelles s'effacent.

- **Recherche** : RPC `rechercher_villes(p_texte, p_pays, p_limite)` (préfixe sur le nom normalisé, index btree), et **propositions** : `villes_proposees(p_decalage_minutes)` qui rend d'abord les plus grandes villes dont le fuseau a, **aujourd'hui, ce décalage** (le client ne connaît que le décalage de l'appareil, pas son nom IANA, hors web). Le fuseau de l'appareil sert à proposer, jamais à enregistrer.
- **Noms arabes** : pour l'interface arabe, le nom arabe quand GeoNames en donne un (sinon le nom latin) ; recherche par nom latin toujours possible.
- **Chargement** : la table se charge par migration, en plusieurs fichiers (environ 6 morceaux de 6 000 villes, 350 à 450 Ko chacun, pour tenir dans la page de collage du directeur). **Inconnu : la tolérance de l'éditeur SQL de Supabase pour un collage de 400 Ko, non testée.** Les cas de refus se détectent par un contrôle d'effectif (34 215 lignes) à la fin du dernier morceau.
- **Mise à jour** : la liste est figée à la date de téléchargement (12/11/2026), notée dans la table des mentions.

## 5. Risques classés

| N° | Risque | Gravité | Réponse prévue |
|---|---|---|---|
| R1 | La conversion notifie toutes les familles (déclencheurs vérifiés) | **critique** (contredit H4) | drapeau de transaction lu par `notifier_classe_groupes` et `notifier_classe_creneaux`, scénario de preuve : 0 notification créée |
| R2 | Un instant décalé crée un doublon ou une erreur d'exclusion | **critique** (cours manqué) | assertion avant et après, la migration s'arrête sans rien convertir au moindre écart ; test sur base rejouée avec les 3 créneaux réels |
| R3 | Installation tardive, à moins de 4 semaines du 28/03/2027 | élevé | même assertion ; consigne d'installation écrite |
| R4 | Un ancien client (onglet web ouvert) envoie « Paris + heure de Paris » | élevé | les RPC de création **convertissent** toute heure murale reçue (jamais de refus, jamais d'heure fausse) ; test avec fuseau `Europe/Paris`, `America/Toronto`, `Asia/Kolkata` |
| R5 | « Paris » pris pour un choix | élevé | marqueur explicite : une ligne de lieu ; sans elle, la personne est « sans ville » |
| R6 | Chargement de 34 215 lignes par collage | moyen | morceaux de 400 Ko, contrôle d'effectif ; à tester à l'installation |
| R7 | Demi-heures (Inde, Iran, Népal) | moyen | afficher les minutes, test de rendu :30 |
| R8 | Annonces envoyées deux fois ou jamais | moyen | table d'annonces avec clé unique `(personne, classe, date de changement, palier)` ; tâche quotidienne idempotente |
| R9 | Fuite de la ville ou des coordonnées d'un enseignant ou d'un foyer | élevé | RLS sur la table, aucune vue publique, aucune colonne de lieu ajoutée à `comptes_admin_par_role` sans décision ; test qui tente la lecture par un autre foyer, un élève, un autre enseignant |
| R10 | Frontière de semaine du cahier déplacée | faible | scénario avant installation |
| R11 | Zone interdite de PRIERE-1 | moyen | je ne touche ni `lib/core/priere` ni `prayer_settings` ; je lui laisse `public.mon_lieu()` (voir Q6) |

## 6. Plan de construction (temps 2, après accord)

Numéros de migration : la migration réservée est `20261123940000_horloge_lieu.sql`. Les données des villes et les annonces demandent d'autres fichiers : voir la question Q1.

**Étape 1. Réglages et conversion des classes sans changement visible** (`20261123940000`)
- `app_config` : `fuseau_academie` = `Asia/Riyadh`, `lieu_reports_max` = 3. Fonction `private.fuseau_academie()` qui les lit (jamais de valeur en dur ailleurs).
- Fonction pure `private.vers_academie(weekday, hour, fuseau, instant_de_reference)` : l'heure murale d'un fuseau, à l'instant d'une occurrence, rendue en jour et heure de l'académie.
- Drapeau de transaction `app.horloge_conversion` lu par les deux fonctions de notification (remplacement complet de chaque fonction, sans suppression).
- Conversion : pour chaque classe vivante, l'ancre et chaque créneau sont convertis à partir de l'**instant de la prochaine occurrence** (jamais à partir d'un décalage supposé) ; le fuseau de la classe passe à l'académie ; le défaut de `groupes.timezone_iana` change ; un déclencheur force le fuseau de toute classe nouvelle ou modifiée à l'académie.
- Les RPC `creer_groupe`, `modifier_groupe`, `creer_classe_creneaux_admin`, `publier_groupe_depuis_offre`, `creer_classe_depuis_regroupement`, `creer_offre_horaire` convertissent toute heure murale reçue (R4). Les offres existantes (1) sont converties.
- Fichiers : `supabase/migrations/20261123940000_horloge_lieu.sql`, `supabase/tests/scenarios_horloge_lieu.sql`, ajout du scénario à `ci.yml` **non permis** (dossier `.github/`) : je le signale à l'architecte, qui l'y ajoute.
- **Preuve qu'elle ne casse rien** : avant/après sur une base rejouée avec les 3 créneaux réels : même ensemble d'instants de séances à venir (comparaison exacte), 0 nouvelle séance, 0 séance supprimée ou déplacée, 0 notification créée, `materialiser_seances_groupe` rejouée renvoie 0 ; la même conversion appliquée à une classe d'un fuseau à changement d'heure (`Europe/Paris`) et à un fuseau à demi-heure (`Asia/Kolkata`) ; échec volontaire (une séance décalée d'une heure) : la migration s'arrête et rien n'est converti.

**Étape 2. Création de créneau : l'heure se saisit à Riyad, avec l'aperçu chez l'enseignant**
- `lib/features/admin_groupes/groupes_page.dart:1352-1392`, `feuille_creneau.dart:176`, `lib/core/capacites/port_creation_classe.dart:14` (`fuseauServeurParDefaut` supprimé), `creation_classe_supabase.dart:54-60`, `service_groupes.dart:72,279,309`, `admin_offres/nouvelle_offre_page.dart` et `offres_libelles.dart:16-28` (liste réduite à l'académie), les autres replis `'Europe/Paris'` du relevé du code Dart (`classes_admin_supabase.dart:137`, `pilotage_supabase.dart:103`, `modeles_enseignant.dart:286`, `service_planning.dart:270`, `carte_horaire.dart:101`, `parcours_offres_page.dart:115`).
- Fonction `public.heures_de_l_annee(p_weekday, p_hour_academie, p_fuseau)` : l'heure locale d'hiver et l'heure locale d'été (« 19 h en hiver, 20 h en été chez vous »), aussi pour l'inscription dans une classe (H3).
- **Preuve** : tests de widgets (320 et 1440, texte ×1 et ×2, clair et sombre) ; test de non-régression `classe_form_1_test.dart`, `service_groupes_supabase_test.dart` mis à jour ; passage par le vrai routeur.

**Étape 3. Affichage à deux heures** (Flutter, très peu de SQL)
- `mon_horloge` rend aussi l'horloge de l'académie (`academie`). Fichiers et chaîne du §3.6 : `horloge_seance` / `horloge_classe` (copie complète, sans suppression), `horloge_supabase.dart`, `heure_double.dart`, `fr.i18n.json` `tc.groupe.horloges.*`. Un seul point du core formate « 19 h · 21 h à La Mecque » ; `HeureDouble` (`lib/core/tc_horloge/heure_double.dart`, 5 écrans) et la ligne « Heure de la classe » deviennent « heure de La Mecque » ; les 63 fichiers qui appellent `chezMoi` n'ont rien à changer sauf les endroits qui composent eux-mêmes une phrase d'heure.
- Correction des défauts `journee_page.dart:1466,1722`, `observations_admin_page.dart:797,800` ; limite HEURE-PROFIL-PARTOUT résolue par un seul fournisseur qui écoute `monHorlogeProvider`.
- Notifications et courriels : ajout de `debut_academie` à `private.notifier_classe` et aux gabarits de courriel (`modeles_fr.ts`, etc.).
- Textes fr et ar par le vocabulaire (« heure de La Mecque » ajouté à la compétence `mots-rewayah` dans le même commit).
- **Preuve** : tests de rendu sur les 5 états des écrans touchés ; test « profil à Conakry, appareil à Paris, classe à Riyad » (modèle : `heures_accueil_enseignant_test.dart`) ; test des minutes (:30) ; vérificateurs `verifier_jetons`, `verifier_revue`.

**Étape 4. Annonces du changement d'heure**
- `public.mes_changements_heure_a_venir(p_jours)` (par personne) et version direction ; table `annonces_changement_heure` (clé unique ; RLS) ; tâche `pg_cron` quotidienne (même modèle que `seances_cloche`) qui crée les notifications à 14 jours et à la veille, avec « À partir du dimanche 28 mars, votre cours passe de 19 h à 20 h » ; pour un mineur, le tuteur ; pour l'enseignant, son fuseau ; cas où le jour change.
- Fichiers : même migration que l'étape 1 ou migration suivante (Q1) ; `lib/core/notifications` pour le rendu ; gabarits de courriel.
- **Preuve** : horloge simulée (le modèle `p_maintenant` de `fuseau_info`) : annonce à J-14 et à J-1 une seule fois (relance de la tâche : 0 doublon), bonnes heures avant et après pour Paris, Toronto (dates différentes), Kolkata (aucune annonce), Riyad (aucune annonce) ; mineur : seule la famille est prévenue.

**Étape 5. La ville : obligatoire à l'inscription et pour les inscrits**
- Tables `villes_ref` (données GeoNames) et `lieux` (une ligne par foyer ou par enseignant : ville, pays, fuseau, latitude, longitude, état saisi/vérifié, nombre de reports) ; RLS : la personne et son foyer lisent, la direction lit et vérifie, personne d'autre ; aucune écriture directe.
- RPC : `rechercher_villes`, `villes_proposees`, `enregistrer_ma_ville(p_ville_id)` (copie les valeurs de la ligne choisie ; met à jour `households.timezone` ou `teacher_profiles.timezone_iana` et `country` dans la même transaction), `mon_lieu()`, `mon_lieu_a_fournir()`, `reporter_ma_ville()` (au plus `lieu_reports_max`).
- **Inscription** : nouvelle étape « ville » dans `etapesPour` (`brouillon_inscription.dart`), valeur gardée dans le brouillon, appel de `enregistrer_ma_ville` juste après `creerProfil` : **aucune signature de fonction existante n'est modifiée** (il n'y a aucun DROP possible). Candidat : la ville remplace le fuseau dans l'étape `fuseau_etape.dart`, et `valider_piece_candidat` crée le lieu de l'enseignant.
- **Inscrits** : paramètre de plus à `deciderRedirection` (`redirection.dart:197`, après le bloc de resignature), route `/ville`, bouton « Plus tard » rendu seulement s'il reste un report ; lecture en échec = pas de blocage.
- **Direction** : colonne et geste « Vérifier la ville » dans la vue des enseignants (`comptes_page.dart`), jamais visible des autres.
- Enfant : hérite de la ville du foyer (aucune saisie, aucune ligne).
- **Preuve** : RLS (tentatives de lecture par autre foyer, élève, autre enseignant, anonyme : 0 ligne) ; `has_function_privilege` de chaque RPC (anon refusé) ; ville forgée refusée ; sans compte valide : refus ; cinq états de l'étape ; parcours complet par le vrai routeur pour foyer, adulte « pour moi », enseignant invité, candidat, inscrit existant (report, puis blocage au 4e).

**Étape 6. Signalements à la direction (H6)**
- RPC `incoherences_lieu_direction()` : pays, fuseau et ville qui ne concordent pas (par une table `pays_fuseaux` dérivée de `villes_ref`), ville absente, fuseau du profil différent de celui de la ville ; ligne ajoutée à l'Espace de traitement (`elements_a_traiter.dart`) ; **aucune correction automatique**.
- **Preuve** : le cas « Guinée / Europe/Paris » de la production est signalé, par un scénario sur une base rejouée (pas par une écriture en production) ; aucune ligne modifiée par la fonction.

**Étape 7. Disponibilités de l'enseignant** (si Q4 accordée)
- Au changement de ville de l'enseignant, ses lignes `weekly_availability` sont converties en conservant les instants ; un déclencheur fixe le fuseau d'une nouvelle ligne à celui de l'enseignant (FUSEAU-DEFAUT-SERVEUR).

**Étape 8. Tests et captures**
- `supabase/tests/scenarios_horloge_lieu.sql` ; scénarios existants à adapter (liste du lecteur SQL) : `fuseaux_interlocuteurs`, `fuseaux_decalage_apres`, `f86_timezone_transition`, `horloge_classe_concierge_tuteur`, `raccordement_1016`, `classes_duree_affectation`, `classe_plusieurs_creneaux`, `c11bis_*`, `notifications_classes`, `cahier_hebdomadaire` ; côté Dart : `horloge_fictive.dart`, `heures_profil_h1…h4`, `classe_form_1_test.dart:696,716`, `service_groupes_supabase_test.dart:208,266`, `parcours_offres_test.dart:174-200`, `fuseau_unique_test.dart`, `villes_fuseau_test.dart`, `admin_offres_page_test.dart`.
- Base : Postgres local nu (stub, toutes les migrations, scénarios). Six vérifications exigées (`slang`, `build_runner`, `analyze --fatal-infos`, `flutter test`, `verifier_jetons`, `verifier_branchement`) ; captures dans `docs/current/captures/E2E/horloge-lieu/`.

## 7. Questions pour l'architecte (réponses utiles avant le temps 2)

- **Q1. Numéros de migration.** Le lot demande plusieurs fichiers : schéma et conversion (`20261123940000`), données des villes (`…940100` à `…940105`), annonces (`…940200`). Les numéros `20261123940000` à `20261123949999` sont-ils tous à moi ?
- **Q2. Ordre d'installation.** Les migrations d'abord, puis le client, avec les RPC qui convertissent toute heure reçue (R4) : d'accord ?
- **Q3. Regroupement.** Je laisse les demandes et la clé de regroupement dans le fuseau de **vue** de la famille (preuve de ce qu'elle a vu, comme aujourd'hui) et je convertis à Riyad seulement à la création de la classe : d'accord ?
- **Q4. FUSEAU-CHANGE-PLAGES.** Quand un enseignant change de ville, ses disponibilités sont converties en gardant les instants (comme H4) : d'accord ?
- **Q5. Candidat.** La ville se demande dans le questionnaire de candidature (en remplacement de l'étape fuseau) et devient le lieu de l'enseignant à la validation : d'accord ?
- **Q6. PRIERE-1.** Je livre `mon_lieu()` (ville, pays, fuseau, latitude, longitude de la personne seule) ; le lot PRIERE-1 le lira au lieu de ressaisir. Pouvez-vous le lui dire ? Je ne touche pas `prayer_settings`.
- **Q7. Ajout à la CI.** Je ne peux pas modifier `.github/workflows/ci.yml` : vous y ajoutez `scenarios_horloge_lieu.sql` ?
- **Q8. Mention GeoNames.** Où affichez-vous les crédits et licences de l'application ? Je n'ai pas trouvé d'écran (non relevé).

## 8. Réponses de l'architecte (12/11/2026) et état de la construction

**Accord pour le temps 2, en deux parties livrables séparément.** Partie A « horloge » (conversion, création de créneau, deux heures, annonces, disponibilités), puis partie B « lieu » (villes, étape à l'inscription et pour les inscrits, signalements). Les réponses suivantes priment sur le plan du §6.

| Question | Réponse |
|---|---|
| Q1 numéros | `20261123940000` à `20261123949999` sont à ce lot |
| Q2 ordre d'installation | migrations avant le client ; le client déjà en production continue de marcher : toute fonction qui reçoit une heure murale garde sa signature et son sens, et convertit à l'intérieur ; test « ancien client » obligatoire |
| Q3 regroupement | demandes dans le fuseau de la famille ; normaliser la clé vers le fuseau de référence si c'est petit, sinon décrire le défaut dans le rapport |
| Q4 disponibilités | elles gardent leurs instants réels au changement de ville ; l'écran demande de les relire |
| Q5 candidat | la ville remplace l'étape du fuseau et devient le lieu de l'enseignant, vérifiée par la direction |
| Q6 PRIERE-1 | `mon_lieu()` pour la personne, et une lecture réservée à la direction et aux fonctions serveur ; ni `prayer_settings` ni `lib/core/priere` |
| Q7 CI | personne parmi les agents ne modifie `.github/` : le scénario est rejoué en local, son résultat exact est dans le rapport, le directeur seul l'ajoute à la CI |
| Q8 crédit GeoNames | une ligne discrète sous le champ de recherche de la ville (« Liste des villes : GeoNames, CC BY 4.0 », fr et ar) et un fichier de mentions à côté des données |

Conditions de l'architecte : drapeau de conversion posé seulement par la migration et local à la transaction, avec un test qui prouve 0 notification, 0 push, 0 courriel et qu'un vrai changement notifie encore ; photographie des séances avant et après dans la même transaction ; refus de s'installer à moins de 28 jours d'un changement d'heure ; minutes justes (Delhi 23 h 30, Katmandou 23 h 45) ; annonces jamais vers un mineur, 14 jours avant et la veille, courriel compris, sans prénom d'enfant ; poids exact de chaque morceau de villes et une variante de secours en un seul fichier (plus de 50 000 habitants) ; rejouer tous les scénarios après la partie A.

### Partie A : ce qui a été construit (écarts au plan en gras)

- `supabase/migrations/20261123940000_horloge_lieu.sql` : réglage `fuseau_academie`, journal `private.conversions_horloge` (**le « drapeau » est ce journal, pas un réglage de session** : une ligne écrite par la seule fonction de conversion, lue par les cinq déclencheurs, qui ne se taisent que si leurs anciennes et nouvelles valeurs sont exactement celles du journal pour la même transaction et la même classe ; aucun utilisateur ne peut l'écrire), conversion des classes existantes, tâche de nuit pour l'ancien client (**à la place d'une conversion à l'enregistrement de la transaction : aucune surprise au commit, aucune signature publique modifiée, aucun md5 F86 à mettre à jour**), `mon_horloge()` qui rend aussi `academie`.
- `supabase/migrations/20261123940100_horloge_annonces.sql` : calcul de l'heure locale avant et après un changement d'heure, aperçu pour l'écran, annonce quotidienne (**l'événement `creneau_change` existant est réutilisé, avec `motif = changement_heure` : la contrainte des événements n'est pas modifiée, donc aucun DROP**).
- Client : « Heure de La Mecque » en second dans le composant à deux heures existant, annonce dans l'application (fr, ar) et dans le courriel (fr, en, es, pt, ar), ligne d'aperçu à la création d'une classe, deux défauts de jour de la Journée corrigés, `GroupeAdmin` lit le fuseau réel de la classe.

Écarts et limites : voir le rapport de la partie A.

### Défaut décrit et non corrigé : la clé de regroupement ne regroupe jamais deux fuseaux (Q3, décision de l'architecte du 12/11 : à corriger dans le premier lot des classes vitrines)

- **Où** : `public.cle_horaire_utc(smallint[], smallint[], text)` (`0075_local_schedule_and_future_session.sql`, patchée par ancre dans `20261120200500_fuseaux_connus.sql` avec empreinte), appelée par `public.c11bis_cle_regroupement` (`20261011121958:140`), elle-même appelée par les fonctions de partition des regroupements et par `c11bis_id_regroupement`.
- **Ce qu'elle fait** : la clé vaut `décalageHiver:décalageÉté|jj:hh,...`. Les décalages sont ceux du fuseau de la demande (au 15 janvier et au 15 juillet 2026) ; **le jour et l'heure sont les valeurs MURALES de la demande, jamais ramenées à un instant.** Malgré son nom, elle ne normalise pas vers UTC.
- **Conséquence** : Paris 19 h (décalages `-3600:-7200`) et Montréal 13 h (`18000:14400`) demandent le même instant toute l'année, mais donnent deux clés ; deux familles de fuseaux différents ne se regroupent donc jamais, même pour le même instant. Paris 19 h et Montréal 19 h donnent bien deux clés (instants différents), ce qui est juste.
- **Ce qui reste correct** : aucune fusion à tort. Deux clés égales supposent les mêmes décalages et les mêmes heures murales, donc les mêmes instants.
- **Étendue** : les familles d'un même fuseau se regroupent normalement ; seul le regroupement entre fuseaux est perdu. Production au 12/11/2026 : 0 demande d'horaire (`demandes_horaires_famille`), donc aucun regroupement existant touché.
- **Correction envisagée (non faite)** : calculer pour chaque couple (jour, heure) murale de la demande l'instant d'une semaine de référence en janvier et en juillet, le ramener au fuseau de l'académie, et construire la clé avec ces deux jeux de (jour, heure) de La Mecque. Test attendu : Paris 19 h et Montréal 13 h en hiver donnent la même clé, Paris 19 h et Montréal 19 h deux clés différentes. Elle change la forme de la clé (donc les identifiants de regroupement calculés par `c11bis_id_regroupement`) : à faire avec les classes vitrines, avant que des demandes existent.

## 9. Correctifs de la partie A (revue indépendante de la tête `bd47382a1`, 13/11/2026) et suite de la partie B

### Consigne pour le directeur (ordre d'installation INVERSÉ par rapport à la réponse Q2)

**« Mettre l'application à jour, puis installer la migration ; entre les deux, ne modifier aucun horaire. »**

Le nouveau client est mis en ligne D'ABORD, la migration (page de collage) ensuite. Le nouveau client marche dans les deux états de la base : tant que les fonctions du lieu et de l'horloge ne sont pas installées il retombe sur l'ancien chemin (une heure saisie dans le fuseau de la classe, dite avec sa ville, sans seconde heure), et après la migration il lit chaque créneau à l'heure de la personne puis à l'heure de La Mecque. Un ancien client qui reste ouvert après la migration est refusé quand il veut DÉPLACER une heure (erreur `RechargerPourModifierUnHoraire`, aucune modification, aucune notification) ; renommer une classe, changer son seuil ou la durée d'un créneau sans le déplacer continue de marcher.

### B1 : où l'heure d'un créneau ou d'un cours est montrée, et ce qui a été fait

Règle : l'heure de la personne d'abord, calculée depuis l'instant réel du prochain cours (`lib/core/tc_horloge/creneau_chez_moi.dart`, fuseau du créneau lu par `public.fuseau_vue`), puis « Heure de La Mecque » en second ; jamais « Riyad », jamais « heure de la classe ».

Corrigés (tous passent par `libelleCreneauLu`, `partiesDuCreneau` ou `quandConflit`) : fiche de la classe de l'enseignant (`fiche_groupe_page.dart`), liste des classes de la direction et fiche d'une classe (`groupes_page.dart`), créneaux de la classe (`feuille_reglages_classe.dart`), saisie d'un créneau (`feuille_creneau.dart` : plus de « L'heure est celle du fuseau horaire de la classe », la légende dit « Heure de Paris » ou « Heure de La Mecque » et l'équivalent à La Mecque est montré avant d'envoyer), conflits d'horaire nommés par le serveur (`refus_creation_classe_libelles.dart`), comparaison d'un créneau saisi avec les classes existantes (`groupes_page.dart`, plus de faux conflit : les deux heures sont comparées dans le même fuseau), pilotage (`pilotage_libelles.dart`, `pilotage_page.dart`), filtres Fuseau de la liste des classes, du pilotage et des regroupements, et libellés de fuseau d'un regroupement (« La Mecque » et non « Riyad »).

Déjà conformes (instants, via `chezMoi` et `HeureDouble` de la partie A) : Journée de l'enseignant, accueil famille, salle, suivi, notifications, mes classes de l'enseignant, cartes de classe.

Laissés, avec la raison :
- Filtres **Jour** et **Heure** de la liste des classes et du pilotage : ils filtrent sur la valeur enregistrée ; le filtre Fuseau voisin la qualifie (« La Mecque »). Les lire à l'heure de la personne changerait la signification du filtre (un jour qui change à minuit) : à décider.
- Offres horaires de la direction (`admin_offres`, `libelleHeureMinute` + ville) : une offre est un modèle défini dans son propre fuseau, toujours dit avec sa ville ; ce n'est pas un créneau de classe.
- Disponibilités de l'enseignant et candidature : heures dans le fuseau de la personne elle-même.
- Données de démonstration et playground : fictives.

### B2 : l'ancien client ne déplace plus un cours de deux heures

`supabase/migrations/20261123940300_horloge_correctifs_a.sql` : `ajouter_creneau_classe_admin` (3 et 4 arguments), `modifier_creneau_classe_admin` et `modifier_groupe` refusent, pour une classe à l'heure de La Mecque, tout appel qui déplacerait une heure sans fuseau explicite ; trois fonctions nouvelles (`ajouter_creneau_classe_fuseau`, `modifier_creneau_classe_fuseau`, `modifier_groupe_fuseau`) reçoivent le fuseau de l'heure saisie et convertissent (heure sans équivalent entier refusée). Le nouveau client envoie toujours le fuseau de l'heure saisie (celui de sa ville quand il l'a choisie, sinon celui de la classe, donc l'heure de La Mecque pour une direction sans ville) et montre l'équivalent à La Mecque avant d'envoyer.

**Écart à la décision (a)** : un appel qui ne déplace aucune heure (renommer, changer le seuil, changer la durée d'un créneau sans le déplacer) n'est pas refusé : aucune heure n'y est interprétée, et le refuser aurait empêché tout ancien client de renommer une classe.

**L'ancien client affiche, pour ce refus, sa phrase générale de refus** (il ne connaît pas le message `RechargerPourModifierUnHoraire`) ; seul le nouveau client dit « Rechargez l'application pour modifier un horaire ».

### I1 à I8

- I1 : `push_depuis_notification` donne à l'annonce sa propre « portée » de push (`heure_ete`, `heure_hiver`, `heure_classe`) ; textes dans `_shared/push/textes.ts`. Aucun nouvel événement ni contrainte (marqueur dans les paramètres).
- I2 : le jour d'arrivée est dit quand il change (application, courriel, cinq langues).
- I3 : « Heure de La Mecque » partout ; la phrase « le cours reste à la même heure à La Mecque » n'est dite que si la classe y est (`academie` dans les paramètres).
- I4 : tâche horaire (`7 * * * *`), chaque personne est servie à 10 h locale, jamais entre 21 h et 8 h.
- I5 : `changement_heure_cours` lit le premier des deux changements d'heure (personne, classe) ; une classe refusée par la tâche de nuit prévient la direction une fois (événement `creneau_change`, marqueur `conversion_refusee`).
- I6 : une classe en attente d'enseignant annonce aussi.
- I7 : `public.changements_heure_a_venir_direction` et un bloc dans Comptes (familles, enseignants) ; `transitions_fuseau_a_venir` (par classe) n'a aucun écran dans l'application : elle n'est lue que par un scénario SQL.
- I8 : `test/features/horloge_creneaux/creneaux_routeur_reel_test.dart` part du vrai routeur (`routeurProvider`).

### Zone `lib/features/parcours_offres` : modifiée sur décision de l'architecte (13/11/2026)

Trois preuves données par l'architecte : (1) `docs/orchestration/PASSATION-2026-10-17.md` ligne 15 : « garde-fou levé par le directeur pour `site-public/` et `parcours_offres` » ; (2) `.claude/hooks/garde.py` ne contient plus `parcours_offres` ; (3) la zone a été modifiée depuis par des lots déjà fusionnés (FOYER-PARCOURS, quatre commits du 07/11). L'entrée restée dans `.claude/hooks/zones_apres.sh` est un reste ; je n'ai touché à aucun fichier de `.claude/hooks`.

### Partie B : écart signalé

L'étape « ville » n'est pas une étape de plus dans le parcours d'inscription : à la première entrée d'un tuteur ou d'un enseignant sans ville, la porte du routeur (`villeAFournir`) le mène à `/ville`, avec « Plus tard » tant qu'il reste un report (3 par défaut). Cela évite de toucher le parcours d'inscription ; la personne a le même choix, juste après la création du profil.
