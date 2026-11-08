# ALERTE : lots codés mais jamais livrés (directeur, 08/11/2026)

## Les mots du directeur (08/11/2026, 03:35, relayés par le pilote, mot pour mot)

« bcp choses sont toujours sur git non publiées… la recherche ne marche pas, la banque des noms des
classes, tout ça a été codé mais jamais livré malgré mes demandes répétées… tu l'écris comme une
alerte pour ne pas l'oublier encore… tu ne les lances que si ça peut se lancer avec ce qui existe
déjà, mais après tests… les lots déjà créés mais oubliés dans les abysses de GitHub sont nombreux. »

## Ce que cette alerte impose à toute session et à tout agent

- **Avant d'écrire un lot, chercher s'il existe déjà**, dans `main` et sur les branches
  distantes. L'inventaire ci-dessous, et ce qui le suit, sert à ça.
- **Un lot (a), livrable sur le `main` actuel, n'est lancé que s'il marche avec ce qui existe
  déjà, et seulement après ses tests** (directeur, 08/11). C'est le pilote qui les attribue, un
  par un.
- **Un lot oublié est un blocage**, à annoncer au directeur le jour même (`CLAUDE.md`, « Vérité
  d'abord »). Ce n'est jamais un état normal.
- Ce fichier reste ouvert tant que la liste des lots (a) n'est pas vide.

## D'abord : ce qui est faux, inconnu ou non prouvé

- **Faux : la banque des noms de classes n'a jamais été codée** (cas 2). Elle a été demandée le
  25/10. Elle n'existe ni dans `main`, ni sur aucune branche distante, ni en production : ni fonction,
  ni table (lecture du pilote du 08/11, 04:12). **La liste des noms n'a jamais été proposée au
  directeur.** C'est le lot **NOMS-CLASSES**, confié à B le 08/11.
- **La recherche est livrée côté serveur, pas côté application** (cas 1). Le serveur est dans
  `main` et installé en production. L'application ne l'appelle pas : la recherche n'affiche aucun
  résultat.
- **Production : lu, pas essayé.** J'ai lu le catalogue de la base et la liste des fonctions Edge
  de production (lecture seule, 08/11). Je n'ai fait aucun appel réel à la recherche en production.
- **Les chiffres de branches** sont mesurés le 08/11 sur `origin/main` 13fc04c09, après avoir
  récupéré l'historique complet : le clone de la session était tronqué, et sans cet historique
  611 branches paraissaient sans histoire commune avec `main`.

## Cas 1 : la recherche

Les branches nommées par le pilote, toutes datées du 11 au 13/10 :

| Branche | Contenu déjà dans `main` ? |
| :-- | :-- |
| `claude/recherche`, `claude/rech-d5`, `claude/rech-fin` | **Oui, en entier** (la fusion de la branche avec `main` donne l'arbre de `main`) |
| `codex2/rech-back-1` à `rech-back-6`, `rech-back-3-wip`, `rech-back-3-ancien-wip`, `codex/backend-rech-back-4-negative-r1` | **Oui, en entier** |
| `codex/backend-recherche-classes` | Non : 1 commit, des curseurs de pagination signés dans une fonction Edge (`_shared/recherche/curseur.ts`). Conflit avec `main`. Remplacé par les curseurs SQL `rech_d1_curseur_*` de `main` (migration `20261012130003`) ; à confirmer à la reprise |
| `codex/backend-rech-d3-enseignants` | Non : la recherche d'enseignants dans les classes de la famille, résultats sans doublon. Conflit avec `main`, qui a déjà une fonction `recherche-enseignants` ; à comparer |

**Ce qui est en production (lu le 08/11, lecture seule) :**
- les fonctions SQL `rech_d1_rechercher_classes`, `rech_d1_rechercher_supports`,
  `rech_d4_rechercher_reference_finance`, `rech_d1_curseur_creer`, `rech_d1_curseur_lire`,
  `rech_session_autorisee` et `rechercher_personne_par_matricule` ;
- la fonction Edge `recherche-enseignants` (version 20, active).

**Ce qui manque dans `main`, côté application :**
- **Aucun adaptateur n'appelle ces fonctions**, à une exception près :
  `rechercher_personne_par_matricule`, lue par `lib/core/identite/matricule_supabase.dart`.
- Les moteurs de domaine (`lib/features/recherche/domaines/**`) ne sont branchés sur aucun
  adaptateur des fonctions `rech_*`.
- `moteursRechercheProvider` (`lib/core/recherche/port_recherche.dart:120`) vaut
  `const <MoteurRechercheDomaine>[]` en production. La loupe de l'en-tête est donc cachée
  (`rechercheServieProvider`, `app_router.dart:3240`) : la page `/recherche` ne rend aucun domaine
  (`INVENTAIRE-NON-BRANCHE-2026-10-31.md`).
- Ces moteurs sont tolérés non branchés dans `tool/branchement_tolere.txt`, avec pour échéance
  « l'étape Listes, après la boucle 1 », au 30/11/2026.

**Pour livrer** : écrire un adaptateur Supabase par domaine (classes, supports, enseignants,
finance), qui appelle les fonctions déjà en production ; puis remplir `moteursRechercheProvider`
en production ; enfin, tester. Aucune migration n'est nécessaire pour les domaines dont la fonction
existe. C'est le lot **RECHERCHE-LIVRAISON**, confié à H par le pilote le 08/11.

L'adaptateur de l'application n'a jamais été écrit ; H l'écrit (lot RECHERCHE-LIVRAISON, 08/11).

## Cas 2 : la banque des noms de classes

- **Décision** : directeur, 25/10/2026 (`BOUCLE-1_PLAN_2026-10-24.md` §5) : « Les classes sont
  nommées automatiquement par le système, depuis une bibliothèque de noms versionnée dans le
  dépôt : des noms de personnalités islamiques et historiques, simples à prononcer ; des noms
  féminins pour les groupes et classes féminins, des noms masculins pour les groupes et classes
  masculins. La direction ne saisit pas de nom ; elle peut le changer après coup. Chaque nom sert à
  une seule classe active à la fois. [...] proposée au directeur pour validation avant d'être
  versionnée. »
- **Ce qui existe** : rien. Le relevé du 02/11 (`RELEVES-2026-11-02/DEMANDES-ET-DEFAUTS.md` §2.8)
  le disait déjà : « aucune bibliothèque de noms ni fonction dans `supabase/`, `lib/`, `assets/` ».
  Je l'ai revérifié le 08/11 sur `main` et dans **toutes** les branches distantes, en cherchant
  « bibliothèque de noms », « noms de classes », `noms_classes`, `nom_automatique`, ainsi que des
  noms propres dans `supabase/`, `assets/` et `lib/core/`. Aucun code ne correspond.
- **En production** : le formulaire « Créer une classe » demande toujours un nom à la direction.
- **Pour livrer** :
  1. la liste des noms, proposée au directeur pour validation : c'est la seule étape qui attend son
     geste, et elle est exigée par sa décision du 25/10 ;
  2. un fichier de données versionné ;
  3. une migration qui choisit un nom libre dans la fonction de création de classe ;
  4. le champ nom rendu facultatif dans le formulaire.

## CODE PRÉSENT DANS MAIN MAIS NON BRANCHÉ

**Les mots du directeur (08/11/2026, 03:56, relayés par le pilote, mot pour mot)** :
« N'oublie pas le code non branché, tu commences à faire tout encore pour l'oublier ».

Les branches oubliées ne sont qu'une moitié du problème. L'autre moitié est déjà dans `main` : du
code présent mais qu'aucun chemin de l'application n'atteint en production.

**Raccord vide** : un provider ou un port qui, **en production**, est vide ou sert une
démonstration. L'écran existe et le serveur parfois aussi, mais rien ne les relie.
- *Exemple prouvé, la recherche* : `moteursRechercheProvider` vaut `const []` en production, donc
  la loupe est cachée (cas 1 ci-dessus).

Où trouver ce code :
- `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md` : le relevé du 31/10, par rôle. Il est en
  partie périmé ; une note datée du 08/11 dit ce qui a changé ;
- `tool/branchement_tolere.txt` : les fichiers de `lib/` sans chemin depuis `lib/main.dart`, avec
  leur échéance. La liste ne fait que rétrécir (`DECISION-BRANCHEMENT-2026-11-01.md`) ;
- le lot **NON-BRANCHE-LIVRAISON**, confié à A, qui fait le relevé détaillé des raccords vides et
  les livre ;
- le lot **RECHERCHE-LIVRAISON**, confié à H.

Ce fichier ne fait que renvoyer à ces sources. Le relevé détaillé est celui de A, dans son propre
lot.

## Inventaire des branches distantes (mesuré le 08/11)

Méthode du pilote : `git merge-tree --write-tree origin/main origin/<branche>`. Si l'arbre obtenu
est celui de `main`, tout le contenu de la branche est déjà livré, même après une fusion squash.

| État | Branches |
| :-- | --: |
| Tout le contenu est déjà dans `main` (écartées) | 584 |
| Fusion sans conflit, mais du contenu manque dans `main` | 70 |
| Conflit avec `main` (base trop vieille, ou contenu déjà repris autrement) | 230 |
| Sans histoire commune avec `main` | 5 |
| **Total** (hors `main` et `HEAD`) | **889** |

Le détail, branche par branche, est dans l'annexe `ALERTE-LOTS-NON-LIVRES-2026-11-08-ANNEXE.md`
(305 lignes, avec le verdict, la preuve et le dernier commit).

### Les verdicts (305 branches dont du contenu manque à `main`)

| Verdict | Branches | Ce que c'est |
| :-- | --: | :-- |
| (a) livrable sur le `main` actuel, tel quel ou presque | 22 | 2 lots de code, 4 outils, 16 documents (rapports, passations, revues) |
| (b) à reprendre | 77 | 75 lots serveur Codex du 09 au 13/10, et 2 lots Claude de novembre |
| (c) remplacé par autre chose déjà dans `main` | 167 | le lot est livré ; restent des captures, des preuves, ou des fichiers réécrits depuis dans `main` |
| (d) abandonné | 39 | archives, travail d'avant la remise à plat du 23/09, abandon écrit |

**Comment le verdict est prouvé** :
- Le verdict (c) est prouvé dans l'annexe par deux colonnes :
  - « Réécrit par » : le dernier commit de `main` qui a touché un fichier de la branche ;
  - « Livré par » : le commit de `main` qui contient au moins un fichier de la branche à
    l'identique.
- Le verdict (c) d'un lot livré par un train se lit dans le message du train. Par exemple, CAND-L1B
  et SALLE-1 sont nommés dans les trains G4 (`0081ee309`) et G5 (`225a957da`).

**Limite** : le verdict a été posé par des règles mécaniques, puis relu à la main pour les
42 branches Claude récentes. Les 75 branches Codex n'ont pas été relues une par une ; le paragraphe
« Lots serveur Codex » ci-dessous dit ce qui a été vérifié.

### Ce qui manque vraiment à `main` et compte pour l'école

*Correction du 08/11 (garde-cap)* : PHOTOS-2a, la fermeture du droit client d'écrire
`avatar_storage_key`, n'est **pas** un lot non livré. Elle est dans `main` et en production sous
`20261109300000_photos_2a_fermer_ecriture_avatar.sql` (`e7b9ce49c`, PR 212). Le numéro réservé
`20261107900000` n'a simplement jamais servi. La branche `claude/photos-ecrans` passe en (c).

1. **Recherche** (cas 1) : il manque l'adaptateur de l'application, le serveur est déjà là.
2. **Banque des noms de classes** (cas 2) : jamais codée.
3. **REVENUS, partie 2** (`claude/revenus`, 07/11), verdict (a) :
   - contenu : 3 commits absents de `main`. L'écran des revenus dit la présence de chaque élève
     telle que la paie la compte (présente, partielle, absente), et si une séance est payable ;
     il donne le total à recevoir hors attentes, et l'attente du cahier à part ;
   - migration : `20261110220000_revenus_presence`, une retouche par ancres de
     `mes_revenus_enseignant` ; elle n'a aucun mot d'effacement ;
   - conflit : seulement le code généré (`strings.g.dart`) ;
   - à vérifier avant toute fusion : que les ancres tiennent encore sur la fonction de `main`,
     réécrite par REVENUS-VERITE (`20261110200000`).
4. **PHOTO-CANDIDATURE-FIGEE** (`claude/photo-candidature-figee`, 07/11), verdict (b) :
   - contenu : la photo du dossier d'un candidat est figée à l'envoi des réponses ;
   - migration : `20261111200000`, réservée, jamais livrée ;
   - conflits : 6 fichiers.
5. **FLUIDITE-2** (`claude/fluidite-2`, 07/11), verdict (b) :
   - contenu : un fil de messages ouvert, et une annonce de classe, sont marqués lus tout de suite
     (`DECISION-FLUIDITE-2026-11-07`) ;
   - absent de `main` ; conflits : 2 fichiers (`app_mouvement`, `fil_discussion`).
6. **« classe » en minuscule** (`claude/classe-minuscule`, 06/11), verdict (a) :
   - contenu : le mot en minuscule au milieu d'une phrase (arbitrage du garde-cap du 06/11) ;
   - conflit : les textes fr seulement.

### Lots serveur Codex (75 branches, verdict b)

- **Contexte** : lots du 09 au 13/10, sur une base d'avant la reprise du back-end par Claude
  (17/10, `PASSATION-2026-10-17.md`).
- **Ce qui a été vérifié** : les noms des migrations absentes de `main`.
  - **La plupart existent dans `main` sous un autre numéro**, donc sont remplacées (c), par exemple :
    - `0078_kyc_super_admin_gender_exception`, devenue `0088_…` ;
    - `0057_signature_contrat_versionnee`, devenue `0086_…` ;
    - `cap29_*`, renumérotées le 11/10 ;
    - `f86_pairing_code_positive_guard`, remplacée par `20261012111500_f86_pairing_code_guard`.
  - **Une vingtaine n'ont aucun équivalent par le nom.** Ce sont surtout des gardes de sécurité, par
    exemple :
    - `disabled_account_access_guards` ;
    - `f86_teacher_profile_guard`, `f86_titulaire_profile_create_guard` ;
    - `f86_archive_listen_role_guard`, `f86_archive_retention_guard` ;
    - `f69_super_admin_controls` ;
    - `deleg_fin_1_server`.
- **Ne jamais les appliquer telles quelles** : elles réécrivent des fonctions que `main` a
  réécrites depuis, et les rejouer ferait revenir en arrière. **À reprendre** : comparer chacune
  avec la fonction en production, puis réécrire seulement la garde qui manque. Ce travail n'est pas
  fait ici.

### PR ouvertes oubliées

**34 PR sont ouvertes** (relevé du 08/11). 32 datent du 09/09 au 24/10 :
- refonte d'interface : PR 1 ;
- Codex `backend-*` : PR 10, 13, 17 et 20 à 32 ;
- Claude : PR 5, 7, 34, 35, 37 à 43, 45 et 50 ;
- site public : PR 8 et 44. Elles sont « dans les abysses » au sens du
directeur. Leur sort suit les verdicts de l'annexe, branche par branche ; les fermer revient au
pilote.

## Les lots (a), par ordre d'utilité pour l'école (VISION-ECOLE)

La vision met en premier le suivi de l'élève, une donnée saisie qui sert, et l'enseignant sans
corvée. Les lots (a) ci-dessous ne touchent presque jamais le suivi de l'élève ; ceux qui le
touchent sont en (b), ou ne sont pas codés (recherche, banque des noms).

| Rang | Branche | Ce qu'elle apporte | Avant la fusion |
| :-: | :-- | :-- | :-- |
| 1 | `claude/revenus` | L'enseignant voit la paie de chaque séance, juste et expliquée (VISION : pas de corvée, rien de faux) | Ancres sur `main` ; scénario `scenarios_revenus_presence` ; robot ; migration par le pilote |
| 2 | `claude/ci-propose` | 218 scénarios SQL rejoués par la CI au lieu de 30 : tout le reste est mieux protégé | Le pilote colle la liste dans `ci.yml` ; CI verte |
| 3 | `claude/page-push1` | La page des migrations refuse un fichier avec BEGIN; ou COMMIT; seul sur une ligne (leçon déjà payée) | Test de l'outil |
| 4 | `claude/classe-minuscule` | Textes corrects (arbitrage du 06/11) | Textes fr régénérés ; tests |
| 5 | `claude/harmoniser-argent` | Le relevé technique de la phase 1, cité par `REPONSES-HARMONISER-ARGENT` (section 6) | Aucun : document |
| 6 | `claude/sharp-goldberg-z10a13` (PR 40) | Simulation économique rejouée sur STAGING | Touche `supabase/seed` : ordre du pilote |
| 7 | `claude/page-salle3` | Modèle de page de migration (la migration visée est installée) | Aucun |
| 8 | documents (16) : passations, revues, rapports, captures | Mémoire, sans effet sur l'application | Aucun ; `claude/wizardly-babbage-lmhkog` pèse 665 captures, déconseillé |
| 9 | `claude/jolly-gauss-7rlt4y` (PR 42) | Compétences motion design | Aucun |

**Ordre recommandé au pilote, en comptant les (b) utiles :**
1. recherche ;
2. revenus ;
3. banque des noms, après validation de la liste par le directeur ;
4. FLUIDITE-2 ;
5. la liste des scénarios de la CI ;
6. le reste.

Chaque lot passe ses tests avant toute fusion (directeur, 08/11).
