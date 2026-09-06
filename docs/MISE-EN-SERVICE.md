# MISE EN SERVICE — ce qui tourne pour de vrai, et ce qui manque encore

> Etabli le **7 septembre 2026**, pendant que le lot L8 etait en cours.
> Ce fichier est neuf et volontairement separe : il ne touche ni `HANDOFF.md`
> ni `PROGRESS.md`, que le lot L8 va modifier de son cote.
>
> **A reporter dans `docs/PROGRESS.md` au lot L10** : les lignes C, D et M du
> tableau d'onboarding, et la ligne « Plateforme Android 37 » des decisions en
> attente, ne disent plus la verite. Ce fichier dit ce qu'elles doivent devenir.

## 1. Ce qui est en service

| Quoi | Ou | Etat |
| :--- | :--- | :--- |
| Base Supabase | `gggmtelinlpseweouyav`, eu-west-1, plan gratuit | migrations `0001` a `0005` appliquees |
| Fonctions Edge | `creer-profil-enfant`, `session-enfant` | deployees, `ACTIVE`, `verify_jwt = true` |
| Application web (PWA) | <https://rewayah-academy.vercel.app> | en ligne, chargee sans erreur console |
| Configuration locale | `dart_define.json` | ecrit, ignore par git, cle **publiable** |

L'application a ete construite depuis le commit **`761450a`** (fin du lot L7),
pas depuis le repertoire de travail : le lot L8 etait en cours d'ecriture, et on
ne met pas en ligne du code a moitie ecrit.

### Ce qui a ete verifie sur la base reelle, et non suppose

34 tables, **aucune sans RLS**, 9 vues, 243 fonctions, 74 policies, 2 seaux de
stockage tous deux prives (`kyc`, `avatars`), 18 lignes d'`app_config`.

## 2. Le defaut qui aurait fait tomber le premier `db push`

Le risque note au journal de l'etape 3 etait reel, et il est corrige.

`pgcrypto` **n'est pas installee dans `public` chez Supabase, mais dans
`extensions`**. La migration `0001` faisait `create extension if not exists
pgcrypto` sans schema : sur un projet reel l'extension existe deja, la commande
ne fait donc rien **et ne signale rien**, puis le premier appel a `public.digest`
echoue. Tout le chainage du journal d'audit en depend, et l'appairage des
appareils aussi (`0004`).

La correction vaut des deux cotes, sans embranchement :

```sql
create schema if not exists extensions;              -- ne fait rien chez Supabase
create extension if not exists pgcrypto with schema extensions;
grant usage on schema extensions to public;
```

et tous les appels sont qualifies `extensions.digest(...)` /
`extensions.gen_random_bytes(...)`, parce que chaque fonction de ce depot porte
`set search_path = ''` : rien n'y est resolu implicitement.

**Mesure** : sur un Postgres 17 neuf, migrations `0001` a `0005` puis **34 puis
37 controles verts, zero erreur** — la reference d'avant la correction, intacte.

## 3. Deux commandes restent a votre main

Elles ont ete refusees a l'agent par la barriere de securite du poste, qui
bloque toute ecriture de secret et toute modification de configuration Auth
distante. Elles sont a lancer telles quelles depuis `D:\RA _APP\RA -OFFICIAL-APP`,
avec `SUPABASE_ACCESS_TOKEN` dans l'environnement.

### 3.1 Le hook de jeton, sans lequel RIEN ne s'affiche

C'est la plus importante des deux. `app_role()` et `app_household_id()` lisent
le role et le foyer **dans le jeton**. Sans le hook, ces deux fonctions rendent
`null`, **toutes les policies refusent**, et l'application se connecte
correctement pour n'afficher que des ecrans vides. Aucune erreur n'apparait :
c'est le mode de panne le plus couteux a diagnostiquer.

```powershell
supabase config push --project-ref gggmtelinlpseweouyav --yes
```

`supabase/config.toml` porte deja le bon reglage, **corrige** : l'URI y etait
ecrite `pg-functions://gggmtelinlpseweouyav/...` alors que le premier segment
est le nom de la **base**, toujours `postgres`. Cette commande pousse aussi
`site_url` et la liste des redirections vers l'adresse de la PWA.

A defaut de la CLI : tableau de bord, Authentication, Hooks, « Customize Access
Token (JWT) Claims », choisir `public.custom_access_token_hook`.

### 3.2 Le domaine de courriel des comptes enfants

Sans lui, `creer-profil-enfant` repond `500 configuration absente`, donc aucun
enfant ne peut etre cree.

```powershell
supabase secrets set STUDENT_EMAIL_DOMAIN=eleves.rewayahacademy.com --project-ref gggmtelinlpseweouyav
```

La valeur proposee suit ce que dit le code : « un domaine qu'il maitrise et qui
ne recevra jamais de courrier ». Elle se change librement **tant qu'aucun compte
enfant n'existe** ; apres, elle est inscrite dans l'identite des comptes.

## 4. Ce qui reste ouvert, et qui n'est pas du code

| Sujet | Etat | Ce qu'il faut |
| :--- | :--- | :--- |
| Envoi des liens de connexion | **bloquant pour un vrai usager** | Le SMTP integre du plan gratuit est limite a 2 messages par heure et **n'accepte que les adresses de l'equipe du projet**. Vous-meme recevrez donc vos liens ; personne d'autre. Il faut un SMTP externe (`[auth.email.smtp]` dans `config.toml`) |
| Connexion Google | non configuree | Un identifiant OAuth Google Cloud (gratuit), puis les clefs cote Supabase |
| Lien magique sur l'APK Android | ne revient pas dans l'application | L'application ne declare aucun schema de lien profond et n'envoie pas de `emailRedirectTo`. Sur la **PWA** le retour fonctionne, c'est pourquoi elle est la voie recommandee |
| APK Android | **impossible sur ce poste** | Voir ci-dessous : ce n'est pas la plateforme du SDK, c'est le magasin de certificats |
| iOS natif | impossible depuis ce poste | Un Mac avec Xcode et un compte developpeur Apple. La PWA couvre l'iPad par « Ajouter a l'ecran d'accueil » |
| Hebergement Vercel | plan Hobby, gratuit | Le plan Hobby exclut l'usage commercial : a basculer avant l'ouverture payante |
| Inscriptions ouvertes | `enable_signup = true` | N'importe qui peut creer un compte sur l'adresse publique. Le risque est borne : tout compte naît `pending_kyc` et ne voit rien avant validation |

### 4.1 L'APK ne bute pas sur ce que le handoff annoncait

Le handoff attribuait l'echec du build APK a la plateforme du SDK et prescrivait
`sdkmanager "platforms;android-37"`. **Les deux sont faux**, mesure a l'appui :

- La commande repond `Warning: Failed to find package platforms;android-37`.
  Ce paquet n'existe pas sous ce nom : Google publie desormais `android-37.0`,
  qui est deja installe. Le SDK n'est pas en cause, et la ligne « Plateforme
  Android 37 » du tableau des decisions en attente est a retirer.
- Le build s'arrete en realite sur le **magasin de certificats** : le hook de
  `package:sqlite3` ne peut pas telecharger `libsqlite3.arm.android.so` depuis
  `github.com` (`CERTIFICATE_VERIFY_FAILED`). Ce que le journal de l'etape 2
  notait pour `dart run` vaut donc aussi pour le build Android.
- Et ce n'est pas un defaut de Dart : `Invoke-WebRequest` sur la meme adresse
  echoue pareillement, avec « Impossible d'etablir une relation de confiance
  pour le canal securise SSL/TLS ». **C'est le poste entier qui ne fait pas
  confiance a `github.com`**, pas l'outillage Flutter. La reparation est du
  cote du magasin de racines Windows, ou d'un antivirus qui intercepte le TLS.

Rien de tout cela ne se contourne en desactivant la verification des
certificats : ce serait echanger un build contre une porte ouverte.

Meme repare, l'APK aurait un defaut d'usage : le lien de connexion arrive dans
le navigateur et **ne revient pas dans l'application**, faute de lien profond
declare. La PWA n'a pas ce probleme.

## 5. Consequence a ne pas oublier : `0005` est desormais appliquee

Jusqu'ici la convention etait « `0005` se corrige sur place », puisqu'elle
n'existait nulle part en reel. **Ce n'est plus vrai.** La version appliquee est
celle du commit `761450a`, et les cinq migrations sont inscrites dans
`supabase_migrations.schema_migrations` (versions `0001` a `0005`).

Le lot L8, commite depuis, a modifie **deux objets** de `0005` : un correctif
reel (la semaine de reference s'ancre en UTC et non dans le fuseau de la ligne)
et une colonne ajoutee a `profils_du_foyer_v`. **La base reelle porte encore
l'ancienne version des deux.**

Les deux sont des remplacements, sans destruction et sans perte de droits. A
coller tel quel dans l'editeur SQL du tableau de bord — l'agent n'a pas pu le
faire, la barriere du poste ayant fini par bloquer aussi les ecritures SQL :

```sql
begin;

-- 1. La semaine de reference s'ancre en UTC, et non dans le fuseau de la ligne.
create or replace function public.instant_creneau(
  p_weekday int, p_hour int, p_tz text, p_semaine_offset int default 0
) returns timestamptz
language sql stable set search_path = ''
as $$
  select ((date_trunc('week', (now() at time zone 'UTC'))::date
           + (p_weekday - 1) + (p_semaine_offset * 7))::timestamp
          + make_interval(hours => p_hour)) at time zone p_tz;
$$;

-- 2. profils_du_foyer_v porte la date de fin d'acces, que TUT-01 affiche.
create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select p.id, p.first_name, p.immutable_id, sp.interface_mode,
       sp.camera_policy, sp.avatar_storage_key, p.access_until
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null;

commit;
```

**A partir de maintenant, tout changement structurel passe par une migration
`0006` et suivantes.** Corriger `0005` sur place ne se voit plus nulle part :
la base reelle ne la rejouera jamais.

## 6. Ce qui a ete constate en regardant l'application en ligne

- Elle demarre, initialise Supabase et route jusqu'a `/#/connexion` **sans une
  seule erreur console**.
- Sur une fenetre large (1366 px), le contenu reste dans une colonne d'environ
  500 px **collee a gauche**, les deux tiers restants vides. C'est ce que verra
  un iPad en paysage. Le produit est concu mobile d'abord et la mesure de
  reference du projet est 390x844 ; il n'y a donc pas de defaut de conformite,
  mais il y a un ecran a dessiner pour les grandes largeurs.
- Le manifeste et `index.html` etaient encore ceux du gabarit Flutter (« A new
  Flutter project », bleu `#0175C2`). Ils portent desormais le nom, la
  description, la palette (`#8652E6` sur `#F1E3E4`) et, surtout, **la balise
  `viewport` qui manquait** : sans elle, Safari sur iPad rend la page dans une
  fenetre virtuelle de 980 px et l'application arrive miniaturisee.

## 7. Refaire un deploiement

```powershell
cd "D:\ra-pwa-build"                 # copie de travail detachee, hors du depot de travail
git fetch origin ; git checkout <commit vert>
flutter pub get ; dart run slang ; dart run build_runner build
flutter build web --release --dart-define-from-file=dart_define.json
Copy-Item "D:\RA _APP\RA -OFFICIAL-APP\web\vercel.json" ".\build\web\vercel.json"
cd ".\build\web" ; vercel deploy --prod --yes
```

La copie `D:\ra-pwa-build` est un `git worktree` detache du depot principal :
elle sert a construire sans jamais compiler le travail en cours d'une autre
session. `git worktree remove "D:\ra-pwa-build"` la supprime.
