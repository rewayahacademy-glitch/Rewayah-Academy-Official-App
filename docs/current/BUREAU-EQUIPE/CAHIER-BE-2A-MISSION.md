# Cahier BE-2a : la mission côté serveur (vague 2, lot sensible)

Écrit par le pilote le 16/11/2026, à 20 h 20 UTC, avant tout code. Ordre du directeur, le soir même : « tu es là
pour gérer, et arbitrer ». Stratégie : `../STRATEGIE-BUREAU-EQUIPE-2026-11-15.md` §2, brique 2, §3 R3, R4 et R6,
§4 vague 2. Plage de migrations : `202611294…` (410000 à 430000 et 460000 sont libres ; au-delà, réserver une plage
dans `REGISTRE-LOTS.md`).

## 0. La phrase de recette (directeur)

« J'invite un ami par e-mail, je coche cinq gestes sur les candidatures en anglais ; il ne voit que cela ; je retire
la mission, il ne voit plus rien et son compte n'a pas changé. »

## 1. Ce qui existe (lu le 16/11 dans `main` et en production)

- **La direction, c'est `private.cand_lecteur()`** (`20261021200000_cand_l1_socle_candidatures.sql`) : le rôle
  `admin`, un compte valide, non supprimé. 19 migrations s'en servent. Il y a 1 administrateur en production.
- **Chaque geste passe par `private.candidature_geste_ouvrir`**, qui exige la catégorie `direction` (un lecteur
  dont le genre est connu et le même que celui de la candidature), puis lit la règle dans
  `private.candidature_gestes_regles`. La production compte 28 gestes ouverts à la direction.
- **Le modèle à généraliser est `private.controle_capacites`** : une personne, un approbateur, des dates de début
  et de fin, un périmètre, un retrait avec motif, des clés d'idempotence, RLS fermée. Aucune capacité n'est active
  en production.
- **Les rôles d'application** sont `admin`, `accountant`, `controller`, `teacher`, `guardian` et `student`. Il n'y
  a pas de rôle « associé ».
- **Les invitations** existent par rôle (`inviter_comptable` et `inscrire_comptable_invite`, `inviter_enseignant`).

## 2. Ce que fait BE-2a, et rien d'autre

### 2.1 Tables (schéma `private`, RLS activée, aucun droit pour les rôles de l'API)

- **`private.missions`** : `id`, `nom` (texte court), `gestes text[]` (chaque geste doit exister dans
  `candidature_gestes_regles` avec l'auteur `direction`, ou être l'un des deux gestes de lecture `lire`,
  `voir_contact`), `cree_par`, `cree_le`, `archivee_le`. Une mission est un modèle réutilisable : plusieurs
  personnes peuvent la porter.
- **`private.mission_attributions`** : `id`, `mission_id`, `profile_id`, `accorde_par`, `debut`, `fin` (nulle =
  sans fin), `perimetre jsonb`, `retiree_le`, `retiree_par`, `motif_retrait`, clés d'idempotence d'accord et de
  retrait. Mêmes CHECK que `controle_capacites` : dates cohérentes, retrait complet ou absent. Un index unique
  interdit deux attributions actives de la même mission à la même personne.
- **`private.mission_journal`** : ajout seul (accord, retrait, refus d'un geste hors mission), comme
  `controle_mission_journal`.

### 2.2 Le périmètre (`perimetre jsonb`, validé par une fonction, clé inconnue = erreur)

- **`cote`** : toujours le genre de la personne qui porte la mission (R4). Il n'est jamais choisi : le serveur
  l'écrit.
- **`langues`** (facultatif) : les langues du questionnaire, au moins une en commun avec le dossier.
- **`etapes`** (facultatif) : par exemple `prequalification` seulement.
- **`dossiers`** (facultatif) : une liste d'identifiants de candidatures confiées (« mes dossiers », BE-2c).
- **`liste`** (réservé à la vague 3) : refusé en BE-2a tant que les listes n'existent pas.

### 2.3 Une seule fonction de droit

`private.cand_droit(p_candidature uuid, p_geste text) RETURNS boolean`, `STABLE`, `SECURITY DEFINER`,
`search_path = ''`. Elle répond vrai quand l'une de ces deux conditions est remplie :

- la session est la direction (`cand_lecteur()` non vide) et le dossier est de son côté ;
- la session porte une attribution active (`debut` ≤ maintenant, `fin` nulle ou à venir, non retirée) d'une
  mission non archivée qui contient `p_geste`, et le dossier entre dans le périmètre : même côté, au moins une
  langue commune si `langues` est posé, étape incluse si `etapes` est posé, dossier listé si `dossiers` est posé.

Elle est écrite en exigence positive : NULL vaut faux.

### 2.4 Branchement (retouches par ancrage, jamais une copie entière de fonction)

1. **`candidature_geste_ouvrir`** : pour la catégorie `direction`, l'auteur est accepté si `cand_droit(dossier,
   geste)` est vrai. Le journal du geste note `mission_id` quand l'auteur n'est pas la direction. Un refus écrit
   une ligne dans `mission_journal`.
2. **La lecture** (`lister_candidatures`, `lire_candidature` et le dossier, les voisins) : la direction voit tout
   son côté, comme aujourd'hui. Le porteur d'une mission ne voit que les dossiers de son périmètre, et seulement
   s'il a le geste `lire`. Le contact (courriel, téléphone) n'est visible qu'avec `voir_contact`. **La pièce
   d'identité n'est jamais lisible par une mission en BE-2a** : la signature de la pièce reste réservée à la
   direction.
3. **`capacites_candidatures()`** : pour le porteur d'une mission, les gestes de ses missions actives, et rien
   d'autre.
4. **`private.lp_gestes`** (gestes calculés pour chaque ligne) : il passe par `cand_droit`, pour que la liste
   montre au porteur ses seuls gestes.

### 2.5 Portes publiques (réservées à la direction, `SECURITY DEFINER`, `search_path = ''`, `anon` sans droit)

- `creer_mission(nom, gestes[], cle)` et `archiver_mission(id, motif, cle)`.
- `accorder_mission(profile_id, mission_id, perimetre, debut, fin, cle)` et `retirer_mission(attribution_id,
  motif, cle)`.
- `lister_missions()` et `lister_attributions(filtre)` : qui a quoi, pour l'écran « Équipe » (BE-2b).
- Chaque porte est idempotente, comme `accorder_capacite_controle`. Chaque accord et chaque retrait passe par
  `log_sensitive_access`.

**Accorder ou retirer une mission ne modifie jamais le compte de la personne** (rôle, statut) : c'est la fin de la
phrase de recette.

### 2.6 L'associé extérieur (« un ami par e-mail ») : arbitrage du pilote

Il n'existe pas de rôle « associé ». **Arbitrage : BE-2a ne crée pas de rôle.** Le lot est découpé en deux.

- **BE-2a-1** (ce cahier, §2.1 à §2.5) : missions et attributions pour un compte qui existe déjà, quel que soit son
  rôle.
- **BE-2a-2** : l'invitation d'une personne sans compte. L'agent lit d'abord ce qu'un compte `controller` sans
  capacité de contrôle voit et peut faire dans l'application (routes, capacités, RLS), puis il le rapporte au
  pilote avant d'écrire du code. Si ce compte ne voit rien d'autre que son accueil, l'invitation crée un compte
  `controller` (en suivant le modèle `inviter_comptable`), et la mission fait le reste. Sinon, le pilote tranche
  par écrit.

## 3. Scénarios SQL obligatoires (`supabase/tests/scenarios_be2a_mission.sql`, ajouté au CI)

Les refus, chacun avec le code d'erreur attendu, et rien n'est écrit dans `candidatures` :

1. Un geste non coché dans la mission : refus.
2. Un dossier de l'autre côté : refus (et la mission ne peut pas être accordée avec un autre côté).
3. Une mission dont la fin est passée : refus.
4. Une mission retirée : refus. La lecture de la liste rend 0 ligne et le compte (rôle, statut) est inchangé.
5. Une mission archivée : refus.
6. Un dossier hors des langues du périmètre, ou hors des dossiers confiés : refus et absence de la liste.
7. Lire la pièce d'identité avec une mission : refus.
8. Voir le contact sans `voir_contact` : les champs de contact sont absents.
9. `anon` et `authenticated` sans mission : aucune porte ne s'exécute (`has_function_privilege`).
10. Un geste permis : il aboutit, le journal porte `mission_id`, et l'idempotence rejoue le même résultat.
11. **Non-régression de la direction** : les scénarios de candidature déjà au CI passent sans changement.

## 4. Coût en base (`STRATEGIE-BASE-ECONOME`)

- `cand_droit` se lit à chaque ligne de la liste : il faut un index sur
  `mission_attributions(profile_id) WHERE retiree_le IS NULL`. La mesure, avant et après sur la liste de 502
  dossiers, est écrite dans la PR. Pour la direction, `cand_droit` court-circuite les missions : aucune lecture de
  `mission_attributions`.

## 5. Ce que BE-2a ne fait pas

L'écran « Équipe » (BE-2b), le fait de confier en lot et « Mes dossiers » (BE-2c), suspendre et rétablir un compte
(BE-2d), les listes (vague 3) et l'agent IA (vague 5, qui suivra le même modèle avec un journal « agent »).

## 6. Rattrapage

Aucun dossier n'est coincé par l'ancienne règle : aucune mission n'existe. Il n'y a rien à rattraper. Écrit ici
pour respecter la règle du rapport d'expérience.

## 7. Livraison

Une PR en brouillon, `claude/be2a-mission`, avec les migrations dans la plage, les scénarios du §3, la mesure du §4
et la ligne de `REGISTRE-LOTS.md`. Le pilote relit, fusionne et installe.
