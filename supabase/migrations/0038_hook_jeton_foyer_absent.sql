-- 0038 -- Le hook de jeton rendait NULL pour qui n'a pas de foyer
--
-- ============================================================
-- LE DEFAUT, MESURE EN PRODUCTION LE 21 SEPTEMBRE 2026
-- ============================================================
--
-- Quatre enseignants attendaient a la porte. Ils avaient depose SEIZE fichiers
-- dans le seau `kyc` sans qu'une seule ligne `kyc_documents` puisse etre creee.
-- Le seau existait, la policy `kyc_staff_self_insert` existait et etait juste,
-- le declencheur `completer_kyc_document()` ne refusait rien : une sonde sous
-- l'identite de l'un d'eux, avec un jeton portant `app_metadata.role`, a insere
-- sans broncher. Sans ce claim, la meme sonde rendait
-- `42501 new row violates row-level security policy`.
--
-- La cause est dans ce hook, a la ligne qui posait `household_id` :
--
--     claims := jsonb_set(claims, '{app_metadata, household_id}',
--                         to_jsonb(v_profile.household_id::text));
--
-- `to_jsonb()` est STRICT : `to_jsonb(NULL::text)` rend SQL NULL, et non le
-- jsonb `null` que la lecture naive suppose. `jsonb_set()` est STRICT aussi :
-- une nouvelle valeur a NULL fait rendre NULL a tout l'appel. Donc, pour un
-- profil sans foyer, `claims` devenait SQL NULL, puis le `jsonb_set` final
-- annulait le retour entier : **le hook rendait NULL**. Mesure :
--
--     custom_access_token_hook(<enseignant, household_id NULL>)  -> null
--     custom_access_token_hook(<tuteur, household_id present>)   -> {claims: ...}
--
-- Auth qui recoit NULL d'un hook emet quand meme un jeton, simplement SANS
-- revendication. `app_role()` ne lit rien d'autre que
-- `auth.jwt() -> 'app_metadata' ->> 'role'` : elle rendait donc NULL, et toute
-- policy qui en depend se fermait -- en silence, sans message, sans trace.
--
-- Qui etait touche : `profiles_household_required` (0004) autorise un
-- `household_id` NULL pour exactement quatre roles -- `admin`, `accountant`,
-- `controller`, `teacher`. Ce sont eux, et eux seuls, que ce defaut fermait.
-- Un tuteur et un eleve ont toujours un foyer, donc le chemin par lequel
-- l'application avait ete essayee n'a jamais rencontre le defaut. L'unique
-- administrateur de production a, par hasard, un foyer : voila pourquoi
-- personne ne l'avait vu. Le role enseignant (huit ecrans livres le 20
-- septembre) et le role controleur (livre le 13 septembre) etaient donc inertes
-- en production depuis leur livraison.
--
-- C'est la meme famille de defaut que `0029` et que le `p_gel` a NULL de
-- `0034` : une inconnue qui traverse et ferme tout, sans rien dire. La regle du
-- depot est d'ecrire les portes en EXIGENCE POSITIVE ; ici il fallait surtout
-- ne jamais laisser un NULL remonter jusqu'au retour d'une fonction dont
-- l'appelant ne sait pas lire l'echec.

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  claims jsonb;
  user_id uuid := (event ->> 'user_id')::uuid;
  v_profile public.profiles;
begin
  select * into v_profile
  from public.profiles
  where public.profiles.id = user_id
    and public.profiles.deleted_at is null;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  if v_profile.id is not null then
    -- Exigence POSITIVE : on ne repart de `{}` que si `app_metadata` est bien
    -- un objet. La garde d'origine testait `jsonb_typeof(...) is null`, ce qui
    -- ne voyait que la cle ABSENTE ; une cle presente valant `null`, un nombre
    -- ou une chaine la passait, et les `jsonb_set` suivants restaient alors
    -- sans effet -- le jeton partait sans role, du meme silence que ci-dessus.
    if coalesce(jsonb_typeof(claims -> 'app_metadata'), 'absent') <> 'object' then
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
    end if;

    -- `coalesce` sur chacune des deux valeurs : c'est le correctif. Un foyer
    -- absent devient le jsonb `null`, que les deux seuls lecteurs de ce claim
    -- traitent deja comme une absence -- `app_household_id()` par
    -- `->> 'household_id'` puis `nullif`, et `ClaimsJwt.depuisJeton` par un
    -- transtypage nullable. La cle reste donc toujours presente, et sa forme ne
    -- depend plus de qui se connecte.
    --
    -- `profiles.role` est `not null`, donc son `coalesce` ne se declenchera
    -- jamais. Il est la quand meme : le jour ou une colonne deviendrait
    -- nullable, le defaut ne doit pas pouvoir revenir par la meme porte.
    claims := jsonb_set(
      claims,
      '{app_metadata, role}',
      coalesce(to_jsonb(v_profile.role::text), 'null'::jsonb)
    );
    claims := jsonb_set(
      claims,
      '{app_metadata, household_id}',
      coalesce(to_jsonb(v_profile.household_id::text), 'null'::jsonb)
    );
  end if;

  -- Dernier filet. Ce hook doit rendre l'evenement, jamais NULL : un NULL ne
  -- provoque pas d'erreur visible, il produit un jeton muet et une application
  -- entierement fermee. Si une expression inattendue annulait encore `claims`,
  -- l'evenement repart tel qu'il est arrive -- Auth emet alors le jeton avec
  -- les revendications qu'il avait deja, ce qui est degrade mais jamais muet.
  return coalesce(jsonb_set(event, '{claims}', claims), event);
end;
$$;

comment on function public.custom_access_token_hook(jsonb) is
  'Pose app_metadata.role et app_metadata.household_id dans le jeton d''acces. Ne rend JAMAIS NULL : un hook qui rend NULL fait emettre par Auth un jeton sans revendication, et app_role() ferme alors toutes les policies en silence (defaut mesure le 21 septembre 2026, corrige par 0038).';

-- `create or replace` conserve les privileges existants ; on les rejoue tout de
-- meme, pour que ce fichier dise a lui seul qui peut appeler ce hook. Le double
-- `revoke` (`from public` ET `from anon`) est la lecon de `0028` : sur Supabase,
-- l'EXECUTE arrive par deux chemins et aucun des deux retraits ne suffit seul.
revoke execute on function public.custom_access_token_hook(jsonb)
  from anon, authenticated, public;

grant execute on function public.custom_access_token_hook(jsonb)
  to supabase_auth_admin;

-- ============================================================
-- Verification de sortie
-- ============================================================
--
-- Le controle fonctionnel complet -- un enseignant sans foyer obtient bien son
-- role -- exige des profils, et vit donc dans
-- `supabase/tests/scenarios_hook_jeton.sql`. Ici on verifie ce qui se verifie
-- sans fixture : que le hook ne rend pas NULL, que les deux primitives qui ont
-- cause la panne se comportent toujours comme mesure, et que le hook n'est
-- ouvert qu'a `supabase_auth_admin`.

do $$
declare
  v_retour jsonb;
  v_inconnu uuid := '00000000-0000-0000-0000-000000000000';
begin
  if to_jsonb(null::text) is not null then
    raise exception '0038 ECHEC : to_jsonb(NULL) ne rend plus SQL NULL, revoir le correctif';
  end if;

  if jsonb_set('{"a":1}'::jsonb, '{b}', null) is not null then
    raise exception '0038 ECHEC : jsonb_set ne propage plus NULL, revoir le correctif';
  end if;

  if coalesce(to_jsonb(null::text), 'null'::jsonb) is null then
    raise exception '0038 ECHEC : le coalesce ne neutralise pas to_jsonb(NULL)';
  end if;

  v_retour := public.custom_access_token_hook(
    jsonb_build_object('user_id', v_inconnu,
                       'claims', jsonb_build_object('sub', v_inconnu))
  );
  if v_retour is null then
    raise exception '0038 ECHEC : le hook rend NULL pour un compte inconnu';
  end if;

  if to_regprocedure('public.custom_access_token_hook(jsonb)') is null
     or not has_function_privilege('supabase_auth_admin',
            'public.custom_access_token_hook(jsonb)', 'execute')
     or has_function_privilege('authenticated',
            'public.custom_access_token_hook(jsonb)', 'execute')
     or has_function_privilege('anon',
            'public.custom_access_token_hook(jsonb)', 'execute') then
    raise exception '0038 ECHEC : le hook n''est pas reserve au seul supabase_auth_admin';
  end if;
end $$;
