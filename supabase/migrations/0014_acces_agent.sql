-- ============================================================
-- 0014_acces_agent.sql -- Acces des agents IA a l'application (ADR-025)
-- ============================================================
--
-- Ce que cette migration ouvre : l'operateur emet un jeton, choisit un parcours
-- et une personne, et un agent IA peut alors OUVRIR L'APPLICATION DEPLOYEE dans
-- un navigateur et lire exactement ce que cette personne lit. Rien de plus.
--
-- Les cinq regles qui tiennent ce fichier. Elles viennent toutes d'un defaut
-- deja paye sur l'autre produit de l'operateur (console PISI, 05/08/2026), et
-- elles sont ecrites ici parce qu'une regle qui vit dans la memoire d'un agent
-- n'est pas lue par le suivant.
--
--   1. **Le privilege est accorde a la REQUETE, jamais au COMPTE.** Aucun compte
--      de service n'est cree, aucun `role` de profil n'est eleve. Il n'existe
--      donc rien a voler qui survive au jeton.
--
--   2. **La lecture seule est un defaut de PRIVILEGE POSTGRES, pas une
--      politesse d'interface.** Le jeton fait parler PostgREST sous le role
--      `agent_ro`, qui ne detient AUCUN droit d'ecriture sur aucune table. Un
--      agent qui clique « Annuler la seance », ou qui rejoue la requete a la
--      main avec curl, recoit un refus du moteur. Masquer un bouton n'a jamais
--      empeche d'appeler l'action.
--
--   3. **La portee se lit EN BASE a chaque requete ; le jeton ne fait que
--      designer la ligne.** Le JWT ne porte pas les droits, il porte un
--      identifiant opaque. Revoquer la ligne coupe l'acces au coup d'apres,
--      sans attendre l'expiration du jeton.
--
--   4. **Le plafond d'un agent est l'ecran de la personne qu'il observe.** Le
--      jeton est signe avec `sub` = la personne observee. Les 105 policies et
--      les dix vues de ce depot, qui se bornent deja par `auth.uid()`,
--      `app_household_id()` et `app_role()`, s'appliquent donc telles quelles.
--      Aucune regle de securite n'est reecrite pour l'occasion : c'est ce qui
--      evite d'en ecrire une deuxieme, divergente, qu'il faudrait maintenir.
--
--   5. **Un oubli fait echouer la lecture, jamais fuir l'ecriture.** Les
--      policies de ce depot sont toutes `to authenticated` : elles ne
--      s'appliquent donc PAS a `agent_ro` tant qu'on ne les etend pas une par
--      une. Le defaut est le silence. Une table ajoutee par une migration
--      future sera invisible a l'agent jusqu'a ce que quelqu'un le decide.
--
-- Ce que cette migration ne fait pas, volontairement :
--
--   * elle n'ouvre aucune ecriture, meme « inoffensive ». Pas de compteur
--     d'usage ecrit en cours de requete : PostgREST sert les GET dans une
--     transaction READ ONLY, un compteur y echouerait et casserait toute
--     lecture. L'usage se compte a la remise du jeton (section 5), pas au coup
--     par coup ;
--   * elle ne donne acces ni aux pieces KYC, ni aux appareils, ni au journal
--     d'audit, ni a la table des jetons elle-meme ;
--   * elle ne permet pas de RELEVER la portee d'un jeton. Aucune ligne de code
--     n'ecrit `parcours`, `profil_observe`, `identite_masquee` ni `expire_le`
--     apres l'insertion : un declencheur le refuse. Pour changer de portee, on
--     emet un autre jeton.

begin;

-- ============================================================
-- 1. Le role Postgres de l'agent
-- ============================================================
--
-- `nologin noinherit`, comme `anon` et `authenticated` : il ne se connecte
-- jamais lui-meme, PostgREST y bascule le temps d'une requete apres avoir
-- verifie la signature du jeton.
--
-- Il ne recoit ici que `usage` sur les schemas. Les droits de lecture sont
-- poses en section 7, table par table, et jamais par defaut.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'agent_ro') then
    create role agent_ro nologin noinherit;
  end if;
end;
$$;

-- `authenticator` n'existe pas dans le harnais SQL local (tests/stub_auth.sql
-- ne le cree pas) : sans cette garde, la migration ne serait pas rejouable sur
-- une base vide, ce qu'exige le critere 0.3 des fondations.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'authenticator') then
    execute 'grant agent_ro to authenticator';
  end if;
end;
$$;

grant usage on schema public to agent_ro;
grant usage on schema extensions to agent_ro;

-- ============================================================
-- 2. La table des jetons
-- ============================================================
--
-- Le secret n'est PAS stocke : seule son empreinte l'est, et un prefixe assez
-- long pour reconnaitre un jeton dans une liste sans jamais permettre de le
-- rejouer. Le secret n'existe en clair qu'une fois, dans la reponse de
-- `creer_jeton_agent()`.

create table public.jetons_agent (
  id uuid primary key default gen_random_uuid(),

  -- Ce que l'operateur lira dans la liste. Obligatoire : un jeton anonyme est
  -- un jeton que personne n'ose revoquer.
  libelle text not null,

  -- `rag_` + 8 caracteres. Assez pour identifier, trop peu pour rejouer.
  prefixe text not null,
  empreinte text not null,

  -- La personne observee. C'est elle, et elle seule, qui fixe le plafond de
  -- l'agent : le jeton sera signe avec son identifiant.
  profil_observe uuid not null references public.profiles(id),

  -- Redondant avec le role du profil observe, et c'est voulu : la portee est
  -- FIGEE a l'emission. Si le role du profil changeait plus tard, le jeton ne
  -- suivrait pas -- il deviendrait incoherent, et la section 5 le refuse.
  parcours public.app_role not null,

  identite_masquee boolean not null default true,

  expire_le timestamptz not null,
  revoque_le timestamptz,
  revoque_par uuid references public.profiles(id),

  cree_par uuid not null references public.profiles(id),
  cree_le timestamptz not null default now(),

  -- Compte les REMISES (echanges jeton -> session), pas les requetes : voir
  -- l'en-tete, une lecture ne doit rien ecrire.
  derniere_remise_le timestamptz,
  remises integer not null default 0,

  constraint jetons_agent_prefixe_unique unique (prefixe),
  constraint jetons_agent_empreinte_unique unique (empreinte),
  constraint jetons_agent_duree_positive check (expire_le > cree_le),
  -- Plafond cote SERVEUR. Une duree longue se demande en reemettant, elle ne
  -- se negocie pas dans le corps d'une requete.
  constraint jetons_agent_duree_plafonnee
    check (expire_le <= cree_le + interval '24 hours')
);

create index jetons_agent_vivants_idx
  on public.jetons_agent (expire_le desc)
  where revoque_le is null;

comment on table public.jetons_agent is
  'Jetons d''observation des agents IA (ADR-025). Lecture seule, bornee a '
  'l''ecran de la personne observee, revocable, plafonnee a 24 heures. Le '
  'secret n''y figure jamais, seulement son empreinte.';

alter table public.jetons_agent enable row level security;

-- Seule l'administration voit les jetons. `agent_ro` n'y a aucun droit : un
-- agent n'a pas a savoir quels autres agents observent quoi, ni a lire le
-- prefixe du jeton qui le porte.
create policy jetons_agent_admin_read on public.jetons_agent
  for select to authenticated
  using (public.app_role() = 'admin' and public.app_account_valid());

-- ============================================================
-- 3. La portee ne se releve pas
-- ============================================================
--
-- Lecon PISI, mot pour mot : « aucune ligne de code n'ecrit `scope` ni
-- `expires_at` ». Ici c'est le moteur qui l'interdit, pas la discipline.
-- Seuls la revocation et les compteurs de remise peuvent bouger.

create function public.guard_jeton_agent_immuable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
     or new.libelle is distinct from old.libelle
     or new.prefixe is distinct from old.prefixe
     or new.empreinte is distinct from old.empreinte
     or new.profil_observe is distinct from old.profil_observe
     or new.parcours is distinct from old.parcours
     or new.identite_masquee is distinct from old.identite_masquee
     or new.expire_le is distinct from old.expire_le
     or new.cree_par is distinct from old.cree_par
     or new.cree_le is distinct from old.cree_le
  then
    raise exception 'la portee d un jeton agent est figee a l emission'
      using errcode = '42501';
  end if;

  -- Une revocation ne se defait pas : rendre un jeton revoque ferait mentir
  -- toute trace deja ecrite.
  if old.revoque_le is not null and new.revoque_le is null then
    raise exception 'un jeton agent revoque ne se reactive pas'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger jetons_agent_immuable
  before update on public.jetons_agent
  for each row execute function public.guard_jeton_agent_immuable();

-- ============================================================
-- 4. La resolution -- le seul decideur
-- ============================================================
--
-- Le JWT ne porte qu'un identifiant opaque (`agent_token_id`). Tout le reste
-- -- qui est observe, sous quel parcours, avec ou sans identite, et si le
-- jeton est encore vivant -- se lit EN BASE. C'est ce qui rend la revocation
-- immediate au lieu d'attendre l'expiration du jeton signe.

create function public.agent_jeton_id()
returns uuid
language sql stable
set search_path = ''
as $$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'agent_token_id', '')::uuid;
$$;

comment on function public.agent_jeton_id() is
  'L''identifiant opaque porte par la session agent, ou NULL. Ne prouve rien '
  'a lui seul : la vivacite se verifie en base (agent_pre_request).';

-- Vrai des que la session SE PRESENTE comme une session d'agent, meme si son
-- jeton est mort. C'est volontaire : ce booleen commande le MASQUAGE, et le
-- sens sur : un jeton douteux masque plus, jamais moins.
create function public.app_est_agent()
returns boolean
language sql stable
set search_path = ''
as $$
  select public.agent_jeton_id() is not null;
$$;

create function public.agent_identite_masquee()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce(
    (select t.identite_masquee
       from public.jetons_agent t
      where t.id = public.agent_jeton_id()),
    -- Session agent dont la ligne a disparu : on masque.
    public.agent_jeton_id() is not null
  );
$$;

comment on function public.agent_identite_masquee() is
  'Commande la substitution du prenom par l''identifiant immuable dans les '
  'vues (section 9). Faux pour toute session humaine.';

-- Reservee au service : elle rend l'empreinte, donc jamais un client.
create function public.agent_jeton_vivant(p_id uuid)
returns public.jetons_agent
language sql stable security definer
set search_path = ''
as $$
  select t.*
  from public.jetons_agent t
  where t.id = p_id
    and t.revoque_le is null
    and t.expire_le > now();
$$;

-- ============================================================
-- 5. Emission, remise, revocation
-- ============================================================

create function public.creer_jeton_agent(
  p_libelle text,
  p_profil_observe uuid,
  p_duree_heures integer default 8,
  p_identite_masquee boolean default true
)
returns table (jeton text, jeton_id uuid, expire_le timestamptz)
language plpgsql volatile security definer
set search_path = ''
as $$
declare
  v_secret text;
  v_role public.app_role;
  v_id uuid;
  v_expire timestamptz;
  v_immuable text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'emission reservee a l administration'
      using errcode = '42501';
  end if;

  if coalesce(btrim(p_libelle), '') = '' then
    raise exception 'un jeton sans libelle ne se revoque jamais : libelle obligatoire'
      using errcode = '22023';
  end if;

  if p_duree_heures is null or p_duree_heures < 1 or p_duree_heures > 24 then
    raise exception 'duree hors bornes : de 1 a 24 heures'
      using errcode = '22023';
  end if;

  select p.role, p.immutable_id into v_role, v_immuable
  from public.profiles p
  where p.id = p_profil_observe
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_role is null then
    raise exception 'profil observe introuvable, supprime ou inactif'
      using errcode = '23503';
  end if;

  -- 32 octets d'alea. `gen_random_bytes` vient de pgcrypto, installe en schema
  -- `extensions` par 0001 ; l'appel est qualifie parce que `search_path` est
  -- vide.
  v_secret := 'rag_' || encode(extensions.gen_random_bytes(32), 'hex');
  v_expire := now() + make_interval(hours => p_duree_heures);

  insert into public.jetons_agent (
    libelle, prefixe, empreinte, profil_observe, parcours,
    identite_masquee, expire_le, cree_par
  )
  values (
    btrim(p_libelle),
    left(v_secret, 12),
    encode(extensions.digest(convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'),
    p_profil_observe,
    v_role,
    coalesce(p_identite_masquee, true),
    v_expire,
    auth.uid()
  )
  returning public.jetons_agent.id into v_id;

  perform public.log_sensitive_access(
    'agent_token_issued', 'jetons_agent', v_id::text,
    jsonb_build_object(
      'libelle', btrim(p_libelle),
      'parcours', v_role::text,
      'profil_observe', v_immuable,
      'identite_masquee', coalesce(p_identite_masquee, true),
      'expire_le', v_expire
    )
  );

  -- Le secret ne repassera jamais par ici.
  return query select v_secret, v_id, v_expire;
end;
$$;

comment on function public.creer_jeton_agent(text, uuid, integer, boolean) is
  'Emet un jeton d''observation. Rend le secret UNE SEULE FOIS. Le parcours '
  'est celui du profil observe, jamais un parcours demande par l''appelant.';

create function public.revoquer_jeton_agent(p_id uuid)
returns boolean
language plpgsql volatile security definer
set search_path = ''
as $$
declare
  v_libelle text;
begin
  if public.app_role() <> 'admin' or not public.app_account_valid() then
    raise exception 'revocation reservee a l administration'
      using errcode = '42501';
  end if;

  update public.jetons_agent
     set revoque_le = now(), revoque_par = auth.uid()
   where id = p_id and revoque_le is null
  returning libelle into v_libelle;

  if v_libelle is null then
    return false;
  end if;

  perform public.log_sensitive_access(
    'agent_token_revoked', 'jetons_agent', p_id::text,
    jsonb_build_object('libelle', v_libelle)
  );
  return true;
end;
$$;

-- La remise : le seul endroit qui transforme un secret en session. Reservee au
-- service (fonction Edge `agent-session`), comme `consommer_code_appairage`,
-- parce qu'elle doit lire l'empreinte de TOUS les jetons pour en reconnaitre
-- un -- ce qu'aucun client ne doit pouvoir faire.
create function public.remettre_session_agent(p_jeton text)
returns table (
  jeton_id uuid,
  profil_observe uuid,
  parcours public.app_role,
  foyer uuid,
  identite_masquee boolean,
  expire_le timestamptz
)
language plpgsql volatile security definer
set search_path = ''
as $$
declare
  v_empreinte text;
  v_ligne public.jetons_agent;
  v_profil public.profiles;
begin
  if coalesce(btrim(p_jeton), '') = '' then
    raise exception 'jeton absent' using errcode = '28000';
  end if;

  v_empreinte := encode(
    extensions.digest(convert_to(p_jeton, 'UTF8'), 'sha256'), 'hex');

  select * into v_ligne
  from public.jetons_agent t
  where t.empreinte = v_empreinte;

  -- Un message unique pour les trois cas. « Jeton inconnu » et « jeton expire »
  -- se distinguent pour le porteur legitime, pas pour celui qui essaie.
  if v_ligne.id is null
     or v_ligne.revoque_le is not null
     or v_ligne.expire_le <= now()
  then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  select * into v_profil
  from public.profiles p
  where p.id = v_ligne.profil_observe
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active');

  if v_profil.id is null then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  -- Le parcours a ete FIGE a l'emission. Si le role du profil a change depuis,
  -- le jeton ne decrit plus la realite : il ne se rattrape pas en silence.
  if v_profil.role <> v_ligne.parcours then
    raise exception 'jeton refuse' using errcode = '28000';
  end if;

  update public.jetons_agent
     set derniere_remise_le = now(), remises = remises + 1
   where id = v_ligne.id;

  perform public.log_sensitive_access(
    'agent_session_opened', 'jetons_agent', v_ligne.id::text,
    jsonb_build_object(
      'libelle', v_ligne.libelle,
      'parcours', v_ligne.parcours::text,
      'profil_observe', v_profil.immutable_id
    )
  );

  return query
    select v_ligne.id, v_profil.id, v_ligne.parcours, v_profil.household_id,
           v_ligne.identite_masquee, v_ligne.expire_le;
end;
$$;

-- La liste que lit l'ecran d'administration. Ni empreinte, ni secret.
create function public.jetons_agent_actifs()
returns table (
  id uuid,
  libelle text,
  prefixe text,
  parcours public.app_role,
  profil_observe uuid,
  observe_identifiant text,
  observe_prenom text,
  identite_masquee boolean,
  expire_le timestamptz,
  revoque_le timestamptz,
  cree_le timestamptz,
  derniere_remise_le timestamptz,
  remises integer,
  etat text
)
language sql stable security definer
set search_path = ''
as $$
  select
    t.id, t.libelle, t.prefixe, t.parcours, t.profil_observe,
    p.immutable_id, p.first_name,
    t.identite_masquee, t.expire_le, t.revoque_le, t.cree_le,
    t.derniere_remise_le, t.remises,
    case
      when t.revoque_le is not null then 'revoque'
      when t.expire_le <= now()     then 'expire'
      else 'actif'
    end
  from public.jetons_agent t
  join public.profiles p on p.id = t.profil_observe
  where public.app_role() = 'admin' and public.app_account_valid()
  order by
    case when t.revoque_le is null and t.expire_le > now() then 0 else 1 end,
    t.cree_le desc;
$$;

-- ============================================================
-- 6. Le garde central : la revocation prend effet a la requete suivante
-- ============================================================
--
-- PostgREST appelle `db_pre_request` au debut de CHAQUE requete, avant la
-- requete elle-meme. C'est le seul endroit du systeme traverse par tout ce que
-- l'agent fait -- lectures de tables, de vues et appels de fonctions compris.
--
-- Elle ne fait que LIRE et, le cas echeant, refuser : PostgREST sert les GET
-- dans une transaction READ ONLY, et toute ecriture ici casserait chaque
-- lecture de l'application entiere, pour tout le monde. Elle est donc `stable`
-- et non `volatile` -- ce qui la rend aussi conforme a l'invariant I2, qui
-- interdit toute fonction volatile a `agent_ro`.
--
-- ⚠ ELLE S'EXECUTE SOUS LE ROLE DE LA REQUETE, pas sous `authenticator` :
-- PostgREST bascule de role AVANT d'appeler `db_pre_request`. L'appelant est
-- donc `anon`, `authenticated` ou `agent_ro`, et chacun des trois doit pouvoir
-- l'executer. La lui refuser ferait echouer **toutes** les requetes de
-- l'application, pour tout le monde. Les droits sont poses en section 8, et un
-- controle d'invariant les verifie.
--
-- Elle rend la main immediatement pour une session humaine : un seul acces a
-- un champ JSON deja parse, aucun acces disque.

create function public.agent_pre_request()
returns void
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_vivant boolean;
begin
  v_id := public.agent_jeton_id();
  if v_id is null then
    return;                       -- session humaine : on ne fait rien du tout
  end if;

  select true into v_vivant
  from public.jetons_agent t
  where t.id = v_id
    and t.revoque_le is null
    and t.expire_le > now();

  if v_vivant is null then
    raise exception 'jeton agent revoque ou expire'
      using errcode = '42501';
  end if;
end;
$$;

-- Ne jamais ecraser en silence un `db_pre_request` que quelqu'un d'autre aurait
-- pose : on prefere echouer ici, a froid, qu'en production.
do $$
declare
  v_cfg text[];
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticator') then
    return;                       -- harnais SQL local : rien a configurer
  end if;

  select s.setconfig into v_cfg
  from pg_db_role_setting s
  where s.setrole = (select oid from pg_roles where rolname = 'authenticator');

  if exists (
    select 1 from unnest(coalesce(v_cfg, '{}'::text[])) c
    where c like 'pgrst.db\_pre\_request=%'
      and c <> 'pgrst.db_pre_request=public.agent_pre_request'
  ) then
    raise exception
      'un pgrst.db_pre_request different est deja configure : le chainer a la main';
  end if;

  execute 'alter role authenticator set pgrst.db_pre_request = ''public.agent_pre_request''';
end;
$$;

-- ============================================================
-- 7. Les droits de lecture
-- ============================================================
--
-- Rappel de la regle 5 de l'en-tete : les 105 policies de ce depot sont toutes
-- `to authenticated`. Elles ne s'appliquent donc pas a `agent_ro`, et le defaut
-- de `agent_ro` est de ne rien voir. Cette section ouvre, table par table.
--
-- Trois exclusions, et leurs raisons :
--   * `profiles` recoit une policy DEDIEE (plus bas) et non l'extension des
--     siennes : c'est la seule table ou le masquage d'identite ne peut pas
--     passer par une expression, la RLS bornant les LIGNES et jamais les
--     COLONNES ;
--   * `kyc_documents` et `devices` ne sont pas ouverts du tout. Une piece
--     d'identite de mineur et une empreinte d'appareil n'ont aucune raison de
--     traverser un agent. Les ecrans qui les lisent echoueront pour l'agent,
--     bruyamment : c'est le bon sens de panne ;
--   * `audit_logs` non plus : l'observation ne lit pas la trace des autres.
--
-- Etendre une policy `for all` est sans effet sur l'ecriture : sans le
-- privilege INSERT/UPDATE/DELETE, une policy permissive ne rend rien possible.
-- La RLS filtre, elle n'accorde pas.

do $$
declare
  r record;
  v_roles text;
begin
  for r in
    select schemaname, tablename, policyname, roles
    from pg_policies
    where schemaname = 'public'
      and cmd in ('SELECT', 'ALL')
      and 'authenticated' = any(roles)
      and not ('agent_ro' = any(roles))
      and tablename not in (
        'profiles', 'kyc_documents', 'devices',
        'audit_logs', 'audit_logs_default', 'jetons_agent'
      )
  loop
    select string_agg(quote_ident(x), ', ')
      into v_roles
      from unnest(r.roles || 'agent_ro'::name) as x;

    execute format('alter policy %I on %I.%I to %s',
                   r.policyname, r.schemaname, r.tablename, v_roles);
  end loop;
end;
$$;

-- `profiles` : une seule policy, ecrite pour l'agent.
--
-- Jeton masquant : l'agent ne lit QU'UNE ligne, celle de la personne observee.
-- Il a besoin de celle-la -- l'application ne sait pas demarrer sans savoir qui
-- elle est -- et d'aucune autre. Les autres personnes lui parviennent par les
-- vues de la section 9, ou le prenom est remplace par l'identifiant immuable.
--
-- Jeton nominatif : le perimetre est exactement celui que la personne observee
-- verrait elle-meme, recopie de `profiles_admin_all` et `profiles_family_select`.
create policy profiles_agent_select on public.profiles
  for select to agent_ro
  using (
    deleted_at is null
    and (
      id = auth.uid()
      or (
        not public.agent_identite_masquee()
        and (
          public.app_role() = 'admin'
          or (
            household_id = public.app_household_id()
            and public.app_role() in ('guardian', 'accountant', 'controller')
          )
        )
      )
    )
  );

-- Les privileges de table. `grant select on all tables` couvre aussi les vues.
grant select on all tables in schema public to agent_ro;

-- Puis on retire, explicitement, ce qui ne doit jamais etre lu.
revoke all on public.jetons_agent from agent_ro;
revoke all on public.kyc_documents from agent_ro;
revoke all on public.devices from agent_ro;
revoke all on public.audit_logs from agent_ro;
revoke all on public.audit_logs_default from agent_ro;

-- Ceinture et bretelles : meme si un `grant` futur se trompait de role, il n'y
-- a aucune ecriture a accorder ici.
revoke insert, update, delete, truncate, references, trigger
  on all tables in schema public from agent_ro;
revoke all on all sequences in schema public from agent_ro;

-- ============================================================
-- 8. Les droits d'execution
-- ============================================================
--
-- Le vrai trou de cette architecture, et il est invisible : en PostgreSQL,
-- EXECUTE sur une fonction est accorde a PUBLIC PAR DEFAUT. `agent_ro`, qui est
-- membre de PUBLIC comme tout le monde, heriterait donc du droit d'appeler
-- toute fonction dont personne n'a pense a retirer ce defaut -- y compris une
-- fonction `security definer` qui ECRIT. Le role en lecture seule aurait alors
-- une porte d'ecriture.
--
-- 8.a -- On retire ce defaut, en preservant exactement l'existant : toute
-- fonction que PUBLIC pouvait appeler reste appelable par `anon`,
-- `authenticated` et `service_role`, c'est-a-dire par les trois seuls roles
-- clients du projet. Les proprietaires et les roles d'administration de
-- Supabase ne passent pas par PUBLIC.
--
-- ⚠ LES FONCTIONS D'EXTENSION SONT EXCLUES, et ce n'est pas un detail. En
-- production, `btree_gist` est installe dans `public` : ses 188 fonctions de
-- support d'index (`gbt_*`, `gbtreekey*`, `*_dist`) y sont ouvertes a PUBLIC
-- comme toutes les fonctions d'extension. Les refermer toucherait la
-- machinerie d'index -- dont la contrainte d'exclusion qui empeche deux
-- seances de se chevaucher -- pour un benefice nul : ces fonctions n'ecrivent
-- aucune donnee du projet et n'ouvrent aucune porte a `agent_ro`. Le trou
-- qu'on ferme ici est celui des fonctions DU PROJET, `security definer`
-- comprises. `pg_depend.deptype = 'e'` les distingue exactement.

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and has_function_privilege('public', p.oid, 'EXECUTE')
      and not exists (
        select 1 from pg_depend d
        where d.objid = p.oid and d.deptype = 'e'
      )
  loop
    execute format('revoke execute on function %s from public', r.signature);
    execute format(
      'grant execute on function %s to anon, authenticated, service_role',
      r.signature);
  end loop;
end;
$$;

-- 8.b -- Ce que l'agent peut appeler : l'intersection de deux criteres
-- mecaniques, jamais une liste tenue a la main (une liste s'oublie).
--
--   * la fonction est `stable` ou `immutable` : PostgreSQL REFUSE au moteur
--     toute modification de donnees dans une fonction non `volatile`. Elle ne
--     peut donc pas ecrire, quelle que soit son intention ;
--   * elle est deja appelable par `authenticated` : l'agent n'obtient jamais
--     une porte qu'un humain connecte n'a pas.
--
-- Les helpers de RLS (`app_role`, `app_household_id`, `partie_concernee`...)
-- entrent par ce chemin, et c'est necessaire : une expression de policy
-- s'evalue avec les droits de l'appelant.

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.provolatile in ('s', 'i')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')
      -- Les fonctions d'extension restent ouvertes a PUBLIC (8.a) : `agent_ro`
      -- y accede deja par la, il n'y a rien a lui accorder.
      and not exists (
        select 1 from pg_depend d
        where d.objid = p.oid and d.deptype = 'e'
      )
  loop
    execute format('grant execute on function %s to agent_ro', r.signature);
  end loop;
end;
$$;

-- L'administration des jetons n'est pas une lecture d'observation, meme
-- `stable` : un agent n'inventorie pas les acces de la maison.
revoke execute on function public.jetons_agent_actifs() from agent_ro;

-- Reservees au service : elles lisent l'empreinte ou franchissent la RLS.
revoke execute on function public.agent_jeton_vivant(uuid) from public, anon, authenticated, agent_ro;
grant execute on function public.agent_jeton_vivant(uuid) to service_role;

revoke execute on function public.remettre_session_agent(text) from public, anon, authenticated, agent_ro;
grant execute on function public.remettre_session_agent(text) to service_role;

revoke execute on function public.creer_jeton_agent(text, uuid, integer, boolean) from public, anon, agent_ro;
grant execute on function public.creer_jeton_agent(text, uuid, integer, boolean) to authenticated;

revoke execute on function public.revoquer_jeton_agent(uuid) from public, anon, agent_ro;
grant execute on function public.revoquer_jeton_agent(uuid) to authenticated;

revoke execute on function public.jetons_agent_actifs() from public, anon;
grant execute on function public.jetons_agent_actifs() to authenticated;

-- Le garde central, et le piege qu'il porte : PostgREST bascule de role AVANT
-- d'appeler `db_pre_request`. La fonction s'execute donc sous `anon`,
-- `authenticated` ou `agent_ro` selon la requete, jamais sous `authenticator`.
-- Les TROIS doivent pouvoir l'appeler : leur refuser ce droit ferait echouer
-- chaque requete de l'application, pour tout le monde.
--
-- L'ouvrir ne donne rien : la fonction ne prend aucun parametre, ne rend aucune
-- donnee, et ne lit que le jeton de l'appelant lui-meme. L'appeler a la main ne
-- fait donc rien d'autre que ce qu'elle fait deja a chaque requete.
revoke execute on function public.agent_pre_request() from public;
grant execute on function public.agent_pre_request()
  to anon, authenticated, service_role, agent_ro;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'authenticator') then
    execute 'grant execute on function public.agent_pre_request() to authenticator';
  end if;
end;
$$;

-- ============================================================
-- 9. Le masquage d'identite
-- ============================================================
--
-- Les dix vues de ce depot appartiennent a `postgres` et ne portent PAS
-- `security_invoker` : elles s'executent avec les droits de leur proprietaire
-- et ne voient donc pas la RLS des tables qu'elles lisent. Leur seule borne est
-- le `where ... = auth.uid()` (ou `app_household_id()`, ou `partie_concernee`)
-- ecrit dans leur corps -- 0011 a paye cette lecon pour `presence_seance_v`.
--
-- Cela tombe bien ici : le jeton etant signe avec `sub` = la personne observee,
-- ces bornes rendent a l'agent exactement les lignes de cette personne, sans
-- qu'aucune d'elles soit reecrite.
--
-- Reste le prenom. L'ADR-008 a deja exclu le nom de famille de ces vues ; pour
-- un jeton masquant, le prenom lui-meme cede la place a l'identifiant immuable.
-- C'est le seul endroit ou le masquage peut etre DUR : la RLS borne les lignes,
-- jamais les colonnes, et une donnee substituee dans la vue ne quitte pas la
-- base.
--
-- Les huit vues ci-dessous sont recopiees a l'identique de leur derniere
-- definition (0004, 0005, 0006, 0011, 0012), a l'expression du prenom pres.
-- `create or replace view` impose de garder noms et types de colonnes : c'est
-- le cas, `first_name` et `immutable_id` sont tous deux `text`.

create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  case when public.agent_identite_masquee()
       then p.immutable_id else p.first_name end as first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key,
  p.access_until
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null;

create or replace view public.mes_appareils_v
with (security_barrier = true)
as
select
  d.id,
  d.profile_id,
  case when public.agent_identite_masquee()
       then p.immutable_id else p.first_name end as first_name,
  d.platform,
  d.label,
  d.paired_at,
  d.last_used_at,
  d.revoked_at
from public.devices d
join public.profiles p on p.id = d.profile_id
where d.deleted_at is null
  and p.deleted_at is null
  and p.household_id is not null
  and p.household_id = public.app_household_id();

create or replace view public.teacher_roster_v
with (security_barrier = true)
as
select distinct
  s.id as session_id,
  p.id as student_id,
  case when public.agent_identite_masquee()
       then p.immutable_id else p.first_name end as first_name,
  p.immutable_id,
  sp.level,
  sp.riwaya
from public.sessions s
join public.session_participants spart on spart.session_id = s.id
join public.profiles p on p.id = spart.profile_id
join public.student_profiles sp on sp.profile_id = p.id
where s.teacher_id = auth.uid()
  and s.deleted_at is null
  and spart.deleted_at is null
  and p.deleted_at is null;

create or replace view public.mes_seances_v
with (security_barrier = true)
as
select
  s.id as session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  s.prayer_pause_minutes,
  eleve.id as student_id,
  case when public.agent_identite_masquee()
       then eleve.immutable_id else eleve.first_name end as student_first_name,
  eleve.immutable_id as student_immutable_id,
  ens.id as teacher_id,
  case when public.agent_identite_masquee()
       then ens.immutable_id else ens.first_name end as teacher_first_name,
  ens.immutable_id as teacher_immutable_id
from public.sessions s
join public.session_participants spe
  on spe.session_id = s.id and spe.role = 'student' and spe.deleted_at is null
join public.profiles eleve on eleve.id = spe.profile_id and eleve.deleted_at is null
join public.profiles ens on ens.id = s.teacher_id and ens.deleted_at is null
where s.deleted_at is null
  and (
    s.teacher_id = auth.uid()
    or spe.profile_id = auth.uid()
    or (
      eleve.household_id is not null
      and eleve.household_id = public.app_household_id()
    )
    or public.app_role() in ('admin', 'controller')
  );

create or replace view public.mes_affectations_v
with (security_barrier = true)
as
select
  a.id,
  a.teacher_id,
  case when public.agent_identite_masquee()
       then ens.immutable_id else ens.first_name end as teacher_first_name,
  ens.immutable_id as teacher_immutable_id,
  a.student_id,
  case when public.agent_identite_masquee()
       then eleve.immutable_id else eleve.first_name end as student_first_name,
  eleve.immutable_id as student_immutable_id,
  a.weekday,
  a.hour_local,
  a.timezone_iana,
  a.created_at,
  a.ended_at
from public.teacher_student_assignments a
join public.profiles ens on ens.id = a.teacher_id and ens.deleted_at is null
join public.profiles eleve on eleve.id = a.student_id and eleve.deleted_at is null
where a.teacher_id = auth.uid()
   or public.partie_concernee(a.student_id);

create or replace view public.eleves_en_attente_v
with (security_barrier = true)
as
select
  e.id as student_id,
  case when public.agent_identite_masquee()
       then e.immutable_id else e.first_name end as first_name,
  e.immutable_id,
  sp.level,
  sp.interface_mode,
  we.weekday,
  we.hour_local,
  we.timezone_iana,
  attente.depuis
from public.profiles e
join public.student_profiles sp on sp.profile_id = e.id and sp.deleted_at is null
join public.weekly_availability we on we.profile_id = e.id
join public.weekly_availability wt on wt.profile_id = auth.uid()
  and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
    = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
join lateral (
  select min(w2.created_at) as depuis
  from public.weekly_availability w2 where w2.profile_id = e.id
) attente on true
where e.role = 'student'
  and e.deleted_at is null
  and e.account_status in ('active', 'provisional_active')
  and public.app_role() = 'teacher'
  and not exists (
    select 1 from public.teacher_student_assignments a
    where a.student_id = e.id and a.ended_at is null
  );

create or replace view public.presence_seance_v
with (security_barrier = true)
as
select
  sp.session_id,
  sp.profile_id,
  sp.role,
  -- Prenom et identifiant immuable, jamais le nom de famille (ADR-008) ; et
  -- pour une session d'agent masquant, l'identifiant a la place du prenom.
  case when public.agent_identite_masquee()
       then p.immutable_id else p.first_name end as prenom,
  p.immutable_id as identifiant_immuable,
  public.etat_presence(sp.session_id, sp.profile_id) as etat,
  (select min(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id
      and e.event_type = 'joined')                   as entre_le,
  (select max(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id)              as derniere_trace_le,
  (o.etat is not null)                               as consolide,
  o.decide_le                                        as consolide_le,
  s.started_at,
  s.ended_at,
  s.status                                           as statut_seance
from public.session_participants sp
join public.sessions s on s.id = sp.session_id
join public.profiles p on p.id = sp.profile_id
left join public.session_presence_override o
       on o.session_id = sp.session_id
      and o.profile_id = sp.profile_id
where sp.deleted_at is null
  and s.deleted_at is null
  and p.deleted_at is null
  and (
    public.app_role() in ('admin', 'controller')
    or s.teacher_id = auth.uid()
    or (public.app_role() = 'guardian'
        and p.household_id = public.app_household_id())
    or sp.profile_id = auth.uid()
  )
  and (sp.role <> 'masked_controller' or public.app_role() = 'admin');

create or replace view public.session_peers_v
with (security_barrier = true)
as
select distinct
  sp.session_id,
  p2.id as peer_id,
  case when public.agent_identite_masquee()
       then p2.immutable_id else p2.first_name end as first_name,
  p2.immutable_id
from public.session_participants sp
join public.session_participants sp2 using (session_id)
join public.profiles p2 on p2.id = sp2.profile_id
where sp.profile_id = auth.uid()
  and sp.deleted_at is null
  and sp2.deleted_at is null
  and p2.deleted_at is null
  and sp2.profile_id <> sp.profile_id
  and (sp2.role <> 'masked_controller' or public.app_role() = 'admin');

-- ============================================================
-- 10. Les invariants, verifies a l'application de la migration
-- ============================================================
--
-- Une migration de securite qui ne prouve rien n'est qu'une intention. Ces
-- quatre controles echouent la migration plutot que de laisser passer un trou.

do $$
declare
  v_n integer;
  v_detail text;
begin
  -- I1 : aucune ecriture, nulle part.
  select count(*), string_agg(distinct c.relname, ', ')
    into v_n, v_detail
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p', 'v', 'm', 'f')
    and (
      has_table_privilege('agent_ro', c.oid, 'INSERT')
      or has_table_privilege('agent_ro', c.oid, 'UPDATE')
      or has_table_privilege('agent_ro', c.oid, 'DELETE')
    );
  if v_n > 0 then
    raise exception 'I1 : agent_ro peut ecrire sur % objet(s) : %', v_n, v_detail;
  end if;

  -- I2 : aucune fonction volatile DU PROJET n'est appelable.
  --
  -- Les fonctions d'extension sont hors sujet et restent ouvertes a PUBLIC
  -- (section 8.a) : elles n'ecrivent aucune donnee du projet, et les refermer
  -- couterait la machinerie d'index sans rien fermer.
  select count(*), string_agg(p.proname, ', ')
    into v_n, v_detail
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prokind = 'f'
    and p.provolatile = 'v'
    and has_function_privilege('agent_ro', p.oid, 'EXECUTE')
    and not exists (
      select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e'
    );
  if v_n > 0 then
    raise exception 'I2 : agent_ro peut appeler % fonction(s) volatile(s) : %',
      v_n, v_detail;
  end if;

  -- I3 : les tables fermees le sont.
  select count(*), string_agg(c.relname, ', ')
    into v_n, v_detail
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('jetons_agent', 'kyc_documents', 'devices', 'audit_logs')
    and has_table_privilege('agent_ro', c.oid, 'SELECT');
  if v_n > 0 then
    raise exception 'I3 : agent_ro lit % table(s) fermee(s) : %', v_n, v_detail;
  end if;

  -- I4 : la table des jetons n'accorde sa lecture qu'a l'administration.
  select count(*) into v_n
  from pg_policies
  where schemaname = 'public' and tablename = 'jetons_agent';
  if v_n <> 1 then
    raise exception 'I4 : jetons_agent porte % policies, 1 attendue', v_n;
  end if;

  -- I5 : le garde central est appelable par TOUS les roles de requete.
  --
  -- C'est l'invariant le plus important de ce fichier, et le moins evident :
  -- PostgREST appelle `db_pre_request` APRES avoir bascule de role. Si l'un
  -- des trois roles ne peut pas l'executer, **toutes** les requetes de
  -- l'application echouent, pour tout le monde. Ce controle existe parce que
  -- le defaut a ete ecrit une fois, et qu'aucun harnais Postgres nu ne peut le
  -- voir : il n'y a pas de PostgREST dedans.
  select string_agg(r, ', ') into v_detail
  from unnest(array['anon', 'authenticated', 'agent_ro']) as r
  where not has_function_privilege(
    r, 'public.agent_pre_request()', 'EXECUTE');
  if v_detail is not null then
    raise exception
      'I5 : le garde central est refuse a % -- toute requete de ces roles echouerait',
      v_detail;
  end if;
end;
$$;

commit;

-- PostgREST relit sa configuration hors transaction.
notify pgrst, 'reload config';
