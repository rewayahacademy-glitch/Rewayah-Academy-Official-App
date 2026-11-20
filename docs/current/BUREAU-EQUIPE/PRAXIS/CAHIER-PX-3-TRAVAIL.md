# Cahier PX-3 : Praxis travaille sur les dossiers des candidats (20/11/2026)

Ordre du directeur, 20/11/2026 : « La stratégie de Praxis a été écrite mais pas appliquée. Je suis seul dans la
direction, pas d'associé, et des centaines de dossiers à traiter. Il doit commencer à répondre aux gens, classer
les dossiers, définir des objectifs journaliers ou hebdomadaires, relancer les gens comme je le fais parfois. Quand
je valide un dossier j'écris dans le privé, pas pour tout le monde : il doit le faire aussi, avec son profil. »

## 0. Ce qui est faux, bloqué ou non prouvé

- **Deux points sur six ne sont pas livrés** : les relances (point 5, filtre `sans_nouvelles`) et le mot privé après
  une décision (point 6, filtre `a_feliciter`). Rien n'est écrit pour eux. Praxis ne relance donc pas encore et ne
  félicite pas encore. Voir §6 pour ce qu'il faut décider avant de les écrire.
- **Revue indépendante du 20/11/2026 (soir) : les deux scénarios ci-dessous sont corrigés et verts**, sans être
  affaiblis, et la migration a reçu quatre retouches (voir §0 bis). Le texte qui suit est gardé pour l'historique.
- **Deux scénarios existants deviennent ROUGES avec cette migration, et je ne les ai pas modifiés** (ce sont des
  garde-fous, hors de ma zone : au pilote de décider) :
  - `scenarios_sec1_praxis.sql`, vérification « R2 : la liste des fonctions public.praxis_* est exactement la liste
    blanche » : il faut y ajouter `praxis_objectif_clore(text,uuid,text,text)`,
    `praxis_objectif_fixer(text,text,date,text,integer,uuid)`, `praxis_objectifs_lire(text,text,integer)` et
    `praxis_ranger(text,text,text,text,uuid)` (ordre des noms), comme PX-SUIVI l'avait fait pour ses trois outils.
  - `scenarios_px2_preparer.sql`, vérification « 2 : aucune réponse ne contient courriel, téléphone, pièce,
    photo… » : elle cherche les mots `piece` et `photo` dans toute la réponse de `lire`. Or l'ordre demande que
    `manquants` porte les codes `piece_identite` et `photo`. **Contradiction entre ce garde-fou et l'ordre** : soit
    le garde-fou ignore les deux listes de codes (et vérifie à part qu'elles ne portent que des codes), soit les
    codes changent de nom. Rien n'est tranché.
  Les 29 autres scénarios qui touchent Praxis, les candidatures ou les gestes restent verts, avant comme après.
- **Rien n'est installé en production.** La migration `20261130100000_praxis_travail.sql` n'a tourné que sur un
  Postgres 16 local (la CI et la production sont en 17). Le pilote l'installe après relecture.
- **Les empreintes du contrôle d'entrée viennent du dépôt, pas de la production.** Si une des six fonctions
  remplacées diffère en production, la migration s'arrête sans rien modifier (c'est voulu) ; il faudra comparer.
- **Les tests Deno n'ont pas été lancés** (pas de `deno` sur ce poste). `outils.ts` passe `tsc --strict` ;
  `praxis_test.ts` est mis à jour mais non exécuté.
- **La fonction Edge `praxis-mcp` n'est pas déployée.** Tant qu'elle ne l'est pas, les quatre outils neufs
  n'existent pas pour Praxis, et `preparer` refuse `dispenser_entretien` au schéma.
- **Aucun écran** ne lit encore `direction_praxis_rangements` ni `direction_praxis_objectifs` (hors zone).
- **La routine ne connaît pas ces outils** : `ROUTINE-PRAXIS.md` n'est pas modifié (hors zone). Sans consigne dans
  la routine, Praxis ne rangera rien et ne fixera aucun objectif.
- `manquants` ne nomme que **le premier accord manquant** (contrat, puis avis, puis code de conduite) : c'est ce
  que rend la fonction existante des contrôles, réutilisée sans copie.

## 0 bis. Revue indépendante du 20/11/2026 : ce qui a été trouvé et corrigé

Rien n'est installé. La revue a rejoué la migration sur un Postgres 16 local (pas 17) et a lu la production en
lecture seule (aucune écriture).

- **Défaut trouvé dans la migration (important)** : deux commentaires écrits DANS le corps de fonctions
  (`praxis_gestes_ligne`, `direction_praxis_valider`) contenaient le mot « execute » suivi d'un espace. Le garde-fou
  R1 de `scenarios_sec1_praxis.sql` (« aucun EXECUTE dynamique ») cherche ce motif : il devenait rouge. Aucun SQL
  dynamique n'existait ; les commentaires sont réécrits (« lance »), le garde-fou n'est pas touché.
- **Durcissement** : le retrait et l'ajout du CHECK `praxis_propositions_geste_check` sont réunis en UNE instruction
  `ALTER TABLE`, pour qu'aucun mode d'exécution ne laisse la colonne sans CHECK. Toujours un seul mot d'effacement.
- **Durcissement** : la signature de `praxis_gestes_ligne` qualifie ses types (`public.candidatures`,
  `public.gender[]`) au lieu de dépendre du `search_path` de la session qui installe.
- **Défaut mineur corrigé** : `praxis_objectif_fixer` acceptait, pour une semaine, une date jusqu'à six jours en
  arrière, donc la semaine précédente. La borne est le lundi de la semaine en cours ; une vérification de plus dans
  `scenarios_praxis_travail.sql` (63 vérifications).
- **`scenarios_sec1_praxis.sql`** : les quatre outils neufs entrent dans la liste blanche (R2) et dans la liste des
  arguments (R1) ; les trois couples (fonction, table écrite) neufs et les sept appels qualifiés neufs entrent dans
  les listes fermées (R4, AR-10) ; la dispense d'entretien est désormais SURVEILLÉE comme les trois autres portes de
  geste (seule `direction_praxis_valider` l'appelle).
- **`scenarios_px2_preparer.sql`** : le motif interdit (pièce, photo, note, motif, montant…) s'applique toujours,
  mot pour mot, à toute la réponse de `lire` SAUF aux deux listes `manquants` et `attend_direction`, qui sont
  contrôlées à part contre des listes fermées de codes ; les six clés neuves entrent dans la liste fermée des clés.
- **Lu en production (lecture seule)** : Postgres 17.6 ; les six empreintes du contrôle d'entrée sont celles de la
  production ; les dépendances, la règle `dispenser_entretien`, le nom du CHECK et les colonnes lues existent ;
  `private.praxis_propositions` est vide ; aucune des deux tables neuves n'existe ; la version est libre.

## 1. Ce qui est livré

| Point | Livré | Où |
| :-: | :--- | :--- |
| 1 | `lire` (vue candidatures) rend en plus `manquants`, `attend_direction`, `complet`, `jours_sans_activite_candidat`, `a_une_conversation`, `pile` | `praxis_lire` remplacée ; aides `private.praxis_dossier_manques`, `private.praxis_candidat_derniere_action` |
| 2 | Piles : outil `ranger`, lecture `direction_praxis_rangements(pile, limite, decalage)` | table `private.praxis_rangements`, `praxis_ranger` |
| 3 | `preparer` accepte `dispenser_entretien` ; la validation l'exécute | `praxis_gestes_ligne`, `praxis_preparer`, `direction_praxis_valider` remplacées ; CHECK du geste réécrit |
| 4 | Objectifs : `objectif_fixer`, `objectif_clore`, `objectifs_lire`, lecture `direction_praxis_objectifs(filtre, limite, decalage)` ; `rendre_compte` rend `objectifs_ouverts` et `propositions_en_attente` | table `private.praxis_objectifs`, `praxis_rendre_compte` remplacée |
| 5 | Non livré | |
| 6 | Non livré | |

Scénario : `supabase/tests/scenarios_praxis_travail.sql` (62 vérifications isolées, plus 7 refus d'appel).

## 2. Les codes

- `manquants` (c'est au candidat d'agir) : `compte`, `cadre_religieux`, `contrat`, `avis`, `code_conduite`,
  `piece_identite`, `questionnaire`, `pays_versement`, `photo`, `accord_publication`, plus les codes d'un complément
  en cours (ceux de `private.candidature_complement_codes`).
- `attend_direction` (c'est à la direction d'agir) : `piece_identite` (déposée, à vérifier), `versement` (à
  examiner), `cadre_religieux` (texte non publié), `questionnaire` (aucun questionnaire courant), `autre`.
- `complet` : `manquants` est vide.
- Piles : `pret_a_decider`, `incomplet`, `a_regarder`, `sans_nouvelles`.
- Objectifs : période `jour` ou `semaine` (rangée sous son lundi) ; état `ouvert`, `atteint`, `abandonne`.
- Paramètres de `dispenser_entretien` : `categorie` (`fondateur` ou `autre`) et `motif` (1 à 300 signes).
- Refus neufs : `plafond_rangements`, `plafond_objectifs`, `deja_clos`, `inconnu`, `geste_inconnu` (validation).

## 3. Les plafonds

| Quoi | Plafond |
| :--- | :--- |
| Rangements écrits | 60 par heure glissante, toutes clés confondues ; raison de 200 signes |
| Objectifs ouverts | 3 par jour, 3 par semaine ; libellé de 200 signes ; note de clôture de 300 ; date de la veille à dans 14 jours |
| Propositions | inchangé : 50 ouvertes, une ouverte par dossier et par geste, 72 heures |
| Tous les appels | inchangé : plafond global par clé (`appels_par_heure`) |

## 4. Les décisions prises, et pourquoi

1. **Deux listes au lieu d'une** (`manquants`, `attend_direction`) : une pièce déposée qui attend la vérification
   n'est pas une chose à réclamer au candidat. Sans cette séparation, Praxis relancerait des gens qui ont fait leur
   part.
2. **L'inactivité se compte sur les actions du candidat**, pas sur `candidatures.derniere_activite`, que tout geste
   de la direction remet à zéro. Sources : ses gestes au moteur, ses messages dans sa conversation de candidature,
   ses dépôts de pièce, ses signatures, ses envois du questionnaire ; à défaut, la réception.
3. **`ranger` n'écrit rien si la pile et la raison sont les mêmes** : un passage horaire ne doit pas remplir
   l'historique de copies.
4. **L'historique des piles est gardé par ajout** : la ligne précédente cesse d'être courante, rien n'est effacé.
5. **`direction_praxis_valider` n'exécute plus rien pour un geste qu'elle ne connaît pas.** Avant, toute valeur
   autre que les deux premières exécutait l'admission en salle de vérification. Avec un quatrième geste, ce défaut
   devenait dangereux.
6. **Les objectifs ne dépendent ni du mode essai ni des données réelles** : ils ne lisent aucun dossier (comme le
   calendrier). Le libellé « sans nom de personne » est une règle de l'outil ; le serveur ne peut pas la vérifier.
7. **`ranger` suit `preparer`** : fermé en mode essai et tant que les données réelles sont fermées ; un dossier
   inconnu, clos ou de l'autre côté rend la même réponse.
8. **Les candidatures en pause ou restreintes** : rien ne change. `lire` les liste comme avant ; les conversations
   restent fermées par `praxis_fil_refus`, non touchée.
9. **Six fonctions remplacées** par `CREATE OR REPLACE`, corps recopié de la dernière migration qui les définit,
   empreinte contrôlée avant ; chaque ajout porte le mot `PX-3`.
10. **Un mot d'effacement** : la réécriture du CHECK `praxis_propositions_geste_check` (trois gestes deviennent
    quatre). Aucune donnée n'est touchée.
11. **`praxis_noter_refus`** connaît les quatre outils neufs. Constat hors lot : elle ne connaît toujours pas
    `demander_equipe`, `reponses_equipe`, `question_traitee`, `terminer` (un refus de paramètre sur ces outils
    n'est pas journalisé). Non corrigé ici.

## 5. Liste de contrôle d'installation (pilote)

Avant, en production, en lecture seule :

1. `supabase_migrations.schema_migrations` contient `20261129470000`, `20261129840000`, `20261129860000`,
   `20261129870000`, `20261129910000`, `20261129930000`, et ne contient pas `20261130100000`.
2. Les six empreintes `md5(prosrc)` sont celles du contrôle d'entrée de la migration :
   `praxis_gestes_ligne` `acabfd9b92fb878b091dfcafe441384a`, `praxis_lire` `544c9b89b987f29ba3bca9fe47b16748`,
   `praxis_preparer` `f0b3a65bc044fa44203f439bd35183bf`, `direction_praxis_valider`
   `567af70c9f25f81290f2a20202ac2d23`, `praxis_rendre_compte` `6f9b1cb79dddf7146f830d62241237ae`,
   `praxis_noter_refus` `067543751b2057b7fa24635cd5705aaa`.
3. `private.praxis_rangements` et `private.praxis_objectifs` n'existent pas ; la règle `dispenser_entretien`
   existe dans `private.candidature_gestes_regles`.
4. Aucune proposition ouverte ne porte un geste hors des trois connus (le CHECK est réécrit).
5. Compter les mots d'effacement du fichier : un, section 3.

Après :

6. Les deux tables existent, RLS active, aucune politique, aucun droit pour `anon`, `authenticated`,
   `service_role`, `agent_ro`, zéro ligne.
7. `has_function_privilege` : les quatre outils neufs et les quatre outils remplacés pour `service_role` seul ; les
   deux lectures neuves et `direction_praxis_valider` pour `authenticated` seul ; les trois aides privées pour
   personne.
8. Les cinq fonctions publiques remplacées sont toujours `SECURITY DEFINER`, propriétaire `postgres`,
   `search_path` vide.
9. `private.praxis_reglages` : `actif`, `autonome`, `donnees_reelles`, `essai_fils` inchangés.
10. Déployer `praxis-mcp`, puis `tools/list` rend 18 outils ; `lire` rend les clés neuves sur une ligne réelle.

## 6. Ce qui n'est pas fait

- **Point 5, relancer.** À écrire : filtre `sans_nouvelles` de `boite`, limites dans `ecrire` (une relance par
  personne tous les 7 jours, 3 en tout, 20 par jour, jamais si la direction a écrit dans les 48 heures), une table
  des relances (le journal est purgé à douze mois, il ne peut pas porter « 3 en tout »). **Question à trancher
  avant** : aujourd'hui `ecrire` permet déjà d'écrire dans un fil où le dernier message n'est pas de la personne
  (3 de suite au plus). Mettre les limites « dans le serveur » oblige donc à **resserrer** `ecrire` pour les fils de
  candidature : hors réponse à la personne et hors retour d'une réponse de la direction (`reponses_equipe`), un
  message serait refusé s'il n'est ni une relance permise ni une félicitation permise. C'est un changement de
  comportement d'un outil que la routine appelle toutes les heures.
- **Point 6, le mot privé.** L'événement à retenir est une ligne de `candidature_evenements` dont
  `details ->> 'geste'` vaut `valider_piece` (transition 14, accueil, étape `confirmee`) ou
  `admettre_verifications` (transition 10, admission en salle de vérification), avec `details ->> 'auteur'` =
  `direction`. L'accueil fait passer l'étape à `confirmee`, que `private.praxis_fil_refus` ferme : il faut donc
  rouvrir le fil 72 heures dans cette fonction, et borner `ecrire` à un seul message.
- L'écran de la direction pour les piles et les objectifs ; la consigne de la routine ; le déploiement.
