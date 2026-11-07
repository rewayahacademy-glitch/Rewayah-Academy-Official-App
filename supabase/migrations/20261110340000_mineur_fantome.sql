-- MINEUR-FANTOME (06 et 07/11/2026, decisions du directeur relayees par le
-- garde-cap et le pilote) : `creer_profil_enfant` ne cree plus de profil eleve
-- MINEUR pour un adulte, et enregistre le genre de l'enfant.
--
-- Fichier SANS mot d'effacement (regle B5) : le pilote l'installe.
--
-- Constat (lecture seule en production, 06/11/2026) : deux adultes inscrits
-- « pour moi » ont un profil eleve mineur a leurs propres prenom et nom, cree
-- par « Ajouter un profil eleve ». La fonction acceptait jusqu'a 99 ans et
-- posait toujours student_type = 'minor'.
--
-- Retouches PAR ANCRES (regle B4, pg_temp.remplacer) de la seule surcharge a
-- sept parametres, qui porte toute la logique ; celle a six parametres
-- delegue et ne change pas. Aucune nouvelle surcharge, aucun retrait de fonction :
--   1. 18 ans ou plus : refus (« age adulte : … », check_violation).
--   2. prenom + nom identiques a ceux du titulaire appelant, sans casse, sans
--      accents latins courants ni espaces doubles : refus (« profil du
--      titulaire : … »).
--   3. le genre : lu dans auth.users.raw_app_meta_data.gender (la fonction
--      Edge creer-profil-enfant l'y pose a cote de child_of ; jamais
--      user_metadata), refuse s'il n'est pas une valeur de public.gender
--      (« genre_requis »), ecrit dans profiles.gender. ABSENT, il reste
--      accepte (regle B6 : l'ancienne fonction Edge, encore en service tant
--      que l'application n'est pas deployee, ne l'envoie pas). L'obligation
--      vit dans la nouvelle fonction Edge et a l'ecran.
--   Valeurs de public.gender en production : male, female (releve du pilote,
--   07/11/2026 07:50 UTC, en lecture).
-- L'exception d'age de la direction (3 a 5 ans, L2-08 reprise) ne change pas.
--
-- PHOTO-GEREE (directeur, 07/11/2026 : « on peut poser une photo sur TOUS les
-- profils que le tuteur gere ») : poser_photo_eleve exigeait student_type =
-- 'minor' ; un profil cree a 18 ans par « Ajouter un profil » (autonomous,
-- releve en production le 07/11 : cree par le tuteur titulaire, child_of dans
-- app_metadata, courriel non confirme, jamais connecte) restait sans photo, le
-- fichier deja depose dans le seau. Retouche par ancre : est accepte tout
-- profil eleve du foyer dont le compte a ete cree par un tuteur
-- (auth.users.raw_app_meta_data ? 'child_of', la marque que pose la fonction
-- Edge creer-profil-enfant), jamais l'appelant lui-meme. Un profil qui a son
-- propre compte (inscrit « pour moi ») pose sa photo par poser_ma_photo.
-- Preflight : md5(pg_get_functiondef) de production 5858689e… (07/11). La
-- ligne de la liste blanche AF-LB n'est pas touchee.
--
-- Preflight : md5(pg_get_functiondef) de production, 52fa1414… (sept
-- parametres) et 28c612af… (six parametres), relus le 06/11 et identiques a
-- la base rejouee depuis le depot ; chaque ancre presente exactement une fois.
-- Rejeu : les retouches deja la (marqueur « profil du titulaire »), rien n'est
-- reapplique.
begin;

-- ---------------------------------------------------------------------------
-- 1. Preflight
-- ---------------------------------------------------------------------------
do $preflight$
declare
  v_def7 text := pg_catalog.pg_get_functiondef(
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure);
  v_def6 text := pg_catalog.pg_get_functiondef(
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)'::regprocedure);
begin
  if pg_catalog.md5(v_def6) <> '28c612afa2017b1247898a4b13d273d7' then
    raise exception 'MINEUR-FANTOME : la surcharge a six parametres a change (md5 %)',
      pg_catalog.md5(v_def6);
  end if;
  if pg_catalog.md5(v_def7) <> '52fa141491170592a9041094880c322d'
     and pg_catalog.strpos(v_def7, 'profil du titulaire') = 0 then
    raise exception 'MINEUR-FANTOME : la surcharge a sept parametres a change depuis la lecture du 06/11 (md5 %)',
      pg_catalog.md5(v_def7);
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. Retouches par ancres (sautees au rejeu)
-- ---------------------------------------------------------------------------
create or replace function pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
returns void
language plpgsql
as $function$
declare
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
begin
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  if v_n <> p_n then
    raise exception '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  end if;
  execute pg_catalog.replace(v_def, p_avant, p_apres);
end;
$function$;

do $retouches$
declare
  v_f constant pg_catalog.regprocedure :=
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure;
begin
  if pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f), 'profil du titulaire') > 0 then
    raise notice 'MINEUR-FANTOME : retouches deja presentes, rien n''est reapplique';
    return;
  end if;

  -- 2.1 La variable du genre.
  perform pg_temp.remplacer(v_f,
    $a$  v_exception boolean;
begin$a$,
    $b$  v_exception boolean;
  v_genre text;
begin$b$, 1);

  -- 2.2 18 ans ou plus, et le titulaire lui-meme : refuses avant toute
  -- lecture d'auth.users et toute ecriture.
  perform pg_temp.remplacer(v_f,
    $a$    raise exception 'âge minimum 6 ans' using errcode = 'check_violation';
  end if;$a$,
    $b$    raise exception 'âge minimum 6 ans' using errcode = 'check_violation';
  end if;
  -- MINEUR-FANTOME (06/11/2026) : un profil eleve cree ici est un mineur.
  if p_age >= 18 then
    raise exception 'age adulte : un profil eleve de 18 ans ou plus ne se cree pas ici ; pour soi-meme, creer mon profil eleve'
      using errcode = 'check_violation';
  end if;
  -- MINEUR-FANTOME : le titulaire ne se recree pas en mineur (memes prenom et
  -- nom, sans casse, accents latins courants ni espaces doubles).
  if pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.translate(
         pg_catalog.btrim(p_first_name) || ' ' || pg_catalog.btrim(p_last_name),
         'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿ',
         'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOoooooUUUUuuuuYyy')), '\s+', ' ', 'g')
     = pg_catalog.regexp_replace(pg_catalog.lower(pg_catalog.translate(
         pg_catalog.btrim(v_guardian.first_name) || ' ' || pg_catalog.btrim(v_guardian.last_name),
         'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖòóôõöÙÚÛÜùúûüÝýÿ',
         'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOoooooUUUUuuuuYyy')), '\s+', ' ', 'g') then
    raise exception 'profil du titulaire : ce prenom et ce nom sont ceux du titulaire ; pour soi-meme, creer mon profil eleve'
      using errcode = 'check_violation';
  end if;$b$, 1);

  -- 2.3 Le genre, lu dans les metadonnees serveur du compte cree par la
  -- fonction Edge (app_metadata), apres la verification de ce compte.
  perform pg_temp.remplacer(v_f,
    $a$  select coalesce((public.get_config('child_ui_mode_max_age', '9'::jsonb) #>> '{}')::integer, 9)$a$,
    $b$  -- MINEUR-FANTOME B (07/11/2026) : le genre de l'enfant. Absent, il reste
  -- accepte pour l'ancienne fonction Edge (B6) ; hors de public.gender, refuse.
  v_genre := nullif(pg_catalog.btrim(v_auth_user #>> '{raw_app_meta_data,gender}'), '');
  if v_genre is not null
     and not (v_genre = any (pg_catalog.enum_range(null::public.gender)::text[])) then
    raise exception 'genre_requis : le genre de l''eleve n''est pas une valeur connue'
      using errcode = 'check_violation';
  end if;

  select coalesce((public.get_config('child_ui_mode_max_age', '9'::jsonb) #>> '{}')::integer, 9)$b$, 1);

  -- 2.4 Le genre ecrit sur le profil.
  perform pg_temp.remplacer(v_f,
    $a$    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  values (p_auth_user_id, null, 'student', v_guardian.household_id,
    btrim(p_first_name), btrim(p_last_name), v_guardian.account_status)$a$,
    $b$    (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
  values (p_auth_user_id, null, 'student', v_guardian.household_id,
    btrim(p_first_name), btrim(p_last_name), v_guardian.account_status,
    v_genre::public.gender)$b$, 1);
end;
$retouches$;

-- Droits inchanges (create or replace les conserve) ; reaffirmes par prudence.
alter function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text) owner to postgres;
revoke all on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  from public, anon, service_role, agent_ro;
grant execute on function public.creer_profil_enfant(uuid, uuid, text, text, integer, text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 2 bis. PHOTO-GEREE : poser_photo_eleve, par ancre (sautee au rejeu)
-- ---------------------------------------------------------------------------
do $photo$
declare
  v_f constant pg_catalog.regprocedure := 'public.poser_photo_eleve(uuid,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef('public.poser_photo_eleve(uuid,text)'::regprocedure);
begin
  if pg_catalog.strpos(v_def, 'PHOTO-GEREE') > 0 then
    raise notice 'PHOTO-GEREE : retouche deja presente, rien n''est reapplique';
    return;
  end if;
  if pg_catalog.md5(v_def) <> '5858689e7465a174eff31a8f54530ae0' then
    raise exception 'PHOTO-GEREE : poser_photo_eleve a change depuis la lecture du 07/11 (md5 %)',
      pg_catalog.md5(v_def);
  end if;
  perform pg_temp.remplacer(v_f,
    $a$        WHERE sp.profile_id = p_eleve AND sp.deleted_at IS NULL
          AND sp.student_type = 'minor') THEN$a$,
    $b$        WHERE sp.profile_id = p_eleve AND sp.deleted_at IS NULL
          AND p_eleve IS DISTINCT FROM auth.uid()
          -- PHOTO-GEREE (07/11/2026) : tout profil eleve du foyer que le
          -- tuteur gere, c'est-a-dire cree par un tuteur (child_of), meme
          -- autonome ; jamais l'appelant lui-meme (poser_ma_photo).
          AND (sp.student_type = 'minor'
               OR EXISTS (SELECT 1 FROM auth.users u
                           WHERE u.id = sp.profile_id
                             AND u.raw_app_meta_data ? 'child_of'))) THEN$b$, 1);
end;
$photo$;

alter function public.poser_photo_eleve(uuid, text) owner to postgres;

do $allowlist_photo$
declare
  v_sig constant text := 'poser_photo_eleve(uuid,text)';
begin
  execute pg_catalog.format('comment on function public.poser_photo_eleve(uuid, text) is %L', pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_GUARDIAN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-07. PHOTOS-1. PHOTO-GEREE: tout profil eleve du foyer cree par un tuteur (child_of), jamais l appelant.',
    v_sig,
    pg_catalog.md5(pg_catalog.pg_get_functiondef('public.poser_photo_eleve(uuid,text)'::regprocedure))));
end;
$allowlist_photo$;

-- ---------------------------------------------------------------------------
-- 3. Empreinte F86 recalculee sur la definition reelle
-- ---------------------------------------------------------------------------
do $allowlist$
declare
  v_sig constant text := 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)';
begin
  execute pg_catalog.format('comment on function %s is %L', v_sig, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-07; L2-08 reprise D-6: exception d age bornee aux moins de 6 ans, tracee par l administration; MINEUR-FANTOME: refus de 18 ans ou plus et des prenom et nom du titulaire, genre lu dans app_metadata.',
    v_sig,
    pg_catalog.md5(pg_catalog.pg_get_functiondef(v_sig::regprocedure)),
    'AUTHENTICATED_GUARDIAN_OR_ADMIN_AGE_EXCEPTION_UNDER_6_AND_SERVER_CHILD_OF_RECENT_UNCONFIRMED_NO_SESSION_NO_PROFILE_MINOR_ONLY_NOT_SELF_GENDER_APP_METADATA'));
end;
$allowlist$;

-- ---------------------------------------------------------------------------
-- 4. Postflight
-- ---------------------------------------------------------------------------
do $postflight$
declare
  v_def text := pg_catalog.pg_get_functiondef(
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure);
begin
  if pg_catalog.strpos(v_def, 'p_age >= 18') = 0
     or pg_catalog.strpos(v_def, 'profil du titulaire') = 0
     or pg_catalog.strpos(v_def, 'age adulte') = 0
     or pg_catalog.strpos(v_def, 'genre_requis') = 0
     or pg_catalog.strpos(v_def, '{raw_app_meta_data,gender}') = 0
     or pg_catalog.strpos(v_def, 'v_genre::public.gender') = 0
     or pg_catalog.strpos(v_def, 'p_age between 3 and 5') = 0
     or pg_catalog.strpos(v_def, 'âge minimum 6 ans') = 0 then
    raise exception 'MINEUR-FANTOME postflight : regles absentes';
  end if;
  if pg_catalog.strpos(v_def, 'user_meta_data') > 0 then
    raise exception 'MINEUR-FANTOME postflight : user_metadata ne doit jamais etre lu';
  end if;
  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)'::regprocedure))
     <> '28c612afa2017b1247898a4b13d273d7' then
    raise exception 'MINEUR-FANTOME postflight : la surcharge a six parametres a bouge';
  end if;
  if pg_catalog.has_function_privilege('anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or pg_catalog.has_function_privilege('service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE')
     or not pg_catalog.has_function_privilege('authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)', 'EXECUTE') then
    raise exception 'MINEUR-FANTOME postflight : droits EXECUTE incorrects';
  end if;
  if pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.poser_photo_eleve(uuid,text)'::regprocedure),
                       'raw_app_meta_data ? ''child_of''') = 0
     or pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.poser_photo_eleve(uuid,text)'::regprocedure),
                       'p_eleve IS DISTINCT FROM auth.uid()') = 0
     or pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.poser_photo_eleve(uuid,text)'::regprocedure),
                       'photo d''''un enfant reservee a son tuteur') = 0 then
    raise exception 'PHOTO-GEREE postflight : garde absente ou modifiee';
  end if;
  if pg_catalog.has_function_privilege('anon', 'public.poser_photo_eleve(uuid,text)', 'EXECUTE')
     or not pg_catalog.has_function_privilege('authenticated', 'public.poser_photo_eleve(uuid,text)', 'EXECUTE')
     or not exists (select 1 from pg_catalog.pg_proc p
                     where p.oid = 'public.poser_photo_eleve(uuid,text)'::regprocedure
                       and p.prosecdef and p.proconfig @> array['search_path=""']::text[]) then
    raise exception 'PHOTO-GEREE postflight : droits, DEFINER ou search_path incorrects';
  end if;
  if not exists (
       select 1 from pg_catalog.pg_proc p
        where p.oid = 'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'::regprocedure
          and p.prosecdef
          and p.proconfig @> array['search_path=""']::text[]
          and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres') then
    raise exception 'MINEUR-FANTOME postflight : SECURITY DEFINER, search_path ou proprietaire incorrect';
  end if;
end;
$postflight$;

commit;
