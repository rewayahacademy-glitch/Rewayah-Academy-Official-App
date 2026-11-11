# Proposition : progression par sourate, côté serveur (11/11/2026)

**Statut : TRANCHÉ le 11/11/2026, option A** (« l'enseignant coche la sourate au cahier », décision du directeur relayée par le garde-cap et le pilote). Ce document garde la proposition d'origine ; la mise en œuvre est décrite plus bas (« Ce qui est codé »).

**Correction (11/11/2026)** : la première version disait « 17 sourates à l'étape 4 ». C'est faux. L'étape 4 compte **13 sourates**, d'Al-Masad (111) à Az-Zalzalah (99). Les **17 sourates des bases** comprennent en plus Al-Fatiha, An-Nâs (114), Al-Falaq (113) et Al-Ikhlâs (112), apprises plus tôt en matière secondaire (`programme-rewayah`, « Les 17 sourates des bases (105 versets) »).

Demande : le pilote, le 11/11/2026. Lot « Lumières des accueils », volet « des accueils plus vivants » (`docs/current/A-FAIRE-LUMIERE-ACCUEILS.md`, lignes 43 et 50) : un anneau de progression par sourate autour de la photo de l'élève, et un tour doré à la fin d'une sourate. Le suivi pédagogique est la priorité n° 1 (`docs/current/VISION-ECOLE-2026-11-05.md`).

## D'abord : ce qui bloque

- **Aucune donnée serveur ne compte les sourates validées d'un élève.** L'anneau ne peut donc rien montrer de vrai aujourd'hui.
- **« Sourate validée » n'est défini nulle part.** Ni la compétence `programme-rewayah` (règles, réponses figées, journal), ni `REGISTRE-RECONCILIATION-2026-10-14.md`, ni `VISION-ECOLE` ne le définissent. Le programme valide par **étape** : « L'enseignant propose, l'administration confirme » (`programme-rewayah`, réponse figée « Comment l'élève passe-t-il une étape ? »). La définition revient au directeur (question ci-dessous). Le lot n'est pas constructible avant sa réponse.
- **L'élève adulte n'a pas d'équivalent de `progression_famille`.** La fonction refuse tout appel qui n'est pas celui d'un tuteur (`public.app_role() = 'guardian'`, migration `20261018190000_ped_cahier_partage.sql`, lignes 259 et 266), même pour le titulaire de son propre profil.
- **Commentaire faux à corriger dans un lot de code :** `lib/core/capacites/port_progression_famille.dart` dit « aucun adaptateur prévu avant DB-CRS-11 ». Or `lib/main.dart:774` branche `ProgressionFamilleSupabase` en production.

## Ce qui existe, vérifié dans les migrations

| Table, fonction | Colonnes utiles | Ce qu'elle dit, ce qu'elle ne dit pas |
| :--- | :--- | :--- |
| `public.sourate` (`0007_coran_structure_position_presence.sql:44`) | `numero` (1 à 114), `nom_arabe`, `nom_translittere`, `nombre_versets` | Le référentiel des sourates. Rien sur un élève. |
| `public.programme_niveaux` (`0020_programme_pedagogique.sql:51`) | `id`, `version_id`, `code_technique`, `nom_humain`, `cycle`, `ordre` | Les étapes du programme publié. **Aucun lien vers des numéros de sourates** : l'étape 4 « Les sourates courtes, d'Al-Masad à Az-Zalzalah » n'existe qu'en texte (`20261110600000_cahier_c2_programme_donnees.sql:334`). |
| `public.seance_resumes` (`0054_seance_resumes_famille.sql`) | `student_id`, `session_id`, `jalon_atteint` (vers `programme_niveaux`), `publie_le`, `revoque_le`, `publication_manuelle`, `auto_partage`, `regle_ouverte` | Un jalon (une étape) atteint par séance, au plus. Pas de sourate. |
| `public.evaluations` (`0023_evaluations.sql:22`) | `student_id`, `niveau_id`, `type`, `statut`, `resultat` (`reussi`, `echec`, `a_revoir`) | Le résultat d'une évaluation d'**étape**. Pas de sourate. |
| `public.cahier_observations` (`20261110610000_cahier_c3_confirmation.sql:27`) | `student_id`, `session_id`, `nature` (`a_renforcer`, `pret_bilan`), `objectif` | Ce que le cahier signale par élève. Pas de sourate validée. |
| `public.student_reading_position` (`0007_coran_structure_position_presence.sql:98`) | `student_profile_id`, `sourate`, `verset`, `page_mushaf` | **La position de lecture, pas une validation** : elle ne doit jamais remplir l'anneau. |
| `public.progression_famille(p_student_id, p_limit)` (dernière version : `20261018190000_ped_cahier_partage.sql:281`) | rend `niveau_humain`, `jalons` (noms des jalons franchis), `seances` | Aucun compte de sourates. Réservée au tuteur. |

## Question ouverte au directeur : qu'est-ce qu'une « sourate validée » ?

Aucune option n'est tranchée ici.

| Option | Ce que c'est | Conséquences |
| :--- | :--- | :--- |
| **A. L'enseignant coche la sourate au cahier de séance** | Une sourate est validée quand l'enseignant indique au cahier que l'élève l'a récitée de mémoire, sans erreur de mot. C'est le critère écrit de l'étape 4 (« Récite chaque sourate de l'étape de mémoire, sans erreur de mot »). | Le plus simple pour l'enseignant : une case de plus au cahier, qu'il remplit déjà. L'anneau avance séance après séance. Mais une sourate est validée sans confirmation de l'administration, alors que le programme veut « l'enseignant propose, l'administration confirme » pour une étape. Le principe « ce qui est validé n'est jamais perdu » s'applique dès la coche. |
| **B. Comme une étape : l'enseignant propose, l'administration confirme** | Chaque sourate suit le circuit d'une étape, avec le résultat « Étape validée » ou « Quelques points sont à renforcer ». | Fidèle au circuit existant. Mais 17 confirmations par élève pour les seules bases, donc une charge lourde pour l'administration, contraire à « l'enseignant ne fait pas de corvée » (`VISION-ECOLE`). L'anneau avance plus lentement. |
| **C. Pas de comptage par sourate : l'anneau compte les étapes** | L'anneau montre les étapes validées (4 pour les bases), par les évaluations `reussi` déjà enregistrées. | Constructible sans saisie nouvelle, avec les seules données existantes. Mais l'anneau bouge rarement (4 crans pour les bases) et le « tour doré à la fin d'une sourate » devient un tour doré à la fin d'une étape : la demande change, c'est au directeur de l'accepter. |

## Le lot serveur, une fois la question tranchée

Ce qui suit vaut pour A et B. Pour C, seul le calcul change : il compte les `evaluations` `reussi` par étape, sans table nouvelle.

1. **Relier les étapes aux sourates.** Ajouter une table de correspondance `public.programme_niveau_sourates (niveau_id → programme_niveaux.id, sourate_numero → sourate.numero, ordre)`, remplie pour l'étape 4 des bases (les 17 sourates de `programme-rewayah`, ligne 51) dans la version publiée du programme. Lecture : tout compte valide. Écriture : la direction seule, par la fonction de version du programme. *(Remplacé dans la mise en œuvre : une table fixe des 17 sourates des bases, voir « Ce qui est codé ».)*
2. **Enregistrer la validation.**
   - Option A : une table `public.sourates_validees (student_id, sourate_numero, session_id, valide_le, enseignant_id)`, unique par `(student_id, sourate_numero)`. Elle est remplie par un déclencheur sur le dépôt du cahier, sur le modèle de `private.cahier_c3_observations()`. Jamais effacée (« ce qui est validé n'est jamais perdu »).
   - Option B : la même table, avec un statut `propose` puis `confirme`, et la confirmation par la direction.
3. **Le champ ajouté.** `progression_famille` rend en plus un objet `sourates` :
   - `{ "etape_humaine": text, "validees": int, "total": int }` pour l'étape en cours, calculé par la correspondance ;
   - `null` quand l'étape en cours n'a pas de sourates (étapes 1 à 3) ou quand rien n'est connu.
   - Le client lit `null` comme « donnée absente », jamais comme 0.
4. **L'équivalent élève.** Une fonction `public.ma_progression()`, sans argument, qui rend le même objet pour l'appelant lui-même :
   - l'élève adulte titulaire de son profil (`student_profiles.titulaire_profile_id = auth.uid()`, `app_account_valid()`) ;
   - ou l'enfant en Interface guidée (`profiles.id = auth.uid()`, `role = 'student'`).
   - Jamais pour un autre élève.
5. **Portée RLS.**
   - Les tables neuves ont RLS activée, et `REVOKE ALL` pour `PUBLIC`, `anon` et `authenticated`.
   - Aucune lecture directe : seulement par les deux fonctions `SECURITY DEFINER`, `search_path = ''`, `EXECUTE` accordé à `authenticated` seul.
   - Le tuteur lit les élèves de son foyer (condition actuelle de `progression_famille`). L'élève ne lit que lui-même. L'enseignant ne passe pas par ces fonctions.
6. **Scénario SQL** : `supabase/tests/scenarios_progression_sourates.sql`, à nommer dans `ci.yml`.
   - Un tuteur lit le compte d'un enfant de son foyer, et pas celui d'un autre foyer.
   - L'élève adulte lit le sien, et pas celui d'un autre élève.
   - Une validation n'est jamais perdue, même après un changement de classe.
   - `null` à l'étape 2.
   - `total = 17` sur les bases (décision du directeur ci-dessous).
   - `anon` refusé.
7. **Plage de migration** : à demander au garde-cap avant toute écriture. La dernière migration de `main` est `20261122800000_cand_alertes_bloquees_retard.sql`. Il faut une plage libre après elle, pour un ou deux fichiers. L'installation en production reste au pilote.

## Ce que l'anneau affiche tant que la donnée manque

- Pas d'anneau de progression, et **jamais un 0** : un anneau vide dirait « rien n'est fait », ce qui serait faux.
- À la place, le cercle doré seul, sans chiffre. C'est la consigne du pilote (« sinon doré »).
- Aucune lumière ne se déduit sur l'appareil (`A-FAIRE-LUMIERE-ACCUEILS.md`, « uniquement des états fournis par le serveur »).
- Un `null` du serveur et une lecture en échec donnent le même rendu : le doré seul.

## Hors de ce document

- Aucun écran : le point 2 du lot (Accueil de l'élève, tour doré) est attribué à l'agent H, et l'anneau viendra après le lot serveur.
- Aucun mot nouveau à l'écran avant que la question soit tranchée.
- `features/salle` n'est pas concerné.

## Ce qui est codé (option A, 11/11/2026)

Branche `claude/sourates-travail`, migration `20261122900000_sourates_validees.sql` (plage réservée par le garde-cap).

- **Une seule source des 17 sourates des bases** : `private.sourates_des_bases (ordre, numero)`, dans l'ordre d'étude (Al-Fatiha, puis 114 à 99). La table `programme_etape_reglages` de la PR #382 (H) s'aligne sur elle (consigne du pilote).
- **`public.sourates_validees`** : une ligne par élève et par sourate, jamais effacée ni modifiée, aucun accès direct (RLS activée, aucun droit).
- **Écriture** : un déclencheur sur le dépôt du cahier (`lesson_reports`) lit `eleves[].sourates_validees`. L'écriture reste celle de l'enseignant de la séance, sous la politique existante. **Aucune écriture par la direction** : l'option A dit « l'enseignant coche » ; la question d'une validation par la direction est sur la liste du directeur.
- **Lecture** : une fonction à part, `sourates_eleve(élève)`, rend en JSON le compte (`sourates_validees`, `sourates_total`) et la liste des 17 sourates dans l'ordre d'étude, avec la même porte que `suivi_pedagogique_eleve` (élève, titulaire de son profil, tuteur du foyer). `suivi_pedagogique_eleve` reste inchangée : elle rend une table, et lui ajouter deux colonnes aurait demandé un `DROP FUNCTION` (pilote, 11/11 : zéro mot d'effacement). L'application lit les deux et ajoute le compte au suivi ; si `sourates_eleve` manque, le suivi s'affiche sans sourates, jamais avec un 0 inventé. `sourates_bases_classe(groupe)` rend au cahier les 17 sourates de chaque élève et celles déjà validées (titulaire, remplaçant de la séance, direction en lecture).
- **Cahier** : sous chaque élève, les sourates pas encore validées se cochent (« Cochez une sourate seulement si cet élève l'a récitée de mémoire, sans erreur de mot »). Une sourate déjà validée ne se propose plus.
- **Anneau** : il reste à la PR #382 (H). Tant que le serveur ne rend pas le compte, le client lit `null` : doré seul, jamais 0.

### Décision du directeur (11/11/2026)

**Les 17 sourates des bases comptent à toute étape ; le total est 17.** Elles sont posées telles quelles depuis `programme-rewayah`, section 2, ligne 51 (« Les 17 sourates des bases (105 versets) »). La direction ne valide pas les sourates : elle voit l'état, sans plus (décision relayée par le garde-cap et le pilote).
