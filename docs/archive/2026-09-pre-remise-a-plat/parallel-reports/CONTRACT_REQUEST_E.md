# CONTRACT_REQUEST_E

Demandes de l'**Agent E** (onboarding et profil enseignant, `ENS-01` / `ENS-05`)
à l'**Agent Z**. Base : `BASELINE_SHA = 550e605`.

Chaque demande dit ce qui manque, pourquoi l'écran ne peut pas le combler
lui-même, et ce qui a été livré en attendant.

---

## 0. Ce qui a été appliqué en base, et qu'il faut committer

L'opérateur a donné une autorisation explicite d'écrire en base pendant cette
session. Deux migrations ont donc été **appliquées** sur le projet
`gggmtelinlpseweouyav` (vérifié par `get_project_url` avant écriture), et elles
ne sont **pas** dans `supabase/migrations/` : ce dossier appartient à l'Agent Z,
et un agent métier ne l'ouvre pas. **Il faut les y écrire telles quelles**, sinon
la base et le dépôt racontent deux histoires différentes et la CI, qui rejoue les
fichiers sur une base neuve, ne reproduira pas la production.

### `0027_maj_profil_enseignant.sql`

Ce qu'elle débloque, mesuré : `creer_profil_inscription()` reçoit `p_timezone`
mais ne l'emploie que pour `households` ; pour un enseignant elle fait
`insert into teacher_profiles (profile_id)` et laisse le défaut
`'Europe/Paris'`. La seule policy du titulaire est `teacher_profiles_self`, en
`SELECT`. Conséquence : **un enseignant hors d'Europe ne pouvait jamais corriger
son fuseau**, alors que `mon_fuseau()` fait loi sur sa grille de disponibilités.

Pourquoi une fonction et non une policy `UPDATE` : une policy borne les LIGNES,
pas les COLONNES. Bornée à `profile_id = auth.uid()`, elle aurait laissé
l'enseignant relever son propre `weekly_hours_cap`, qui est contractuel.

```sql
create or replace function public.maj_profil_enseignant(
  p_country text default null,
  p_languages text[] default null,
  p_timezone text default null
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentification requise';
  end if;

  if p_timezone is not null
     and not exists (
       select 1 from pg_catalog.pg_timezone_names z where z.name = p_timezone
     ) then
    raise exception 'fuseau inconnu';
  end if;

  update public.teacher_profiles t
     set country = coalesce(p_country, t.country),
         languages = coalesce(p_languages, t.languages),
         timezone_iana = coalesce(p_timezone, t.timezone_iana)
   where t.profile_id = v_uid
     and t.deleted_at is null;

  if not found then
    raise exception 'aucun profil enseignant';
  end if;
end;
$$;

comment on function public.maj_profil_enseignant(text, text[], text) is
  'ENS-05 : ecriture bornee aux trois champs non sensibles du profil enseignant (pays, langues, fuseau). Jamais weekly_hours_cap ni kyc_status.';

revoke all on function public.maj_profil_enseignant(text, text[], text) from public;
grant execute on function public.maj_profil_enseignant(text, text[], text) to authenticated;
```

Fonction **volatile** : aucun `grant execute` à `agent_ro`, jamais. Vérifié après
application : `has_function_privilege('agent_ro', ..., 'execute')` rend `false`.

### `0028_maj_profil_enseignant_revoke_anon.sql`

```sql
revoke execute on function public.maj_profil_enseignant(text, text[], text) from anon;
```

**À lire, parce que ce n'est pas le défaut que `0026` a corrigé, et que la leçon
est plus large.** Mesure prise juste après l'application de `0027`, dont le
`revoke all ... from public` est correctement écrit :

```
proacl   = {postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
anon_peut = true
```

`0026` avait établi que `revoke ... from anon` ne retire rien quand le droit est
hérité de `PUBLIC`. Ici c'est l'inverse : Supabase pose un
`alter default privileges ... grant execute on functions to anon` sur le schéma
`public`, donc `anon` détient un droit **nominal**, et révoquer `PUBLIC` ne le
retire pas. Les deux formules sont nécessaires, et aucune des deux ne suffit.

**Le seul contrôle qui vaut, après chaque création de fonction sur ce projet, est
`has_function_privilege('anon', ..., 'execute')`, jamais la lecture du `revoke`
écrit dans le fichier.** Ni `get_advisors` ni la relecture ne voient cette faute.
Après `0028` : `anon_peut = false`, `authenticated = true`, `agent_ro = false`.

Aucune donnée n'a été exposée dans l'intervalle : la fonction lève
`authentification requise` quand `auth.uid()` est nul. C'était une surface
d'appel de trop, pas une fuite.

---

## 1. Deux accusés séparément opposables (ADR-011) — NON fait, et pourquoi

`signature_page.dart` écrit **une seule** acceptation
`recording_and_control_notice` qui porte à la fois l'enregistrement audio et la
visite de contrôle. Le protocole demande deux accusés explicites.

**L'autorisation d'écrire en base ne suffit pas à le faire.** Ce qu'il faudrait :

1. deux valeurs de `contract_acceptances.contract_kind` et le `check` SQL
   correspondant (`0004:224-228`) — migration, faisable ;
2. deux valeurs de plus dans `SorteContrat` — `lib/core/domain/enums.dart`,
   **Agent Z** ;
3. `etat_dossier()` ne teste qu'une seule sorte (`0004:466-470`) : il faudrait
   qu'elle en exige deux **pour un enseignant seulement**, sinon le parcours du
   **tuteur** change, ce que le périmètre de l'Agent E interdit absolument ;
4. une valeur de plus dans `PieceManquante` — `lib/core/dossier/etat_dossier.dart`,
   **Agent Z**.

Appliquer seulement le point 1 aurait créé en production une valeur de
`contract_kind` qu'aucune ligne de Dart ne peut produire ni lire : une porte
ouverte sur rien. La demande reste donc entière, et elle est **de l'Agent Z de
bout en bout**.

**Ce qui est livré en attendant** : les deux points sont dits explicitement et
lisiblement, chacun pour lui-même, sur `ENS-01`
(`t.contrat.pointEnregistrement` et `t.contrat.pointControle`), et un test le
mesure. Qu'ils soient montrés trois fois — accusé, contrat, bienvenue — est
conforme à l'ADR-011, qui le veut, et non un doublon.

---

## 2. Le fuseau reste en lecture, faute d'un inventaire décidé

`maj_profil_enseignant` accepte `p_timezone` et la base valide le libellé contre
`pg_timezone_names`. **L'écran ne l'écrit pourtant pas**, et c'est délibéré :
aucun inventaire de fuseaux n'est tranché dans le produit, et un champ libre où
l'enseignant devrait deviner `Africa/Conakry` refuserait des saisies qu'il ne peut
pas inventer. Le repli `'Europe/Paris'` est déjà codé en dur en six endroits ;
un septième chemin, à l'écran, ne vaudrait pas mieux.

**Décision opérateur demandée** : liste fermée de fuseaux (lesquels ?), ou
déduction depuis le pays déclaré, ou recherche libre avec autocomplétion. Tant
qu'elle n'est pas écrite, `ENS-05` affiche le fuseau en lecture via
`monFuseauProvider` et dit à quoi il sert.

`country` et `languages` sont, eux, du texte libre en base : un champ libre y dit
exactement ce que la colonne accepte, et l'écran les édite.

---

## 3. `ProfilEnseignant` ne porte pas `timezone_iana`

`service_profil_enseignant.dart:142-145` ne le sélectionne pas, alors que la
colonne existe depuis `0005`. `ENS-05` fait donc **deux** lectures là où une
suffirait : `profilEnseignantProvider` pour le profil, `monFuseauProvider` pour
le fuseau.

Demande : ajouter `timezone_iana` au `select` et un champ `fuseau` à
`ProfilEnseignant`. `lib/core/profil/` est à l'Agent Z.

---

## 4. Deux contrats Dart à promouvoir dans `lib/core/`

Ils sont nés dans `lib/features/profil_enseignant/` parce que c'est le seul
endroit où l'Agent E peut écrire, et ils n'y sont pas à leur place si un autre
écran en a besoin :

| Fichier | Ce qu'il porte | Pourquoi il existe |
| :--- | :--- | :--- |
| `service_acceptations.dart` | `Acceptation`, `ServiceAcceptations`, `acceptationsProvider` | la policy `contract_acceptances_self_read` autorise la lecture depuis `0004` ; **aucune classe Dart ne l'exposait**. Sans elle, un enseignant validé ne peut plus relire son contrat du tout, `deciderRedirection` fermant `/attente/*` |
| `service_declaration.dart` | `ServiceDeclarationEnseignant`, `serviceDeclarationProvider` | l'unique porte d'écriture ouverte au titulaire, sur `maj_profil_enseignant` |

Aucune migration n'a été nécessaire pour le premier : la donnée était lisible, il
manquait de quoi l'afficher.

---

## 5. Deux faux à promouvoir dans le harnais

`test/support/harnais.dart` appartient à l'Agent Z, et `TEACHER_SHARED_CONTRACTS.md`
§11 annonçait un `FauxServiceProfil…` qui **n'y est pas**. Ont donc été écrits
dans `test/features/profil_enseignant_test.dart` :

- `_FauxDeclaration` (implémente `ServiceDeclarationEnseignant`, enregistre les
  écritures champ par champ, sait échouer) ;
- rien pour les acceptations : `acceptationsProvider` est surchargé directement,
  ce qui suffit et n'ajoute pas de classe.

À promouvoir si un autre écran touche ces contrats. Le profil lui-même se
surcharge par `profilEnseignantProvider.overrideWith(...)`, sans faux du tout.

---

## 6. La bienvenue ne sait pas qu'elle a été vue

`Routes.enseignantBienvenue` existe, `BienvenueEnseignantPage` est livrée, mais
**rien ne mémorise la traversée** et rien n'y mène. Trois choses manquent, toutes
hors du périmètre de l'Agent E :

1. la route dans `app_router.dart` — la constante existe, la `GoRoute` non. Elle
   doit vivre **hors** des trois branches de la coquille, sinon la bienvenue
   devient une quatrième destination ;
2. un moyen de ne la montrer qu'une fois. `AppDatabase` est gelée à quatre
   tables et `PreferencesLocales` ne vaut que pour l'appareil courant : sur un
   second appareil, la bienvenue réapparaîtrait. Un drapeau serveur sur
   `profiles` est le seul support honnête, et c'est une migration + `core/` ;
3. l'enchaînement « dossier validé → bienvenue », dans `redirection.dart`.

En attendant, l'écran est complet et sans effet de bord : il ne s'auto-navigue
pas, il ne mémorise rien, et il se comporte correctement s'il est atteint deux
fois.

---

## 7. Deux états de compte qui n'existent pas en base

- **« correction demandée » ne se distingue pas de « refusé »** :
  `EtapeDossier` n'a que `incomplet / enVerification / refuse / suspendu`, et
  `etat_dossier()` ne rend que `kyc_documents.status in (pending, approved,
  rejected)`. Un refus définitif et une demande de correction se disent
  aujourd'hui par le même état, avec le motif pour seule différence. **Décision
  opérateur**, pas décision d'agent : la fiche `ENS-01` l'écrit déjà comme
  ouverte.
- **« expiré » n'existe pas** pour un enseignant : `AccountStatus` n'a pas de
  valeur `expired`, et `profiles.access_until` n'est lu que pour un élève
  (`service_appairage.dart:111`). Le cas voisin est `provisionalActive` avec
  `kyc_completion_deadline`, qui ne coupe rien (ADR-014). `ENS-05` rend donc les
  **cinq** lectures qui existent réellement — les quatre valeurs d'`AccountStatus`
  plus le cas illisible — et pas une sixième inventée.

---

## 8. `VerificationEnseignant` duplique `StatutPiece`

Mêmes trois valeurs SQL (`pending` / `approved` / `rejected`), même `depuisSql`,
mais déclarée dans `lib/core/profil/service_profil_enseignant.dart:99` au lieu de
`lib/core/domain/enums.dart` où vivent tous les autres miroirs SQL. `ENS-05`
emploie l'existant et n'ajoute pas un troisième miroir ; le rangement est à
l'Agent Z.

---

## 9. Les chaînes

`docs/parallel-reports/i18n_E.json` est à fusionner tel quel. Il déclare
`enseignant.profil.*` (complété) et `enseignant.bienvenue.*` (neuf).

**Quatre des six clés `enseignant.profil.*` existantes ne sont pas réemployées** :
`chargePedagogique`, `elevesActifs`, `heuresDisponibles` et `reglagesHeures`
nomment de la charge opérationnelle et des créneaux, que la fiche `ENS-05` exclut
explicitement du Profil (« disponibilités opérationnelles : `ENS-06`, et nulle
part ailleurs »). `titre` et `compteValide` sont réemployées. Les quatre autres
n'ont plus d'appelant : à supprimer de `fr.i18n.json`, ou à laisser si `ENS-02` /
`ENS-06` les reprennent — c'est l'Agent Z qui voit les deux côtés. **Aucun test
de l'Agent E ne les référence** : la régression « le Profil refabrique ses
chiffres » est mesurée sur le widget (`find.byType(StatTile)`), pas sur une
chaîne, précisément pour que ces quatre clés puissent disparaître sans casser
quoi que ce soit.
