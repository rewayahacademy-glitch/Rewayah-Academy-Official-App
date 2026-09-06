# Journal d'exécution - Étape 3

> Ce fichier dit **où en est le code** de l'étape 3, ce que valent les mesures,
> et quels pièges ont déjà coûté du temps.
> `docs/architecture/etape-3-auth-kyc.md` reste la spécification ; ce journal est
> son compte rendu. Mis à jour à la fin de chaque lot, jamais en bloc.

## État : en cours

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | Spécification `etape-3-auth-kyc.md` et ce journal | x |
| L1 | Migration 0004 : les cinq défauts, les tables et fonctions de l'étape | x |
| L2 | Porte `inscription` dans la session et le routeur | x |
| L3 | Connexion `TUT-00` et service d'authentification abstrait | |
| L4 | Onboarding en cartes `TUT-00c` | |
| L5 | KYC, contrat, accusé ADR-011, portail d'attente `TUT-00b` | |
| L6 | Appairage `TUT-02` et connexion enfant `ELV-01` | |
| L7 | Fonctions Edge : profil enfant, session enfant | |
| L8 | Validation des dossiers `ADM-02` | |
| L9 | Vérifications, CI, documentation | |

## Les douze scénarios d'acceptation

Voir la section 8 de la spécification. Aucun n'est coché tant qu'il n'est pas
mesuré : c'est la règle qui a coûté la découverte du défaut de CI à l'étape 1.

| # | Scénario | État | Où c'est vérifié |
| :-- | :--- | :--- | :--- |
| 1 | Compte sans profil : inscription et rien d'autre | vert | `test/router/redirection_test.dart`, 8 routes croisées plus les deux contrôles négatifs |
| 2 | Échec de lecture : portail d'attente, jamais l'inscription | vert | Même fichier, groupe « scénario 2 » |
| 3 | Inscription publique bornée à deux rôles et à `pending_kyc` | vert | `supabase/tests/scenarios_etape3.sql`, S3a à S3d |
| 4 | L'enseignant dépose sa pièce | vert | S4, S4b, S4c, sous RLS réelle |
| 5 | Genre du lecteur KYC inconnu : refus explicite | vert | S5a à S5d |
| 6 | Tablette partagée entre deux enfants | vert | S6 |
| 7 | Troisième appareil refusé par la base | vert | S7a, plus S7b sur la réactivation |
| 8 | Code d'appairage expiré ou consommé : refusé | vert | S8a, S8b, S8c |
| 9 | Le code personnel de l'enfant ne part jamais au réseau | | |
| 10 | Portail d'attente, quatre états | | |
| 11 | Bouton d'ajout absent à la limite, jamais en échec | | |
| 12 | Toujours une issue « Autre » | | |

Les scénarios SQL tournent sur un Postgres 17 nu, avec le stub `auth` versionné
dans `supabase/tests/stub_auth.sql`, et la CI les rejoue à chaque pull request.
Trente contrôles, tous verts au 6 septembre 2026.

## Pièges rencontrés, à ne pas repayer

Les pièges de poste hérités de l'étape 2 restent valables : voir
`etape-2-journal.md`, notamment le magasin de racines qui ne fait pas confiance à
`github.com` et qui fait échouer tout `dart run`.

### Le journal d'audit fuyait par sa partition

`audit_logs` est partitionnée. `alter table ... enable row level security` de
l'étape 1 ne protège **que le parent** : une partition porte sa propre RLS, et
`audit_logs_default` n'en avait aucune, alors que les droits par défaut de
Supabase l'accordent à `authenticated`.

Mesuré sur Postgres 17, pas déduit : un tuteur lit **0 ligne** par
`public.audit_logs` et **24** par `public.audit_logs_default`, dont chaque
consultation de dossier KYC avec le nom du lecteur. L'insertion de fausses
lignes était possible par le même chemin, les déclencheurs d'immuabilité ne
couvrant que la modification et la suppression.

Corrigé en activant la RLS sur la partition **sans y poser de policy** : une
requête sur le parent applique les policies du parent et ignore celles des
partitions, donc les lectures légitimes passent toujours et l'accès direct se
heurte au refus par défaut. `attacher_partition_audit()` est ajoutée pour que la
tâche mensuelle ne puisse pas réintroduire l'oubli.

**Leçon générale : activer la RLS sur une table partitionnée ne protège pas ses
partitions.** Le contrôle « aucune table sans RLS » doit compter les `relkind`
`r` **et** `p`, sinon il rate exactement ce cas.

### PL/pgSQL confond une colonne et un paramètre de sortie

`consommer_code_appairage` renvoie une colonne `profile_id`, qui est aussi une
colonne de `devices`. La clause `on conflict (profile_id, ...)` est une clause
d'inférence, donc une expression : PL/pgSQL y substitue ses variables et échoue
sur `column reference "profile_id" is ambiguous`. Le conflit se désigne par le
**nom de la contrainte**, pas par ses colonnes.

### Le refus doit précéder la journalisation, pas la suivre

Première écriture de `read_kyc_documents()` : journaliser, puis refuser si le
genre du lecteur est inconnu. Une exception annule la transaction, donc la trace
de la lecture était écrite puis effacée. On refuse d'abord, on journalise ce qui
va réellement sortir.

### Risque à vérifier quand l'étape D sera posée

`0001` fait `create extension if not exists pgcrypto` sans schéma, et appelle
`public.digest`. Sur un projet Supabase où pgcrypto est déjà installée dans le
schéma `extensions`, le `if not exists` ne fait rien et `public.digest` n'existe
pas : `0001` échouerait à la première application réelle. `0004` suit la même
convention, volontairement, pour qu'il n'y ait qu'un seul problème à corriger et
qu'une seule correction à faire. **À vérifier au premier `supabase db push`.**
