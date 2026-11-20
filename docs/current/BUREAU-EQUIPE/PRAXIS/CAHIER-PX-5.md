# Cahier PX-5 : Praxis sait où en est la personne qui lui écrit (20/11/2026)

Constat en production, nuit du 20/11/2026 : Praxis a répondu à une candidate « nous étudions les candidatures dans
l'ordre ». Or son dossier avait été admis à l'étape suivante trois jours plus tôt. Cause : `boite` et `fil`, les deux
outils qui servent à répondre, ne rendaient rien sur le dossier de la conversation. 169 candidats sont à l'étape
`verifications` / `entretien_a_planifier`, et 113 n'ont reçu aucun message humain depuis.

Ordre ajouté le même jour (directeur, relayé par le coordinateur) : « relève le plafond à 100 toutes les 5h ».

Migration : `supabase/migrations/20261130300000_praxis_px5.sql`. Scénario : `supabase/tests/scenarios_praxis_px5.sql`.
Essai à plusieurs sessions : `supabase/tests/concurrence_praxis_px5.sh`. Ce lot s'appuie sur PX-4 (`20261130200000`),
installé en production le 20/11/2026 à 03:39 UTC.

## 0. Ce qui est faux, bloqué ou non prouvé

- **Rien n'est installé ni déployé.** La migration a tourné seulement sur un Postgres 16 local, alors que la
  production est en 17.
  - Les empreintes d'entrée ont été mesurées sur la base rejouée jusqu'à PX-4, pas en production. Si une seule diffère
    en production, la migration s'arrête sans rien modifier.
  - La fonction Edge `praxis-mcp` n'est pas redéployée. Tant qu'elle ne l'est pas, Praxis ne voit ni les deux outils
    neufs, ni l'argument `decalage`, ni les nouvelles descriptions. Il reçoit pourtant déjà `dossier` dans `boite` et
    `fil` dès que la migration est installée.
- **Une question retirée bloque encore sa conversation.** L'index unique `praxis_questions_une_ouverte_par_fil`
  (`WHERE repondue_le IS NULL`) ne peut être réécrit qu'avec un `DROP INDEX`, et ce lot n'efface rien. Conséquences :
  - Praxis ne peut pas poser une autre question à l'équipe dans cette conversation. Le refus s'appelle
    `question_retiree`, pas `question_ouverte`.
  - La place se libère dès que la direction répond à la question retirée.
  - Pour lever ce blocage, il faut une décision datée du directeur qui autorise un mot d'effacement (le remplacement de
    l'index).
- **L'écran de la direction (`lib/core/agent/questions_praxis.dart`, hors zone) continue d'afficher une question
  retirée comme « ouverte »**, car il teste `repondueLe == null`.
  - La lecture `direction_praxis_questions` rend désormais `retireeLe` et `retireeMotif`, et classe les questions
    retirées après les ouvertes. Aucun écran ne lit encore ces deux clés.
  - Si la direction répond quand même, sa réponse est transmise à Praxis avec `question_retiree: true` (décision
    expliquée au §5).
- **`rendre_compte` n'a pas été modifié.** Il ne lit pas `private.praxis_questions` : la migration le vérifie, et
  refuse de s'installer si une autre fonction que les cinq connues lit cette table. Aucune question n'y est donc
  « comptée ouverte ».
- **`informe_de_l_etape` ne voit que la conversation de candidature.** Un courriel, un appel, un message du compte
  officiel automatique ou une annonce ne comptent pas. Le champ peut donc valoir faux pour une personne déjà prévenue
  par un autre canal.
- **L'ordre des clés de `fil` n'est pas garanti.** La consigne demandait `dossier` « en tête », mais `jsonb` range les
  clés à sa façon. `dossier` est une clé de premier niveau de la réponse, ce qui revient au même pour Praxis.
- **Les tests Deno ne sont pas lancés** : `deno` est absent du poste, et le registre npm est injoignable d'ici.
  - `outils.ts` passe `tsc --strict`.
  - `praxis_test.ts` est mis à jour (24 outils, 12 refus de schéma, 3 appels), mais il n'a pas été exécuté.
  - Un essai Node du schéma compilé confirme 11 vérifications sur 12. Le seul « rouge » venait de l'essai lui-même : il
    comparait des textes JSON dont les clés n'étaient pas dans le même ordre. Le contenu est juste.
- **Le Postgres local tourne dans `/var/lib/postgresql/px5`, pas dans le dossier de travail `px5/`** comme demandé.
  L'utilisateur `postgres` ne peut pas traverser `/tmp/claude-0/…`. Les journaux et les scripts, eux, sont bien dans
  `px5/`.
- **La consigne de la routine (`ROUTINE-PRAXIS.md`) et le texte de confidentialité ne sont pas modifiés** (hors zone).
  La routine ne connaît donc ni `questions_ouvertes` ni `retirer_question`.

## 1. Ce qui est livré

| Point | Outil | Fonction |
| :-: | :--- | :--- |
| 1 | `boite` : objet `dossier` par fil de candidature | `praxis_boite` remplacée ; aide `private.praxis_dossier_resume(fil, côtés)` |
| 2 | `fil` : objet `dossier` dans la réponse | `praxis_fil` remplacée (même aide) |
| 3 | `lire` : `decalage` (0 à 5000, dans le filtre), `fil` par ligne, `total` juste même pour une page vide, `decalage` et `reste` | `praxis_lire` remplacée |
| 4 | `questions_ouvertes`, `retirer_question` | `praxis_questions_ouvertes(cle, limite)`, `praxis_retirer_question(cle, question, motif)` ; colonnes `retiree_le`, `retiree_motif` ; `praxis_demander_equipe`, `praxis_reponses_equipe`, `direction_praxis_questions` remplacées |
| 5 | Plafond des ouvertures : 100 par 5 heures glissantes, réglable | colonnes `ouvertures_par_fenetre` (100, de 1 à 500), `ouvertures_fenetre_heures` (5, de 1 à 48) dans `private.praxis_reglages` ; porte `direction_praxis_regler_ouvertures(nombre, heures)` (aal2, audit `praxis_regle_ouvertures`) ; `private.praxis_ouverture_refus` et `praxis_etat` remplacées |
| + | `praxis_noter_refus` connaît les deux outils neufs, ainsi que `demander_equipe`, `reponses_equipe`, `question_traitee` et `terminer`, qu'il avait oubliés (constat du cahier PX-3, §4.11) | remplacée |

### L'objet `dossier`

Clés : `reference`, `etape`, `etat`, `issue`, `complet`, `manquants`, `attend_direction`, `informe_de_l_etape`,
`etape_depuis_jours`. On n'y trouve aucun nom, prénom, courriel, téléphone, motif interne ni identifiant de compte.
`complet`, `manquants` et `attend_direction` sont calculés par `private.praxis_dossier_manques` : c'est la même aide
que pour `lire` et `dossier`, et rien n'en est recopié.

- **Dernière transition d'étape** : le dernier événement du moteur où `etape_apres` vaut l'étape actuelle et
  `etape_avant` est différent. Une transition d'état au sein de la même étape ne compte pas. Sans événement, on prend la
  date de réception du dossier.
- **`informe_de_l_etape`** : vrai si un message a été envoyé dans la conversation après cette transition, par Praxis
  ou par un membre humain de l'équipe (`private.praxis_est_equipe`, qui exclut le compte officiel). Le message du
  candidat ne compte pas.
- **`null`** dans tous les cas suivants, qui sont les fermetures de `praxis_dossier` :
  - mode essai ;
  - données réelles fermées ;
  - dossier refusé, retiré, en pause ou restreint ;
  - majorité non attestée ;
  - mineur ;
  - autre côté ;
  - autre type de dossier ;
  - conversation qui n'est pas la conversation standard du dossier.

  Une candidature **restreinte** garde une conversation lisible, mais son `dossier` vaut `null` (vérifié par le
  scénario).

### La consigne donnée à Praxis (descriptions de `boite` et `fil`)

« AVANT DE RÉPONDRE dans une conversation de candidature, lis « dossier » : si informe_de_l_etape est faux et que
l'étape a avancé, ANNONCE-LE à la personne en premier (son dossier est passé à telle étape, ce qui reste à faire
d'après manquants) ; ne dis JAMAIS « nous étudions les candidatures dans l'ordre » à quelqu'un dont le dossier a déjà
avancé. »

## 2. Empreintes d'entrée exigées (`md5(prosrc)`)

| Fonction | Entrée exigée | Sortie (après PX-5) | Dernière définition |
| :--- | :--- | :--- | :--- |
| `public.praxis_boite(text,text,integer)` | `5e1ceb568ce2807ccd7032c4639b14e0` | `2d3fa1d3b22a6ad7f6dc829d2c1fa303` | `20261129650000` |
| `public.praxis_fil(text,uuid,integer)` | `194769e309d65656b1a83ba9c7030a01` | `ad9ff137196ef2f7cc8c5b1c2cd352b0` | `20261129600000` |
| `public.praxis_lire(text,text,jsonb,integer)` | `1ccdd89e67ac1e0b431866f944477473` | `c076f800e8a67b99b4be638f43b7b4c0` | `20261130200000` |
| `public.praxis_demander_equipe(text,uuid,text)` | `8885e3e89621ffeade260ef8fed35d49` | `da08da084ea393ebdde502e5a7c56f2d` | `20261129930000` |
| `public.praxis_reponses_equipe(text,integer)` | `4f6ba9024bfadbe123575543742e461f` | `e8b1e87634103991899eb83c15817cc7` | `20261129930000` |
| `public.direction_praxis_questions(integer)` | `4c0f489e078d60b10eb99c58872730c0` | `093c84d81c868443f017010354e8c8e5` | `20261129930000` |
| `public.praxis_noter_refus(text,text)` | `580fef3b5c94c797ee3d1ba18c1bb0bd` | `9b9fb4d2640b31dda3ef2b0b3ae80bb3` | `20261130200000` |
| `private.praxis_ouverture_refus(candidatures,text,gender[])` | `ec4efc90af75d189a269ca7d8fa05e8c` | `2dcf31b5880269cc7b5e0821a68d3320` | `20261130200000` |
| `public.praxis_etat(text)` | `f5eff392d5eaccf1e225546cfea60cef` | `41563b247222c6ff5dec260ef244bc8a` | `20261130200000` |

Fonctions neuves (sortie) : `private.praxis_dossier_resume` `56697c56a79a8676c191dafef22e9dc0`,
`praxis_questions_ouvertes` `4135ce71515f5a9ea477b79d2c33aa00`, `praxis_retirer_question`
`826c34a1dce1329d733885cc2489c406`, `direction_praxis_regler_ouvertures` `e800f581e35fa80c93c273ed22ae8e97`.

Méthode : chaque corps est recopié de `pg_get_functiondef` sur la base rejouée, puis modifié par des remplacements
contrôlés (chaque motif doit apparaître exactement une fois). Chaque ajout porte le mot `PX-5`.

## 3. Le plafond des ouvertures

- **Avant** : 25 par 24 heures, codé en dur dans `private.praxis_ouverture_refus` et `praxis_etat`.
- **Après** : `ouvertures_par_fenetre` par `ouvertures_fenetre_heures` heures glissantes, au total, soit 100 par
  5 heures à l'installation. On compte les questions, les relances et les entretiens écrits ; les félicitations ne
  comptent pas. Toutes les autres limites sont inchangées :
  - une question ou une relance par personne tous les 7 jours ;
  - 2 messages de suite sans réponse ;
  - 3 relances en tout ;
  - la règle de nuit ;
  - une seule série d'entretien écrit ouverte ;
  - le plafond horaire des envois.
- `praxis_boite_candidats` lit la même fonction et dit donc `refus: plafond_ouvertures`. Sa définition n'est pas
  modifiée.
- `etat` rend `ouverturesRestantesFenetre`, `ouverturesParFenetre` et `ouverturesFenetreHeures`.
  `ouverturesRestantesJour` est **gardée** pour les lecteurs d'avant, et vaut maintenant la même chose que
  `ouverturesRestantesFenetre`.
- **Parallèle** : `praxis_ouvrir` prend le verrou `praxis-envois` avant d'appeler `private.praxis_ouverture_refus`
  (inchangé depuis PX-4). Essai `concurrence_praxis_px5.sh` : 95 ouvertures déjà faites dans la fenêtre, puis 20
  sessions psql lancées à la même seconde. Résultat : **5 passent, 15 refusées `plafond_ouvertures`, 100 dans la
  fenêtre**.
- **Réglage** : `direction_praxis_regler_ouvertures(p_par_fenetre, p_fenetre_heures)`, réservé à l'administrateur en
  aal2, hors bornes refusé (`22023`), avec une ligne d'audit. `direction_praxis_etat` n'est **pas** modifiée : la
  direction lit le réglage par `etat` de Praxis ou par la réponse de la porte. Aucun écran n'existe encore.

## 4. `lire` paginé

- `decalage` est une clé du filtre (connecteur : `dans: 'p_filtre'`), entier de 0 à 5000. Toute autre valeur est
  refusée `parametre` et journalisée. La signature de la fonction ne change pas : aucun `DROP`, aucune surcharge
  ambiguë pour PostgREST.
- L'ordre est total (le tri, puis `derniere_activite`, puis `id`) : deux pages successives n'ont ni doublon ni trou
  tant que les dossiers ne bougent pas. Le scénario le prouve avec et sans filtre, avec le tri `vision`.
- `total` vient du filtre entier, même quand la page est vide (avant, une page vide rendait 0). `reste` = total −
  décalage − lignes rendues.
- `fil` par ligne : l'identifiant de la conversation de candidature quand elle existe **et** que Praxis peut la lire
  (`praxis_fil_refus`). Sinon `null`. `a_une_conversation` est gardé.

## 5. Les questions retirées : décisions

1. Deux colonnes neuves, `retiree_le` et `retiree_motif`. Le motif est pris dans une liste fermée
   (`repondu_par_praxis`, `sans_objet`) et deux CHECK neufs le contrôlent. Aucune colonne existante n'est touchée,
   aucune ligne n'est effacée.
2. On ne peut retirer qu'une question sans réponse et non retirée, dans une conversation encore ouverte à la clé.
   Codes de refus : `inconnue` (même réponse pour une question inexistante et pour l'autre côté), `deja_retiree`,
   `deja_repondue`. La ligne est verrouillée (`FOR UPDATE`) contre une réponse simultanée de la direction.
3. N'est **plus ouverte** pour :
   - `demander_equipe` : le plafond de 100 ouvertes ne la compte plus ;
   - `questions_ouvertes` ;
   - la liste de la direction, qui la classe après les ouvertes.
4. Si la direction répond quand même à une question retirée : `direction_praxis_repondre` n'est pas modifiée, la
   réponse est enregistrée, la place de la conversation se libère, et `reponses_equipe` transmet la réponse avec
   `question_retiree: true`. La description dit à Praxis de ne transmettre que ce qui corrige ou complète ce qu'il a
   déjà dit. Pourquoi ne pas l'écarter : l'écran de la direction, inchangé, montre la question comme ouverte. Une
   réponse avalée en silence tromperait la direction.

## 6. Scénarios (Postgres 16 local, chaque scénario sur une copie neuve de la base rejouée)

- `scenarios_praxis_px5.sql` : **67 vérifications, toutes vertes** :
  - droits (`service_role` seul pour les outils ; `authenticated` seul pour les portes ; personne pour l'aide ; anon et
    administrateur refusés `42501`) ;
  - aucune donnée personnelle dans `dossier`, et liste fermée de ses clés ;
  - `dossier` null pour une candidature restreinte, en pause, refusée, à majorité retirée, de l'autre côté, inconnue,
    en mode essai, et quand les données réelles sont fermées ;
  - `informe_de_l_etape` faux (message de la direction avant la transition, transition d'état, message du candidat),
    puis vrai (direction après, Praxis après) ;
  - pagination sans doublon ni trou ;
  - question retirée qui n'est plus ouverte, refus de retrait, `question_retiree`, plafond des 100 questions ;
  - plafond de 100 par 5 heures (fenêtre glissante, félicitations hors compte, l'ancien 25 par 24 h ne s'applique
    plus) et réglage.
- Rejoués verts avec la migration : `scenarios_sec1_praxis`, `sec1_praxis_ar7`, `px2_preparer`, `px2_annuaire_agent`,
  `praxis_candidats`, `praxis_dossier_complet`, `praxis_purge_journal`, `praxis_routine_pouls`, `praxis_travail`,
  `px3_lectures_direction`, `px4_mode_essai`, `px_suivi`, `messages_candidat`, `com_back_1_messagerie`,
  `af_liste_blanche_volatiles`, `cand_autres_competences`, `com_compte_officiel`, `candidats_flux`,
  `cand_l2a2_gestes_direction`, `messagerie_push`, `messagerie_temps_reel`.
- **Rejeu complet du dépôt avec la migration**, chaque scénario sur une copie neuve : **361 verts sur 364**. Les 3 rouges
  le sont aussi sur la base sans PX-5 : `calendrier_pauses`, `cand_l1b_concurrence` et `cand_l3_concurrence` (ces deux
  derniers par dblink : « could not establish connection » sur ce poste).
- Garde-fous mis à jour, chacun avec un commentaire `PX-5`, sans en affaiblir aucun :
  - `scenarios_sec1_praxis.sql` (R2, R4, AR-10, R1) ;
  - `scenarios_px2_preparer.sql` : clé `fil` dans la liste fermée. `fil` est retiré du texte soumis au motif interdit
    (un uuid aléatoire peut contenir « 0699 ») et contrôlé à part (uuid ou null) ;
  - `scenarios_praxis_travail.sql` : clé `fil` ;
  - `scenarios_praxis_dossier_complet.sql` : le plafond passe de 25/24 h à 100/5 h, avec une vérification de plus
    (fenêtre glissante) ; `etat` lit `ouverturesRestantesFenetre` ;
  - `scenarios_af_liste_blanche_volatiles.sql` : la porte neuve de la direction.

## 7. Liste de contrôle d'installation (pilote)

Avant, en production, en lecture seule :

1. `supabase_migrations.schema_migrations` contient PX-4 (`praxis_dossier_complet`, version `20261120033935`) et
   aucune migration nommée `praxis_px5`. La version `20261130300000` est libre dans le dépôt.
2. Les neuf empreintes d'entrée du §2 sont celles de la production :
   ```sql
   select p.oid::regprocedure, md5(p.prosrc) from pg_proc p where p.oid in (
     'public.praxis_boite(text,text,integer)'::regprocedure, 'public.praxis_fil(text,uuid,integer)'::regprocedure,
     'public.praxis_lire(text,text,jsonb,integer)'::regprocedure, 'public.praxis_demander_equipe(text,uuid,text)'::regprocedure,
     'public.praxis_reponses_equipe(text,integer)'::regprocedure, 'public.direction_praxis_questions(integer)'::regprocedure,
     'public.praxis_noter_refus(text,text)'::regprocedure,
     'private.praxis_ouverture_refus(public.candidatures,text,public.gender[])'::regprocedure,
     'public.praxis_etat(text)'::regprocedure);
   ```
3. Aucune autre fonction ne lit `private.praxis_questions` :
   `select oid::regprocedure from pg_proc where prosrc ~ 'private\.praxis_questions\M'` rend exactement
   `praxis_demander_equipe`, `praxis_reponses_equipe`, `praxis_question_traitee`, `direction_praxis_questions`,
   `direction_praxis_repondre`.
4. Les colonnes `retiree_le`, `retiree_motif`, `ouvertures_par_fenetre` et `ouvertures_fenetre_heures` n'existent pas.
   `private.praxis_reglages` a une ligne. Relever `select count(*) from private.praxis_questions where repondue_le is
   null` (les questions ouvertes aujourd'hui).
5. Compter les mots d'effacement du fichier : **zéro** (`grep -ciwE 'DROP|DELETE|TRUNCATE'`). Pas de `BEGIN` ni de
   `COMMIT` de premier niveau.

Installer : `apply_migration`, le fichier de `main` mot pour mot. Une seconde application est refusée proprement
(`PX-5 : deja installe ; rien n'est modifie`), ce qui a été vérifié en local.

Après, en lecture seule :

6. Les neuf fonctions remplacées ont les empreintes de sortie du §2. Elles sont `SECURITY DEFINER` (sauf l'aide
   privée), `search_path` vide, propriétaire `postgres`.
7. Droits, vérifiés par `has_function_privilege` :
   - `praxis_questions_ouvertes`, `praxis_retirer_question` et les outils remplacés : `service_role` seul ;
   - `direction_praxis_regler_ouvertures`, `direction_praxis_questions` : `authenticated` seul ;
   - `private.praxis_dossier_resume` : personne ;
   - rien pour `anon`, `agent_ro`, `PUBLIC`.
8. `private.praxis_reglages` : `ouvertures_par_fenetre = 100`, `ouvertures_fenetre_heures = 5`, les autres réglages
   inchangés. `private.praxis_questions` : aucune ligne retirée, même nombre de lignes qu'avant. RLS active sur les
   deux tables, aucun droit client.
9. Essai sans trace : bloc `DO` qui appelle `praxis_boite(cle, 'tout', 50)` avec une clé de chat, vérifie que chaque
   fil `candidature` porte `dossier` (objet ou null) sans aucune clé de personne, puis annule par un `raise` final.
10. Redéployer `praxis-mcp`. `tools/list` rend 24 outils.
11. Avant d'annoncer la correction au directeur : le directeur ouvre, dans la boîte de Praxis, une conversation de
    candidature à l'étape `verifications` et vérifie que `dossier.etape` vaut `verifications` et que
    `informe_de_l_etape` est juste. C'est la preuve en production. Sans elle, rien n'est « fait ».
