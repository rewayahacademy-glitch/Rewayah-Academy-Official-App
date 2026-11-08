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

- **Faux : la banque des noms de classes n'a jamais été codée.** Ni dans `main`, ni sur aucune
  branche distante (cas 2). Elle a été décidée le 25/10 ; ce qui manque, c'est le code, pas une
  livraison.
- **La recherche est livrée côté serveur, pas côté application** (cas 1). Le serveur est dans
  `main` et installé en production. L'application ne l'appelle pas : la recherche n'affiche aucun
  résultat.
- **Production : lu, pas essayé.** J'ai lu le catalogue de la base et la liste des fonctions Edge
  de production (lecture seule, 08/11). Je n'ai fait aucun appel réel à la recherche en production.
- **Les chiffres de branches** sont mesurés le 08/11 sur `origin/main` 225a957d, après avoir
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
- Les moteurs de domaine (`lib/features/recherche/domaines/**`) lisent des ports locaux, comme
  `PortGroupes`, qui sert des groupes de démonstration.
- `moteursRechercheProvider` (`lib/core/recherche/port_recherche.dart:120`) reste **vide en
  production**. La page de recherche (`/recherche`) s'ouvre, mais ne rend aucun domaine
  (`INVENTAIRE-NON-BRANCHE-2026-10-31.md`).
- Ces moteurs sont tolérés non branchés dans `tool/branchement_tolere.txt`, avec pour échéance
  « l'étape Listes, après la boucle 1 », au 30/11/2026.

**Pour livrer** : écrire un adaptateur Supabase par domaine (classes, supports, enseignants,
finance), qui appelle les fonctions déjà en production ; puis remplir `moteursRechercheProvider`
en production ; enfin, tester. Aucune migration n'est nécessaire pour les domaines dont la fonction
existe. **Attention** : le garde-fou refuse aux agents l'écriture des adaptateurs
`*_supabase.dart`. Ce lot demande donc un ordre explicite, ou que le pilote l'écrive lui-même.

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

Le détail par lot, avec ses verdicts (a, b, c, d) et le classement des lots (a), suit dans ce même
fichier, aux commits suivants de la PR.
